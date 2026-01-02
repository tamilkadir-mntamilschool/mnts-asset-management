import { createRouter, createWebHistory } from 'vue-router'
import AssetsPage from '../pages/Assets.vue'
import AuthPage from '../pages/Auth.vue'
import { useSessionStore } from '../stores/session'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'auth',
      component: AuthPage,
    },
    {
      path: '/assets',
      name: 'assets',
      component: AssetsPage,
      meta: { requiresAuth: true },
    },
    {
      path: '/auth',
      redirect: { name: 'auth' },
    },
  ],
})

router.beforeEach(async (to) => {
  const sessionStore = useSessionStore()

  if (!sessionStore.initialized) {
    await sessionStore.init()
  }

  if (to.meta.requiresAuth && !sessionStore.user) {
    return { name: 'auth', query: { redirect: to.fullPath } }
  }

  if (to.name === 'auth' && sessionStore.user) {
    return { name: 'assets' }
  }
})

export default router
