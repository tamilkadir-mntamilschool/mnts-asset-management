import { createRouter, createWebHistory } from 'vue-router'
import AssetsPage from '../pages/Assets.vue'
import AssetCreatePage from '../pages/AssetCreate.vue'
import AssetDetailPage from '../pages/AssetDetail.vue'
import AssetPrintPage from '../pages/AssetPrint.vue'
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
      path: '/assets/new',
      name: 'asset-create',
      component: AssetCreatePage,
      meta: { requiresAuth: true },
    },
    {
      path: '/assets/:id',
      name: 'asset-detail',
      component: AssetDetailPage,
      meta: { requiresAuth: true },
    },
    {
      path: '/assets/:id/print',
      name: 'asset-print',
      component: AssetPrintPage,
      meta: { requiresAuth: true },
    },
    {
      path: '/assets/code/:code',
      name: 'asset-code',
      component: AssetDetailPage,
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
