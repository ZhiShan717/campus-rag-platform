package cn.campus.rag.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDateTime;

/** Persistence object only. Never serialize passwordHash to an API response. */
@TableName("users")
public class User {
    @TableId(type = IdType.AUTO)
    public Long id;
    public String username;
    public String passwordHash;
    public String displayName;
    public String role;
    public Integer enabled;
    public LocalDateTime createdAt;
    public LocalDateTime updatedAt;
}
