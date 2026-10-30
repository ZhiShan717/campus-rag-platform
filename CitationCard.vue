<!--
  引用卡片 —— 对应计划 10.28：
  「完成引用卡片：文件名、版本、条款位置与原文；标注条款检索模式并处理空引用」

  计划第 02 节另有两条红线，也落在这个组件上：
  · 引用必须能展开出数据库里的真实原文（不是摘要、不是模型编的）
  · 引用编号存在只代表来源合法，不等于结论已被支持 —— 所以卡片只显示"源"，不评价"答得对"
-->
<template>
  <article class="cite-card" :class="{ 'is-empty': !hasContent }">
    <header class="cite-head">
      <div class="cite-title">
        <span class="cite-index">[{{ index + 1 }}]</span>
        <strong :title="docTitle">{{ docTitle || '未知文件' }}</strong>
        <el-tag v-if="versionNo" size="small" type="info" effect="plain" class="cite-version">
          {{ versionLabel }}
        </el-tag>
      </div>

      <el-button
        v-if="hasContent"
        link
        type="primary"
        size="small"
        @click="expanded = !expanded"
      >
        {{ expanded ? '收起原文' : '展开原文' }}
      </el-button>
    </header>

    <!-- 条款位置：sectionPath（章节路径）+ clauseNo（条款号） -->
    <p v-if="locationText" class="cite-location">
      <span class="cite-location-label">条款位置</span>
      {{ locationText }}
    </p>

    <!-- 原文：默认折叠，展开后显示真实 content -->
    <template v-if="hasContent">
      <p v-if="!expanded" class="cite-preview">{{ previewText }}</p>

      <blockquote v-else class="cite-body">
        {{ content }}
      </blockquote>
    </template>

    <!-- 空引用：明确提示"原文缺失"，绝不拿别的文字顶上 -->
    <p v-else class="cite-missing">
      该引用未返回原文内容（chunkId: {{ chunkId || '缺失' }}），请联系后端确认引用快照是否入库。
    </p>

    <footer class="cite-foot">
      <span class="cite-chunk">chunkId: {{ chunkId || '—' }}</span>
      <span v-if="expanded" class="cite-hint">原文来自数据库快照，与本次检索版本一致</span>
    </footer>
  </article>
</template>

<script setup>
import { computed, ref } from 'vue'

const props = defineProps({
  citation: { type: Object, required: true },
  index: { type: Number, default: 0 }
})

const expanded = ref(false)

/**
 * 字段兼容层。
 * TODO(确认)：与沈明昊/单成宇对齐真实字段名后，用 README 假设 3 的写法替换。
 * 这里兜底的目的是"字段小改不白屏"，但枚举值（status/mode）不做兼容，必须对齐。
 */
function pick(obj, keys) {
  for (const key of keys) {
    const value = obj?.[key]
    if (value !== undefined && value !== null && value !== '') return value
  }
  return ''
}

const chunkId = computed(() => pick(props.citation, ['chunkId', 'chunk_id', 'id']))

const docTitle = computed(() =>
  pick(props.citation, ['docTitle', 'documentTitle', 'documentName', 'title', 'fileName'])
)

const versionNo = computed(() => pick(props.citation, ['versionNo', 'version', 'docVersion']))

const clauseNo = computed(() => pick(props.citation, ['clauseNo', 'clauseCode', 'articleNo', 'clause']))

const sectionPath = computed(() =>
  pick(props.citation, ['sectionPath', 'section', 'chapterPath', 'clausePath'])
)

const content = computed(() => pick(props.citation, ['content', 'text', 'chunkText', 'originalText']))

const hasContent = computed(() => !!content.value)

const versionLabel = computed(() => {
  const raw = String(versionNo.value)
  return /^v/i.test(raw) ? raw : `v${raw}`
})

/** 条款位置：章节路径 + 条款号，缺哪个就少哪个，不拼出"第 条"这种怪东西 */
const locationText = computed(() => {
  const parts = []
  if (sectionPath.value) parts.push(sectionPath.value)
  if (clauseNo.value) parts.push(String(clauseNo.value))
  return parts.join(' · ')
})

/** 折叠时最多显示 60 字，避免卡片过高 */
const previewText = computed(() => {
  const text = content.value
  return text.length > 60 ? `${text.slice(0, 60)}…` : text
})
</script>

<style scoped>
.cite-card {
  padding: 14px 16px;
  background: #fbfcfe;
  border: 1px solid #e2eaf3;
  border-left: 3px solid #245784;
  border-radius: 10px;
  transition: border-color 0.15s, background 0.15s;
}

.cite-card:hover {
  border-color: #c3d6e8;
  background: #fff;
}

/* 原文缺失时视觉上就"弱"下去，一眼能看出这条引用不完整 */
.cite-card.is-empty {
  border-left-color: #d9a441;
  background: #fffdf6;
}

.cite-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 10px;
  flex-wrap: wrap;
}

.cite-title {
  display: flex;
  align-items: center;
  gap: 7px;
  min-width: 0;
  flex-wrap: wrap;
}

.cite-index {
  font-weight: 700;
  color: #245784;
  font-variant-numeric: tabular-nums;
}

.cite-title strong {
  font-size: 14px;
  color: #1c2d43;
  font-weight: 600;
  overflow-wrap: anywhere;
}

.cite-version {
  font-variant-numeric: tabular-nums;
}

.cite-location {
  margin: 8px 0 0;
  font-size: 12.5px;
  color: #617184;
  overflow-wrap: anywhere;
}

.cite-location-label {
  display: inline-block;
  margin-right: 6px;
  padding: 1px 6px;
  font-size: 11px;
  color: #48627b;
  background: #eaf2fa;
  border-radius: 4px;
}

.cite-preview {
  margin: 8px 0 0;
  font-size: 13.5px;
  line-height: 1.85;
  color: #4a5b6d;
}

.cite-body {
  margin: 10px 0 0;
  padding: 10px 12px;
  font-size: 13.5px;
  line-height: 1.9;
  color: #22303f;
  background: #f4f7fb;
  border-radius: 8px;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}

.cite-missing {
  margin: 9px 0 0;
  font-size: 12.5px;
  line-height: 1.7;
  color: #8a6a24;
}

.cite-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin-top: 10px;
  padding-top: 8px;
  border-top: 1px dashed #e6edf5;
  font-size: 11.5px;
  color: #93a4b6;
  flex-wrap: wrap;
}

.cite-chunk {
  font-family: Consolas, "Courier New", monospace;
  overflow-wrap: anywhere;
}

.cite-hint {
  color: #a9b7c6;
}
</style>
