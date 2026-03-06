<template>
  <div class="page-placeholder">
    <div class="placeholder-icon">
      <i class="pi pi-chart-bar"></i>
    </div>
    <h2 class="placeholder-title">Laporan</h2>
    <p class="placeholder-desc">Laporan penjualan, pembelian, stok, dan piutang. Export ke Excel.</p>
    <div class="placeholder-badge">Coming Soon</div>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

function handleKeydown(e) {
  if (e.key === 'Escape') {
    e.preventDefault()
    router.push('/dashboard')
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>
