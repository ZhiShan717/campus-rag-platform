<!--
  问答页 —— 对应计划 10.25「问答页面外壳」+ 10.28「标注条款检索模式」+ 10.29「对接真实 ask，三态」

  这一页是整个演示的主角，四条规则写死在这里：
  1. 四种状态互斥且外观不同：idle / loading / hit / noEvidence / error
  2. 只有后端返回 status === 'NO_EVIDENCE' 才算"无依据"；
     网络失败、超时、5xx 一律走 error，绝不当成无依据（计划 10.30 验收第 8 条）
  3. 没有真实模型时页面写"条款检索模式"，只有 mode === 'RAG' 才写"RAG 问答模式"
  4. 临时固定答案已移除。要离线看效果，见本文件底部注释，别写死在组件里。
-->
<template>
  <div class="ask-page">
    <!-- 顶部：模式与能力状态 -->
    <header class="ask-head">
      <div>
        <h1>制度问答</h1>
        <p class="sub">围绕奖助学金制度提问，回答只引用现行有效版本，并给出条款原文。</p>
      </div>

      <div class="mode-box">
        <el-tag :type="modeTag.type" effect="plain" size="small">{{ modeTag.text }}</el-tag>
        <el-tag
          v-if="features.generation === 'unavailable'"
          type="info"
          effect="plain"
          size="small"
        >
          生成能力未启用
        </el-tag>
      </div>
    </header>

    <!-- 提问区 -->
    <section class="ask-form">
      <el-input
        v-model="question"
        type="textarea"
        :rows="3"
        maxlength="200"
        show-word-limit
        resize="none"
        placeholder="例如：国家励志奖学金的申请条件是什么？"
        :disabled="state === 'loading'"
        @keydown.ctrl.enter="onAsk"
      />
      <div class="ask-actions">
        <span class="tip">Ctrl + Enter 快速提问</span>
        <el-button
          type="primary"
          :loading="state === 'loading'"
          :disabled="!question.trim()"
          @click="onAsk"
        >
          {{ state === 'loading' ? '检索中…' : '提 问' }}
        </el-button>
      </div>
    </section>

    <!-- 结果区：五态之一 -->
    <section class="ask-result">
      <!-- ① 空态 -->
      <el-empty
        v-if="state === 'idle'"
        description="输入问题后开始检索，回答会附上可展开的条款原文"
        :image-size="82"
      />

      <!-- ② 加载态 -->
      <div v-else-if="state === 'loading'" class="panel">
        <el-skeleton :rows="3" animated />
        <p class="loading-tip">正在过滤有效版本 → 检索候选条款 → 核验引用…</p>
      </div>

      <!-- ③ 命中 -->
      <div v-else-if="state === 'hit'" class="panel">
        <div class="panel-head">
          <el-tag :type="modeTag.type" size="small" effect="plain">{{ modeTag.text }}</el-tag>
          <span class="meta">共 {{ citations.length }} 条引用 · 耗时 {{ costMs }} ms</span>
        </div>

        <p v-if="answer" class="answer">{{ answer }}</p>

        <!-- 命中但零引用：接口异常，必须显式说出，不能让用户以为"有依据" -->
        <el-alert
          v-if="!citations.length"
          type="warning"
          :closable="false"
          show-icon
          title="接口返回命中，但没有返回任何引用"
          description="这属于接口异常（不是无依据）。请联系后端确认 /api/qa/ask 的 citations 字段。"
        />

        <div v-else class="cite-list">
          <CitationCard
            v-for="(item, index) in citations"
            :key="item.chunkId || item.chunk_id || index"
            :citation="item"
            :index="index"
          />
        </div>
      </div>

      <!-- ④ 无依据：正常业务结果，不是错误 -->
      <div v-else-if="state === 'noEvidence'" class="panel no-evidence">
        <el-result icon="info" title="未找到可依据的条款" sub-title="本次检索没有命中现行有效的制度条款。">
          <template #extra>
            <p class="no-evidence-tip">
              可能原因：问题超出当前制度库范围，或涉及的是旧版 / 已废止 / 尚未生效的条款。
              请换个说法，或联系管理员确认制度是否已录入。
            </p>
            <el-button @click="onAsk">重新提问</el-button>
          </template>
        </el-result>
      </div>

      <!-- ⑤ 服务异常：与"无依据"严格区分 -->
      <div v-else-if="state === 'error'" class="panel error-panel">
        <el-alert
          :title="errorInfo.title"
          :description="errorInfo.detail"
          :type="errorInfo.type"
          :closable="false"
          show-icon
        />
        <div class="error-actions">
          <el-button v-if="errorInfo.action === 'retry'" type="primary" plain @click="onAsk">
            重试
          </el-button>
          <el-button v-if="errorInfo.action === 'relogin'" type="primary" @click="goLogin">
            去登录
          </el-button>
          <span class="err-code">kind: {{ errorKind }}</span>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import CitationCard from '../components/CitationCard.vue'
import { qaApi } from '../api/qa'
import { errorText } from '../utils/errorText'

const router = useRouter()

const question = ref('')
const state = ref('idle') // idle | loading | hit | noEvidence | error
const answer = ref('')
const citations = ref([])
const mode = ref('RETRIEVAL') // RETRIEVAL | RAG
const costMs = ref(0)
const errorInfo = ref({ title: '', detail: '', type: 'error', action: 'retry' })
const errorKind = ref('')
const features = ref({ retrieval: 'available', generation: 'unavailable' })

/** 模式文案：不许在没有模型时写"RAG 问答模式" */
const modeTag = computed(() =>
  mode.value === 'RAG'
    ? { text: 'RAG 问答模式', type: 'success' }
    : { text: '条款检索模式', type: 'primary' }
)

onMounted(loadFeatures)

async function loadFeatures() {
  try {
    const data = await qaApi.features()
    if (data) features.value = { ...features.value, ...data }
  } catch {
    // 能力接口没就绪不影响提问，默认按"检索模式"展示
    features.value = { retrieval: 'available', generation: 'unavailable' }
  }
}

/**
 * 归一化后端返回，容忍两种常见形状：
 *   A. { status, mode, answer, citations }        ← 计划里的推荐形状
 *   B. { result: {...} } 或 { code, msg, data:{} } ← 被 http.js 解包后的 data
 * TODO(确认)：与沈明昊对齐后，把下面这些兜底删掉，只留一种
 */
function normalize(raw) {
  const data = raw?.result || raw || {}
  const list = data.citations || data.refs || data.evidences || []
  const status =
    data.status ||
    data.result ||
    (Array.isArray(list) && list.length > 0 ? 'HIT' : 'NO_EVIDENCE')

  return {
    status: String(status).toUpperCase(),
    mode: String(data.mode || data.answerMode || 'RETRIEVAL').toUpperCase(),
    answer: data.answer || data.content || '',
    citations: Array.isArray(list) ? list : []
  }
}

async function onAsk() {
  if (state.value === 'loading') return

  const text = question.value.trim()
  if (!text) {
    ElMessage.warning('请先输入问题')
    return
  }

  // 切到加载态，同时清掉上一次结果，避免旧引用"粘"在新回答上
  state.value = 'loading'
  errorKind.value = ''
  answer.value = ''
  citations.value = []
  const startedAt = Date.now()

  try {
    const result = normalize(await qaApi.ask(text))
    costMs.value = Date.now() - startedAt
    mode.value = result.mode || 'RETRIEVAL'

    if (result.status === 'NO_EVIDENCE') {
      // ① 无依据：正常业务结果
      state.value = 'noEvidence'
      return
    }

    // ② 命中
    answer.value = result.answer
    citations.value = result.citations
    state.value = 'hit'
  } catch (err) {
    costMs.value = Date.now() - startedAt
    errorKind.value = err?.kind || 'SERVER'
    errorInfo.value = errorText(err)
    state.value = 'error' // ③ 服务异常：与无依据严格区分

    if (err?.kind === 'UNAUTHORIZED') {
      ElMessage.warning('登录已过期，请重新登录')
    }
  }
}

function goLogin() {
  router.replace({ name: 'login', query: { redirect: '/ask' } })
}

/* ---------------------------------------------------------------
 * 离线预览（仅在完全没有后端时临时用，10.29 之后删掉这段）
 *   1) 打开 ../mock/sampleCitations.js 复制 SAMPLE_ASK
 *   2) 在 onAsk 的 try 里临时替换：
 *        // const result = normalize(await qaApi.ask(text))
 *        const result = normalize(SAMPLE_ASK)
 *   3) 预览完立刻还原 —— 计划 10.29 明确要求"移除临时固定答案"
 * --------------------------------------------------------------- */
</script>

<style scoped>
.ask-page {
  max-width: 860px;
  margin: 0 auto;
  padding: 28px 20px 60px;
}

.ask-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
  margin-bottom: 18px;
}

.ask-head h1 {
  margin: 0;
  font-size: 22px;
  color: #1d4d76;
}

.ask-head .sub {
  margin: 6px 0 0;
  font-size: 13px;
  color: #617184;
  line-height: 1.7;
}

.mode-box {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  padding-top: 4px;
}

.ask-form {
  padding: 16px;
  background: #fff;
  border: 1px solid #dbe4ee;
  border-radius: 12px;
}

.ask-actions {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 12px;
}

.tip {
  font-size: 12px;
  color: #93a4b6;
}

.ask-result {
  margin-top: 18px;
}

.panel {
  padding: 18px;
  background: #fff;
  border: 1px solid #dbe4ee;
  border-radius: 12px;
}

.panel-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  flex-wrap: wrap;
  margin-bottom: 12px;
}

.meta {
  font-size: 12px;
  color: #93a4b6;
  font-variant-numeric: tabular-nums;
}

.answer {
  margin: 0 0 14px;
  padding: 12px 14px;
  font-size: 14.5px;
  line-height: 1.95;
  color: #22303f;
  background: #f7fafd;
  border-left: 3px solid #7fa8cc;
  border-radius: 8px;
  white-space: pre-wrap;
}

.cite-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.loading-tip {
  margin: 14px 0 0;
  font-size: 12.5px;
  color: #7b8ea3;
  text-align: center;
}

/* 无依据：中性偏蓝，不能用红色（红色代表故障） */
.no-evidence {
  border-color: #cfdff0;
}

.no-evidence-tip {
  max-width: 460px;
  margin: 0 auto 14px;
  font-size: 13px;
  line-height: 1.85;
  color: #617184;
  text-align: left;
}

/* 服务异常：红色描边，和无依据一眼区分 */
.error-panel {
  border-color: #f0cdc8;
  background: #fffafa;
}

.error-actions {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 14px;
  flex-wrap: wrap;
}

.err-code {
  font-size: 11.5px;
  color: #b9a9a6;
  font-family: Consolas, "Courier New", monospace;
}

@media (max-width: 640px) {
  .ask-page {
    padding: 18px 12px 40px;
  }

  .ask-head h1 {
    font-size: 19px;
  }
}
</style>
