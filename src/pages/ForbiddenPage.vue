<template>
  <div class="forbidden-wrap">
    <div class="forbidden-card">
      <div class="forbidden-icon">
        <i class="pi pi-lock"></i>
      </div>
      <h1 class="forbidden-code">403</h1>
      <h2 class="forbidden-title">Akses Tidak Diizinkan</h2>
      <p class="forbidden-desc">
        Anda tidak memiliki izin untuk mengakses halaman ini.<br>
        Silakan hubungi administrator jika ini merupakan kesalahan.
      </p>
      <button class="forbidden-btn" @click="goBack">
        <i class="pi pi-arrow-left"></i>
        Kembali
      </button>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
const router = useRouter()
function goBack() { router.go(-1) }
</script>

<style scoped>
@import '@/assets/pages/forbidden/forbidden-page.css';
</style>
