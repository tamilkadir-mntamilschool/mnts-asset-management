import { createRouter, createWebHistory } from 'vue-router'
import HomePage from '../pages/Home.vue'
import AssetsPage from '../pages/Assets.vue'
import AuthPage from '../pages/Auth.vue'
import { useSessionStore } from '../stores/session'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomePage,
    },
    {
      path: '/assets',
      name: 'assets',
      component: AssetsPage,
      meta: { requiresAuth: true },
    },
    {
      path: '/auth',
      name: 'auth',
      component: AuthPage,
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
