/**
 * 登录态 —— 对应计划 10.27「对接登录、Token、退出；按后端真实权限显示入口」
 *
 * 为什么不引 Pinia：
 *   计划里没有要求状态库，仲雯大概率用 localStorage + 模块变量，
 *   你先别引入额外依赖，等 11.07 之后真需要了再换 Pinia。
 */
import { reactive } from 'vue'
import { authApi } from '../api/auth'
import { getToken, setToken, clearToken } from '../api/http'

export const userStore = reactive({
  token: getToken(),
  profile: null, // { id, username, role }
  loaded: false, // profile 是否已经从 /auth/me 拉过

  get isLogin() {
    return !!this.token
  },

  /** 是否管理员：必须以后端返回的 role 为准，不要用"有没有某个按钮"来判断 */
  get isAdmin() {
    return this.profile?.role === 'ADMIN'
  },

  /** 登录：拿 Token + 顺手存用户信息 */
  async login(form) {
    const data = await authApi.login(form)
    // TODO(确认)：Token 字段是 token 还是 accessToken
    const token = data?.token || data?.accessToken
    if (!token) throw new Error('登录接口未返回 Token，请与后端确认字段名')

    this.token = token
    setToken(token)
    this.profile = data.user || null
    this.loaded = !!data.user

    // 后端只回 Token 时，补拉一次当前用户
    if (!this.profile) await this.fetchProfile()
    return this.profile
  },

  /** 拉当前用户，做并发去重：多个守卫同时触发只发一次请求 */
  async fetchProfile() {
    if (this._inflight) return this._inflight
    this._inflight = authApi
      .me()
      .then((user) => {
        this.profile = user
        this.loaded = true
        return user
      })
      .finally(() => {
        this._inflight = null
      })
    return this._inflight
  },

  /** 页面刷新后恢复登录态 */
  async ensureProfile() {
    if (!this.isLogin) return null
    if (this.loaded && this.profile) return this.profile
    return this.fetchProfile()
  },

  /** 退出：先通知后端撤销，再清本地（计划：前端清 Token 不等于服务端已撤销） */
  async logout() {
    try {
      await authApi.logout()
    } catch (err) {
      // 退出接口失败不阻塞本地退出，但要在控制台留痕
      console.warn('[logout] 服务端退出失败：', err?.message || err)
    } finally {
      this.reset()
    }
  },

  reset() {
    this.token = ''
    this.profile = null
    this.loaded = false
    clearToken()
  }
})
