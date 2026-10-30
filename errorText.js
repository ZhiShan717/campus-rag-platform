/**
 * 错误文案归一 —— 对应计划 10.30 验收第 8 条：
 * 「无依据、网络失败、服务故障有不同且明确的提示」
 *
 * 三种失败必须长得不一样，用户才能判断该找谁：
 *   网络/超时  → 找自己（网络、后端是否启动）
 *   服务异常   → 找沈明昊/张睿轩（后端 5xx、Python 服务）
 *   无依据     → 不是故障，是正常的业务结果
 */
export function errorText(err) {
  const kind = err?.kind || 'SERVER'
  const message = err?.message || ''

  switch (kind) {
    case 'UNAUTHORIZED':
      return { title: '登录已过期', detail: '请重新登录后再试。', action: 'relogin', type: 'warning' }

    case 'NETWORK':
      return {
        title: '网络异常',
        detail: '连不上服务，请检查网络或确认后端是否已启动。',
        action: 'retry',
        type: 'error'
      }

    case 'TIMEOUT':
      return {
        title: '请求超时',
        detail: '服务响应过慢，可能是检索服务（Python）未启动或正在重启。',
        action: 'retry',
        type: 'error'
      }

    case 'BIZ':
      // 业务失败：后端给了明确原因，原话透出，别自己改写
      return { title: '操作未完成', detail: message || '请检查填写内容', action: 'none', type: 'warning' }

    default:
      return {
        title: '服务异常',
        detail: `服务端出错了${message ? '：' + message : ''}，请联系后端同学。`,
        action: 'retry',
        type: 'error'
      }
  }
}
