<template>
  <div class="gudang-menu-page" ref="pageEl" tabindex="-1">
    
    <!-- ── PAGE HEADER ──────────────────────────────────── -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Operasional Gudang</h1>
        <p class="g-subtitle">Pengelolaan inventori, harga, dan data produk</p>
      </div>
    </div>

    <!-- ── MENU OPTIONS ──────────────────────────────────── -->
    <div class="menu-container">
      <div 
        v-for="(option, index) in menuOptions" 
        :key="option.id"
        class="menu-card"
        :class="{ 'menu-card--active': selectedIndex === index }"
        @click="onCardClick(option, index)"
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
          <i class="pi pi-box"></i>
        </div>
        <div class="stat-content">
          <span class="stat-label">Total SKU</span>
          <span class="stat-value">{{ stats.totalProducts }} item</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--green">
          <i class="pi pi-check-circle"></i>
        </div>
        <div class="stat-content">
          <span class="stat-label">Stok Normal</span>
          <span class="stat-value">{{ stats.safeStock }} item</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--orange">
          <i class="pi pi-exclamation-triangle"></i>
        </div>
        <div class="stat-content">
          <span class="stat-label">Perlu Restock</span>
          <span class="stat-value">{{ stats.lowStock }} item</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--purple">
          <i class="pi pi-users"></i>
        </div>
        <div class="stat-content">
          <span class="stat-label">Mitra Supplier</span>
          <span class="stat-value">{{ stats.suppliers }} supplier</span>
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
    id: 'cek-harga',
    title: 'Informasi Harga',
    description: 'Cek harga jual & histori transaksi per pelanggan',
    icon: 'pi pi-search',
    route: '/gudang/cek-harga'
  },
  {
    id: 'katalog',
    title: 'Kelola Produk',
    description: 'Tambah, ubah, dan atur master data produk gudang',
    icon: 'pi pi-book',
    route: '/gudang/katalog'
  },
  {
    id: 'archive',
    title: 'Arsip Produk',
    description: 'Kelola produk yang dinonaktifkan & pemulihan data',
    icon: 'pi pi-inbox',
    route: '/gudang/archive'
  },
  {
    id: 'cek-semua',
    title: 'Daftar Inventori',
    description: 'Pantau seluruh stok & data produk secara real-time',
    icon: 'pi pi-database',
    route: '/gudang/cek-semua'
  }
]

const stats = ref({
  totalProducts: 0,
  safeStock: 0,
  lowStock: 0,
  suppliers: 0
})

// ───────────────────────────────────────────────────────────
// LOAD STATS
// ───────────────────────────────────────────────────────────
async function loadStats() {
  try {
    // Total products (exclude archived)
    const { count: totalCount } = await supabase
      .from('products')
      .select('*', { count: 'exact', head: true })
      .eq('is_archived', false)
    
    stats.value.totalProducts = totalCount || 0
    
    // Count products with stock > 3 and <= 3
    const { data: products } = await supabase
      .from('product_prices')
      .select('product_id, stok')
    
    if (products) {
      // Group by product_id and sum stock
      const stockByProduct = {}
      products.forEach(p => {
        if (!stockByProduct[p.product_id]) {
          stockByProduct[p.product_id] = 0
        }
        stockByProduct[p.product_id] += p.stok
      })
      
      let safeCount = 0
      let lowCount = 0
      
      Object.values(stockByProduct).forEach(totalStock => {
        if (totalStock > 3) {
          safeCount++
        } else {
          lowCount++
        }
      })
      
      stats.value.safeStock = safeCount
      stats.value.lowStock = lowCount
    }
    
    // Total suppliers
    const { count: supplierCount } = await supabase
      .from('suppliers')
      .select('*', { count: 'exact', head: true })
    
    stats.value.suppliers = supplierCount || 0
    
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

function onCardClick(option, index) {
  selectedIndex.value = index
  navigateToOption(option)
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
@import '@/assets/pages/gudang/gudang-menu-page.css';
</style>
