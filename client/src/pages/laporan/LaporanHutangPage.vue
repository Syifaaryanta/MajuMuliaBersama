<template>
  <div class="laporan-detail" ref="pageEl" tabindex="-1">
    <div class="g-header laporan-detail-header">
      <div class="g-header-left">
        <h1 class="g-title">Laporan Hutang Dagang</h1>
        <p class="g-subtitle">Ringkasan hutang dan jadwal pembayaran ke supplier.</p>
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
        <h3>Rincian Hutang</h3>
        <div class="table-wrap">
          <table class="g-table">
            <thead>
              <tr>
                <th>Tanggal</th>
                <th>No Order</th>
                <th>Supplier</th>
                <th>Subtotal</th>
                <th>Jatuh Tempo</th>
                <th>Umur (hari)</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in rows" :key="row.id">
                <td>{{ row.orderDate }}</td>
                <td>{{ row.noOrder }}</td>
                <td>{{ row.supplier }}</td>
                <td>{{ formatRp(row.subtotal) }}</td>
                <td>{{ row.dueDate }}</td>
                <td>{{ row.ageDays }}</td>
                <td>{{ row.status }}</td>
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

function addMonths(value, months) {
  if (!value) return '-'
  const date = new Date(`${value}T00:00:00`)
  if (Number.isNaN(date.getTime())) return '-'
  const next = new Date(date)
  next.setMonth(next.getMonth() + Number(months || 0))
  return toIsoDate(next)
}

function calcAgeDays(value) {
  if (!value) return '-'
  const date = new Date(`${value}T00:00:00`)
  if (Number.isNaN(date.getTime())) return '-'
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  return Math.ceil((today.getTime() - date.getTime()) / 86400000)
}

async function loadData() {
  loading.value = true
  error.value = ''

  try {
    const { startDate, endDate } = filters.value
    const [purchaseResp, supplierResp] = await Promise.all([
      supabase
        .from('purchases')
        .select('id, no_order, order_date, subtotal, status, supplier_id, supplier_nama')
        .gte('order_date', startDate)
        .lte('order_date', endDate)
        .order('order_date', { ascending: false }),
      supabase
        .from('suppliers')
        .select('id, nama, jatuh_tempo_bulan'),
    ])

    if (purchaseResp.error) throw purchaseResp.error
    if (supplierResp.error) throw supplierResp.error

    const supplierMap = new Map(
      (supplierResp.data || []).map(row => [row.id, row])
    )

    rows.value = (purchaseResp.data || []).map(row => {
      const supplier = supplierMap.get(row.supplier_id)
      const tempo = supplier?.jatuh_tempo_bulan ?? 1
      const dueDateIso = addMonths(row.order_date, tempo)

      return {
        id: row.id,
        orderDate: formatDate(row.order_date),
        noOrder: row.no_order,
        supplier: row.supplier_nama || supplier?.nama || '-',
        subtotal: Number(row.subtotal || 0),
        dueDate: dueDateIso === '-' ? '-' : formatDate(dueDateIso),
        ageDays: calcAgeDays(row.order_date),
        status: row.status || '-',
      }
    })
  } catch (err) {
    error.value = err?.message || 'Gagal memuat data laporan.'
  } finally {
    loading.value = false
  }
}

async function exportExcel() {
  if (loading.value) return

  await exportWorkbook({
    fileName: 'laporan-hutang',
    sheets: [
      {
        name: 'Hutang',
        columns: [
          { header: 'Tanggal', key: 'orderDate', width: 16 },
          { header: 'No Order', key: 'noOrder', width: 16 },
          { header: 'Supplier', key: 'supplier', width: 24 },
          { header: 'Subtotal', key: 'subtotal', width: 16 },
          { header: 'Jatuh Tempo', key: 'dueDate', width: 16 },
          { header: 'Umur (hari)', key: 'ageDays', width: 12 },
          { header: 'Status', key: 'status', width: 12 },
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