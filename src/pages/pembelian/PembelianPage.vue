<template>
  <div class="pembelian-menu-page" ref="pageEl" tabindex="-1">

    <!-- ── PAGE HEADER ──────────────────────────────────── -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Manajemen Pembelian</h1>
        <p class="g-subtitle">Kelola order pembelian & proses barang masuk</p>
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

  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const pageEl = ref(null)
const selectedIndex = ref(0)

const menuOptions = [
  {
    id: 'order-pembelian',
    title: 'Order Pembelian',
    description: 'Buat dan kelola order pembelian baru ke supplier',
    icon: 'pi pi-file-plus',
    route: '/pembelian/order'
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
    route: '/pembelian/history'
  }
]

function selectOption(index) {
  selectedIndex.value = index
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

onMounted(() => {
  pageEl.value?.focus()
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<style scoped>
@import '@/assets/pages/pembelian/pembelian-menu-page.css';
</style>
