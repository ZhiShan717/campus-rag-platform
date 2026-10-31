package cn.campus.rag.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

/**
 * 登录成功后返回给前端的东西。
 *
 * <p>重点是 token，前端要把它存进 localStorage，
 * 之后每次请求都放在请求头里：Authorization: Bearer eyJhbGciOi...</p>
 *
 * <p>除了 token 还顺手返回用户名和角色，前端可以直接显示"欢迎你，xxx"、
 * 根据角色决定是否显示"制度管理"菜单，不用再多请求一次 /me。</p>
 */
@Data
@AllArgsConstructor
public class LoginResponse {

    private String token;

    private Long userId;

    private String username;

    /** USER 普通用户 / ADMIN 管理员 */
    private String role;
}
