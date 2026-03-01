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
/* ============================================================
   WRAPPER
   ============================================================ */
.login-wrapper {
  display: flex;
  min-height: 100vh;
  min-height: 100dvh;
  background: #f1f5f9;
}

/* ============================================================
   KIRI — BRANDING (60%)
   ============================================================ */
.login-left {
  flex: 0 0 60%;
  background: linear-gradient(135deg, #0f172a 0%, #1e3a5f 45%, #1a5276 100%);
  position: relative;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Decorative circles */
.login-left::before {
  content: '';
  position: absolute;
  width: 500px;
  height: 500px;
  border-radius: 50%;
  background: rgba(59, 130, 246, 0.08);
  top: -150px;
  right: -150px;
}
.login-left::after {
  content: '';
  position: absolute;
  width: 350px;
  height: 350px;
  border-radius: 50%;
  background: rgba(59, 130, 246, 0.06);
  bottom: -80px;
  left: -80px;
}

.brand-overlay {
  position: relative;
  z-index: 1;
  padding: 3rem;
  width: 100%;
  max-width: 480px;
}

.brand-content {
  color: white;
}

.brand-logo {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 2.5rem;
}

.logo-icon {
  font-size: 2.5rem;
  filter: drop-shadow(0 0 12px rgba(59,130,246,0.8));
}

.logo-text {
  font-size: 1.8rem;
  font-weight: 800;
  letter-spacing: 4px;
  color: #60a5fa;
}

.brand-title {
  font-size: 2.8rem;
  font-weight: 800;
  line-height: 1.15;
  margin: 0 0 1rem 0;
  color: #ffffff;
  text-shadow: 0 2px 10px rgba(0,0,0,0.3);
}

.brand-tagline {
  font-size: 1rem;
  color: #94a3b8;
  margin: 0 0 2.5rem 0;
  line-height: 1.7;
}

.brand-divider {
  width: 60px;
  height: 3px;
  background: linear-gradient(90deg, #3b82f6, #60a5fa);
  border-radius: 2px;
  margin-bottom: 2rem;
}

.brand-features {
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 0.9rem;
  color: #cbd5e1;
}

.feature-item .pi {
  color: #22c55e;
  font-size: 0.95rem;
}

/* ============================================================
   KANAN — FORM LOGIN
   ============================================================ */
.login-right {
  flex: 0 0 40%;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2.5rem 3rem;
  background: #ffffff;
  overflow-y: auto;
}

.login-form-container {
  width: 100%;
  max-width: 400px;
}

.form-header {
  margin-bottom: 2.5rem;
  text-align: center;
}

.form-welcome {
  font-size: 2rem;
  font-weight: 800;
  color: #0f172a;
  margin: 0 0 0.4rem 0;
}

.form-subtitle {
  font-size: 0.92rem;
  color: #64748b;
  margin: 0;
}

/* ============================================================
   FIELD GROUPS
   ============================================================ */
.login-form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.field-group {
  display: flex;
  flex-direction: column;
  gap: 0.45rem;
}

.field-label {
  font-size: 0.82rem;
  font-weight: 600;
  color: #374151;
  letter-spacing: 0.5px;
  text-transform: uppercase;
}

.input-wrapper {
  display: flex;
  align-items: center;
  border: 1.5px solid #e2e8f0;
  border-radius: 10px;
  background: #f8fafc;
  transition: border-color 0.2s, box-shadow 0.2s;
  overflow: hidden;
}

.input-wrapper:focus-within {
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.12);
  background: #fff;
}

.input-wrapper.input-error {
  border-color: #ef4444;
}

.input-icon {
  padding: 0 0.85rem;
  color: #94a3b8;
  font-size: 0.95rem;
  flex-shrink: 0;
}

.field-input {
  flex: 1;
  border: none;
  outline: none;
  background: transparent;
  font-size: 0.95rem;
  color: #0f172a;
  padding: 0.8rem 0.5rem 0.8rem 0;
  font-family: 'Inter', sans-serif;
}

.field-input::placeholder {
  color: #cbd5e1;
}

.toggle-password {
  background: none;
  border: none;
  cursor: pointer;
  padding: 0 0.85rem;
  color: #94a3b8;
  display: flex;
  align-items: center;
  font-size: 0.9rem;
  transition: color 0.2s;
}
.toggle-password:hover {
  color: #3b82f6;
}

.error-msg {
  font-size: 0.78rem;
  color: #ef4444;
  padding-left: 0.25rem;
}

/* ============================================================
   GLOBAL ERROR
   ============================================================ */
.global-error {
  background: #fef2f2;
  border: 1px solid #fecaca;
  color: #dc2626;
  border-radius: 8px;
  padding: 0.75rem 1rem;
  font-size: 0.85rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

/* ============================================================
   SUBMIT BUTTON
   ============================================================ */
.btn-login {
  width: 100%;
  padding: 0.9rem;
  background: linear-gradient(90deg, #1d4ed8, #3b82f6);
  color: white;
  font-size: 0.9rem;
  font-weight: 700;
  letter-spacing: 1.5px;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  transition: opacity 0.2s, transform 0.1s, box-shadow 0.2s;
  box-shadow: 0 4px 15px rgba(59, 130, 246, 0.4);
  margin-top: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  font-family: 'Inter', sans-serif;
}

.btn-login:hover:not(:disabled) {
  opacity: 0.92;
  transform: translateY(-1px);
  box-shadow: 0 6px 20px rgba(59, 130, 246, 0.5);
}

.btn-login:active:not(:disabled) {
  transform: translateY(0);
}

.btn-login:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}

/* ============================================================
   FOOTER
   ============================================================ */
.login-footer {
  text-align: center;
  margin-top: 2.5rem;
  font-size: 0.78rem;
  color: #94a3b8;
}

/* ============================================================
   RESPONSIVE — Tablet (max 1024px): sedikit lebih compact
   ============================================================ */
@media (max-width: 1024px) {
  .login-left {
    flex: 0 0 55%;
  }
  .login-right {
    flex: 0 0 45%;
    padding: 2rem 2rem;
  }
  .brand-title {
    font-size: 2.2rem;
  }
  .brand-overlay {
    padding: 2rem;
  }
}

/* ============================================================
   RESPONSIVE — Mobile (max 640px): stack vertikal
   ============================================================ */
@media (max-width: 640px) {
  .login-wrapper {
    flex-direction: column;
  }

  /* Panel kiri jadi banner compact di atas */
  .login-left {
    flex: none;
    min-height: 220px;
    height: 220px;
  }

  .brand-overlay {
    padding: 1.5rem;
    display: flex;
    align-items: center;
    justify-content: center;
    height: 100%;
  }

  .brand-content {
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
  }

  .brand-logo {
    margin-bottom: 0.75rem;
  }

  .logo-icon {
    font-size: 1.8rem;
  }

  .logo-text {
    font-size: 1.4rem;
  }

  .brand-title {
    font-size: 1.5rem;
    margin: 0 0 0.4rem 0;
    text-align: center;
  }

  .brand-tagline {
    font-size: 0.82rem;
    margin: 0;
    text-align: center;
  }

  /* Sembunyikan elemen yang tidak perlu di mobile */
  .brand-divider,
  .brand-features {
    display: none;
  }

  /* Panel kanan ambil sisa ruang */
  .login-right {
    flex: 1;
    width: 100%;
    padding: 2rem 1.25rem;
    align-items: flex-start;
    padding-top: 2.5rem;
  }

  .login-form-container {
    max-width: 100%;
  }

  .form-welcome {
    font-size: 1.6rem;
  }

  .login-footer {
    margin-top: 1.5rem;
  }
}
</style>
