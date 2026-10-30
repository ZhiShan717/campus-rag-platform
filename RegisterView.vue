<!--
  注册页 —— 对应计划 10.26：
  「对接注册接口，处理空输入、重复账号和失败提示；注册不提供管理员选项」
  接口：POST /api/auth/register（沈明昊实现）

  三条硬要求写在本文件里：
  1. 表单里**没有任何角色/管理员字段**，请求体也不带 role
  2. 空输入由 el-form 规则拦住，不发请求
  3. 重复账号（后端 code != 0 或 400）把后端原话透出，不吞成"注册失败"
-->
<template>
  <div class="auth-page">
    <section class="auth-card">
      <header class="auth-head">
        <div class="eyebrow">CAMPUS RAG</div>
        <h1>注册账号</h1>
        <p>注册后即可提问制度条款。管理员账号由系统分配，不在此页开放。</p>
      </header>

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
        @submit.prevent="onSubmit"
      >
        <el-form-item label="用户名" prop="username">
          <el-input
            v-model.trim="form.username"
            placeholder="4-20 位字母、数字或下划线"
            maxlength="20"
            clearable
            autocomplete="username"
          />
        </el-form-item>

        <el-form-item label="密码" prop="password">
          <el-input
            v-model="form.password"
            type="password"
            placeholder="至少 6 位"
            maxlength="64"
            show-password
            autocomplete="new-password"
          />
        </el-form-item>

        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input
            v-model="form.confirmPassword"
            type="password"
            placeholder="请再次输入密码"
            maxlength="64"
            show-password
            autocomplete="new-password"
          />
        </el-form-item>

        <el-form-item label="邮箱" prop="email">
          <el-input
            v-model.trim="form.email"
            placeholder="选填，用于找回密码"
            maxlength="64"
            clearable
            autocomplete="email"
          />
        </el-form-item>

        <el-form-item prop="agree" class="agree-item">
          <el-checkbox v-model="form.agree">
            我已阅读并同意《平台使用说明》
          </el-checkbox>
        </el-form-item>

        <el-button
          type="primary"
          class="submit-btn"
          :loading="loading"
          native-type="submit"
          @click="onSubmit"
        >
          {{ loading ? '提交中…' : '注 册' }}
        </el-button>
      </el-form>

      <footer class="auth-foot">
        <span>已有账号？</span>
        <router-link :to="{ name: 'login' }">去登录</router-link>
      </footer>
    </section>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { authApi } from '../api/auth'
import { errorText } from '../utils/errorText'

const router = useRouter()
const formRef = ref(null)
const loading = ref(false)
const error = ref(null)

const form = reactive({
  username: '',
  password: '',
  confirmPassword: '',
  email: '',
  agree: false
  // 注意：这里没有 role / isAdmin 字段，将来也不加
})

const USERNAME_RE = /^[A-Za-z0-9_]{4,20}$/

const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    {
      validator(_rule, value, callback) {
        if (!value) return callback()
        if (!USERNAME_RE.test(value)) {
          return callback(new Error('4-20 位字母、数字或下划线'))
        }
        callback()
      },
      trigger: 'blur'
    }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码至少 6 位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请再次输入密码', trigger: 'blur' },
    {
      validator(_rule, value, callback) {
        if (value && value !== form.password) {
          return callback(new Error('两次输入的密码不一致'))
        }
        callback()
      },
      trigger: 'blur'
    }
  ],
  email: [
    {
      type: 'email',
      message: '邮箱格式不正确',
      trigger: 'blur',
      // 选填：为空时跳过校验
      validator(_rule, value, callback) {
        if (!value) return callback()
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
          return callback(new Error('邮箱格式不正确'))
        }
        callback()
      }
    }
  ],
  agree: [
    {
      validator(_rule, value, callback) {
        callback(value ? undefined : new Error('请先勾选同意'))
      },
      trigger: 'change'
    }
  ]
}

async function onSubmit() {
  if (loading.value) return
  error.value = null

  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return

  loading.value = true
  try {
    // 只提交这三个字段，role 由后端决定（默认普通用户）
    await authApi.register({
      username: form.username,
      password: form.password,
      email: form.email
    })

    ElMessage.success('注册成功，请登录')
    router.replace({ name: 'login', query: { username: form.username } })
  } catch (err) {
    error.value = errorText(err)

    // 重复账号：后端通常返回 code!=0 + msg="用户名已存在"
    // 这里把后端原话直接展示，不要统一改写成"注册失败"
    if (err?.kind === 'BIZ') {
      ElMessage.error(err.message || '注册失败，请检查填写内容')
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
  width: 460px;
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

.agree-item {
  margin-bottom: 8px;
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
</style>
