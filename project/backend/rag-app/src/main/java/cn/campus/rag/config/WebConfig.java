package cn.campus.rag.config;

import cn.campus.rag.auth.LoginInterceptor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web 层配置。三件事：挂拦截器、开跨域、注册密码加密器。
 *
 * <p>WebMvcConfigurer 是 Spring MVC 的"定制接口"，
 * 实现它就能往框架的默认流程里插自己的一手。</p>
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    private final LoginInterceptor loginInterceptor;

    public WebConfig(LoginInterceptor loginInterceptor) {
        this.loginInterceptor = loginInterceptor;
    }

    /**
     * 拦截所有 /api/**，但登录和注册这两个接口必须放过——
     * 不然用户还没登录就被拦，永远登不进来。
     */
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(loginInterceptor)
                .addPathPatterns("/api/**")
                .excludePathPatterns(
                        "/api/auth/login",
                        "/api/auth/register",
                        "/api/features"
                );
    }

    /**
     * 跨域。前端跑在 5173 端口，后端跑在 8080，
     * 浏览器认为这是"两个不同的源"，默认不让 JS 读响应。
     * 这里明确告诉浏览器：我允许。
     */
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOriginPatterns("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }

    /**
     * BCrypt 密码加密器。
     * 它每次加密同一个密码，结果都不一样（因为加了随机盐），
     * 但 matches(明文, 哈希) 能正确判断对错——这比 MD5 安全得多。
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
