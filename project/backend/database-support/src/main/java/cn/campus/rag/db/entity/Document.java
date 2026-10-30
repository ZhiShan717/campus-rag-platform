package cn.campus.rag.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDate;
import java.time.LocalDateTime;

@TableName("documents")
public class Document {
    @TableId(type = IdType.AUTO)
    public Long id;
    public String documentKey;
    public String title;
    public String version;
    public String status;
    public LocalDate effectiveFrom;
    public LocalDate effectiveTo;
    public Long replacedBy;
    public String sourceType;
    public String sourceUrl;
    public String sourceNote;
    public Long createdBy;
    public LocalDateTime createdAt;
    public LocalDateTime updatedAt;
}
