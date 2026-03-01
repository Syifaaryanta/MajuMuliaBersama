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
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          class="nav-item"
          active-class="nav-item--active"
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
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ROLE_ROUTES } from '@/router'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const isSidebarCollapsed  = ref(false)
const isMobileDrawerOpen  = ref(false)

const MOBILE_BP = 768

// Tutup drawer otomatis saat resize ke desktop
function onResize() {
  if (window.innerWidth > MOBILE_BP) {
    isMobileDrawerOpen.value = false
  }
}
onMounted(()  => window.addEventListener('resize', onResize))
onUnmounted(() => window.removeEventListener('resize', onResize))

// Tutup drawer saat nav diklik di mobile
function handleNavClick() {
  if (window.innerWidth <= MOBILE_BP) {
    isMobileDrawerOpen.value = false
  }
}

const ALL_NAV = [
  { to: '/dashboard',  icon: 'pi pi-th-large',       label: 'Dashboard',  name: 'Dashboard'  },
  { to: '/gudang',     icon: 'pi pi-warehouse',       label: 'Gudang',     name: 'Gudang'     },
  { to: '/pembelian',  icon: 'pi pi-shopping-cart',   label: 'Pembelian',  name: 'Pembelian'  },
  { to: '/penjualan',  icon: 'pi pi-receipt',         label: 'Penjualan',  name: 'Penjualan'  },
  { to: '/penagihan',  icon: 'pi pi-wallet',          label: 'Penagihan',  name: 'Penagihan'  },
  { to: '/laporan',    icon: 'pi pi-chart-bar',       label: 'Laporan',    name: 'Laporan'    },
]

const navItems = computed(() => {
  const role   = authStore.userRole
  const allowed = role ? (ROLE_ROUTES[role] ?? []) : []
  
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
  return ALL_NAV.find(n => route.path.startsWith(n.to))?.label ?? '—'
})

const currentDate = computed(() => {
  return new Date().toLocaleDateString('id-ID', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  })
})

async function handleLogout() {
  await authStore.logout()
  router.push('/login')
}
</script>

<style scoped>
@import '@/assets/layout.css';
</style>
