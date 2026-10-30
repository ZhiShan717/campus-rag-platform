/**
 * 问答接口 —— 对应计划 10.29「对接真实 ask」+ 10.28「标注检索模式」
 * 接口边界见计划第 08 节：
 *   POST /api/qa/ask        业务：沈明昊；检索：张睿轩；持久化：单成宇
 *   GET  /api/features      11.03 才正式要求，但 10.28 就要靠它标注模式
 */
import http from './http'

export const qaApi = {
  /**
   * 提问
   * @param {string} question 用户问题
   * @returns {Promise<AskResult>}
   *
   * AskResult（TODO(确认)，见 README 假设 2）：
   * {
   *   status: 'HIT' | 'NO_EVIDENCE',   // 只有后端能判"无依据"
   *   mode:   'RETRIEVAL' | 'RAG',     // 决定页面文案：条款检索模式 / RAG 问答模式
   *   answer: string,                  // RETRIEVAL 模式下为条款摘录
   *   citations: Citation[]
   * }
   *
   * Citation（TODO(确认)，见 README 假设 3）：
   * { chunkId, docTitle, versionNo, clauseNo, sectionPath, content }
   */
  ask(question) {
    return http.post('/qa/ask', { question })
  },

  /**
   * 能力状态
   * @returns {{retrieval: 'available', generation: 'available'|'unavailable'}}
   */
  features() {
    return http.get('/features')
  }
}
