<template>
  <div class="laporan-detail" ref="pageEl" tabindex="-1">
    <div class="g-header laporan-detail-header">
      <div class="g-header-left">
        <h1 class="g-title">Log Audit & Aktivitas Sistem</h1>
        <p class="g-subtitle">Catatan perubahan stok dan aktivitas pengguna.</p>
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

      <article class="laporan-detail-card" v-else>
        <h3>Riwayat Penyesuaian</h3>
        <div class="table-wrap">
          <table class="g-table">
            <thead>
              <tr>
                <th>Tanggal</th>
                <th>Produk</th>
                <th>Stok Awal</th>
                <th>Delta</th>
                <th>Stok Akhir</th>
                <th>Staff</th>
                <th>Alasan</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in rows" :key="row.id">
                <td>{{ row.date }}</td>
                <td>{{ row.product }}</td>
                <td>{{ row.stockBefore }}</td>
                <td>{{ row.delta }}</td>
                <td>{{ row.stockAfter }}</td>
                <td>{{ row.staff }}</td>
                <td>{{ row.reason }}</td>
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
import { formatDate, toIsoDate } from '@/lib/penagihanService'
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

async function loadData() {
  loading.value = true
  error.value = ''

  try {
    const { startDate, endDate } = filters.value
    const { data, error: fetchError } = await supabase
      .from('stock_adjustments')
      .select('id, adjustment_date, product_nama, stock_before, qty_delta, stock_after, staff_nama, alasan')
      .gte('adjustment_date', startDate)
      .lte('adjustment_date', endDate)
      .order('adjustment_date', { ascending: false })

    if (fetchError) throw fetchError

    rows.value = (data || []).map(row => ({
      id: row.id,
      date: formatDate(row.adjustment_date),
      product: row.product_nama || '-',
      stockBefore: Number(row.stock_before || 0),
      delta: Number(row.qty_delta || 0),
      stockAfter: Number(row.stock_after || 0),
      staff: row.staff_nama || '-',
      reason: row.alasan || '-',
    }))
  } catch (err) {
    error.value = err?.message || 'Gagal memuat data laporan.'
  } finally {
    loading.value = false
  }
}

async function exportExcel() {
  if (loading.value) return

  await exportWorkbook({
    fileName: 'laporan-audit-aktivitas',
    sheets: [
      {
        name: 'Audit',
        columns: [
          { header: 'Tanggal', key: 'date', width: 16 },
          { header: 'Produk', key: 'product', width: 28 },
          { header: 'Stok Awal', key: 'stockBefore', width: 12 },
          { header: 'Delta', key: 'delta', width: 10 },
          { header: 'Stok Akhir', key: 'stockAfter', width: 12 },
          { header: 'Staff', key: 'staff', width: 16 },
          { header: 'Alasan', key: 'reason', width: 24 },
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
