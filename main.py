# -*- coding: utf-8 -*-
"""校园级 RAG 知识库平台 · Python 检索服务（第一周 10.24—10.30）

负责人：张睿轩（Python · 问答与检索能力）
本周目标：跑通 Python 侧最小闭环 —— 健康检查 + 候选条款检索 + 排序 + 引用编号 + 无依据处理。

怎么运行
    1. PyCharm 右上角运行 FastAPI 配置（main:app），浏览器打开 http://127.0.0.1:8000/docs
    2. 命令行：python main.py              → 启动服务，监听 127.0.0.1:8000
    3. 命令行：python main.py --selftest   → 不启服务，跑 15 条自测并逐条打印 PASS / FAIL

对外接口（只给 Java 调用，不直接暴露给浏览器）
    GET  /health    健康检查：Java 启动时探活，失败要显示"服务异常"
    POST /retrieve  入参 question、topK、candidateChunks[]；出参排序后的条款 + 引用编号

和 Java 的分工（组会必须讲清）
    - 候选条款由 Java 先按"有效版本"过滤好再送过来；本服务不连数据库、不做版本过滤。
    - 返回的 chunkId、文件名、原文一律原样拷贝入参，不编造条款、文件名或引用编号。
    - 三种结果必须分开，不能混：
        code = "OK"          → 200，命中条款，可展示引用
        code = "NO_EVIDENCE" → 200，没有依据，明确说"没有找到"，不生成答案
        HTTP 500 / 422       → 服务异常 / 参数不合法，前端要提示"服务异常"，不能伪装成"没有依据"

课程对位（黑马）
    6.1 列表：把数据排成一队        → candidateChunks 是一个 list，每条是一个 dict
    6.2 字典：给数据贴标签          → 每条条款用 dict 存 chunkId / content / sectionPath
    6.3 函数：把代码打包复用        → tokenize / score / retrieve_core 都是函数
    3.5 Pydantic 结构化模型         → CandidateChunk / RetrieveRequest / RetrieveResponse
    3.6 FastAPI 快速入门            → @app.get / @app.post 装饰器（本集之前没讲过，先照抄）
"""

import logging
import os
import time
import unicodedata

from fastapi import FastAPI, Header, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse ##统一异常处理
from pydantic import BaseModel, Field, ValidationError

# ---------------------------------------------------------------------------
# 一、参数约定：要改阈值只改这里，不要在代码各处散落魔法数字
# ---------------------------------------------------------------------------
SERVICE_NAME = "campus-rag-retrieval"
SERVICE_VERSION = "0.1.0"
MODE_LABEL = "条款检索模式"        # 第一周没有生成模型，页面上就写这四个字，不能写"RAG 问答"

DEFAULT_TOP_K = 5                 # 不传 topK 时返回几条
MAX_TOP_K = 20                    # Java 传错也不允许一次要 1000 条
MAX_QUESTION_CHARS = 200          # 问题最长 200 字，超了直接 422
MAX_CANDIDATES = 500              # 单次候选条款上限
MAX_CONTENT_CHARS = 4000          # 单条原文上限，超了要求 Java 先切分，避免把长文截断后当引用
MAX_TERM_CHARS = 8                # 分词时最长匹配窗口（中文词一般 2—6 字）

# 打分权重：正文 3 分，条款位置 1 分，文件名 1 分。
# 为什么正文最高？因为引用最终要展示原文，正文命中才是有依据；另外两项只用于同分时排序。
WEIGHT_CONTENT = 3
WEIGHT_SECTION = 1
WEIGHT_TITLE = 1

# 服务间内部令牌：环境变量 PY_INTERNAL_TOKEN 有值时，/retrieve 必须带同样的请求头。
# 留空表示本地开发不校验（不要在生产环境留空）。
INTERNAL_TOKEN = os.environ.get("PY_INTERNAL_TOKEN", "").strip()

# 生成能力状态：如实上报，前端按这个字段决定是否显示"生成"入口
GENERATION_INFO = {
    "enabled": False,
    "reason": "第一周不接入真实生成模型；本服务只返回原文条款，不写答案正文。",
    "model": None,
}

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger(SERVICE_NAME)


# ---------------------------------------------------------------------------
# 二、文本处理：归一化 + 词表最长匹配 + 同义词归一（纯标准库，不装 jieba）
# ---------------------------------------------------------------------------
# 同义词表：只做"说法归一"，不改语义。比如"资料 / 材料 / 文件"在制度里是同一件事。
# 注意：废止 / 失效 不是一个意思，不能合并，否则会把失效条款当成废止条款。
SYNONYMS = {
    "国家助学金": "助学金",
    "助学金": "助学金",
    "助学": "助学金",
    "家庭经济困难": "困难",
    "经济困难": "困难",
    "困难": "困难",
    "贫困": "困难",
    "材料": "材料",
    "资料": "材料",
    "文件": "材料",
    "证明材料": "材料",
    "申报": "申请",
    "提交申请": "申请",
    "申请": "申请",
    "学业成绩": "成绩",
    "成绩": "成绩",
    "公示期": "公示",
    "公示": "公示",
    "作废": "废止",
    "废止": "废止",
    "评定": "评审",
    "评选": "评审",
    "评审": "评审",
}

# 停用词：问了等于没问的词，保留会到处乱命中，所以直接丢掉
STOPWORDS = {
    "的", "了", "吗", "呢", "啊", "吧", "是", "有", "和", "与", "及", "或", "在", "对", "按", "把",
    "请", "请问", "如何", "怎么", "怎样", "什么", "哪些", "哪个", "多少", "可以", "能否", "是否",
    "需要", "应当", "应该", "提交", "办理", "规定", "有关", "关于", "以及", "一个", "这个", "那个",
    "目前", "现在", "具体", "一下", "告诉", "同学", "老师",
}

# 基础词表：领域词 + 常见词。分词就是"拿这张表去句子里做最长匹配"。
# 词表外的字会被丢掉（宁缺勿错），所以漏检时先回来加词 —— 这是本周已知局限之一。
BASE_WORDS = """
学生 学校 学院 班级 专业 年级 学期 学年 每学年 时间 期限 金额 人数 名额 比例 条件 流程 步骤
部门 办公室 中心 电话 网址 系统 平台 账号 密码 登录 注册 查询 结果 状态 版本 制度 办法 细则
通知 公告 条款 原文 依据 说明 内容 问题 宿舍 调换 食堂 报修 缴费 学费 住宿 贷款 还款 档案
证明 盖章 签字 表格 附件 材料 申请 资助 标准 评审 公示 发放 成绩 困难 助学金 奖学金 奖助学金
资助标准 申请材料 申请条件 评审标准 发放时间 名额分配 公示期 认定标准
励志 勤工 助学贷款 补助 补贴 减免 资格 认定 审核 批准 备案 报送 逾期 受理 咨询 联系方式
""".split()

VOCAB = set(SYNONYMS) | set(STOPWORDS) | set(BASE_WORDS)


def normalize_text(text):
    """把文本压成"只留字和数字"的干净字符串。

    1. NFKC：全角字母/数字转半角（ＡＢＣ → ABC，３０００ → 3000）
    2. 转小写：ABC 和 abc 当成同一个词
    3. 标点、空格、换行全部换成空格：避免"申请。材料"这种断句影响匹配
    """
    if not isinstance(text, str):
        text = "" if text is None else str(text)
    text = unicodedata.normalize("NFKC", text).lower()
    chars = []
    for ch in text:
        if ch.isalnum() or "\u4e00" <= ch <= "\u9fff":
            chars.append(ch)
        else:
            chars.append(" ")
    return " ".join("".join(chars).split())


def split_words(text):
    """按词表做最长匹配切词，返回还带着停用词、同义词原形的原始词列表。

    例："国家助学金的资助标准是多少？" → ["国家助学金", "的", "资助标准", "是", "多少"]
    """
    text = normalize_text(text)
    words = []
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == " ":
            i += 1
            continue
        # 英文字母和数字：连续的一串算一个词，比如 abc123、3000
        if ch.isascii() and ch.isalnum():
            j = i
            while j < len(text) and text[j].isascii() and text[j].isalnum():
                j += 1
            words.append(text[i:j])
            i = j
            continue
        # 中文：从长到短试词表，命中就用最长的那个（"助学金"优先于"助学"）
        matched = ""
        longest = min(MAX_TERM_CHARS, len(text) - i)
        for size in range(longest, 0, -1):
            piece = text[i:i + size]
            if piece in VOCAB:
                matched = piece
                break
        if matched:
            words.append(matched)
            i += len(matched)
        else:
            i += 1          # 词表没收录的字直接跳过
    return words


def query_terms(question, limit=12):
    """把问题变成真正用来检索的词：去停用词 → 同义词归一 → 去重 → 截断。

    limit 是防止一个问题被切成几十个词，导致排序不可解释。
    """
    terms = []
    for word in split_words(question):
        if word in STOPWORDS:
            continue
        word = SYNONYMS.get(word, word)
        # 单字词噪声太大（"金""章"会命中一切），除非它是数字
        if len(word) == 1 and not word.isdigit():
            continue
        if word in STOPWORDS:
            continue
        if word not in terms:
            terms.append(word)
    return terms[:limit]


def score_candidate(terms, chunk):
    """给一条候选条款打分，并记录每个词命中了哪里（组会现场要能解释）。

    返回：(总分, 命中词列表, 明细 dict)
    """
    content = normalize_text(chunk.get("content"))
    section = normalize_text(chunk.get("sectionPath"))
    title = normalize_text(chunk.get("documentTitle"))

    matched = []
    content_hits = 0
    section_hits = 0
    title_hits = 0
    for term in terms:
        in_content = term in content
        in_section = term in section
        in_title = term in title
        if in_content:
            content_hits += 1
        if in_section:
            section_hits += 1
        if in_title:
            title_hits += 1
        if in_content or in_section or in_title:
            matched.append(term)

    score = (
        WEIGHT_CONTENT * content_hits
        + WEIGHT_SECTION * section_hits
        + WEIGHT_TITLE * title_hits
    )
    detail = {"content": content_hits, "section": section_hits, "title": title_hits}
    return score, matched, detail


# ---------------------------------------------------------------------------
# 三、请求 / 响应模型（Pydantic）：把"字段长什么样"写死，Java 和前端照这个来
# ---------------------------------------------------------------------------
class CandidateChunk(BaseModel):
    """一条候选条款。字段名用 camelCase，和 Java 的 DTO、前端的 JSON 保持一致。"""

    chunkId: str = Field(min_length=1, max_length=64, description="条款唯一编号，必须原样返回")
    content: str = Field(min_length=1, max_length=MAX_CONTENT_CHARS, description="条款原文")
    documentId: str | None = Field(default=None, max_length=64, description="所属制度 ID")
    documentTitle: str | None = Field(default=None, max_length=200, description="制度/文件名")
    versionNo: str | None = Field(default=None, max_length=64, description="版本号，如 2026-v2")
    status: str | None = Field(default=None, max_length=32, description="ACTIVE / REVOKED / PENDING / EXPIRED")
    sectionPath: str | None = Field(default=None, max_length=200, description="条款位置，如 第三章 资助标准 · 第2条")
    effectiveFrom: str | None = Field(default=None, max_length=32, description="生效日期，服务端只透传不判断")
    effectiveTo: str | None = Field(default=None, max_length=32, description="失效日期，服务端只透传不判断")


class RetrieveRequest(BaseModel):
    """POST /retrieve 的请求体。三个字段就够，多了就是设计问题。"""

    question: str = Field(min_length=1, max_length=MAX_QUESTION_CHARS, description="用户问题")
    topK: int = Field(default=DEFAULT_TOP_K, ge=1, le=MAX_TOP_K, description=f"返回条数 1—{MAX_TOP_K}")
    candidateChunks: list[CandidateChunk] = Field(
        default_factory=list,
        max_length=MAX_CANDIDATES,
        description="Java 过滤后的候选条款",
    )


class Hit(BaseModel):
    """一条命中结果：引用卡片需要的字段全在这里。"""

    citationId: str = Field(description="引用编号 C1、C2……，只按本次排序生成")
    rank: int = Field(description="名次，从 1 开始")
    chunkId: str = Field(description="原始条款编号，来自入参")
    documentId: str | None = None
    documentTitle: str | None = None
    versionNo: str | None = None
    status: str | None = None
    sectionPath: str | None = None
    content: str = Field(description="原文，逐字来自入参")
    score: int = Field(description="加权总分")
    coverage: float = Field(description="命中词 / 问题词，0—1 之间")
    matchedTerms: list[str] = Field(description="命中了哪些词，用于解释排序")
    scoreDetail: dict[str, int] = Field(description="正文 / 条款位置 / 文件名各命中几个词")


class RetrieveResponse(BaseModel):
    """统一响应：Java 只看 code、hits、message 三个字段就能决定怎么展示。"""

    mode: str = Field(description="固定 retrieval，第一周不会出现 generation")
    modeLabel: str = Field(description="给页面显示的文案：条款检索模式")
    code: str = Field(description="OK / NO_EVIDENCE")
    question: str
    topK: int
    terms: list[str] = Field(description="分词结果，用来解释“为什么命中”")
    hits: list[Hit] = Field(default_factory=list)
    message: str = Field(description="给用户看的一句话")
    reason: str | None = Field(default=None, description="NO_EVIDENCE 的原因：NO_TERMS / NO_CANDIDATES / NO_MATCH")
    warnings: list[str] = Field(default_factory=list, description="给联调看的告警，不展示给用户")
    generation: dict = Field(default_factory=dict, description="生成能力状态，第一周 enabled=false")
    elapsedMs: float = Field(description="本服务耗时，毫秒")


# ---------------------------------------------------------------------------
# 四、核心检索：不依赖 FastAPI，可以单独调用、单独测试
# ---------------------------------------------------------------------------
def _build_response(code, question, top_k, terms, hits, message, warnings, started,
                    reason=None):
    """所有响应都从这里产出，避免各处字段拼错。"""
    return {
        "mode": "retrieval",
        "modeLabel": MODE_LABEL,
        "code": code,
        "question": question,
        "topK": top_k,
        "terms": terms,
        "hits": hits,
        "message": message,
        "reason": reason,
        "warnings": warnings,
        "generation": dict(GENERATION_INFO),
        "elapsedMs": round((time.perf_counter() - started) * 1000, 2),
    }


def _no_evidence(reason, question, top_k, terms, warnings, started):
    """没有依据：200 + NO_EVIDENCE，明确告诉用户没找到，不生成答案。"""
    messages = {
        "NO_TERMS": "问题里没有可检索的关键词（词表还没收录），本次不生成答案。",
        "NO_CANDIDATES": "候选条款为空：没有拿到任何有效版本条款，本次不生成答案。",
        "NO_MATCH": "没有检索到有效依据，本次不生成答案；请换个问法，或让管理员补充制度原文。",
    }
    return _build_response(
        "NO_EVIDENCE", question, top_k, terms, [], messages.get(reason, messages["NO_MATCH"]),
        warnings, started, reason=reason,
    )


def retrieve_core(question, top_k, candidates):
    """检索主流程：去重 → 打分 → 排序 → 取 Top-K → 编引用号。

    入参都是普通 Python 对象（str / int / list[dict]），所以自测里可以直接调，
    不需要启动 HTTP 服务，也不需要 Java 在场。
    """
    started = time.perf_counter()
    question = "" if question is None else str(question).strip()
    # 双保险：Pydantic 已经拦过 topK，这里再兜一次，防止以后有人绕过 HTTP 直接调用
    try:
        top_k = int(top_k)
    except (TypeError, ValueError):
        top_k = DEFAULT_TOP_K
    top_k = max(1, min(top_k, MAX_TOP_K))

    terms = query_terms(question)
    warnings = []

    # 1) 按 chunkId 去重：同一个条款送两遍会让引用卡片重复
    unique_chunks = []
    seen_ids = set()
    duplicated = 0
    for chunk in candidates or []:
        chunk_id = str((chunk or {}).get("chunkId") or "").strip()
        if not chunk_id:
            continue
        if chunk_id in seen_ids:
            duplicated += 1
            continue
        seen_ids.add(chunk_id)
        unique_chunks.append(chunk)
    if duplicated:
        warnings.append(f"有 {duplicated} 条候选的 chunkId 重复，已忽略重复项。")

    # 2) 条数上限：超出就截断并告警（不能静默丢证据，否则查不出问题）
    if len(unique_chunks) > MAX_CANDIDATES:
        warnings.append(
            f"候选 {len(unique_chunks)} 条超过上限 {MAX_CANDIDATES} 条，只检索前 {MAX_CANDIDATES} 条。"
        )
        unique_chunks = unique_chunks[:MAX_CANDIDATES]

    # 3) 版本状态只告警、不过滤：过滤是 Java 的职责，这里若偷偷过滤会掩盖 Java 的 bug
    inactive = []
    for chunk in unique_chunks:
        status = str(chunk.get("status") or "").upper()
        if status and status != "ACTIVE":
            inactive.append(f"{chunk.get('chunkId')}({status})")
    if inactive:
        warnings.append(
            "候选中有 %d 条状态不是 ACTIVE：%s。版本过滤应由 Java 在调用前完成，本服务不做过滤。"
            % (len(inactive), "、".join(inactive[:5]))
        )

    if not unique_chunks:
        return _no_evidence("NO_CANDIDATES", question, top_k, terms, warnings, started)
    if not terms:
        return _no_evidence("NO_TERMS", question, top_k, terms, warnings, started)

    # 4) 逐条打分，0 分的（一个词都没命中）不进结果，绝不凑数
    scored = []
    for chunk in unique_chunks:
        score, matched, detail = score_candidate(terms, chunk)
        if score <= 0:
            continue
        scored.append((score, chunk, matched, detail))

    # 5) 排序：分数高的在前；同分按 chunkId 升序。
    #    加上 chunkId 这个兜底，同一问题查多少次、Java 传的候选顺序怎么变，结果都一样。
    scored.sort(key=lambda item: (-item[0], str(item[1].get("chunkId"))))

    hits = []
    for rank, (score, chunk, matched, detail) in enumerate(scored[:top_k], start=1):
        hits.append({
            "citationId": "C%d" % rank,
            "rank": rank,
            "chunkId": chunk.get("chunkId"),
            "documentId": chunk.get("documentId"),
            "documentTitle": chunk.get("documentTitle"),
            "versionNo": chunk.get("versionNo"),
            "status": chunk.get("status"),
            "sectionPath": chunk.get("sectionPath"),
            "content": chunk.get("content", ""),
            "score": score,
            "coverage": round(len(matched) / len(terms), 2) if terms else 0.0,
            "matchedTerms": matched,
            "scoreDetail": detail,
        })

    if not hits:
        return _no_evidence("NO_MATCH", question, top_k, terms, warnings, started)

    message = "已在候选条款中检索到 %d 条依据（%s，未调用生成模型）。" % (len(hits), MODE_LABEL)
    return _build_response("OK", question, top_k, terms, hits, message, warnings, started)


# ---------------------------------------------------------------------------
# 五、HTTP 层：FastAPI 只做"收请求 → 调核心 → 包响应"，不写业务逻辑
# ---------------------------------------------------------------------------
app = FastAPI(
    title="校园 RAG · Python 检索服务",
    version=SERVICE_VERSION,
    description=(
        "第一周：候选条款检索、排序、Top-K、引用编号、无依据处理。\n\n"
        "调用方只有 Java 后端；候选条款由 Java 按有效版本过滤后传入。"
    ),
)


@app.get("/health", tags=["运维"], summary="健康检查")
def health():
    """Java 启动和联调时先打这个接口：返回 ok 才继续问问题。"""
    return {
        "status": "ok",
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "mode": "retrieval",
        "generationEnabled": GENERATION_INFO["enabled"],
        "limits": {
            "topKMax": MAX_TOP_K,
            "questionMaxChars": MAX_QUESTION_CHARS,
            "candidatesMax": MAX_CANDIDATES,
        },
        "time": time.strftime("%Y-%m-%d %H:%M:%S"),
    }


@app.post("/retrieve", response_model=RetrieveResponse, tags=["检索"], summary="候选条款检索与排序")
def retrieve(req: RetrieveRequest, x_internal_token: str = Header(default="")):
    """核心接口。注意：业务规则（阈值、排序、引用）都在 retrieve_core，这里只做转接。"""
    # 内部令牌：只有配置了 PY_INTERNAL_TOKEN 才校验，本地开发默认放行
    if INTERNAL_TOKEN and x_internal_token != INTERNAL_TOKEN:
        return JSONResponse(
            status_code=401,
            content={"code": "UNAUTHORIZED", "message": "缺少或错误的内部令牌，本接口只给 Java 后端调用。"},
        )

    candidates = [chunk.model_dump() for chunk in req.candidateChunks]
    result = retrieve_core(req.question, req.topK, candidates)

    logger.info(
        "retrieve question_len=%d candidates=%d hits=%d code=%s cost=%sms",
        len(req.question), len(candidates), len(result["hits"]), result["code"], result["elapsedMs"],
    )
    return result


@app.get("/", include_in_schema=False)
def index():
    return {
        "service": SERVICE_NAME,
        "docs": "/docs",
        "health": "/health",
        "retrieve": "POST /retrieve",
        "note": "第一周只做条款检索（%s），不生成答案。" % MODE_LABEL,
    }


@app.exception_handler(RequestValidationError)
async def handle_invalid_request(request: Request, exc: RequestValidationError):
    """参数不合法（问题太长、topK 越界、缺 content 等）→ 422。

    注意 422 和 NO_EVIDENCE 是两码事：422 是"你传错了"，NO_EVIDENCE 是"传得对但没找到"。
    """
    details = []
    for err in exc.errors():
        location = ".".join(str(part) for part in err.get("loc", []) if part != "body")
        details.append("%s: %s" % (location or "请求体", err.get("msg", "不合法")))
    return JSONResponse(
        status_code=422,
        content={
            "code": "INVALID_REQUEST",
            "message": "请求参数不合法，请检查 question、topK、candidateChunks。",
            "errors": details,
        },
    )


@app.exception_handler(Exception)
async def handle_service_error(request: Request, exc: Exception):
    """兜底：真出异常时返回 500 + SERVICE_ERROR，绝不伪装成"没有依据"。"""
    logger.exception("retrieve failed: %s", exc)
    return JSONResponse(
        status_code=500,
        content={
            "code": "SERVICE_ERROR",
            "message": "检索服务内部错误，请稍后重试；这是服务异常，不代表没有找到依据。",
        },
    )


# ---------------------------------------------------------------------------
# 六、演示数据（虚构，非真实制度）+ 自测
# ---------------------------------------------------------------------------
def demo_candidates():
    """6 条虚构条款，用于本地自测和组会演示。

    其中 ch_3001 是已废止的旧版，故意留在候选里，用来验证"版本过滤必须由 Java 做"。
    真实数据由戴月整理，不放进代码。
    """
    return [
        {
            "chunkId": "ch_1001", "documentId": "doc_01", "documentTitle": "××大学国家助学金评审与管理办法",
            "versionNo": "2026-v2", "status": "ACTIVE", "sectionPath": "第三章 资助标准 · 第2条",
            "content": "国家助学金资助标准为每生每学年3000元，按学期分两次发放，用于补助家庭经济困难学生的生活费用。",
        },
        {
            "chunkId": "ch_1002", "documentId": "doc_01", "documentTitle": "××大学国家助学金评审与管理办法",
            "versionNo": "2026-v2", "status": "ACTIVE", "sectionPath": "第二章 申请条件 · 第1条",
            "content": "申请国家助学金的学生应当具备下列条件：家庭经济困难、学习态度端正、无违纪记录；同一学年内不得重复申请同类资助。",
        },
        {
            "chunkId": "ch_1003", "documentId": "doc_01", "documentTitle": "××大学国家助学金评审与管理办法",
            "versionNo": "2026-v2", "status": "ACTIVE", "sectionPath": "第四章 申请材料与评审流程 · 第1条",
            "content": "学生应当在每年9月30日前提交申请材料，包括家庭经济困难证明与个人申请书，逾期不再受理。",
        },
        {
            "chunkId": "ch_2001", "documentId": "doc_02", "documentTitle": "××大学奖学金评定实施细则",
            "versionNo": "2026-v1", "status": "ACTIVE", "sectionPath": "第三章 评审标准 · 第2条",
            "content": "奖学金按学年评定，依据学业成绩与综合素质测评结果排序，公示期为5个工作日。",
        },
        {
            "chunkId": "ch_2002", "documentId": "doc_02", "documentTitle": "××大学奖学金评定实施细则",
            "versionNo": "2026-v1", "status": "ACTIVE", "sectionPath": "第三章 评审标准 · 第3条",
            "content": "国家励志奖学金面向家庭经济困难且学业成绩优秀的学生，每学年5000元。",
        },
        {
            "chunkId": "ch_3001", "documentId": "doc_03", "documentTitle": "××大学国家助学金评审与管理办法",
            "versionNo": "2024-v1", "status": "REVOKED", "sectionPath": "第三章 资助标准 · 第2条",
            "content": "国家助学金资助标准为每生每学年2000元，按学期分两次发放。",
        },
    ]


@app.get("/demo/candidates", tags=["演示"], summary="演示用候选条款（虚构数据，仅供本地联调）")
def demo():
    return {
        "notice": "虚构演示数据，不是真实制度；真实数据由戴月整理，经 Java 读取数据库后传入。",
        "candidates": demo_candidates(),
    }


def run_self_test():
    """15 条自测，覆盖分词、打分、Top-K、稳定排序、无依据、引用编号、参数校验。

    这是组会最有说服力的部分：不用点按钮，一条命令跑完，逐条 PASS。
    """
    print("=" * 76)
    print("校园 RAG · Python 检索服务自测（不启动 HTTP，直接测核心逻辑）")
    print("=" * 76)

    passed = 0
    failed = 0

    def check(name, ok, detail=""):
        nonlocal passed, failed
        if ok:
            passed += 1
            print("[PASS] %s%s" % (name, ("    " + detail) if detail else ""))
        else:
            failed += 1
            print("[FAIL] %s%s" % (name, ("    " + detail) if detail else ""))

    candidates = demo_candidates()
    q_standard = "国家助学金的资助标准是多少？"
    q_material = "申请国家助学金需要提交什么材料？"

    # 1—2 分词与同义词
    terms = query_terms(q_standard)
    check("分词：问题切成可检索词", terms == ["助学金", "资助标准"], str(terms))
    check("同义词：资料 → 材料", query_terms("申请资料") == ["申请", "材料"], str(query_terms("申请资料")))

    # 3—4 命中排序
    r1 = retrieve_core(q_standard, 5, candidates)
    check("排序：问标准 → 资助标准条款第一", r1["hits"] and r1["hits"][0]["chunkId"] == "ch_1001",
          "第一名 " + (r1["hits"][0]["chunkId"] if r1["hits"] else "无"))
    r2 = retrieve_core(q_material, 5, candidates)
    check("排序：问材料 → 申请材料条款第一", r2["hits"] and r2["hits"][0]["chunkId"] == "ch_1003",
          "第一名 " + (r2["hits"][0]["chunkId"] if r2["hits"] else "无"))

    # 5—7 Top-K 与稳定排序
    r1_top2 = retrieve_core(q_standard, 2, candidates)
    check("Top-K：topK=2 只返回 2 条", len(r1_top2["hits"]) == 2 and
          [h["chunkId"] for h in r1_top2["hits"]] == [h["chunkId"] for h in r1["hits"][:2]])
    r1_again = retrieve_core(q_standard, 5, candidates)
    check("稳定：同一问题两次结果完全一致",
          [h["chunkId"] for h in r1["hits"]] == [h["chunkId"] for h in r1_again["hits"]])
    shuffled = list(reversed(candidates))
    r_shuffled = retrieve_core(q_standard, 5, shuffled)
    check("稳定：候选顺序倒过来结果不变",
          [h["chunkId"] for h in r1["hits"]] == [h["chunkId"] for h in r_shuffled["hits"]])

    # 8—10 三种"没有依据"
    r_nomatch = retrieve_core("宿舍调换要去找哪个部门？", 5, candidates)
    check("无依据：词不匹配 → NO_EVIDENCE / NO_MATCH",
          r_nomatch["code"] == "NO_EVIDENCE" and r_nomatch["reason"] == "NO_MATCH" and not r_nomatch["hits"])
    r_empty = retrieve_core(q_standard, 5, [])
    check("无依据：候选为空 → NO_EVIDENCE / NO_CANDIDATES",
          r_empty["code"] == "NO_EVIDENCE" and r_empty["reason"] == "NO_CANDIDATES")
    r_noterms = retrieve_core("你好", 5, candidates)
    check("无依据：没有关键词 → NO_EVIDENCE / NO_TERMS",
          r_noterms["code"] == "NO_EVIDENCE" and r_noterms["reason"] == "NO_TERMS")

    # 11—12 引用编号与"不编造"
    ids_ok = all(h["citationId"] == "C%d" % h["rank"] for h in r1["hits"])
    check("引用编号：C1、C2……与名次一致", ids_ok, str([h["citationId"] for h in r1["hits"]]))
    original = {c["chunkId"]: c for c in candidates}
    same_content = all(h["content"] == original[h["chunkId"]]["content"] for h in r1["hits"])
    ids_from_input = {h["chunkId"] for h in r1["hits"]} <= set(original)
    check("不编造：chunkId 和原文逐字来自入参", same_content and ids_from_input)

    # 13 版本告警：Python 不过滤版本，但要提醒 Java
    revoked_in_hits = any(h["chunkId"] == "ch_3001" for h in r1["hits"])
    warned = any("REVOKED" in w for w in r1["warnings"])
    check("版本：废止条款不被 Python 过滤，但给 Java 告警", revoked_in_hits and warned,
          (r1["warnings"][0][:40] + "…") if r1["warnings"] else "无告警")

    # 14 全角 / 大小写归一
    custom = [{"chunkId": "ch_test_1", "content": "预约系统账号为 ABC123，登录后可以查询办理进度。"}]
    r_full = retrieve_core("abc123 账号", 5, custom)
    check("归一化：全角字母、大小写都能命中",
          r_full["code"] == "OK" and r_full["hits"][0]["chunkId"] == "ch_test_1")

    # 15 参数校验：靠 Pydantic 拦，不靠业务函数自己判
    bad_topk = False
    try:
        RetrieveRequest.model_validate({"question": "助学金的资助标准", "topK": 99, "candidateChunks": []})
    except ValidationError:
        bad_topk = True
    bad_long = False
    try:
        RetrieveRequest.model_validate({"question": "字" * (MAX_QUESTION_CHARS + 1), "topK": 5, "candidateChunks": []})
    except ValidationError:
        bad_long = True
    good = True
    try:
        RetrieveRequest.model_validate({"question": "助学金的资助标准", "topK": 5, "candidateChunks": candidates})
    except ValidationError:
        good = False
    check("参数校验：topK 越界、问题超长被拒，合法请求通过", bad_topk and bad_long and good,
          "topK>%d 拒绝=%s，问题>%d 字拒绝=%s" % (MAX_TOP_K, bad_topk, MAX_QUESTION_CHARS, bad_long))

    print("-" * 76)
    print("结果：%d 条通过，%d 条失败" % (passed, failed))
    if failed:
        print("有失败项，先修好再提交，不要拿“看起来能跑”当验收。")
    else:
        print("全部通过：可以把 /retrieve 交给沈明昊联调，并按下周计划准备模型适配。")
    print("=" * 76)
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    import sys

    if "--selftest" in sys.argv:
        raise SystemExit(run_self_test())

    import uvicorn

    print("服务地址 http://127.0.0.1:8000 ，接口文档 http://127.0.0.1:8000/docs")
    uvicorn.run(app, host="127.0.0.1", port=8000)
