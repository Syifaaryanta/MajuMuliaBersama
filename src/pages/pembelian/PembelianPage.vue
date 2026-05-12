<template>
  <div class="pembelian-menu-page" ref="pageEl" tabindex="-1">
    <Toast position="top-right" />

    <!-- ── PAGE HEADER ──────────────────────────────────── -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Manajemen Pembelian</h1>
        <p class="g-subtitle">Kelola order pembelian dan proses penerimaan barang</p>
      </div>
    </div>

    <!-- ── MENU OPTIONS ──────────────────────────────────── -->
    <div :class="['menu-container', `menu-count-${menuOptions.length}`]">
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

    <div class="stats-cards">
      <div class="stat-card stat-card--blue">
        <div class="stat-icon stat-icon--blue">
          <i class="pi pi-file"></i>
        </div>
        <div class="stat-content">
          <span class="stat-label">Total Order</span>
          <span class="stat-value">{{ infoStats.totalOrder }} order</span>
        </div>
      </div>
      <div class="stat-card stat-card--orange">
        <div class="stat-icon stat-icon--orange">
          <i class="pi pi-clock"></i>
        </div>
        <div class="stat-content">
          <span class="stat-label">Menunggu Terima</span>
          <span class="stat-value">{{ infoStats.menungguTerima }} order</span>
        </div>
      </div>
      <div class="stat-card stat-card--green">
        <div class="stat-icon stat-icon--green">
          <i class="pi pi-check-circle"></i>
        </div>
        <div class="stat-content">
          <span class="stat-label">Sudah Diterima</span>
          <span class="stat-value">{{ infoStats.sudahDiterima }} order</span>
        </div>
      </div>
      <div class="stat-card stat-card--purple">
        <div class="stat-icon stat-icon--purple">
          <i class="pi pi-truck"></i>
        </div>
        <div class="stat-content">
          <span class="stat-label">Supplier Aktif</span>
          <span class="stat-value">{{ infoStats.supplierAktif }} supplier</span>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { listPurchaseOrders } from '@/lib/pembelianStore'
import { useToast } from 'primevue/usetoast'
import Toast from 'primevue/toast'

const router = useRouter()
const toast = useToast()
const pageEl = ref(null)
const selectedIndex = ref(0)
const PEMBELIAN_FLASH_KEY = 'pembelian_flash_notice'
const infoStats = ref({
  totalOrder: 0,
  menungguTerima: 0,
  sudahDiterima: 0,
  supplierAktif: 0,
})

const menuOptions = [
  {
    id: 'order-pembelian',
    title: 'Order Pembelian',
    description: 'Buat dan kelola order pembelian baru ke supplier',
    icon: 'pi pi-file-plus',
    route: '/pembelian/order'
  },
  {
    id: 'draft-pembelian',
    title: 'Order Tertunda',
    description: 'Kelola order pembelian yang belum selesai diproses',
    icon: 'pi pi-clock',
    route: '/pembelian/draft'
  },
  {
    id: 'edit-order-pembelian',
    title: 'Edit Order Pembelian',
    description: 'Perbaiki dan ubah data order pembelian yang sudah dibuat',
    icon: 'pi pi-file-edit',
    route: '/pembelian/edit-order'
  },
  {
    id: 'receiving',
    title: 'Receiving',
    description: 'Catat penerimaan barang dari supplier ke gudang',
    icon: 'pi pi-inbox',
    route: '/pembelian/receiving'
  },
  {
    id: 'history-pembelian',
    title: 'History Pembelian',
    description: 'Lihat riwayat lengkap order dan penerimaan pembelian',
    icon: 'pi pi-history',
    route: '/pembelian/history-pembelian'
  }
]

async function loadInfoStats() {
  const orders = await listPurchaseOrders()
  infoStats.value.totalOrder = orders.length
  infoStats.value.sudahDiterima = orders.filter(o => o.status === 'received').length
  infoStats.value.menungguTerima = Math.max(0, orders.length - infoStats.value.sudahDiterima)

  const { count: supplierCount, error: supplierError } = await supabase
    .from('suppliers')
    .select('id', { count: 'exact', head: true })
    .eq('aktif', true)

  if (supplierError) throw supplierError
  infoStats.value.supplierAktif = Number(supplierCount || 0)
}

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

  // F3 - Order Tertunda
  else if (e.key === 'F3') {
    e.preventDefault()
    router.push('/pembelian/draft')
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

onMounted(async () => {
  try {
    await loadInfoStats()
  } catch (err) {
    console.error('[loadInfoStats pembelian]', err)
  }
  pageEl.value?.focus()
  window.addEventListener('keydown', handleKeydown)

  const flashRaw = sessionStorage.getItem(PEMBELIAN_FLASH_KEY)
  if (flashRaw) {
    try {
      const flash = JSON.parse(flashRaw)
      if (flash?.summary) {
        toast.add({
          severity: flash.severity || 'success',
          summary: flash.summary,
          detail: flash.detail || '',
          life: Number(flash.life || 3000),
        })
      }
    } catch (err) {
      console.error('[parse PEMBELIAN_FLASH_KEY menu]', err)
    }

    sessionStorage.removeItem(PEMBELIAN_FLASH_KEY)
  }
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<style scoped>
@import '@/assets/Styles/pembelian/pembelian-menu-page.css';
</style>
