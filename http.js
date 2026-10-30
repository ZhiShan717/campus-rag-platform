/**
 * 请求底座 —— 对应计划 10.27「错误提示」+ 18.2「拦截器与错误处理」
 *
 * ⚠️ 如果仲雯已经封装过 src/utils/request.js，请直接删掉本文件，
 *    在 auth.js / qa.js 里改成 import request from '../utils/request' 即可。
 */
import axios from 'axios'

const TOKEN_KEY = 'rag_token'

/* ---------------- Token 存取（一处收口，避免各处硬编码 key） ---------------- */
export function getToken() {
  return localStorage.getItem(TOKEN_KEY) || ''
}

export function setToken(token) {
  if (token) localStorage.setItem(TOKEN_KEY, token)
  else localStorage.removeItem(TOKEN_KEY)
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY)
}

/* ---------------- 统一错误对象 ---------------- */
/**
 * kind 的四种取值，直接决定页面显示哪种提示（这是三态能区分开的关键）：
 *   UNAUTHORIZED 登录过期 / 未登录
 *   NETWORK      断网、跨域、后被代理挂掉
 *   TIMEOUT      超时（本项目常见：Python 检索服务没起来）
 *   SERVER       500/502/503 等服务端故障
 *   BIZ          业务失败（code !== 0），如"用户名已被占用"
 */
export class ApiError extends Error {
  constructor(message, kind = 'SERVER', code = null, raw = null) {
    super(message)
    this.name = 'ApiError'
    this.kind = kind
    this.code = code
    this.raw = raw
  }
}

/* ---------------- axios 实例 ---------------- */
const http = axios.create({
  // TODO(确认)：Vite 代理前缀是否是 /api（见 vite.config.js 的 proxy 配置）
  baseURL: import.meta.env.VITE_API_BASE || '/api',
  timeout: 15000 // 计划里 10.29 要求处理超时，这里给 15 秒
})

/* ---------------- 请求拦截：带 Token ---------------- */
http.interceptors.request.use((config) => {
  const token = getToken()
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

/* ---------------- 响应拦截：解包 + 归一化错误 ---------------- */
http.interceptors.response.use(
  (response) => {
    const body = response.data

    // TODO(确认)：统一响应体是否为 { code, msg, data } —— 见 README 假设 1
    if (body && typeof body === 'object' && 'code' in body) {
      if (body.code === 0) return body.data
      throw new ApiError(body.msg || body.message || '请求失败', 'BIZ', body.code, body)
    }

    // 后端没包统一响应体时，原样返回
    return body
  },
  (error) => {
    // 1) 超时
    if (error.code === 'ECONNABORTED' || /timeout/i.test(error.message || '')) {
      return Promise.reject(new ApiError('请求超时，服务可能未启动，请稍后重试', 'TIMEOUT', null, error))
    }

    // 2) 压根没拿到响应（断网 / 代理没起 / 服务被关掉）
    if (!error.response) {
      return Promise.reject(new ApiError('网络异常，无法连接服务', 'NETWORK', null, error))
    }

    const { status, data } = error.response

    // 3) 未登录 / Token 过期：清 Token，交给页面决定跳不跳
    if (status === 401) {
      clearToken()
      return Promise.reject(new ApiError('登录已过期，请重新登录', 'UNAUTHORIZED', 401, data))
    }

    // 4) 业务码混在错误里（有的后端 400 也返回 { code, msg }）
    if (data && typeof data === 'object' && data.msg) {
      return Promise.reject(new ApiError(data.msg, status === 403 ? 'BIZ' : 'SERVER', data.code ?? status, data))
    }

    // 5) 其余按服务端故障处理
    return Promise.reject(new ApiError(`服务异常（${status}）`, 'SERVER', status, data))
  }
)

export default http
