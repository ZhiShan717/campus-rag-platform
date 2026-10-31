package cn.campus.rag.auth;

import io.jsonwebtoken.Claims;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * 登录拦截器。
 *
 * <p>HandlerInterceptor 是 Spring MVC 提供的"关卡"，请求进 Controller 之前先过它。
 * 三个方法：preHandle（进之前）、postHandle（出之前）、afterCompletion（彻底完事）。</p>
 *
 * <p>工作流程：从请求头 Authorization 里拿 "Bearer <token>"，
 * 取后半段验签，验过了把用户信息塞进 UserContext，放行；验不过直接返回 401，请求根本到不了 Controller。</p>
 */
@Component
public class LoginInterceptor implements HandlerInterceptor {

    private final JwtUtil jwtUtil;

    public LoginInterceptor(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws Exception {

        // 浏览器跨域时会先发一个 OPTIONS 预检请求，这种请求不带 token，直接放行
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        String header = request.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) {
            write401(response, "未登录或登录已过期");
            return false;
        }

        String token = header.substring(7);
        try {
            Claims claims = jwtUtil.parse(token);
            Long userId = Long.valueOf(claims.getSubject());
            String username = claims.get("username", String.class);
            String role = claims.get("role", String.class);
            UserContext.set(new UserContext.LoginUser(userId, username, role));
            return true;
        } catch (Exception e) {
            write401(response, "登录凭证无效或已过期");
            return false;
        }
    }

    /** 请求结束后必须清空，不然线程池复用线程会把身份串给别人 */
    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                                Object handler, Exception ex) {
        UserContext.clear();
    }

    private void write401(HttpServletResponse response, String message) throws Exception {
        response.setStatus(401);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"code\":401,\"message\":\"" + message + "\",\"data\":null}");
    }
}
