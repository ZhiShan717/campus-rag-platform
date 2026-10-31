package cn.campus.rag.document;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import cn.campus.rag.auth.UserContext;
import cn.campus.rag.clause.Clause;
import cn.campus.rag.clause.ClauseMapper;
import cn.campus.rag.common.BizException;
import cn.campus.rag.document.dto.DocumentRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 制度业务。
 *
 * <p>第一周的核心规则都在这一个类里：
 * 1. 默认只列有效版本（status=1）
 * 2. 有失效日期的，过期了也算无效
 * 3. 新增/编辑/废止只有管理员能干
 * 4. 有条款的制度不能硬删，只能废止</p>
 */
@Service
public class DocumentService {

    private final DocumentMapper documentMapper;
    private final ClauseMapper clauseMapper;

    public DocumentService(DocumentMapper documentMapper, ClauseMapper clauseMapper) {
        this.documentMapper = documentMapper;
        this.clauseMapper = clauseMapper;
    }

    /**
     * 制度列表。
     *
     * @param keyword 按名称模糊搜，可空
     * @param status  1 只看有效 / 0 只看废止 / null 全都看
     */
    public List<Document> list(String keyword, Integer status) {
        System.out.println("[2] Service 开始拼查询条件");
        List<Document> result = documentMapper.selectList(
                Wrappers.<Document>lambdaQuery()
                        // 第一个参数是"要不要拼这段条件"，false 就跳过
                        .like(StringUtils.hasText(keyword), Document::getTitle, keyword)
                        .eq(status != null, Document::getStatus, status)
                        .orderByDesc(Document::getStatus)
                        .orderByDesc(Document::getEffectiveDate)
                        .orderByDesc(Document::getId)
        );
        System.out.println("[3] Service 从数据库拿到 " + result.size() + " 条");
        return result;
    }

    public Document getById(Long id) {
        Document doc = documentMapper.selectById(id);
        if (doc == null) {
            throw new BizException(404, "制度不存在");
        }
        return doc;
    }

    /** 新增制度，管理员限定 */
    public Document create(DocumentRequest req) {
        requireAdmin();
        checkDateRange(req);

        Document doc = new Document();
        doc.setDocNo(req.getDocNo());
        doc.setTitle(req.getTitle());
        doc.setVersion(req.getVersion());
        doc.setStatus(req.getStatus() == null ? 1 : req.getStatus());
        doc.setEffectiveDate(req.getEffectiveDate());
        doc.setExpireDate(req.getExpireDate());
        documentMapper.insert(doc);
        // 重新查一次，把数据库生成的 created_at / updated_at 带回去
        return documentMapper.selectById(doc.getId());
    }

    /** 修改制度，管理员限定 */
    public Document update(Long id, DocumentRequest req) {
        requireAdmin();
        checkDateRange(req);

        Document doc = getById(id);
        doc.setDocNo(req.getDocNo());
        doc.setTitle(req.getTitle());
        doc.setVersion(req.getVersion());
        if (req.getStatus() != null) {
            doc.setStatus(req.getStatus());
        }
        doc.setEffectiveDate(req.getEffectiveDate());
        doc.setExpireDate(req.getExpireDate());
        doc.setUpdatedAt(LocalDateTime.now());
        documentMapper.updateById(doc);
        return doc;
    }

    /**
     * 废止一份制度。
     *
     * <p>为什么不直接删掉？因为历史问答记录里引用的条文可能就出自它，
     * 删了之后引用就变成悬空的。所以制度只"废止"，不"消失"。</p>
     *
     * @param id         要废止的制度
     * @param replacedBy 被哪份新制度替代，可空
     */
    @Transactional
    public void revoke(Long id, Long replacedBy) {
        requireAdmin();
        Document doc = getById(id);
        if (doc.getStatus() != null && doc.getStatus() == 0) {
            throw new BizException("该制度已经是废止状态");
        }
        doc.setStatus(0);
        if (doc.getExpireDate() == null) {
            doc.setExpireDate(java.time.LocalDate.now());
        }
        doc.setReplacedBy(replacedBy);
        doc.setUpdatedAt(LocalDateTime.now());
        documentMapper.updateById(doc);
    }

    /**
     * 物理删除。只允许删已经废止、且没有条款的空制度，
     * 用来清理录错的测试数据。
     */
    @Transactional
    public void delete(Long id) {
        requireAdmin();
        Document doc = getById(id);
        if (doc.getStatus() != null && doc.getStatus() == 1) {
            throw new BizException("有效制度不能直接删除，请先废止");
        }
        Long clauseCount = clauseMapper.selectCount(
                Wrappers.<Clause>lambdaQuery().eq(Clause::getDocumentId, id)
        );
        if (clauseCount != null && clauseCount > 0) {
            throw new BizException("该制度下还有 " + clauseCount + " 条条款，不能删除");
        }
        documentMapper.deleteById(id);
    }

    /** 权限检查：只有 ADMIN 能改数据 */
    private void requireAdmin() {
        if (!UserContext.isAdmin()) {
            throw new BizException(403, "只有管理员可以执行这个操作");
        }
    }

    /** 生效日不能晚于失效日，否则这份制度永远不会有效 */
    private void checkDateRange(DocumentRequest req) {
        if (req.getEffectiveDate() != null && req.getExpireDate() != null
                && req.getEffectiveDate().isAfter(req.getExpireDate())) {
            throw new BizException("生效日期不能晚于失效日期");
        }
    }
}
