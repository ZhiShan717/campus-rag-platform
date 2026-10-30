package cn.campus.rag.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDateTime;

@TableName("chunks")
public class Chunk {
    @TableId(type = IdType.AUTO)
    public Long id;
    public Long documentId;
    public Integer chunkNo;
    public String sectionPath;
    public String content;
    public LocalDateTime createdAt;
    public LocalDateTime updatedAt;
}
