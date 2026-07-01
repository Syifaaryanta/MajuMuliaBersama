<template>
  <div class="laporan-detail" ref="pageEl" tabindex="-1">
    <div class="g-header laporan-detail-header">
      <div class="g-header-left">
        <h1 class="g-title">Laporan Rincian Penjualan</h1>
        <p class="g-subtitle">Rincian penjualan berdasarkan waktu, pelanggan, produk, dan salesman.</p>
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
        <h3>Rincian Penjualan</h3>
        <div class="table-wrap">
          <table class="g-table">
            <thead>
              <tr>
                <th>Tanggal</th>
                <th>No Order</th>
                <th>Customer</th>
                <th>Salesman</th>
                <th>Subtotal</th>
                <th>Penyesuaian</th>
                <th>Total</th>
                <th>Estimasi HPP</th>
                <th>Margin</th>
                <th>Margin %</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in rows" :key="row.id">
                <td>{{ row.orderDate }}</td>
                <td>{{ row.noOrder }}</td>
                <td>{{ row.customer }}</td>
                <td>{{ row.salesman }}</td>
                <td>{{ formatRp(row.subtotal) }}</td>
                <td>{{ formatRp(row.adjustment) }}</td>
                <td>{{ formatRp(row.total) }}</td>
                <td>{{ formatRp(row.estimatedCost) }}</td>
                <td>{{ formatRp(row.margin) }}</td>
                <td>{{ row.marginPct }}%</td>
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

function buildCostMap(priceRows) {
  const map = new Map()
  ;(priceRows || []).forEach(row => {
    const key = row.product_id
    if (!key) return
    const current = map.get(key)
    if (!current || new Date(row.updated_at || 0) > new Date(current.updated_at || 0)) {
      map.set(key, row)
    }
  })
  return map
}

async function loadData() {
  loading.value = true
  error.value = ''

  try {
    const { startDate, endDate } = filters.value
    const { data: salesRows, error: salesError } = await supabase
      .from('sales')
      .select('id, no_order, order_date, customer_nama, subtotal, extra_charge_amount, status, created_by')
      .gte('order_date', startDate)
      .lte('order_date', endDate)
      .order('order_date', { ascending: false })

    if (salesError) throw salesError

    const saleIds = (salesRows || []).map(row => row.id)
    const createdByIds = Array.from(new Set((salesRows || []).map(row => row.created_by).filter(Boolean)))

    const { data: itemRows, error: itemError } = saleIds.length
      ? await supabase
        .from('sale_items')
        .select('sale_id, product_id, qty, total')
        .in('sale_id', saleIds)
      : { data: [], error: null }

    if (itemError) throw itemError

    const productIds = Array.from(new Set((itemRows || []).map(row => row.product_id).filter(Boolean)))
    const { data: priceRows, error: priceError } = productIds.length
      ? await supabase
        .from('product_prices')
        .select('product_id, harga_beli, updated_at')
        .in('product_id', productIds)
      : { data: [], error: null }

    if (priceError) throw priceError

    const { data: profileRows, error: profileError } = createdByIds.length
      ? await supabase
        .from('profiles')
        .select('id, nama')
        .in('id', createdByIds)
      : { data: [], error: null }

    if (profileError) throw profileError

    const costMap = buildCostMap(priceRows || [])
    const profileMap = new Map((profileRows || []).map(row => [row.id, row.nama]))
    const costPerSale = new Map()

    ;(itemRows || []).forEach(item => {
      const costRow = costMap.get(item.product_id)
      const unitCost = Number(costRow?.harga_beli || 0)
      const itemCost = Number(item.qty || 0) * unitCost
      const current = costPerSale.get(item.sale_id) || 0
      costPerSale.set(item.sale_id, current + itemCost)
    })

    rows.value = (salesRows || []).map(row => {
      const subtotal = Number(row.subtotal || 0)
      const adjustment = Number(row.extra_charge_amount || 0)
      const total = subtotal + adjustment
      const estimatedCost = Number(costPerSale.get(row.id) || 0)
      const margin = total - estimatedCost
      const marginPct = total ? ((margin / total) * 100).toFixed(1) : '0.0'

      return {
        id: row.id,
        orderDate: formatDate(row.order_date),
        noOrder: row.no_order,
        customer: row.customer_nama,
        salesman: profileMap.get(row.created_by) || '-',
        subtotal,
        adjustment,
        total,
        estimatedCost,
        margin,
        marginPct,
        status: row.status,
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
    fileName: 'laporan-penjualan-detail',
    sheets: [
      {
        name: 'Penjualan',
        columns: [
          { header: 'Tanggal', key: 'orderDate', width: 16 },
          { header: 'No Order', key: 'noOrder', width: 16 },
          { header: 'Customer', key: 'customer', width: 24 },
          { header: 'Salesman', key: 'salesman', width: 20 },
          { header: 'Subtotal', key: 'subtotal', width: 16 },
          { header: 'Penyesuaian', key: 'adjustment', width: 16 },
          { header: 'Total', key: 'total', width: 16 },
          { header: 'Estimasi HPP', key: 'estimatedCost', width: 18 },
          { header: 'Margin', key: 'margin', width: 14 },
          { header: 'Margin %', key: 'marginPct', width: 12 },
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