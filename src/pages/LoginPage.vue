<template>
  <div class="login-wrapper">

    <!-- KIRI: Branding Panel -->
    <div class="login-left">
      <div class="brand-overlay">
        <div class="brand-content">
          <div class="brand-logo">
            <span class="logo-icon">⚙</span>
            <span class="logo-text">MMB</span>
          </div>
          <h1 class="brand-title">Maju Mulia<br />Bersama</h1>
          <p class="brand-tagline">Sistem Inventori & POS<br />Sparepart AC Mobil</p>
          <div class="brand-divider"></div>
          <div class="brand-features">
            <div class="feature-item">
              <i class="pi pi-check-circle"></i>
              <span>Manajemen Stok Real-time</span>
            </div>
            <div class="feature-item">
              <i class="pi pi-check-circle"></i>
              <span>Pencatatan Piutang Otomatis</span>
            </div>
            <div class="feature-item">
              <i class="pi pi-check-circle"></i>
              <span>Laporan Keuangan Lengkap</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- KANAN: Form Login -->
    <div class="login-right">
      <div class="login-form-container">

        <!-- Header -->
        <div class="form-header">
          <h2 class="form-welcome">Selamat Datang</h2>
          <p class="form-subtitle">Masuk ke Sistem MMB</p>
        </div>

        <!-- Form -->
        <form @submit.prevent="handleLogin" class="login-form">

          <!-- Email -->
          <div class="field-group">
            <label class="field-label">Email</label>
            <div class="input-wrapper" :class="{ 'input-error': errors.email }">
              <i class="pi pi-envelope input-icon"></i>
              <input
                v-model="form.email"
                type="email"
                placeholder="email@perusahaan.com"
                class="field-input"
                autocomplete="email"
                @focus="errors.email = ''"
              />
            </div>
            <span v-if="errors.email" class="error-msg">{{ errors.email }}</span>
          </div>

          <!-- Password -->
          <div class="field-group">
            <label class="field-label">Password</label>
            <div class="input-wrapper" :class="{ 'input-error': errors.password }">
              <i class="pi pi-lock input-icon"></i>
              <input
                v-model="form.password"
                :type="showPassword ? 'text' : 'password'"
                placeholder="••••••••"
                class="field-input"
                autocomplete="current-password"
                @focus="errors.password = ''"
              />
              <button
                type="button"
                class="toggle-password"
                @click="showPassword = !showPassword"
                tabindex="-1"
              >
                <i :class="showPassword ? 'pi pi-eye-slash' : 'pi pi-eye'"></i>
              </button>
            </div>
            <span v-if="errors.password" class="error-msg">{{ errors.password }}</span>
          </div>

          <!-- Error Global -->
          <div v-if="errorMessage" class="global-error">
            <i class="pi pi-exclamation-triangle"></i>
            {{ errorMessage }}
          </div>

          <!-- Submit -->
          <button
            type="submit"
            class="btn-login"
            :disabled="authStore.loading"
          >
            <i v-if="authStore.loading" class="pi pi-spin pi-spinner"></i>
            <span v-else>MASUK</span>
          </button>

        </form>

        <p class="login-footer">
          MMB &copy; {{ new Date().getFullYear() }} — Sistem Internal
        </p>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const showPassword = ref(false)
const errorMessage = ref('')

const form = reactive({
  email: '',
  password: ''
})

const errors = reactive({
  email: '',
  password: ''
})

function validate() {
  let valid = true
  errors.email = ''
  errors.password = ''

  if (!form.email) {
    errors.email = 'Email wajib diisi.'
    valid = false
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    errors.email = 'Format email tidak valid.'
    valid = false
  }

  if (!form.password) {
    errors.password = 'Password wajib diisi.'
    valid = false
  } else if (form.password.length < 6) {
    errors.password = 'Password minimal 6 karakter.'
    valid = false
  }

  return valid
}

async function handleLogin() {
  errorMessage.value = ''
  if (!validate()) return

  try {
    await authStore.login(form.email, form.password)
    router.push('/dashboard')
  } catch (err) {
    errorMessage.value = 'Email atau password salah. Silakan coba lagi.'
  }
}
</script>

<style scoped>
@import '@/assets/pages/login/login-page.css';
</style>1
