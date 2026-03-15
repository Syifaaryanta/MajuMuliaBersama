<template>
  <div class="penjualan-menu-page" ref="pageEl" tabindex="-1">
    
    <!-- ── PAGE HEADER ──────────────────────────────────── -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Operasional Penjualan</h1>
        <p class="g-subtitle">Pengelolaan transaksi, draft, dan riwayat penjualan</p>
      </div>
    </div>

    <!-- ── MENU OPTIONS ──────────────────────────────────── -->
    <div class="menu-container">
      <div 
        v-for="(option, index) in menuOptions" 
        :key="option.id"
        class="menu-card"
        :class="{ 'menu-card--active': selectedIndex === index }"
        @click="selectOption(index)"
        @dblclick="navigateToOption(option)"
      >
        <div class="menu-card-icon">
          <i :class="option.icon"></i>
        </div>
        <div class="menu-card-content">
          <h3 class="menu-card-title">{{ option.title }}</h3>
          <p class="menu-card-desc">{{ option.description }}</p>
        </div>
      </div>
    </div>

    <!-- ── QUICK STATS ──────────────────────────────────── -->
    <div class="stats-cards">
      <div class="stat-card">
        <div class="stat-icon stat-icon--blue">
          <i class="pi pi-calendar"></i>
        </div>
        <div class="stat-content">
          <span class="stat-label">Transaksi Hari Ini</span>
          <span class="stat-value">{{ stats.today }} order</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--green">
          <i class="pi pi-calendar-plus"></i>
        </div>
        <div class="stat-content">
          <span class="stat-label">Minggu Berjalan</span>
          <span class="stat-value">{{ stats.week }} order</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--purple">
          <i class="pi pi-chart-bar"></i>
        </div>
        <div class="stat-content">
          <span class="stat-label">Bulan Berjalan</span>
          <span class="stat-value">{{ stats.month }} order</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--orange">
          <i class="pi pi-database"></i>
        </div>
        <div class="stat-content">
          <span class="stat-label">Total Transaksi</span>
          <span class="stat-value">{{ stats.total }} order</span>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const pageEl = ref(null)
const selectedIndex = ref(0)

const menuOptions = [
  {
    id: 'buat',
    title: 'Input Penjualan',
    description: 'Buat & catat transaksi penjualan baru',
    icon: 'pi pi-plus-circle',
    route: '/penjualan/buat'
  },
  {
    id: 'edit',
    title: 'Revisi Transaksi',
    description: 'Ubah & koreksi data transaksi yang sudah tercatat',
    icon: 'pi pi-pencil',
    route: '/penjualan/edit'
  },
  {
    id: 'draft',
    title: 'Order Tertunda',
    description: 'Kelola transaksi yang belum diselesaikan',
    icon: 'pi pi-file-edit',
    route: '/penjualan/draft'
  },
  {
    id: 'daftar',
    title: 'Riwayat Transaksi',
    description: 'Pantau seluruh rekap transaksi penjualan',
    icon: 'pi pi-list',
    route: '/penjualan/list'
  }
]

const stats = ref({
  today: 0,
  week: 0,
  month: 0,
  total: 0
})

// ───────────────────────────────────────────────────────────
// LOAD STATS
// ───────────────────────────────────────────────────────────
async function loadStats() {
  try {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    
    const startOfWeek = new Date(today)
    startOfWeek.setDate(today.getDate() - today.getDay())
    
    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1)
    
    // Total orders
    const { count: totalCount } = await supabase
      .from('sales')
      .select('*', { count: 'exact', head: true })
    
    stats.value.total = totalCount || 0
    
    // Today's orders
    const { count: todayCount } = await supabase
      .from('sales')
      .select('*', { count: 'exact', head: true })
      .gte('order_date', today.toISOString().split('T')[0])
    
    stats.value.today = todayCount || 0
    
    // This week's orders
    const { count: weekCount } = await supabase
      .from('sales')
      .select('*', { count: 'exact', head: true })
      .gte('order_date', startOfWeek.toISOString().split('T')[0])
    
    stats.value.week = weekCount || 0
    
    // This month's orders
    const { count: monthCount } = await supabase
      .from('sales')
      .select('*', { count: 'exact', head: true })
      .gte('order_date', startOfMonth.toISOString().split('T')[0])
    
    stats.value.month = monthCount || 0
    
  } catch (error) {
    console.error('Error loading stats:', error)
  }
}

// ───────────────────────────────────────────────────────────
// SELECTION & NAVIGATION
// ───────────────────────────────────────────────────────────
function selectOption(index) {
  selectedIndex.value = index
}

function navigateToOption(option) {
  router.push(option.route)
}

// ───────────────────────────────────────────────────────────
// KEYBOARD NAVIGATION
// ───────────────────────────────────────────────────────────
function handleKeydown(e) {
  // Arrow Left
  if (e.key === 'ArrowLeft') {
    e.preventDefault()
    selectedIndex.value = selectedIndex.value > 0 
      ? selectedIndex.value - 1 
      : menuOptions.length - 1
  }
  
  // Arrow Right
  else if (e.key === 'ArrowRight') {
    e.preventDefault()
    selectedIndex.value = selectedIndex.value < menuOptions.length - 1 
      ? selectedIndex.value + 1 
      : 0
  }
  
  // Enter - Navigate to selected option
  else if (e.key === 'Enter') {
    e.preventDefault()
    navigateToOption(menuOptions[selectedIndex.value])
  }
  
  // F1 - Tambah Penjualan
  else if (e.key === 'F1') {
    e.preventDefault()
    router.push('/penjualan/buat')
  }
  
  // F2 - Edit Penjualan
  else if (e.key === 'F2') {
    e.preventDefault()
    router.push('/penjualan/edit')
  }
  
  // F3 - Draft Order
  else if (e.key === 'F3') {
    e.preventDefault()
    router.push('/penjualan/draft')
  }
  
  // F4 - Daftar Penjualan
  else if (e.key === 'F4') {
    e.preventDefault()
    router.push('/penjualan/list')
  }
  
  // Number keys 1-N (match card order left to right)
  else if (e.key >= '1' && e.key <= '9') {
    e.preventDefault()
    const index = parseInt(e.key) - 1
    if (index < menuOptions.length) {
      selectedIndex.value = index
      navigateToOption(menuOptions[index])
    }
  }
  
  // Escape - Back to dashboard
  else if (e.key === 'Escape') {
    e.preventDefault()
    router.push('/dashboard')
  }
}

// ───────────────────────────────────────────────────────────
// LIFECYCLE
// ───────────────────────────────────────────────────────────
onMounted(() => {
  pageEl.value?.focus()
  window.addEventListener('keydown', handleKeydown)
  loadStats()
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<style scoped>
@import '@/assets/pages/penjualan/penjualan-menu-page.css';
</style>
