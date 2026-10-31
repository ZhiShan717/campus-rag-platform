package cn.campus.rag.user;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户。
 *
 * <p>注意字段名 passwordHash 对应数据库列 password_hash，
 * 靠 mybatis-plus 的 map-underscore-to-camel-case 自动对上。</p>
 *
 * <p>数据库列名故意不叫 password —— 存的是哈希，不是明文。
 * 名字里带上 hash 是为了提醒自己：这里的东西不能直接拿去比对明文。</p>
 */
@Data
@TableName("app_user")
public class User {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String username;

    private String passwordHash;

    /** USER 普通用户 / ADMIN 管理员 */
    private String role;

    private LocalDateTime createdAt;
}
