package cn.campus.rag.qa;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import cn.campus.rag.clause.Clause;
import cn.campus.rag.clause.ClauseMapper;
import cn.campus.rag.document.Document;
import cn.campus.rag.document.DocumentMapper;
import cn.campus.rag.qa.dto.AskResponse;
import cn.campus.rag.qa.dto.Citation;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 问答主流程 —— 这是整个第一周最核心的一段代码。
 *
 * <p>它做的事情可以浓缩成四步：</p>
 * <ol>
 *   <li>筛：从数据库里挑出"有效制度下面"的条款，形成候选集</li>
 *   <li>排：把候选集交给 Python，让它按相关度排序</li>
 *   <li>验：Python 回来的编号，必须能在候选集里查得到，否则丢掉</li>
 *   <li>答：用数据库里的原文组装答案和引用</li>
 * </ol>
 *
 * <p>为什么一定要有第三步"验"？因为 Python 是另一个进程、另一套代码，
 * 它可能返回一个不存在的编号，也可能把废止制度的编号混进来。
 * Java 是最后一道闸，它不认"编号"，只认"数据库里查得到的编号"。</p>
 */
@Service
public class QaService {

    private final DocumentMapper documentMapper;
    private final ClauseMapper clauseMapper;
    private final PythonClient pythonClient;

    /** true 表示 Python 还没上线，用本地关键词匹配假装它在 */
    @Value("${app.python.mock:true}")
    private boolean mock;

    public QaService(DocumentMapper documentMapper, ClauseMapper clauseMapper, PythonClient pythonClient) {
        this.documentMapper = documentMapper;
        this.clauseMapper = clauseMapper;
        this.pythonClient = pythonClient;
    }

    public AskResponse ask(String question) {
        // ---------- 第一步：筛 ----------
        // 有效 = status 是 1，且（没有失效日 或 失效日还没到）
        LocalDate today = LocalDate.now();
        List<Document> validDocs = documentMapper.selectList(
                Wrappers.<Document>lambdaQuery()
                        .eq(Document::getStatus, 1)
                        .and(w -> w.isNull(Document::getExpireDate)
                                .or().ge(Document::getExpireDate, today))
        );
        if (validDocs.isEmpty()) {
            return new AskResponse(false, "目前没有可用的有效制度，暂时无法回答。", List.of());
        }

        Map<Long, Document> docById = validDocs.stream()
                .collect(Collectors.toMap(Document::getId, d -> d));

        List<Clause> candidates = clauseMapper.selectList(
                Wrappers.<Clause>lambdaQuery().in(Clause::getDocumentId, docById.keySet())
        );
        if (candidates.isEmpty()) {
            return new AskResponse(false, "现行有效制度下还没有录入条款，暂时无法回答。", List.of());
        }

        // ---------- 第二步：排 ----------
        List<RetrieveHit> hits;
        if (mock) {
            // Python 还没接上时走这里，保证前端和 Java 能先联调
            hits = mockRetrieve(question, candidates);
        } else {
            hits = pythonClient.retrieve(
                    question,
                    candidates.stream().map(Clause::getChunkId).toList()
            );
        }

        // ---------- 第三步：验 ----------
        // 把数据库里的条款按 chunkId 建索引，一会儿用 Python 给的编号来查
        Map<String, Clause> clauseByChunk = candidates.stream()
                .filter(c -> c.getChunkId() != null)
                .collect(Collectors.toMap(Clause::getChunkId, c -> c, (a, b) -> a));

        List<Citation> citations = new ArrayList<>();
        for (RetrieveHit hit : hits) {
            Clause clause = clauseByChunk.get(hit.chunkId());
            if (clause == null) {
                // Python 返回了数据库里没有的编号，直接丢弃，绝不拿来当依据
                continue;
            }
            Document doc = docById.get(clause.getDocumentId());
            if (doc == null) {
                // 属于已废止制度，丢弃
                continue;
            }
            citations.add(new Citation(
                    clause.getChunkId(),
                    doc.getId(),
                    doc.getTitle(),
                    doc.getVersion(),
                    clause.getClauseNo(),
                    clause.getContent(),
                    hit.score()
            ));
        }

        if (citations.isEmpty()) {
            // 注意：这是"没找到依据"，不是"服务坏了"，两种要给不同的提示
            return new AskResponse(false, "在现行有效制度中没有找到相关依据。", List.of());
        }

        // ---------- 第四步：答 ----------
        return new AskResponse(true, buildAnswer(citations), citations);
    }

    /**
     * 用最相关的那条改成一段人话，其余作为补充列出来。
     * 这里故意不做"生成式回答"——第一周只要求"原文引用"，
     * 生成交给后面的 Python /generate，Java 不该抢这个活。
     */
    private String buildAnswer(List<Citation> citations) {
        Citation top = citations.get(0);
        StringBuilder sb = new StringBuilder();
        sb.append("根据《").append(top.getDocumentTitle()).append("》（")
                .append(top.getVersion()).append("）第 ").append(top.getClauseNo()).append(" 条：\n")
                .append(top.getContent());

        if (citations.size() > 1) {
            sb.append("\n\n另外还涉及：");
            for (int i = 1; i < citations.size(); i++) {
                Citation c = citations.get(i);
                sb.append("\n·《").append(c.getDocumentTitle()).append("》第 ")
                        .append(c.getClauseNo()).append(" 条：").append(c.getContent());
            }
        }
        return sb.toString();
    }

    /**
     * 假的检索：Python 还没上线时用它顶着。
     *
     * <p>做法很土但有效：把问题拆成一个个字，看某个条款里出现了几个。
     * 命中比例超过 20% 就算相关，取前 3 条。</p>
     *
     * <p>它当然不如向量检索准，但它能证明"链路是通的"——
     * 前端能拿到答案、能显示引用、能区分"没找到"。
     * 等 Python 的 /retrieve 上线，把 app.python.mock 改成 false 就切过去了。</p>
     */
    private List<RetrieveHit> mockRetrieve(String question, List<Clause> candidates) {
        // 这些字几乎每句话都有，留着会干扰打分
        String stopWords = "的了吗呢吧啊什怎哪些可以能否需要多少怎样么请问一下";

        Set<Integer> questionChars = new HashSet<>();
        question.codePoints().forEach(cp -> {
            if (stopWords.indexOf(cp) < 0) {
                questionChars.add(cp);
            }
        });
        if (questionChars.isEmpty()) {
            return List.of();
        }

        List<RetrieveHit> result = new ArrayList<>();
        for (Clause clause : candidates) {
            long matched = questionChars.stream()
                    .filter(cp -> clause.getContent().indexOf(cp) >= 0)
                    .count();
            double score = (double) matched / questionChars.size();
            if (score >= 0.2) {
                result.add(new RetrieveHit(clause.getChunkId(), Math.round(score * 100) / 100.0));
            }
        }

        result.sort((a, b) -> Double.compare(b.score(), a.score()));
        return result.size() > 3 ? result.subList(0, 3) : result;
    }
}
