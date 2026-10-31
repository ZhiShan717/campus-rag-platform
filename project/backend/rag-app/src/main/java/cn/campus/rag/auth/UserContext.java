package cn.campus.rag.auth;

/**
 * 当前请求的登录用户。
 *
 * <p>问题：拦截器里验完 token 知道"这是 1 号用户"，但 Controller 在另一个方法里，
 * 怎么把"我是谁"传过去？加参数一路传？那每个方法签名都得改，太丑。</p>
 *
 * <p>ThreadLocal 是"每个线程一个储物柜"。Tomcat 处理一个请求用一个线程，
 * 拦截器把用户放进柜子，Controller 从柜子拿出来，请求结束再清空。
 * 线程之间互不干扰，天然安全。</p>
 */
public class UserContext {

    private static final ThreadLocal<LoginUser> HOLDER = new ThreadLocal<>();

    public static void set(LoginUser user) {
        HOLDER.set(user);
    }

    public static LoginUser get() {
        return HOLDER.get();
    }

    public static Long currentUserId() {
        LoginUser u = HOLDER.get();
        return u == null ? null : u.userId();
    }

    public static boolean isAdmin() {
        LoginUser u = HOLDER.get();
        return u != null && "ADMIN".equals(u.role());
    }

    /** 一定要在请求结束时调用，否则线程复用时会把上一个用户的信息带给下一个人 */
    public static void clear() {
        HOLDER.remove();
    }

    /** 只读的小盒子，装登录态的三个字段 */
    public record LoginUser(Long userId, String username, String role) {
    }
}
