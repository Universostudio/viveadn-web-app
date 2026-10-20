import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    // Auth
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/auth/LoginView.vue'),
      meta: { public: true }
    },
    // App principal (requiere auth)
    {
      path: '/',
      component: () => import('@/layouts/AppLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        {
          path: '',
          name: 'dashboard',
          component: () => import('@/views/DashboardView.vue')
        },
        {
          path: 'miembros',
          name: 'miembros',
          component: () => import('@/views/miembros/MiembrosView.vue')
        },
        {
          path: 'miembros/:id',
          name: 'miembro-detalle',
          component: () => import('@/views/miembros/MiembroDetalleView.vue')
        },
        {
          path: 'casas',
          name: 'casas',
          component: () => import('@/views/casas/CasasView.vue')
        },
        {
          path: 'consolidacion',
          name: 'consolidacion',
          component: () => import('@/views/consolidacion/ConsolidacionView.vue')
        },
        {
          path: 'formacion',
          name: 'formacion',
          component: () => import('@/views/FormacionView.vue')
        },
        {
          path: 'comunicacion',
          name: 'comunicacion',
          component: () => import('@/views/ComunicacionView.vue')
        },
        {
          path: 'reportes',
          name: 'reportes',
          component: () => import('@/views/ReportesView.vue')
        },
        {
          path: 'configuracion',
          name: 'configuracion',
          component: () => import('@/views/ConfiguracionView.vue')
        },
      ]
    },
    // 404
    {
      path: '/:pathMatch(.*)*',
      redirect: '/'
    }
  ]
})

// Guard de autenticación
router.beforeEach(async (to) => {
  const auth = useAuthStore()
  if (auth.loading) await auth.init()

  if (to.meta.requiresAuth && !auth.isLoggedIn) {
    return { name: 'login' }
  }
  if (to.meta.public && auth.isLoggedIn) {
    return { name: 'dashboard' }
  }
})

export default router
