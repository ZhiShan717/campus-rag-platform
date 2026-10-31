package cn.campus.rag.clause;

import cn.campus.rag.clause.dto.ClauseRequest;
import cn.campus.rag.common.Result;
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
 * 条款接口。
 */
@RestController
@RequestMapping("/api/clauses")
public class ClauseController {

    private final ClauseService clauseService;

    public ClauseController(ClauseService clauseService) {
        this.clauseService = clauseService;
    }

    /** GET /api/clauses?documentId=1 列出某份制度的全部条款 */
    @GetMapping
    public Result<List<Clause>> list(@RequestParam Long documentId) {
        return Result.ok(clauseService.listByDocument(documentId));
    }

    /** POST /api/clauses 新增条款，管理员 */
    @PostMapping
    public Result<Clause> create(@Valid @RequestBody ClauseRequest req) {
        return Result.ok(clauseService.create(req));
    }

    /** PUT /api/clauses/1 修改条款，管理员 */
    @PutMapping("/{id}")
    public Result<Clause> update(@PathVariable Long id, @Valid @RequestBody ClauseRequest req) {
        return Result.ok(clauseService.update(id, req));
    }

    /** DELETE /api/clauses/1 删除条款，管理员 */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        clauseService.delete(id);
        return Result.ok();
    }
}
