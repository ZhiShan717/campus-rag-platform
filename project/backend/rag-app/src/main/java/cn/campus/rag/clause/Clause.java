package cn.campus.rag.clause;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 条款。一条制度被拆成很多条，每条是检索的最小单位。
 *
 * <p>chunk_id 是给 Python 那边用的唯一编号。
 * 为什么不让 Python 自己编号？因为"哪条条款被引用了"必须由 Java 说得准，
 * 否则答案里给出的出处对不上原文，整个 RAG 的可信度就没了。</p>
 */
@Data
@TableName("clause")
public class Clause {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long documentId;

    /** 条款号，如 3.1 */
    private String clauseNo;

    private String content;

    /** 检索用的唯一标识，形如 doc1-c1 */
    private String chunkId;

    private LocalDateTime createdAt;
}
