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
/* ============================================================
   SHELL
   ============================================================ */
.app-shell {
  display: flex;
  height: 100vh;
  overflow: hidden;
  background: #f1f5f9;
}

/* ============================================================
   SIDEBAR
   ============================================================ */
.sidebar {
  width: 240px;
  min-width: 240px;
  background: #0f172a;
  display: flex;
  flex-direction: column;
  transition: width 0.25s ease, min-width 0.25s ease;
  overflow: hidden;
  z-index: 100;
}

.sidebar.collapsed {
  width: 68px;
  min-width: 68px;
}

/* Logo */
.sidebar-logo {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1.25rem 1rem;
  border-bottom: 1px solid rgba(255,255,255,0.07);
  white-space: nowrap;
  overflow: hidden;
}

.logo-mark {
  font-size: 1.6rem;
  flex-shrink: 0;
  filter: drop-shadow(0 0 8px rgba(59,130,246,0.7));
  width: 36px;
  text-align: center;
}

.logo-label {
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.logo-name {
  font-size: 1.1rem;
  font-weight: 800;
  color: #60a5fa;
  letter-spacing: 3px;
}

.logo-sub {
  font-size: 0.65rem;
  color: #475569;
  letter-spacing: 0.5px;
  white-space: nowrap;
}

/* Nav items */
.sidebar-nav {
  flex: 1;
  padding: 0.75rem 0;
  overflow-y: auto;
  overflow-x: hidden;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 0.85rem;
  padding: 0.75rem 1rem;
  color: #94a3b8;
  text-decoration: none;
  font-size: 0.875rem;
  font-weight: 500;
  border-radius: 0;
  transition: background 0.15s, color 0.15s;
  white-space: nowrap;
  overflow: hidden;
  position: relative;
  margin: 1px 8px;
  border-radius: 8px;
}

.nav-item:hover {
  background: rgba(59, 130, 246, 0.1);
  color: #e2e8f0;
}

.nav-item--active {
  background: rgba(59, 130, 246, 0.18);
  color: #60a5fa;
  font-weight: 600;
}

.nav-item--active::before {
  content: '';
  position: absolute;
  left: 0;
  top: 20%;
  height: 60%;
  width: 3px;
  background: #3b82f6;
  border-radius: 0 2px 2px 0;
}

.nav-icon {
  font-size: 1rem;
  width: 20px;
  text-align: center;
  flex-shrink: 0;
}

.nav-label {
  flex: 1;
}

.nav-badge {
  background: #ef4444;
  color: white;
  font-size: 0.65rem;
  font-weight: 700;
  padding: 1px 6px;
  border-radius: 10px;
}

/* Bottom area */
.sidebar-bottom {
  border-top: 1px solid rgba(255,255,255,0.07);
  padding: 0.85rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  overflow: hidden;
  padding: 0.4rem 0.25rem;
}

.user-avatar {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background: linear-gradient(135deg, #1d4ed8, #3b82f6);
  color: white;
  font-size: 0.85rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.user-avatar-sm {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background: linear-gradient(135deg, #1d4ed8, #3b82f6);
  color: white;
  font-size: 0.85rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto;
}

.user-detail {
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.user-name {
  font-size: 0.8rem;
  font-weight: 600;
  color: #e2e8f0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.user-role {
  font-size: 0.68rem;
  color: #475569;
  white-space: nowrap;
}

.btn-logout {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  width: 100%;
  padding: 0.55rem;
  background: rgba(239, 68, 68, 0.1);
  color: #f87171;
  border: 1px solid rgba(239, 68, 68, 0.2);
  border-radius: 7px;
  cursor: pointer;
  font-size: 0.8rem;
  font-weight: 500;
  transition: background 0.15s;
  font-family: 'Inter', sans-serif;
  white-space: nowrap;
  overflow: hidden;
}

.btn-logout:hover {
  background: rgba(239, 68, 68, 0.2);
}

/* ============================================================
   MAIN WRAPPER
   ============================================================ */
.main-wrapper {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* TOPBAR */
.topbar {
  height: 60px;
  background: #ffffff;
  border-bottom: 1px solid #e2e8f0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 1.5rem;
  flex-shrink: 0;
  box-shadow: 0 1px 4px rgba(0,0,0,0.05);
}

.topbar-left {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.collapse-btn {
  background: none;
  border: none;
  cursor: pointer;
  color: #64748b;
  font-size: 1rem;
  padding: 0.4rem;
  border-radius: 6px;
  transition: background 0.15s, color 0.15s;
}
.collapse-btn:hover {
  background: #f1f5f9;
  color: #1e293b;
}

.page-breadcrumb {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  font-size: 0.85rem;
}

.breadcrumb-app {
  color: #94a3b8;
  font-weight: 500;
}

.breadcrumb-sep {
  font-size: 0.65rem;
  color: #cbd5e1;
}

.breadcrumb-current {
  color: #1e293b;
  font-weight: 600;
}

.topbar-right {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.topbar-date {
  font-size: 0.78rem;
  color: #94a3b8;
}

.topbar-divider {
  width: 1px;
  height: 20px;
  background: #e2e8f0;
}

.topbar-user {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.topbar-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: linear-gradient(135deg, #1d4ed8, #3b82f6);
  color: white;
  font-size: 0.8rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
}

.topbar-user-info {
  display: flex;
  flex-direction: column;
}

.topbar-name {
  font-size: 0.82rem;
  font-weight: 600;
  color: #1e293b;
  line-height: 1.2;
}

.topbar-role {
  font-size: 0.7rem;
  color: #94a3b8;
  line-height: 1.2;
}

/* PAGE CONTENT */
.page-content {
  flex: 1;
  overflow-y: auto;
  padding: 1.75rem;
}

/* ============================================================
   UTILITY: SHOW/HIDE PER DEVICE
   ============================================================ */
.mobile-only  { display: none; }
.desktop-only { display: flex; }

/* ============================================================
   MOBILE BACKDROP
   ============================================================ */
.mobile-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.55);
  z-index: 99;
  backdrop-filter: blur(1px);
}

/* ============================================================
   TOPBAR — tambahan elemen mobile
   ============================================================ */
.topbar-brand {
  align-items: center;
  gap: 0.5rem;
  text-decoration: none;
}

.topbar-brand-icon {
  font-size: 1.2rem;
  filter: drop-shadow(0 0 6px rgba(59,130,246,0.7));
}

.topbar-brand-name {
  font-size: 1rem;
  font-weight: 800;
  color: #3b82f6;
  letter-spacing: 3px;
}

.page-title {
  font-size: 0.95rem;
  font-weight: 700;
  color: #1e293b;
}

/* ============================================================
   TRANSITIONS
   ============================================================ */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.backdrop-fade-enter-active,
.backdrop-fade-leave-active {
  transition: opacity 0.25s ease;
}
.backdrop-fade-enter-from,
.backdrop-fade-leave-to {
  opacity: 0;
}

/* ============================================================
   RESPONSIVE — Mobile (≤ 768px)
   ============================================================ */
@media (max-width: 768px) {
  /* Utility swap */
  .mobile-only  { display: flex; }
  .desktop-only { display: none !important; }

  /* Sidebar: jadi fixed drawer, tersembunyi di kiri layar */
  .sidebar {
    position: fixed;
    top: 0;
    left: 0;
    height: 100%;
    width: 260px !important;
    min-width: 260px !important;
    transform: translateX(-100%);
    transition: transform 0.28s cubic-bezier(0.4, 0, 0.2, 1);
    z-index: 200;
    box-shadow: 4px 0 24px rgba(0,0,0,0.3);
  }

  /* Drawer terbuka */
  .sidebar.mobile-open {
    transform: translateX(0);
  }

  /* Nav label selalu tampil di dalam drawer mobile */
  .sidebar .nav-label  { display: flex !important; opacity: 1 !important; }
  .sidebar .logo-label { display: flex !important; opacity: 1 !important; }
  .sidebar .user-info  { display: flex !important; }
  .sidebar .user-avatar-sm { display: none !important; }
  .sidebar .btn-logout span { display: inline !important; opacity: 1 !important; }

  /* Main wrapper full width karena sidebar sudah absolute */
  .main-wrapper {
    width: 100%;
  }

  /* Topbar lebih compact */
  .topbar {
    padding: 0 1rem;
  }

  .topbar-left {
    gap: 0.6rem;
  }

  /* Page content padding lebih kecil di mobile */
  .page-content {
    padding: 1rem;
  }
}

/* ============================================================
   RESPONSIVE — Small Mobile (≤ 400px)
   ============================================================ */
@media (max-width: 400px) {
  .topbar-brand-name {
    display: none;
  }

  .page-content {
    padding: 0.75rem;
  }
}
</style>
