import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

// Role → halaman yang boleh diakses
// staff_kantor boleh akses semua tapi read-only (ditandai meta.readOnly)
const ROLE_ROUTES = {
  admin         : ['Dashboard','Gudang','Pembelian','Penjualan','Penagihan','Laporan'],
  staff_gudang  : ['Dashboard','Gudang'],
  sales         : ['Dashboard','Pembelian','Penjualan','Penagihan'],
  staff_kantor  : ['Dashboard','Gudang','Pembelian','Penjualan','Penagihan','Laporan'],
}

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'Login',
      component: () => import('@/pages/LoginPage.vue'),
      meta: { guest: true }
    },
    {
      path: '/',
      component: () => import('@/layouts/MainLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        { path: '', redirect: '/dashboard' },
        {
          path: 'dashboard',
          name: 'Dashboard',
          component: () => import('@/pages/DashboardPage.vue')
        },
        {
          path: 'gudang',
          name: 'Gudang',
          component: () => import('@/pages/GudangPage.vue')
        },
        {
          path: 'pembelian',
          name: 'Pembelian',
          component: () => import('@/pages/PembelianPage.vue')
        },
        {
          path: 'penjualan',
          name: 'Penjualan',
          component: () => import('@/pages/PenjualanPage.vue')
        },
        {
          path: 'penagihan',
          name: 'Penagihan',
          component: () => import('@/pages/PenagihanPage.vue')
        },
        {
          path: 'laporan',
          name: 'Laporan',
          component: () => import('@/pages/LaporanPage.vue')
        }
      ]
    },
    {
      path: '/403',
      name: 'Forbidden',
      component: () => import('@/pages/ForbiddenPage.vue')
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: '/'
    }
  ]
})

// Navigation Guard
router.beforeEach(async (to) => {
  const auth = useAuthStore()

  if (!auth.initialized) {
    await auth.init()
  }

  // Belum login → ke halaman login
  if (to.meta.requiresAuth && !auth.user) {
    return { name: 'Login' }
  }

  // Sudah login → jangan ke /login
  if (to.meta.guest && auth.user) {
    return { name: 'Dashboard' }
  }

  // Cek akses role
  if (to.meta.requiresAuth && to.name && to.name !== 'Forbidden') {
    // Jika user login tapi profile belum ter-load, coba fetch sekali lagi
    if (auth.user && !auth.userRole) {
      await auth.fetchProfile()
    }

    const role = auth.userRole
    // Jika role masih null setelah retry (misal profile tidak ada),
    // biarkan lewat dulu — jangan hard-block supaya tidak stuck di 403
    if (role) {
      const allowed = ROLE_ROUTES[role] ?? []
      if (!allowed.includes(to.name)) {
        return { name: 'Forbidden' }
      }
    }
    // Tandai read-only untuk staff_kantor
    to.meta.readOnly = (role === 'staff_kantor')
  }
})

export { ROLE_ROUTES }
export default router
