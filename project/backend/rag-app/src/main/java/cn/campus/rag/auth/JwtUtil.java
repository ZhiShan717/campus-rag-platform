package cn.campus.rag.auth;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * JWT 工具类：负责"签发通行证"和"验通行证"。
 *
 * <p>JWT 长这样：eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.xxxxx
 * 由三段组成，用两个点分开：头部.载荷.签名。
 * 前两段只是 Base64 编码，谁都能解开看——所以里面绝不能放密码。
 * 第三段是用密钥算出来的签名，改了前两段签名就对不上，服务端一验就知道被伪造了。</p>
 *
 * <p>为什么不用 session？session 存在服务器内存里，多台服务器要同步；
 * JWT 把状态放在客户端，服务端只验签名，天然适合前后端分离。</p>
 */
@Component
public class JwtUtil {

    /** 签名密钥，从 application.yml 的 app.jwt.secret 读。必须 32 字节以上 */
    @Value("${app.jwt.secret}")
    private String secret;

    /** 通行证有效期（分钟） */
    @Value("${app.jwt.expire-minutes}")
    private long expireMinutes;

    /** 把字符串密钥变成 HMAC 用的 SecretKey 对象 */
    private SecretKey key() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * 签发通行证。把用户的身份信息写进载荷，再用密钥签名。
     *
     * @param userId   用户 id
     * @param username 用户名
     * @param role     角色 USER / ADMIN
     * @return 一个 JWT 字符串
     */
    public String createToken(Long userId, String username, String role) {
        Date now = new Date();
        Date expireAt = new Date(now.getTime() + expireMinutes * 60 * 1000);

        return Jwts.builder()
                .subject(String.valueOf(userId))   // subject 放主键
                .claim("username", username)       // 自定义载荷
                .claim("role", role)               // 角色也放进去，省一次查库
                .issuedAt(now)                     // 签发时间
                .expiration(expireAt)              // 过期时间
                .signWith(key())                   // 用密钥签名
                .compact();                        // 压成字符串
    }

    /**
     * 验通行证并取出载荷。
     * 签名不对、过期了，都会在这里抛异常（JwtException），由拦截器统一处理。
     */
    public Claims parse(String token) {
        return Jwts.parser()
                .verifyWith(key())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
