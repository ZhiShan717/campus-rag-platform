<!--
  登录页 —— 对应计划 10.27：
  「对接登录、Token、退出、路由守卫和错误提示；按后端真实权限显示入口」
  接口：POST /api/auth/login（沈明昊实现）
-->
<template>
  <div class="auth-page">
    <section class="auth-card">
      <header class="auth-head">
        <div class="eyebrow">CAMPUS RAG</div>
        <h1>奖助学金制度查询</h1>
        <p>登录后可提问，并查看每条回答引用的制度条款原文。</p>
      </header>

      <!-- 全局错误：按 kind 区分文案，网络/超时/服务异常/业务失败各不相同 -->
      <el-alert
        v-if="error"
        :title="error.title"
        :description="error.detail"
        :type="error.type"
        :closable="false"
        show-icon
        class="auth-alert"
      />

      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="84px"
        label-position="right"
        @submit.prevent="onSubmit"
      >
        <el-form-item label="用户名" prop="username">
          <el-input
            v-model.trim="form.username"
            placeholder="请输入用户名"
            maxlength="32"
            clearable
            autocomplete="username"
            @keyup.enter="onSubmit"
          />
        </el-form-item>

        <el-form-item label="密码" prop="password">
          <el-input
            v-model="form.password"
            type="password"
            placeholder="请输入密码"
            maxlength="64"
            show-password
            autocomplete="current-password"
            @keyup.enter="onSubmit"
          />
        </el-form-item>

        <el-button
          type="primary"
          class="submit-btn"
          :loading="loading"
          native-type="submit"
          @click="onSubmit"
        >
          {{ loading ? '登录中…' : '登 录' }}
        </el-button>
      </el-form>

      <footer class="auth-foot">
        <span>还没有账号？</span>
        <router-link :to="{ name: 'register' }">去注册</router-link>
      </footer>
    </section>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { userStore } from '../stores/user'
import { errorText } from '../utils/errorText'

const router = useRouter()
const route = useRoute()

const formRef = ref(null)
const loading = ref(false)
const error = ref(null)

const form = reactive({
  username: '',
  password: ''
})

const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 2, max: 32, message: '用户名长度 2-32 位', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码至少 6 位', trigger: 'blur' }
  ]
}

onMounted(() => {
  // 从守卫弹回来时，把"为什么在这"告诉用户，别让人一脸问号
  if (route.query.redirect) {
    ElMessage.info('请先登录')
  }
})

async function onSubmit() {
  if (loading.value) return
  error.value = null

  // 1) 前端校验：空输入不发请求
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return

  // 2) 调接口
  loading.value = true
  try {
    const profile = await userStore.login({
      username: form.username,
      password: form.password
    })

    ElMessage.success(`欢迎回来，${profile?.username || form.username}`)

    // 3) 回到原来想去的页面（守卫带过来的 redirect）
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/ask'
    router.replace(redirect)
  } catch (err) {
    // 4) 失败：不跳转、不伪造成功；按 kind 给不同提示
    error.value = errorText(err)

    // 账号密码错属于业务失败，把后端原话直接显示出来
    if (err?.kind === 'BIZ') {
      ElMessage.error(err.message || '账号或密码错误')
    }
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.auth-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f3f6fa;
  padding: 24px 16px;
}

.auth-card {
  width: 420px;
  max-width: 100%;
  padding: 36px 34px 26px;
  background: #fff;
  border: 1px solid #dbe4ee;
  border-radius: 14px;
  box-shadow: 0 10px 32px rgba(23, 57, 84, 0.08);
}

.auth-head {
  margin-bottom: 22px;
}

.eyebrow {
  font-size: 12px;
  letter-spacing: 2px;
  color: #7b8ea3;
}

.auth-head h1 {
  margin: 6px 0 0;
  font-size: 22px;
  color: #1d4d76;
}

.auth-head p {
  margin: 8px 0 0;
  font-size: 13px;
  color: #617184;
  line-height: 1.7;
}

.auth-alert {
  margin-bottom: 18px;
}

.submit-btn {
  width: 100%;
  height: 44px;
  font-size: 15px;
}

.auth-foot {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 18px;
  padding-top: 16px;
  border-top: 1px solid #eef3f8;
  font-size: 13px;
  color: #617184;
}

.auth-foot a {
  color: #245784;
  text-decoration: none;
}

.auth-foot a:hover {
  text-decoration: underline;
}
</style>
