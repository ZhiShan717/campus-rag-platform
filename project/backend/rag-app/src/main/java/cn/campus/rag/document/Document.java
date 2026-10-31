package cn.campus.rag.document;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 一份制度。
 *
 * <p>第一周最关键的设计就在 status 和 effectiveDate/expireDate 上：
 * 同一份制度会有多个版本，只有 status=1 的那版算"当前有效"。
 * 学生问"国家奖学金多少钱"，系统必须只拿有效版回答，
 * 不能把已废止的 2023 版条文当依据——这就是"制度查询"和"随便搜一下"的区别。</p>
 */
@Data
@TableName("document")
public class Document {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 制度文号，如 NZ-2024 */
    private String docNo;

    private String title;

    /** 版本号，如 2024-A */
    private String version;

    /** 1=有效，0=废止 */
    private Integer status;

    private LocalDate effectiveDate;

    /** null 表示长期有效 */
    private LocalDate expireDate;

    /** 被哪条新制度替代，指向 document.id */
    private Long replacedBy;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
