package cn.campus.rag.document;

import cn.campus.rag.common.Result;
import cn.campus.rag.document.dto.DocumentRequest;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 制度接口。
 *
 * <p>@PathVariable 取的是路径里的 {id}，
 * @RequestParam 取的是 ?keyword=xxx 这种查询参数。</p>
 */
@RestController
@RequestMapping("/api/documents")
public class DocumentController {

    private final DocumentService documentService;

    public DocumentController(DocumentService documentService) {
        this.documentService = documentService;
    }

    /** GET /api/documents?keyword=奖学金&status=1 */
    @GetMapping
    public Result<List<Document>> list(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status) {
        System.out.println("[1] Controller 收到请求：keyword=" + keyword + " status=" + status);
        List<Document> data = documentService.list(keyword, status);
        System.out.println("[4] Controller 拿到 " + data.size() + " 条，准备转成 JSON 返回");
        return Result.ok(data);
    }

    /** GET /api/documents/1 */
    @GetMapping("/{id}")
    public Result<Document> detail(@PathVariable Long id) {
        return Result.ok(documentService.getById(id));
    }

    /** POST /api/documents 新增，管理员 */
    @PostMapping
    public Result<Document> create(@Valid @RequestBody DocumentRequest req) {
        return Result.ok(documentService.create(req));
    }

    /** PUT /api/documents/1 修改，管理员 */
    @PutMapping("/{id}")
    public Result<Document> update(@PathVariable Long id, @Valid @RequestBody DocumentRequest req) {
        return Result.ok(documentService.update(id, req));
    }

    /** POST /api/documents/1/revoke?replacedBy=2 废止，管理员 */
    @PostMapping("/{id}/revoke")
    public Result<Void> revoke(@PathVariable Long id,
                               @RequestParam(required = false) Long replacedBy) {
        documentService.revoke(id, replacedBy);
        return Result.ok();
    }

    /** DELETE /api/documents/1 删除，管理员，且必须是已废止的空制度 */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        documentService.delete(id);
        return Result.ok();
    }
}
