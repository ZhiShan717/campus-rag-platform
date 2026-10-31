package cn.campus.rag.clause;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import cn.campus.rag.auth.UserContext;
import cn.campus.rag.clause.dto.ClauseRequest;
import cn.campus.rag.common.BizException;
import cn.campus.rag.document.Document;
import cn.campus.rag.document.DocumentMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 条款业务。
 *
 * <p>条款是录入工作量最大的一块：8 份制度、30 多条条款，一条条录进去。
 * 所以这里必须把"录入"这条路做得顺：新增一条，自动生成 chunk_id。</p>
 */
@Service
public class ClauseService {

    private final ClauseMapper clauseMapper;
    private final DocumentMapper documentMapper;

    public ClauseService(ClauseMapper clauseMapper, DocumentMapper documentMapper) {
        this.clauseMapper = clauseMapper;
        this.documentMapper = documentMapper;
    }

    /** 按制度列条款，前端"查看制度"页用 */
    public List<Clause> listByDocument(Long documentId) {
        return clauseMapper.selectList(
                Wrappers.<Clause>lambdaQuery()
                        .eq(Clause::getDocumentId, documentId)
                        .orderByAsc(Clause::getClauseNo)
        );
    }

    /**
     * 新增条款。
     *
     * <p>两步：先插入拿自增 id，再用 id 拼 chunk_id 回填。
     * 加 @Transactional 是因为这两步必须同生共死——
     * 要是插入成功了、回填失败了，库里就留下一条没有 chunk_id 的孤儿数据，
     * 检索的时候对不上号，还特别难查。</p>
     */
    @Transactional
    public Clause create(ClauseRequest req) {
        requireAdmin();

        Document doc = documentMapper.selectById(req.getDocumentId());
        if (doc == null) {
            throw new BizException(404, "制度不存在，不能给它加条款");
        }

        Clause clause = new Clause();
        clause.setDocumentId(req.getDocumentId());
        clause.setClauseNo(req.getClauseNo());
        clause.setContent(req.getContent());
        clauseMapper.insert(clause);

        // insert 之后 MyBatis-Plus 会把自增主键回填到 clause.id
        // 有了 id 才能生成稳定的 chunk_id，让 Java 和 Python 认的是同一个编号
        clause.setChunkId("doc" + clause.getDocumentId() + "-c" + clause.getId());
        clauseMapper.updateById(clause);

        // 重新查一次，是为了把数据库生成的 created_at 也带回去给前端
        return clauseMapper.selectById(clause.getId());
    }

    public Clause update(Long id, ClauseRequest req) {
        requireAdmin();
        Clause clause = clauseMapper.selectById(id);
        if (clause == null) {
            throw new BizException(404, "条款不存在");
        }
        clause.setClauseNo(req.getClauseNo());
        clause.setContent(req.getContent());
        clauseMapper.updateById(clause);
        return clause;
    }

    public void delete(Long id) {
        requireAdmin();
        if (clauseMapper.selectById(id) == null) {
            throw new BizException(404, "条款不存在");
        }
        clauseMapper.deleteById(id);
    }

    private void requireAdmin() {
        if (!UserContext.isAdmin()) {
            throw new BizException(403, "只有管理员可以执行这个操作");
        }
    }
}
