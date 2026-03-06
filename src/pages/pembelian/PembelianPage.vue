<template>
  <div class="page-placeholder">
    <div class="placeholder-icon">
      <i class="pi pi-shopping-cart"></i>
    </div>
    <h2 class="placeholder-title">Pembelian</h2>
    <p class="placeholder-desc">Input PO dan validasi barang masuk dari supplier.</p>
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
