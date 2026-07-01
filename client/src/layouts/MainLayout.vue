<template>
  <div class="app-shell">

    <!-- BACKDROP (mobile only) -->
    <transition name="backdrop-fade">
      <div
        v-if="isMobileDrawerOpen"
        class="mobile-backdrop"
        @click="isMobileDrawerOpen = false"
      />
    </transition>

    <!-- SIDEBAR -->
    <aside
      class="sidebar"
      :class="{
        collapsed: isSidebarCollapsed,
        'mobile-open': isMobileDrawerOpen
      }"
    >
      <!-- Logo area -->
      <div class="sidebar-logo">
        <div class="logo-mark">⚙</div>
        <transition name="fade">
          <div v-if="!isSidebarCollapsed" class="logo-label">
            <span class="logo-name">MMB</span>
            <span class="logo-sub">Sparepart AC Mobil</span>
          </div>
        </transition>
      </div>

      <!-- Navigation -->
      <nav class="sidebar-nav">
        <RouterLink
          v-for="(item, index) in navItems"
          :key="item.to"
          :to="item.to"
          class="nav-item"
          :class="{
            'nav-item--active': isNavItemActive(item),
            'nav-item--keyboard-selected': index === selectedNavIndex
          }"
          @click="handleNavClick"
        >
          <i :class="['nav-icon', item.icon]"></i>
          <transition name="fade">
            <span v-if="!isSidebarCollapsed" class="nav-label">{{ item.label }}</span>
          </transition>
          <span v-if="!isSidebarCollapsed && item.badge" class="nav-badge">{{ item.badge }}</span>
        </RouterLink>
      </nav>

      <!-- Bottom: user info + logout -->
      <div class="sidebar-bottom">
        <div class="user-info" v-if="!isSidebarCollapsed">
          <div class="user-avatar">{{ avatarInitial }}</div>
          <div class="user-detail">
            <span class="user-name">{{ authStore.displayName }}</span>
            <span class="user-role">{{ roleLabel }}</span>
          </div>
        </div>
        <div class="user-avatar-sm" v-else>{{ avatarInitial }}</div>
        <button class="btn-logout" @click="handleLogout" :title="'Keluar'">
          <i class="pi pi-sign-out"></i>
          <transition name="fade">
            <span v-if="!isSidebarCollapsed">Keluar</span>
          </transition>
        </button>
      </div>
    </aside>

    <!-- MAIN CONTENT -->
    <div class="main-wrapper">

      <!-- TOPBAR -->
      <header class="topbar">
        <div class="topbar-left">
          <!-- Desktop: collapse toggle -->
          <button
            class="collapse-btn desktop-only"
            @click="isSidebarCollapsed = !isSidebarCollapsed"
            :title="isSidebarCollapsed ? 'Perluas sidebar' : 'Ciutkan sidebar'"
          >
            <i class="pi pi-bars"></i>
          </button>
          <!-- Mobile: drawer toggle -->
          <button
            class="collapse-btn mobile-only"
            @click="isMobileDrawerOpen = !isMobileDrawerOpen"
          >
            <i :class="isMobileDrawerOpen ? 'pi pi-times' : 'pi pi-bars'"></i>
          </button>

          <div class="topbar-brand mobile-only">
            <span class="topbar-brand-icon">⚙</span>
            <span class="topbar-brand-name">MMB</span>
          </div>

          <div class="page-breadcrumb desktop-only">
            <span class="breadcrumb-app">MMB</span>
            <i class="pi pi-chevron-right breadcrumb-sep"></i>
            <span class="breadcrumb-current">{{ currentPageLabel }}</span>
          </div>

          <div class="page-title mobile-only">{{ currentPageLabel }}</div>
        </div>

        <div class="topbar-right">
          <div class="topbar-date desktop-only">{{ currentDate }}</div>
          <div class="topbar-divider desktop-only"></div>
          <div class="topbar-user">
            <div class="topbar-avatar">{{ avatarInitial }}</div>
            <div class="topbar-user-info desktop-only">
              <span class="topbar-name">{{ authStore.displayName }}</span>
              <span class="topbar-role">{{ roleLabel }}</span>
            </div>
          </div>
        </div>
      </header>

      <!-- PAGE CONTENT -->
      <main class="page-content">
        <RouterView :key="route.fullPath" />
      </main>

    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ROLE_ROUTES } from '@/router'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const isSidebarCollapsed  = ref(false)
const isMobileDrawerOpen  = ref(false)
const selectedNavIndex = ref(0)

const MOBILE_BP = 768

// Tutup drawer otomatis saat resize ke desktop
function onResize() {
  if (window.innerWidth > MOBILE_BP) {
    isMobileDrawerOpen.value = false
  }
}

// Keyboard navigation for sidebar
function handleGlobalKeydown(e) {
  if (e.defaultPrevented) return
  // Only handle arrow keys when not in an input/textarea
  if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return

  if (e.key === 'Escape') {
    if (window.innerWidth <= MOBILE_BP) {
      isMobileDrawerOpen.value = true
    } else {
      isSidebarCollapsed.value = false
    }
    return
  }

  if (e.ctrlKey && e.shiftKey && String(e.key).toLowerCase() === 'p') {
    e.preventDefault()
    isMobileDrawerOpen.value = false
    router.push('/profile')
    return
  }
  
  // Let child pages that have their own arrow key handlers take priority
  // Only handle arrows on dashboard (no sub-page active)
  const isOnDashboard = route.path === '/dashboard'
  
  const items = navItems.value
  if (items.length === 0) return
  
  if (e.key === 'ArrowDown' && isOnDashboard) {
    e.preventDefault()
    selectedNavIndex.value = (selectedNavIndex.value + 1) % items.length
  } else if (e.key === 'ArrowUp' && isOnDashboard) {
    e.preventDefault()
    selectedNavIndex.value = (selectedNavIndex.value - 1 + items.length) % items.length
  } else if (e.key === 'Enter' && isOnDashboard && items[selectedNavIndex.value]) {
    e.preventDefault()
    if (window.innerWidth <= MOBILE_BP) {
      isMobileDrawerOpen.value = false
    } else {
      isSidebarCollapsed.value = true
    }
    router.push(items[selectedNavIndex.value].to)
  }
}

onMounted(() => {
  window.addEventListener('resize', onResize)
  window.addEventListener('keydown', handleGlobalKeydown)
})

onUnmounted(() => {
  window.removeEventListener('resize', onResize)
  window.removeEventListener('keydown', handleGlobalKeydown)
})

// Tutup drawer saat nav diklik di mobile
function handleNavClick() {
  if (window.innerWidth <= MOBILE_BP) {
    isMobileDrawerOpen.value = false
  } else {
    isSidebarCollapsed.value = true
  }
}

function isNavItemActive(item, path = route.path) {
  if (item.to === '/pembelian/history') {
    return path === '/pembelian/history'
  }

  if (item.to === '/pembelian') {
    return path.startsWith('/pembelian') && path !== '/pembelian/history'
  }

  return path.startsWith(item.to)
}

const ALL_NAV = [
  { to: '/dashboard',    icon: 'pi pi-th-large',       label: 'Dashboard',   name: 'Dashboard'   },
  { to: '/penjualan',    icon: 'pi pi-receipt',        label: 'Penjualan',   name: 'Penjualan'   },
  { to: '/pembelian',    icon: 'pi pi-shopping-cart',  label: 'Pembelian',   name: 'Pembelian'   },
  { to: '/penagihan',    icon: 'pi pi-wallet',         label: 'Penagihan',   name: 'Penagihan'   },
  { to: '/gudang',       icon: 'pi pi-warehouse',      label: 'Gudang',      name: 'Gudang'      },
  { to: '/pembelian/history', icon: 'pi pi-history',   label: 'History',     name: 'Pembelian'   },
  { to: '/master-data',  icon: 'pi pi-database',       label: 'Data Master', name: 'MasterData'  },
  { to: '/laporan',      icon: 'pi pi-chart-bar',      label: 'Laporan',     name: 'Laporan'     },
]

const navItems = computed(() => {
  const role   = authStore.userRole
  if (!role) {
    console.warn('[MainLayout] userRole kosong, pakai fallback ALL_NAV sementara')
    return ALL_NAV
  }

  const allowed = ROLE_ROUTES[role] ?? []
  
  // Debug logging
  console.log('🔍 [MainLayout] userRole:', role)
  console.log('🔍 [MainLayout] profile:', authStore.profile)
  console.log('🔍 [MainLayout] allowed pages:', allowed)
  console.log('🔍 [MainLayout] ROLE_ROUTES:', ROLE_ROUTES)
  
  return ALL_NAV.filter(n => allowed.includes(n.name))
})

const roleMap = {
  admin:         'Admin / Bos',
  staff_gudang:  'Staff Gudang',
  staff_kantor:  'Staff Kantor',
  sales:         'Sales',
}

const roleLabel = computed(() => roleMap[authStore.userRole] ?? authStore.userRole ?? '—')

const avatarInitial = computed(() => {
  const name = authStore.displayName
  return name ? name.charAt(0).toUpperCase() : '?'
})

const currentPageLabel = computed(() => {
  if (route.path.startsWith('/profile')) return 'Profil'
  return navItems.value.find(n => isNavItemActive(n))?.label ?? '—'
})

const currentDate = computed(() => {
  return new Date().toLocaleDateString('id-ID', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  })
})

// Sync selectedNavIndex with current route
watch(() => route.path, (newPath) => {
  const items = navItems.value
  const index = items.findIndex(item => isNavItemActive(item, newPath))
  if (index !== -1) {
    selectedNavIndex.value = index
  }
}, { immediate: true })

async function handleLogout() {
  await authStore.logout()
  router.push('/login')
}
</script>

<style scoped>
@import '@/assets/layout.css';
</style>
