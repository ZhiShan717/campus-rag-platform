import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', redirect: { name: 'qa' } },
    {
      path: '/qa',
      name: 'qa',
      component: () => import('@/views/qa/QaView.vue'),
    },
    {
      path: '/documents',
      name: 'documents',
      component: () => import('@/views/documents/DocumentsView.vue'),
    },
    {
      path: '/admin',
      name: 'admin',
      component: () => import('@/views/admin/AdminView.vue'),
    },
    {
      path: '/evaluation',
      name: 'evaluation',
      component: () => import('@/views/evaluation/EvaluationView.vue'),
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: () => import('@/views/NotFoundView.vue'),
    },
  ],
})

export default router
