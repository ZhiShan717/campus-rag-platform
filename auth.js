/**
 * 账号接口 —— 对应计划 10.26（注册）/ 10.27（登录、退出、当前用户）
 * 接口边界见计划第 08 节「最小接口责任表」：
 *   POST /api/auth/register  POST /api/auth/login
 *   GET  /api/auth/me        POST /api/auth/logout
 * 实现负责人：沈明昊；前端调用方：陈奥文
 */
import http from './http'

export const authApi = {
  /**
   * 注册（普通用户）
   * TODO(确认)：只传 username / password / email，**不传 role**
   * 计划明确"注册不能授予管理员"，所以前端连字段都不给。
   * @returns {{id, username, email, role}} 或统一响应体的 data
   */
  register({ username, password, email }) {
    return http.post('/auth/register', { username, password, email: email || undefined })
  },

  /**
   * 登录
   * @returns {{token: string, user?: {id, username, role}}}
   * TODO(确认)：Token 字段名是 token 还是 accessToken —— 见 README 假设
   */
  login({ username, password }) {
    return http.post('/auth/login', { username, password })
  },

  /**
   * 当前用户（带 Token 调，用于刷新页面后恢复登录态）
   * @returns {{id, username, role}} role: 'ADMIN' | 'USER'
   */
  me() {
    return http.get('/auth/me')
  },

  /**
   * 退出登录（计划：前端清 Token ≠ 服务端已撤销，所以要真调接口）
   */
  logout() {
    return http.post('/auth/logout')
  }
}
