<template>
  <div class="forbidden-wrap">
    <div class="forbidden-card">
      <div class="forbidden-icon">
        <i class="pi pi-lock"></i>
      </div>
      <h1 class="forbidden-code">403</h1>
      <h2 class="forbidden-title">Akses Ditolak</h2>
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
.forbidden-wrap {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f8fafc;
  padding: 2rem;
}
.forbidden-card {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 20px;
  padding: 3rem 2.5rem;
  text-align: center;
  max-width: 420px;
  width: 100%;
  box-shadow: 0 4px 24px rgba(0,0,0,.07);
}
.forbidden-icon {
  width: 72px; height: 72px;
  border-radius: 50%;
  background: #fef2f2;
  display: flex; align-items: center; justify-content: center;
  margin: 0 auto 1rem;
  font-size: 1.8rem;
  color: #ef4444;
}
.forbidden-code {
  font-size: 3.5rem;
  font-weight: 900;
  color: #0f172a;
  margin: 0 0 .25rem;
  line-height: 1;
}
.forbidden-title {
  font-size: 1.15rem;
  font-weight: 700;
  color: #0f172a;
  margin: 0 0 .75rem;
}
.forbidden-desc {
  font-size: .88rem;
  color: #64748b;
  line-height: 1.65;
  margin: 0 0 1.75rem;
}
.forbidden-btn {
  display: inline-flex;
  align-items: center;
  gap: .5rem;
  padding: .7rem 1.5rem;
  background: linear-gradient(90deg, #1d4ed8, #3b82f6);
  color: #fff;
  border: none;
  border-radius: 10px;
  font-size: .9rem;
  font-weight: 600;
  cursor: pointer;
  font-family: 'Inter', sans-serif;
  transition: opacity .15s;
}
.forbidden-btn:hover { opacity: .88; }
</style>
