/**
 * 离线预览用的样例数据 —— 只在完全没有后端时临时使用
 *
 * ⚠️ 这个文件不会被任何正式代码 import。
 *    计划 10.29 明确要求「移除临时固定答案」，
 *    所以它只能手动粘进 AskView 的 onAsk 里预览，看完立刻还原。
 *
 * 用法见 AskView.vue 底部注释。
 *
 * 三个场景覆盖了验收要演示的三件事：
 *   ① HIT    有依据，引用原文
 *   ② HIT    引用里有一条 content 为空（验证"空引用"处理）
 *   ③ NO_EVIDENCE  没有依据，明确说明不编造
 */

/** ① 命中：两条真实形状的引用 */
export const SAMPLE_HIT = {
  status: 'HIT',
  mode: 'RETRIEVAL',
  answer:
    '国家励志奖学金的申请条件主要包括：家庭经济困难且已通过学校家庭经济困难认定；上一学年学习成绩排名位于同年级同专业前 30%；无违纪处分记录。',
  citations: [
    {
      chunkId: 'chunk_1024',
      docTitle: '××大学国家励志奖学金评审办法',
      versionNo: '2',
      clauseNo: '第五条',
      sectionPath: '第三章 申请条件',
      content:
        '第五条 申请国家励志奖学金的学生应当同时具备以下条件：（一）热爱社会主义祖国，拥护中国共产党的领导；（二）遵守宪法和法律，遵守学校规章制度，无违纪处分记录；（三）家庭经济困难，生活俭朴，并已通过学校家庭经济困难学生认定；（四）上一学年学习成绩排名位于同年级同专业前 30%，且无不及格科目。'
    },
    {
      chunkId: 'chunk_1031',
      docTitle: '××大学家庭经济困难学生认定工作实施办法',
      versionNo: '1',
      clauseNo: '第八条',
      sectionPath: '第二章 认定程序',
      content:
        '第八条 家庭经济困难学生认定每学年进行一次，由学生本人提出申请，班级民主评议小组评议，院（系）认定工作组审核，学校学生资助管理中心复核后公示不少于 5 个工作日。'
    }
  ]
}

/** ② 有一条引用缺原文（验证 CitationCard 的空引用分支） */
export const SAMPLE_HIT_WITH_EMPTY_CITATION = {
  status: 'HIT',
  mode: 'RETRIEVAL',
  answer: '助学金按学年评审，分秋、春两次发放。',
  citations: [
    {
      chunkId: 'chunk_2088',
      docTitle: '××大学国家助学金管理办法',
      versionNo: '3',
      clauseNo: '第十二条',
      sectionPath: '第四章 发放管理',
      content:
        '第十二条 国家助学金按学年评审，按秋季学期和春季学期两次发放，每次发放金额为当年资助标准的一半。'
    },
    {
      // 故意缺 content：模拟引用快照入库失败
      chunkId: 'chunk_2089',
      docTitle: '××大学国家助学金管理办法',
      versionNo: '3',
      clauseNo: '第十三条',
      sectionPath: '第四章 发放管理'
    }
  ]
}

/** ③ 无依据：正常业务结果，不是错误 */
export const SAMPLE_NO_EVIDENCE = {
  status: 'NO_EVIDENCE',
  mode: 'RETRIEVAL',
  answer: '',
  citations: []
}

/** ④ 真实模型接入后的形状（只用于对照，别用来预览） */
export const SAMPLE_RAG = {
  status: 'HIT',
  mode: 'RAG',
  answer:
    '根据《××大学国家励志奖学金评审办法》第五条，你需要同时满足家庭经济困难认定、成绩排名前 30%、无违纪处分三项条件。[1][2]',
  citations: SAMPLE_HIT.citations
}
