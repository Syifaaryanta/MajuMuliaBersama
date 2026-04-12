<template>
  <div class="penagihan-menu-page" ref="pageEl" tabindex="-1">
    <Toast position="top-right" />

    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Manajemen Penagihan</h1>
        <p class="g-subtitle">Kelola piutang, nota customer, transaksi tunai, dan riwayat pembayaran</p>
      </div>
    </div>

    <div class="shortcut-strip">
      <kbd>1 Piutang</kbd>
      <kbd>2 Nota</kbd>
      <kbd>3 Tunai</kbd>
      <kbd>4 Riwayat</kbd>
      <kbd>Enter Buka</kbd>
      <kbd>Esc Kembali</kbd>
    </div>

    <div v-if="schemaError" class="schema-warning">
      <i class="pi pi-exclamation-triangle"></i>
      <div>
        <strong>Schema Penagihan Belum Siap</strong>
        <p>{{ schemaError }}</p>
        <span>Jalankan migrasi: server/schema/22_penagihan_payments_and_notes.sql</span>
      </div>
    </div>

    <template v-else>
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
            <i class="pi pi-wallet"></i>
          </div>
          <div class="stat-content">
            <span class="stat-label">Total Piutang Aktif</span>
            <span class="stat-value">{{ formatRp(infoStats.totalOutstanding) }}</span>
          </div>
        </div>
        <div class="stat-card stat-card--orange">
          <div class="stat-icon stat-icon--orange">
            <i class="pi pi-exclamation-circle"></i>
          </div>
          <div class="stat-content">
            <span class="stat-label">Overdue</span>
            <span class="stat-value">{{ infoStats.overdueCount }} transaksi</span>
          </div>
        </div>
        <div class="stat-card stat-card--green">
          <div class="stat-icon stat-icon--green">
            <i class="pi pi-check-circle"></i>
          </div>
          <div class="stat-content">
            <span class="stat-label">Jatuh Tempo Hari Ini</span>
            <span class="stat-value">{{ infoStats.dueTodayCount }} transaksi</span>
          </div>
        </div>
        <div class="stat-card stat-card--purple">
          <div class="stat-icon stat-icon--purple">
            <i class="pi pi-money-bill"></i>
          </div>
          <div class="stat-content">
            <span class="stat-label">Penerimaan Hari Ini</span>
            <span class="stat-value">{{ formatRp(infoStats.paymentTodayTotal) }}</span>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import Toast from 'primevue/toast'
import {
  fetchPenagihanBundle,
  getMenuStats,
  isSchemaIssue,
  formatRp,
  subscribePenagihanAutoSync,
} from '@/lib/penagihanService'

const router = useRouter()
const toast = useToast()

const pageEl = ref(null)
const selectedIndex = ref(0)
const schemaError = ref('')
let stopAutoSync = () => {}
const infoStats = ref({
  totalOutstanding: 0,
  overdueCount: 0,
  dueTodayCount: 0,
  paymentTodayTotal: 0,
  piutangAktifCount: 0,
  tunaiCount: 0,
  riwayatCount: 0,
  needSyncNotaCount: 0,
})

const menuOptions = computed(() => {
  return [
    {
      id: 'piutang-aktif',
      title: 'Piutang Aktif',
      description: 'Tagihan customer termin 1-3 bulan',
      icon: 'pi pi-wallet',
      route: '/penagihan/piutang',
    },
    {
      id: 'manajemen-nota',
      title: 'Manajemen Nota',
      description: 'Kontrol nota merah, putih, dan kuning',
      icon: 'pi pi-file-edit',
      route: '/penagihan/nota',
    },
    {
      id: 'tunai-selesai',
      title: 'Tunai Selesai',
      description: 'Transaksi customer yang langsung bayar',
      icon: 'pi pi-check-circle',
      route: '/penagihan/tunai',
    },
    {
      id: 'riwayat-bayar',
      title: 'Riwayat Bayar',
      description: 'Log cicilan dan pelunasan customer',
      icon: 'pi pi-history',
      route: '/penagihan/riwayat',
    },
  ]
})

function navigateToOption(option) {
  router.push(option.route)
}

function onCardClick(option, index) {
  selectedIndex.value = index
  navigateToOption(option)
}

async function loadStats() {
  schemaError.value = ''
  try {
    const { sales, payments } = await fetchPenagihanBundle()
    infoStats.value = getMenuStats(sales, payments)
  } catch (err) {
    const message = String(err?.message || err || '')
    console.error('[PenagihanPage.loadStats]', err)

    if (isSchemaIssue(message)) {
      schemaError.value = 'Database belum memiliki view/tabel penagihan terbaru.'
      return
    }

    toast.add({
      severity: 'error',
      summary: 'Gagal Memuat Statistik',
      detail: message,
      life: 3200,
    })
  }
}

function handleKeydown(e) {
  if (e.key === 'ArrowLeft') {
    e.preventDefault()
    selectedIndex.value = selectedIndex.value > 0
      ? selectedIndex.value - 1
      : menuOptions.value.length - 1
  } else if (e.key === 'ArrowRight') {
    e.preventDefault()
    selectedIndex.value = selectedIndex.value < menuOptions.value.length - 1
      ? selectedIndex.value + 1
      : 0
  } else if (e.key === 'Enter') {
    e.preventDefault()
    navigateToOption(menuOptions.value[selectedIndex.value])
  } else if (e.key >= '1' && e.key <= '9') {
    e.preventDefault()
    const index = Number(e.key) - 1
    if (index < menuOptions.value.length) {
      selectedIndex.value = index
      navigateToOption(menuOptions.value[index])
    }
  } else if (e.key === 'Escape') {
    e.preventDefault()
    router.push('/dashboard')
  }
}

onMounted(async () => {
  pageEl.value?.focus()
  window.addEventListener('keydown', handleKeydown)
  await loadStats()
  stopAutoSync = subscribePenagihanAutoSync({
    key: 'menu',
    onSync: loadStats,
  })
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
  stopAutoSync()
})
</script>

<style scoped>
@import '@/assets/pages/penagihan/penagihan-menu-page.css';
</style>
