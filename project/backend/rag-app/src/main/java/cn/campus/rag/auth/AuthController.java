package cn.campus.rag.auth;

import cn.campus.rag.auth.dto.LoginRequest;
import cn.campus.rag.auth.dto.LoginResponse;
import cn.campus.rag.auth.dto.RegisterRequest;
import cn.campus.rag.common.Result;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 认证接口。
 *
 * <p>@RequestBody：把请求体的 JSON 变成 Java 对象。
 * @Valid：让 RegisterRequest 里的 @NotBlank/@Size 生效。</p>
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    /** POST /api/auth/register 注册 */
    @PostMapping("/register")
    public Result<Void> register(@Valid @RequestBody RegisterRequest req) {
        authService.register(req);
        return Result.ok();
    }

    /** POST /api/auth/login 登录，成功返回 token */
    @PostMapping("/login")
    public Result<LoginResponse> login(@Valid @RequestBody LoginRequest req) {
        return Result.ok(authService.login(req));
    }

    /** GET /api/auth/me 当前登录用户，前端刷新页面时用它恢复登录态 */
    @GetMapping("/me")
    public Result<UserContext.LoginUser> me() {
        return Result.ok(authService.current());
    }

    /**
     * POST /api/auth/logout 退出登录。
     * JWT 是无状态的，服务端没有"销毁通行证"的能力，
     * 所以这里只返回成功，真正的退出是前端把 localStorage 里的 token 删掉。
     */
    @PostMapping("/logout")
    public Result<Void> logout() {
        return Result.ok();
    }
}
