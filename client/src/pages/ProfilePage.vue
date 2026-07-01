<template>
  <div class="profile-page" ref="pageEl" tabindex="-1">
    <div class="profile-card">
      <div class="profile-header">
        <div class="profile-avatar">{{ avatarInitial }}</div>
        <div class="profile-head-copy">
          <h1 class="profile-title">Profil Pengguna</h1>
          <p class="profile-subtitle">Informasi akun yang sedang login</p>
        </div>
      </div>

      <div class="profile-grid">
        <div class="profile-item">
          <label>Nama</label>
          <strong>{{ authStore.displayName || '-' }}</strong>
        </div>
        <div class="profile-item">
          <label>Role</label>
          <strong>{{ roleLabel }}</strong>
        </div>
        <div class="profile-item profile-item--full">
          <label>Email</label>
          <span>{{ authStore.user?.email || '-' }}</span>
        </div>
        <div class="profile-item profile-item--full">
          <label>User ID</label>
          <span>{{ authStore.user?.id || '-' }}</span>
        </div>
      </div>

      <div class="profile-actions">
        <button class="btn-secondary" @click="goBack">
          <i class="pi pi-arrow-left"></i>
          Kembali
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()
const pageEl = ref(null)

const roleMap = {
  admin: 'Admin / Bos',
  staff_gudang: 'Staff Gudang',
  staff_kantor: 'Staff Kantor',
  sales: 'Sales',
}

const roleLabel = computed(() => roleMap[authStore.userRole] ?? authStore.userRole ?? '-')
const avatarInitial = computed(() => {
  const name = authStore.displayName || authStore.user?.email || '?'
  return String(name).charAt(0).toUpperCase()
})

function goBack() {
  router.push('/dashboard')
}

function handleKeydown(e) {
  if (e.key === 'Escape') {
    e.preventDefault()
    goBack()
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
.profile-page {
  min-height: 100%;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding: 2rem 0;
}

.profile-card {
  width: min(760px, 100%);
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
  border: 1px solid #dbe6f5;
  border-radius: 16px;
  box-shadow: 0 18px 45px rgba(15, 23, 42, 0.08);
  overflow: hidden;
}

.profile-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.4rem 1.6rem;
  background: radial-gradient(circle at top left, #dbeafe 0%, #eef4ff 45%, #ffffff 100%);
  border-bottom: 1px solid #dbe6f5;
}

.profile-avatar {
  width: 56px;
  height: 56px;
  border-radius: 14px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
  color: #ffffff;
  font-size: 1.3rem;
  font-weight: 800;
  box-shadow: 0 10px 22px rgba(37, 99, 235, 0.32);
}

.profile-title {
  margin: 0;
  font-size: 1.35rem;
  color: #0f172a;
}

.profile-subtitle {
  margin: 0.2rem 0 0;
  color: #64748b;
  font-size: 0.9rem;
}

.profile-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.85rem;
  padding: 1.3rem 1.6rem;
}

.profile-item {
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
  padding: 0.8rem 0.9rem;
  border-radius: 10px;
  border: 1px solid #dbe6f5;
  background: #ffffff;
}

.profile-item--full {
  grid-column: 1 / -1;
}

.profile-item label {
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.35px;
  text-transform: uppercase;
  color: #64748b;
}

.profile-item strong,
.profile-item span {
  color: #0f172a;
  font-size: 0.95rem;
  overflow-wrap: anywhere;
}

.profile-actions {
  padding: 0 1.6rem 1.35rem;
}

.btn-secondary {
  border: 1px solid #cbd5e1;
  background: #ffffff;
  color: #334155;
  border-radius: 10px;
  padding: 0.62rem 1rem;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  cursor: pointer;
}

.btn-secondary:hover {
  background: #f8fafc;
}

@media (max-width: 768px) {
  .profile-page {
    padding: 1rem 0;
  }

  .profile-header,
  .profile-grid,
  .profile-actions {
    padding-left: 1rem;
    padding-right: 1rem;
  }

  .profile-grid {
    grid-template-columns: 1fr;
  }
}
</style>
