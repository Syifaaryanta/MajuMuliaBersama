import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

// Role → halaman yang boleh diakses
// staff_kantor boleh akses semua tapi read-only (ditandai meta.readOnly)
const ROLE_ROUTES = {
  admin         : ['Dashboard','Gudang','Pembelian','Penjualan','Penagihan','Laporan','MasterData'],
  staff_gudang  : ['Dashboard','Gudang','MasterData'],
  sales         : ['Dashboard','Pembelian','Penjualan','Penagihan','MasterData'],
  staff_kantor  : ['Dashboard','Gudang','Pembelian','Penjualan','Penagihan','Laporan','MasterData'],
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
          component: () => import('@/pages/gudang/GudangMenuPage.vue')
        },
        {
          path: 'gudang/cek-harga',
          name: 'GudangCekHarga',
          component: () => import('@/pages/gudang/GudangCekHargaPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Gudang' }
        },
        {
          path: 'gudang/cek-semua',
          name: 'GudangCekSemua',
          component: () => import('@/pages/gudang/GudangCekSemuaPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Gudang' }
        },
        {
          path: 'gudang/katalog',
          name: 'GudangKatalog',
          component: () => import('@/pages/gudang/GudangKatalogPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Gudang' }
        },
        {
          path: 'gudang/detail',
          name: 'GudangDetail',
          component: () => import('@/pages/gudang/GudangDetailPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Gudang' }
        },
        {
          path: 'gudang/archive',
          name: 'GudangArchive',
          component: () => import('@/pages/gudang/GudangArchivePage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Gudang' }
        },
        {
          path: 'pembelian',
          name: 'Pembelian',
          component: () => import('@/pages/pembelian/PembelianPage.vue')
        },
        {
          path: 'pembelian/order',
          name: 'PembelianOrder',
          component: () => import('@/pages/pembelian/PembelianOrderPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Pembelian' }
        },
        {
          path: 'pembelian/input',
          name: 'PembelianInput',
          component: () => import('@/pages/pembelian/PembelianInputPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Pembelian' }
        },
        {
          path: 'pembelian/edit-order',
          name: 'PembelianEditOrder',
          component: () => import('@/pages/pembelian/PembelianEditOrderPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Pembelian' }
        },
        {
          path: 'pembelian/receiving',
          name: 'PembelianReceiving',
          component: () => import('@/pages/pembelian/PembelianReceivingPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Pembelian' }
        },
        {
          path: 'pembelian/history',
          name: 'PembelianHistory',
          component: () => import('@/pages/History/HistoryPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Pembelian' }
        },
        {
          path: 'pembelian/history-pembelian',
          name: 'PembelianHistoryPembelian',
          component: () => import('@/pages/pembelian/PembelianHistoryPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Pembelian' }
        },
        {
          path: 'penjualan',
          name: 'Penjualan',
          component: () => import('@/pages/penjualan/PenjualanMenuPage.vue')
        },
        {
          path: 'penjualan/buat',
          name: 'PenjualanBuat',
          component: () => import('@/pages/penjualan/PenjualanBuatPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Penjualan' }
        },
        {
          path: 'penjualan/edit',
          name: 'PenjualanEdit',
          component: () => import('@/pages/penjualan/PenjualanEditPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Penjualan' }
        },
        {
          path: 'penjualan/input',
          name: 'PenjualanInput',
          component: () => import('@/pages/penjualan/PenjualanInputPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Penjualan' }
        },
        {
          path: 'penjualan/list',
          name: 'PenjualanList',
          component: () => import('@/pages/penjualan/PenjualanListPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Penjualan' }
        },
        {
          path: 'penjualan/draft',
          name: 'PenjualanDraft',
          component: () => import('@/pages/penjualan/PenjualanDraftPage.vue'),
          meta: { requiresAuth: true, parentRoute: 'Penjualan' }
        },
        {
          path: 'penagihan',
          name: 'Penagihan',
          component: () => import('@/pages/penagihan/PenagihanPage.vue')
        },
        {
          path: 'laporan',
          name: 'Laporan',
          component: () => import('@/pages/laporan/LaporanPage.vue')
        },
        {
          path: 'master-data',
          name: 'MasterData',
          component: () => import('@/pages/master-data/MasterDataPage.vue')
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
      // Check parentRoute first for nested routes (e.g., /penjualan/input uses Penjualan permission)
      const routeToCheck = to.meta.parentRoute || to.name
      if (!allowed.includes(routeToCheck)) {
        return { name: 'Forbidden' }
      }
    }
    // Tandai read-only untuk staff_kantor
    to.meta.readOnly = (role === 'staff_kantor')
  }
})

export { ROLE_ROUTES }
export default router
