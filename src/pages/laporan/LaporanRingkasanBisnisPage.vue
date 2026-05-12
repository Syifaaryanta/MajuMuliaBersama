<template>
  <div class="laporan-detail" ref="pageEl" tabindex="-1">
    <div class="g-header laporan-detail-header">
      <div class="g-header-left">
        <h1 class="g-title">Ringkasan Bisnis</h1>
        <p class="g-subtitle">Ikhtisar performa bisnis dalam satu periode.</p>
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
        <h3>Ringkasan utama</h3>
        <div class="table-wrap">
          <table class="g-table">
            <thead>
              <tr>
                <th>Metik</th>
                <th>Nilai</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in summaryRows" :key="row.label">
                <td>{{ row.label }}</td>
                <td>{{ row.value }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </article>

      <article class="laporan-detail-card" v-if="topProducts.length">
        <h3>Top 5 Produk</h3>
        <div class="table-wrap">
          <table class="g-table">
            <thead>
              <tr>
                <th>Produk</th>
                <th>Qty</th>
                <th>Total</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in topProducts" :key="row.product">
                <td>{{ row.product }}</td>
                <td>{{ row.qty }}</td>
                <td>{{ formatRp(row.total) }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </article>

      <article class="laporan-detail-card" v-if="trendRows.length">
        <h3>Tren 30/90 Hari</h3>
        <div class="table-wrap">
          <table class="g-table">
            <thead>
              <tr>
                <th>Periode</th>
                <th>Omzet</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in trendRows" :key="row.label">
                <td>{{ row.label }}</td>
                <td>{{ formatRp(row.value) }}</td>
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
import { formatRp, toIsoDate } from '@/lib/penagihanService'
import { exportWorkbook } from '@/lib/reportingExport'

const router = useRouter()
const route = useRoute()
const pageEl = ref(null)
const startInputRef = ref(null)
const loading = ref(false)
const error = ref('')
const summaryRows = ref([])
const topProducts = ref([])
const trendRows = ref([])

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

function sumValues(rows, valueKey) {
  return rows.reduce((sum, row) => sum + Number(row[valueKey] || 0), 0)
}

async function loadData() {
  loading.value = true
  error.value = ''

  try {
    const { startDate, endDate } = filters.value

    const [salesResp, purchasesResp, customersResp, productsResp, itemResp] = await Promise.all([
      supabase
        .from('sales')
        .select('id, order_date, subtotal, extra_charge_amount, status')
        .gte('order_date', startDate)
        .lte('order_date', endDate),
      supabase
        .from('purchases')
        .select('id, order_date, subtotal, status')
        .gte('order_date', startDate)
        .lte('order_date', endDate),
      supabase
        .from('customers')
        .select('saldo_piutang'),
      supabase
        .from('products')
        .select('stok'),
      supabase
        .from('sale_items')
        .select('product_nama, qty, total, sales!inner(order_date, status)')
        .gte('sales.order_date', startDate)
        .lte('sales.order_date', endDate)
        .eq('sales.status', 'completed'),
    ])

    if (salesResp.error) throw salesResp.error
    if (purchasesResp.error) throw purchasesResp.error
    if (customersResp.error) throw customersResp.error
    if (productsResp.error) throw productsResp.error
    if (itemResp.error) throw itemResp.error

    const salesRows = (salesResp.data || []).filter(row => row.status === 'completed')
    const purchaseRows = (purchasesResp.data || []).filter(row => row.status !== 'draft')

    const omzet = salesRows.reduce((sum, row) => {
      return sum + Number(row.subtotal || 0) + Number(row.extra_charge_amount || 0)
    }, 0)
    const totalPembelian = sumValues(purchaseRows, 'subtotal')
    const labaKotor = omzet - totalPembelian
    const piutang = sumValues(customersResp.data || [], 'saldo_piutang')
    const hutang = totalPembelian
    const stokTotal = sumValues(productsResp.data || [], 'stok')

    summaryRows.value = [
      { label: 'Omzet', value: formatRp(omzet) },
      { label: 'Laba kotor (estimasi)', value: formatRp(labaKotor) },
      { label: 'Piutang', value: formatRp(piutang) },
      { label: 'Hutang', value: formatRp(hutang) },
      { label: 'Stok total', value: stokTotal.toLocaleString('id-ID') },
    ]

    const productMap = new Map()
    ;(itemResp.data || []).forEach(row => {
      const key = row.product_nama || '-'
      const current = productMap.get(key) || { product: key, qty: 0, total: 0 }
      current.qty += Number(row.qty || 0)
      current.total += Number(row.total || 0)
      productMap.set(key, current)
    })

    topProducts.value = Array.from(productMap.values())
      .sort((a, b) => b.qty - a.qty)
      .slice(0, 5)

    const end = new Date(filters.value.endDate)
    const start90 = new Date(end)
    start90.setDate(end.getDate() - 90)
    const start30 = new Date(end)
    start30.setDate(end.getDate() - 30)

    const { data: trendSales, error: trendError } = await supabase
      .from('sales')
      .select('order_date, subtotal, extra_charge_amount, status')
      .gte('order_date', toIsoDate(start90))
      .lte('order_date', filters.value.endDate)

    if (trendError) throw trendError

    const completedTrend = (trendSales || []).filter(row => row.status === 'completed')
    const total90 = completedTrend.reduce((sum, row) => {
      return sum + Number(row.subtotal || 0) + Number(row.extra_charge_amount || 0)
    }, 0)
    const total30 = completedTrend
      .filter(row => row.order_date >= toIsoDate(start30))
      .reduce((sum, row) => sum + Number(row.subtotal || 0) + Number(row.extra_charge_amount || 0), 0)

    trendRows.value = [
      { label: 'Omzet 30 hari terakhir', value: total30 },
      { label: 'Omzet 90 hari terakhir', value: total90 },
    ]
  } catch (err) {
    error.value = err?.message || 'Gagal memuat data laporan.'
  } finally {
    loading.value = false
  }
}

async function exportExcel() {
  if (loading.value) return

  await exportWorkbook({
    fileName: 'laporan-ringkasan-bisnis',
    sheets: [
      {
        name: 'Ringkasan',
        columns: [
          { header: 'Metik', key: 'label', width: 32 },
          { header: 'Nilai', key: 'value', width: 22 },
        ],
        rows: summaryRows.value.map(row => ({
          label: row.label,
          value: row.value,
        })),
      },
      {
        name: 'Top Produk',
        columns: [
          { header: 'Produk', key: 'product', width: 32 },
          { header: 'Qty', key: 'qty', width: 12 },
          { header: 'Total', key: 'total', width: 18 },
        ],
        rows: topProducts.value.map(row => ({
          product: row.product,
          qty: row.qty,
          total: row.total,
        })),
      },
      {
        name: 'Tren',
        columns: [
          { header: 'Periode', key: 'label', width: 32 },
          { header: 'Omzet', key: 'value', width: 18 },
        ],
        rows: trendRows.value,
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
