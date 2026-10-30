/**
 * 路由 —— 对应计划 10.27「路由守卫」+ 按后端真实权限显示入口
 *
 * 用法：这是"片段"，把 ROUTES 合并进仲雯已有的 router 即可，不要整个文件覆盖。
 * 如果仲雯的 router 直接 export default，请按文件末尾的注释改造。
 */
import { createRouter, createWebHistory } from 'vue-router'
import { userStore } from '../stores/user'

/** 陈奥文负责的用户侧路由（管理端路由由仲雯维护） */
export const ROUTES = [
  {
    path: '/login',
    name: 'login',
    component: () => import('../views/LoginView.vue'),
    meta: { guestOnly: true, title: '登录' }
  },
  {
    path: '/register',
    name: 'register',
    component: () => import('../views/RegisterView.vue'),
    meta: { guestOnly: true, title: '注册' }
  },
  {
    path: '/ask',
    name: 'ask',
    component: () => import('../views/AskView.vue'),
    meta: { requiresAuth: true, title: '制度问答' }
  },
  // 10.31 之后再补：个人历史 / 反馈页
  // { path: '/history', name: 'history', component: () => import('../views/HistoryView.vue'),
  //   meta: { requiresAuth: true, title: '我的提问记录' } }
]

/**
 * 全局前置守卫：三条规则
 *   1. requiresAuth 但没 Token        → 去登录页，并记住想去的地址
 *   2. guestOnly 但已登录             → 回 /ask（避免已登录还停在登录页）
 *   3. 有 Token 但 profile 没加载     → 先 ensureProfile()，失败即视为登录过期
 */
export async function authGuard(to) {
  const needAuth = to.meta?.requiresAuth
  const guestOnly = to.meta?.guestOnly

  if (!userStore.isLogin) {
    if (needAuth) return { name: 'login', query: { redirect: to.fullPath } }
    return true
  }

  // 已登录：确保 profile 可用（刷新页面后 token 还在、内存状态是空的）
  try {
    await userStore.ensureProfile()
  } catch (err) {
    // Token 失效（401）→ 清掉并回登录页；网络问题也回登录页，但不静默假装登录成功
    userStore.reset()
    if (needAuth || guestOnly) {
      return { name: 'login', query: { redirect: to.fullPath } }
    }
    return true
  }

  if (guestOnly) return { name: 'ask' }
  return true
}

/* ------------------------------------------------------------------
 * 独立运行（如果你们还没有 router）时用这段；
 * 已经有了就把 ROUTES 和 authGuard 合并过去，然后删掉下面的内容。
 * ------------------------------------------------------------------ */
const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', redirect: '/ask' },
    ...ROUTES
  ]
})

router.beforeEach(authGuard)

router.afterEach((to) => {
  const base = '校园 RAG 制度问答'
  document.title = to.meta?.title ? `${to.meta.title} · ${base}` : base
})

export default router
