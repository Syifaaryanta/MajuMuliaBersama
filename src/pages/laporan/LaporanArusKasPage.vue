<template>
  <div class="laporan-detail" ref="pageEl" tabindex="-1">
    <div class="g-header laporan-detail-header">
      <div class="g-header-left">
        <h1 class="g-title">Arus Kas Sederhana</h1>
        <p class="g-subtitle">Ringkasan kas masuk dan keluar dari aktivitas utama.</p>
      </div>
      <div class="laporan-detail-actions">
        <button type="button" class="btn-secondary laporan-action-btn" @click="focusFilter">
          <i class="pi pi-filter"></i>
          <span>Filter</span>
          <kbd>F1</kbd>
        </button>
        <button type="button" class="btn-secondary laporan-action-btn" @click="exportExcel">
          <i class="pi pi-download"></i>
          <span>Export</span>
          <kbd>F2</kbd>
        </button>
      </div>
    </div>

    <div class="laporan-filter">
      <div class="filter-field">
        <label>Mulai</label>
        <input ref="startInputRef" v-model="filters.startDate" type="date" />
      </div>
      <div class="filter-field">
        <label>Selesai</label>
        <input v-model="filters.endDate" type="date" />
      </div>
      <button type="button" class="btn-primary" @click="loadData">Terapkan</button>
    </div>

    <div class="shortcut-strip">
      <kbd>F1 Filter</kbd>
      <kbd>F2 Export</kbd>
      <kbd>Esc Kembali</kbd>
    </div>

    <section class="laporan-detail-body">
      <p v-if="error" class="laporan-error">{{ error }}</p>
      <p v-else-if="loading" class="laporan-loading">Memuat data...</p>

      <article v-else class="laporan-detail-card">
        <h3>Rincian Arus Kas</h3>
        <div class="table-wrap">
          <table class="g-table">
            <thead>
              <tr>
                <th>Tanggal</th>
                <th>Kas Masuk</th>
                <th>Kas Keluar</th>
                <th>Net</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in rows" :key="row.date">
                <td>{{ row.dateLabel }}</td>
                <td>{{ formatRp(row.cashIn) }}</td>
                <td>{{ formatRp(row.cashOut) }}</td>
                <td>{{ formatRp(row.net) }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </article>
    </section>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { formatDate, formatRp, toIsoDate } from '@/lib/penagihanService'
import { exportWorkbook } from '@/lib/reportingExport'

const router = useRouter()
const route = useRoute()
const pageEl = ref(null)
const startInputRef = ref(null)
const loading = ref(false)
const error = ref('')
const rows = ref([])

const filters = ref({
  startDate: '',
  endDate: '',
})

function getDefaultRange() {
  const end = new Date()
  const start = new Date()
  start.setDate(end.getDate() - 30)
  return {
    startDate: toIsoDate(start),
    endDate: toIsoDate(end),
  }
}

function focusFilter() {
  startInputRef.value?.focus()
}

function buildCashRows(paymentRows, purchaseRows) {
  const map = new Map()

  ;(paymentRows || []).forEach(row => {
    const date = String(row.payment_date || '')
    if (!date) return
    const current = map.get(date) || { date, cashIn: 0, cashOut: 0 }
    current.cashIn += Number(row.amount || 0)
    map.set(date, current)
  })

  ;(purchaseRows || []).forEach(row => {
    const date = String(row.order_date || '')
    if (!date) return
    const current = map.get(date) || { date, cashIn: 0, cashOut: 0 }
    current.cashOut += Number(row.subtotal || 0)
    map.set(date, current)
  })

  return Array.from(map.values())
    .map(row => ({
      date: row.date,
      dateLabel: formatDate(row.date),
      cashIn: row.cashIn,
      cashOut: row.cashOut,
      net: row.cashIn - row.cashOut,
    }))
    .sort((a, b) => (a.date < b.date ? 1 : -1))
}

async function loadData() {
  loading.value = true
  error.value = ''

  try {
    const { startDate, endDate } = filters.value
    const [paymentResp, purchaseResp] = await Promise.all([
      supabase
        .from('sales_payments')
        .select('payment_date, amount')
        .gte('payment_date', startDate)
        .lte('payment_date', endDate),
      supabase
        .from('purchases')
        .select('order_date, subtotal, status')
        .gte('order_date', startDate)
        .lte('order_date', endDate),
    ])

    if (paymentResp.error) throw paymentResp.error
    if (purchaseResp.error) throw purchaseResp.error

    const purchases = (purchaseResp.data || []).filter(row => row.status !== 'draft')
    rows.value = buildCashRows(paymentResp.data || [], purchases)
  } catch (err) {
    error.value = err?.message || 'Gagal memuat data laporan.'
  } finally {
    loading.value = false
  }
}

async function exportExcel() {
  if (loading.value) return

  await exportWorkbook({
    fileName: 'laporan-arus-kas',
    sheets: [
      {
        name: 'Arus Kas',
        columns: [
          { header: 'Tanggal', key: 'dateLabel', width: 16 },
          { header: 'Kas Masuk', key: 'cashIn', width: 16 },
          { header: 'Kas Keluar', key: 'cashOut', width: 16 },
          { header: 'Net', key: 'net', width: 16 },
        ],
        rows: rows.value,
      },
    ],
  })
}

function handleKeydown(e) {
  if (e.target?.tagName === 'INPUT' || e.target?.tagName === 'TEXTAREA') return
  if (e.key === 'Escape') {
    e.preventDefault()
    router.push('/laporan')
    return
  }
  if (e.key === 'F1') {
    e.preventDefault()
    focusFilter()
  }
  if (e.key === 'F2') {
    e.preventDefault()
    exportExcel()
  }
}

onMounted(() => {
  pageEl.value?.focus()
  const defaults = getDefaultRange()
  filters.value.startDate = defaults.startDate
  filters.value.endDate = defaults.endDate
  loadData().then(() => {
    if (route.query.action === 'export') {
      exportExcel()
    } else if (route.query.action === 'filter') {
      focusFilter()
    }
  })
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<style scoped>
@import '@/assets/components/table.css';
@import '@/assets/components/form.css';
@import '@/assets/components/modal.css';
@import '@/assets/Styles/laporan/laporan-detail.css';
</style>