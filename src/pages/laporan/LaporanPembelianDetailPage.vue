<template>
  <div class="laporan-detail" ref="pageEl" tabindex="-1">
    <div class="g-header laporan-detail-header">
      <div class="g-header-left">
        <h1 class="g-title">Pembelian Detail</h1>
        <p class="g-subtitle">Rincian pembelian berdasarkan supplier, produk, dan histori harga.</p>
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
        <h3>Rincian Pembelian</h3>
        <div class="table-wrap">
          <table class="g-table">
            <thead>
              <tr>
                <th>Tanggal</th>
                <th>No Order</th>
                <th>Supplier</th>
                <th>Produk</th>
                <th>Qty</th>
                <th>Harga Beli</th>
                <th>Harga Saat Ini</th>
                <th>Selisih</th>
                <th>Lead Time</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in rows" :key="row.id">
                <td>{{ row.orderDate }}</td>
                <td>{{ row.noOrder }}</td>
                <td>{{ row.supplier }}</td>
                <td>{{ row.product }}</td>
                <td>{{ row.qty }}</td>
                <td>{{ formatRp(row.unitCost) }}</td>
                <td>{{ formatRp(row.currentPrice) }}</td>
                <td>{{ formatRp(row.deltaPrice) }}</td>
                <td>{{ row.leadTime }}</td>
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

function buildPriceMap(priceRows) {
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

function getLeadTime(orderDate, receivedAt) {
  if (!orderDate || !receivedAt) return '-'
  const start = new Date(`${orderDate}T00:00:00`)
  const end = new Date(receivedAt)
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return '-'
  const diff = Math.ceil((end.getTime() - start.getTime()) / 86400000)
  return diff < 0 ? '-' : diff
}

async function loadData() {
  loading.value = true
  error.value = ''

  try {
    const { startDate, endDate } = filters.value
    const { data: purchases, error: purchaseError } = await supabase
      .from('purchases')
      .select('id, no_order, order_date, supplier_nama, status, received_at')
      .gte('order_date', startDate)
      .lte('order_date', endDate)
      .order('order_date', { ascending: false })

    if (purchaseError) throw purchaseError

    const purchaseIds = (purchases || []).map(row => row.id)
    const { data: items, error: itemsError } = purchaseIds.length
      ? await supabase
        .from('purchase_items')
        .select('id, purchase_id, product_id, product_nama, qty, unit_cost')
        .in('purchase_id', purchaseIds)
      : { data: [], error: null }

    if (itemsError) throw itemsError

    const productIds = Array.from(new Set((items || []).map(row => row.product_id).filter(Boolean)))
    const { data: priceRows, error: priceError } = productIds.length
      ? await supabase
        .from('product_prices')
        .select('product_id, harga_beli, updated_at')
        .in('product_id', productIds)
      : { data: [], error: null }

    if (priceError) throw priceError

    const priceMap = buildPriceMap(priceRows || [])
    const purchaseMap = new Map((purchases || []).map(row => [row.id, row]))

    rows.value = (items || []).map(item => {
      const purchase = purchaseMap.get(item.purchase_id) || {}
      const currentPriceRow = priceMap.get(item.product_id)
      const currentPrice = Number(currentPriceRow?.harga_beli || 0)
      const unitCost = Number(item.unit_cost || 0)

      return {
        id: item.id,
        orderDate: formatDate(purchase.order_date),
        noOrder: purchase.no_order || '-',
        supplier: purchase.supplier_nama || '-',
        product: item.product_nama || '-',
        qty: Number(item.qty || 0),
        unitCost,
        currentPrice,
        deltaPrice: unitCost - currentPrice,
        leadTime: getLeadTime(purchase.order_date, purchase.received_at),
        status: purchase.status || '-',
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
    fileName: 'laporan-pembelian-detail',
    sheets: [
      {
        name: 'Pembelian',
        columns: [
          { header: 'Tanggal', key: 'orderDate', width: 16 },
          { header: 'No Order', key: 'noOrder', width: 16 },
          { header: 'Supplier', key: 'supplier', width: 24 },
          { header: 'Produk', key: 'product', width: 24 },
          { header: 'Qty', key: 'qty', width: 10 },
          { header: 'Harga Beli', key: 'unitCost', width: 16 },
          { header: 'Harga Saat Ini', key: 'currentPrice', width: 18 },
          { header: 'Selisih', key: 'deltaPrice', width: 14 },
          { header: 'Lead Time (hari)', key: 'leadTime', width: 16 },
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