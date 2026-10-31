package cn.campus.rag.document.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;

/**
 * 新增/修改制度的请求体。
 *
 * <p>为什么不直接用 Document 实体收参数？
 * 因为前端不该决定 id、createdAt 这些字段——那是数据库的活。
 * 单独一个 DTO 只暴露"前端有资格填"的字段，这是接口设计的基本卫生。</p>
 */
@Data
public class DocumentRequest {

    private String docNo;

    @NotBlank(message = "制度名称不能为空")
    private String title;

    @NotBlank(message = "版本号不能为空")
    private String version;

    /** 1=有效 0=废止，不传默认有效 */
    private Integer status;

    private LocalDate effectiveDate;

    private LocalDate expireDate;
}
