<template>
  <div class="dashboard-page" ref="pageEl" tabindex="-1">
    <Toast position="top-right" />

    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Dashboard Operasional</h1>
        <p class="g-subtitle">Grafik lintas modul untuk memantau performa penjualan, pembelian, gudang, penagihan, dan master data.</p>
      </div>

      <div class="g-header-right">
        <span class="last-updated" v-if="lastUpdatedLabel">Update: {{ lastUpdatedLabel }}</span>
        <button class="btn-refresh" @click="loadDashboardData" :disabled="loading" type="button">
          <i class="pi pi-refresh" :class="{ spin: loading }"></i>
          <span>{{ loading ? 'Memuat...' : 'Refresh' }}</span>
        </button>
      </div>
    </div>

    <div class="shortcut-strip">
      <kbd>1 Penjualan</kbd>
      <kbd>2 Pembelian</kbd>
      <kbd>3 Penagihan</kbd>
      <kbd>4 Gudang</kbd>
      <kbd>5 Master Data</kbd>
      <kbd>6 History</kbd>
      <kbd>Enter Refresh</kbd>
      <kbd>Esc Reset Filter</kbd>
      <kbd>F1 Bantuan</kbd>
    </div>

    <div class="range-filter">
      <button
        v-for="option in rangeOptions"
        :key="option.days"
        type="button"
        class="range-chip"
        :class="{ 'range-chip--active': activeRange === option.days }"
        @click="setRange(option.days)"
      >
        {{ option.label }}
      </button>
      <span class="range-note">Periode aktif: {{ selectedRangeLabel }}</span>
    </div>

    <div v-if="schemaWarnings.length" class="schema-warning">
      <i class="pi pi-info-circle"></i>
      <div>
        <strong>Beberapa data modul belum tersedia penuh</strong>
        <p>{{ schemaWarningsText }}</p>
      </div>
    </div>

    <div class="kpi-grid">
      <article class="kpi-card kpi-card--blue">
        <div class="kpi-icon"><i class="pi pi-wallet"></i></div>
        <div class="kpi-body">
          <span class="kpi-label">Omzet Periode</span>
          <strong class="kpi-value">{{ formatRp(kpi.omzet) }}</strong>
        </div>
      </article>

      <article class="kpi-card kpi-card--teal">
        <div class="kpi-icon"><i class="pi pi-shopping-cart"></i></div>
        <div class="kpi-body">
          <span class="kpi-label">Pembelian Periode</span>
          <strong class="kpi-value">{{ formatRp(kpi.pembelian) }}</strong>
        </div>
      </article>

      <article class="kpi-card kpi-card--green">
        <div class="kpi-icon"><i class="pi pi-chart-line"></i></div>
        <div class="kpi-body">
          <span class="kpi-label">HPP Estimasi</span>
          <strong class="kpi-value">{{ formatRp(kpi.hpp) }}</strong>
          <small class="kpi-sub">Margin {{ formatPercent(kpi.marginPct) }}</small>
        </div>
      </article>

      <article class="kpi-card kpi-card--orange">
        <div class="kpi-icon"><i class="pi pi-exclamation-circle"></i></div>
        <div class="kpi-body">
          <span class="kpi-label">Piutang Outstanding</span>
          <strong class="kpi-value">{{ formatRp(kpi.outstanding) }}</strong>
          <small class="kpi-sub">Overdue: {{ formatCount(kpi.overdueCount) }} transaksi</small>
        </div>
      </article>

      <article class="kpi-card kpi-card--amber">
        <div class="kpi-icon"><i class="pi pi-box"></i></div>
        <div class="kpi-body">
          <span class="kpi-label">Stok Kritis + Habis</span>
          <strong class="kpi-value">{{ formatCount(kpi.lowStockCount) }} item</strong>
          <small class="kpi-sub">Pantau di menu Gudang</small>
        </div>
      </article>

      <article class="kpi-card kpi-card--slate">
        <div class="kpi-icon"><i class="pi pi-users"></i></div>
        <div class="kpi-body">
          <span class="kpi-label">Master Data Aktif</span>
          <strong class="kpi-value">{{ formatCount(kpi.activeCustomers) }} customer</strong>
          <small class="kpi-sub">{{ formatCount(kpi.activeSuppliers) }} supplier</small>
        </div>
      </article>
    </div>

    <div class="quick-nav-grid">
      <button
        v-for="(item, index) in moduleLinks"
        :key="item.route"
        class="quick-nav-card"
        :class="{ 'quick-nav-card--active': selectedQuickIndex === index }"
        type="button"
        @mouseenter="selectedQuickIndex = index"
        @click="navigateToModule(index)"
      >
        <span class="quick-nav-index">{{ index + 1 }}</span>
        <div class="quick-nav-body">
          <h3>{{ item.title }}</h3>
          <p>{{ item.description }}</p>
        </div>
        <i class="pi pi-arrow-right"></i>
      </button>
    </div>

    <div class="chart-grid">
      <section class="chart-card chart-card--wide">
        <div class="chart-head">
          <div>
            <h3>Tren Penjualan vs Pembelian</h3>
            <p>Ringkasan nilai transaksi per bulan</p>
          </div>
          <button type="button" class="chart-link" @click="router.push('/penjualan')">Buka Penjualan</button>
        </div>
        <div class="chart-body chart-body--line">
          <canvas ref="salesPurchaseCanvas"></canvas>
        </div>
      </section>

      <section class="chart-card">
        <div class="chart-head">
          <div>
            <h3>Kesehatan Stok Gudang</h3>
            <p>Kategori aman, kritis, dan habis</p>
          </div>
          <button type="button" class="chart-link" @click="router.push('/gudang')">Buka Gudang</button>
        </div>
        <div class="chart-body chart-body--donut">
          <canvas ref="stockHealthCanvas"></canvas>
        </div>
      </section>

      <section class="chart-card">
        <div class="chart-head">
          <div>
            <h3>Status Penagihan</h3>
            <p>Paid, partial, unpaid, dan cash</p>
          </div>
          <button type="button" class="chart-link" @click="router.push('/penagihan')">Buka Penagihan</button>
        </div>
        <div class="chart-body chart-body--donut">
          <canvas ref="penagihanCanvas"></canvas>
        </div>
      </section>

      <section class="chart-card chart-card--wide">
        <div class="chart-head">
          <div>
            <h3>Grafik HPP vs Omzet</h3>
            <p>HPP estimasi dari harga_beli aktif pada master harga produk</p>
          </div>
          <button type="button" class="chart-link" @click="router.push('/pembelian')">Buka Pembelian</button>
        </div>
        <div class="chart-body chart-body--bar">
          <canvas ref="hppCanvas"></canvas>
        </div>
      </section>

      <section class="chart-card chart-card--wide">
        <div class="chart-head">
          <div>
            <h3>Aktivitas Operasional Periode</h3>
            <p>Volume transaksi per modul untuk monitoring harian</p>
          </div>
          <button type="button" class="chart-link" @click="router.push('/pembelian/history')">Buka History</button>
        </div>
        <div class="chart-body chart-body--bar-sm">
          <canvas ref="activityCanvas"></canvas>
        </div>
      </section>
    </div>

    <div v-if="loadError" class="error-banner">
      <i class="pi pi-exclamation-triangle"></i>
      <p>{{ loadError }}</p>
    </div>
  </div>
</template>

<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import Toast from 'primevue/toast'
import { Chart, registerables } from 'chart.js'
import { supabase } from '@/lib/supabase'

Chart.register(...registerables)

const router = useRouter()
const toast = useToast()

const pageEl = ref(null)
const loading = ref(false)
const loadError = ref('')
const lastUpdatedAt = ref(null)
const schemaWarnings = ref([])

const activeRange = ref(90)
const rangeOptions = [
  { days: 30, label: '30 Hari' },
  { days: 90, label: '90 Hari' },
  { days: 180, label: '180 Hari' },
]

const moduleLinks = [
  {
    title: 'Penjualan',
    description: 'Order, faktur, dan performa omzet.',
    route: '/penjualan',
  },
  {
    title: 'Pembelian',
    description: 'Order supplier dan receiving barang.',
    route: '/pembelian',
  },
  {
    title: 'Penagihan',
    description: 'Piutang, pembayaran, dan overdue.',
    route: '/penagihan',
  },
  {
    title: 'Gudang',
    description: 'Stok aman, kritis, dan barang habis.',
    route: '/gudang',
  },
  {
    title: 'Master Data',
    description: 'Pertumbuhan customer dan supplier.',
    route: '/master-data',
  },
  {
    title: 'History',
    description: 'Rekap aktivitas transaksi periodik.',
    route: '/pembelian/history',
  },
]

const selectedQuickIndex = ref(0)

const kpi = ref({
  omzet: 0,
  pembelian: 0,
  hpp: 0,
  marginPct: 0,
  outstanding: 0,
  overdueCount: 0,
  lowStockCount: 0,
  cashIn: 0,
  activeCustomers: 0,
  activeSuppliers: 0,
})

const chartModel = ref({
  labels: [],
  salesSeries: [],
  purchaseSeries: [],
  hppSeries: [],
  marginPctSeries: [],
  stockSeries: [0, 0, 0],
  penagihanSeries: [0, 0, 0, 0],
  activitySeries: [0, 0, 0, 0],
})

const salesPurchaseCanvas = ref(null)
const stockHealthCanvas = ref(null)
const penagihanCanvas = ref(null)
const hppCanvas = ref(null)
const activityCanvas = ref(null)

const chartInstances = {
  salesPurchase: null,
  stockHealth: null,
  penagihan: null,
  hpp: null,
  activity: null,
}

const selectedRangeLabel = computed(() => {
  const found = rangeOptions.find((item) => item.days === activeRange.value)
  return found ? found.label : `${activeRange.value} Hari`
})

const lastUpdatedLabel = computed(() => {
  if (!lastUpdatedAt.value) return ''
  return new Date(lastUpdatedAt.value).toLocaleString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
})

const schemaWarningsText = computed(() => {
  if (!schemaWarnings.value.length) return ''
  const prettyName = {
    v_penagihan_sales: 'View Penagihan',
    sales_payments: 'Tabel Pembayaran Penagihan',
    product_prices: 'Master Harga Produk',
    stock_adjustments: 'Histori Penyesuaian Stok',
  }
  return schemaWarnings.value.map((key) => prettyName[key] || key).join(', ')
})

function pad2(value) {
  return String(value).padStart(2, '0')
}

function toDateOnly(dateObj) {
  return `${dateObj.getFullYear()}-${pad2(dateObj.getMonth() + 1)}-${pad2(dateObj.getDate())}`
}

function getStartDate(days) {
  const now = new Date()
  now.setHours(0, 0, 0, 0)
  now.setDate(now.getDate() - (days - 1))
  return now
}

function monthKeyToLabel(monthKey) {
  const [year, month] = monthKey.split('-').map(Number)
  return new Date(year, month - 1, 1).toLocaleDateString('id-ID', {
    month: 'short',
    year: '2-digit',
  })
}

function buildMonthKeys(startDate, endDate) {
  const keys = []
  const cursor = new Date(startDate.getFullYear(), startDate.getMonth(), 1)
  const end = new Date(endDate.getFullYear(), endDate.getMonth(), 1)

  while (cursor <= end) {
    keys.push(`${cursor.getFullYear()}-${pad2(cursor.getMonth() + 1)}`)
    cursor.setMonth(cursor.getMonth() + 1)
  }

  return keys
}

function sumValues(list) {
  return list.reduce((acc, val) => acc + Number(val || 0), 0)
}

function round2(value) {
  return Number(Number(value || 0).toFixed(2))
}

function formatCount(value) {
  return Number(value || 0).toLocaleString('id-ID')
}

function formatPercent(value) {
  const num = Number(value || 0)
  return `${num.toFixed(1)}%`
}

function formatRp(value) {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    maximumFractionDigits: 0,
  }).format(Number(value || 0))
}

function formatCompactRp(value) {
  const num = Number(value || 0)
  const abs = Math.abs(num)

  if (abs >= 1_000_000_000) {
    return `Rp ${(num / 1_000_000_000).toFixed(1)} M`
  }
  if (abs >= 1_000_000) {
    return `Rp ${(num / 1_000_000).toFixed(1)} jt`
  }
  if (abs >= 1_000) {
    return `Rp ${(num / 1_000).toFixed(0)} rb`
  }

  return `Rp ${Math.round(num)}`
}

function isMissingRelationError(error) {
  const message = String(error?.message || '').toLowerCase()
  const code = String(error?.code || '')

  return (
    code === '42P01'
    || code === 'PGRST205'
    || message.includes('does not exist')
    || message.includes('could not find the table')
  )
}

function rememberWarning(schemaKey) {
  if (schemaWarnings.value.includes(schemaKey)) return
  schemaWarnings.value = [...schemaWarnings.value, schemaKey]
}

async function safeSelectRows(schemaKey, columns, mutateQuery = null) {
  let query = supabase.from(schemaKey).select(columns)
  if (typeof mutateQuery === 'function') {
    query = mutateQuery(query)
  }

  const { data, error } = await query
  if (error) {
    if (isMissingRelationError(error)) {
      rememberWarning(schemaKey)
      return []
    }
    throw error
  }

  return data || []
}

async function safeCountRows(schemaKey, mutateQuery = null) {
  let query = supabase.from(schemaKey).select('id', { count: 'exact', head: true })
  if (typeof mutateQuery === 'function') {
    query = mutateQuery(query)
  }

  const { count, error } = await query
  if (error) {
    if (isMissingRelationError(error)) {
      rememberWarning(schemaKey)
      return 0
    }
    throw error
  }

  return Number(count || 0)
}

async function fetchSaleItemsBySaleIds(saleIds) {
  if (!saleIds.length) return []

  const chunkSize = 150
  const rows = []

  for (let i = 0; i < saleIds.length; i += chunkSize) {
    const chunkIds = saleIds.slice(i, i + chunkSize)
    const { data, error } = await supabase
      .from('sale_items')
      .select('sale_id, product_id, qty')
      .in('sale_id', chunkIds)

    if (error) throw error
    rows.push(...(data || []))
  }

  return rows
}

function destroyCharts() {
  Object.keys(chartInstances).forEach((key) => {
    if (chartInstances[key]) {
      chartInstances[key].destroy()
      chartInstances[key] = null
    }
  })
}

function renderCharts() {
  destroyCharts()

  const sharedLegend = {
    labels: {
      usePointStyle: true,
      boxWidth: 8,
      padding: 16,
      color: '#334155',
      font: {
        size: 11,
      },
    },
  }

  if (salesPurchaseCanvas.value) {
    chartInstances.salesPurchase = new Chart(salesPurchaseCanvas.value, {
      type: 'line',
      data: {
        labels: chartModel.value.labels,
        datasets: [
          {
            label: 'Omzet Penjualan',
            data: chartModel.value.salesSeries,
            borderColor: '#2563eb',
            backgroundColor: 'rgba(37, 99, 235, 0.16)',
            borderWidth: 2.3,
            pointRadius: 2,
            tension: 0.34,
            fill: true,
          },
          {
            label: 'Nilai Pembelian',
            data: chartModel.value.purchaseSeries,
            borderColor: '#f59e0b',
            backgroundColor: 'rgba(245, 158, 11, 0.14)',
            borderWidth: 2.3,
            pointRadius: 2,
            tension: 0.34,
            fill: true,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: sharedLegend,
        },
        scales: {
          y: {
            grid: { color: 'rgba(148, 163, 184, 0.18)' },
            ticks: {
              color: '#475569',
              callback: (val) => formatCompactRp(val),
            },
          },
          x: {
            grid: { display: false },
            ticks: { color: '#475569' },
          },
        },
      },
    })
  }

  if (stockHealthCanvas.value) {
    chartInstances.stockHealth = new Chart(stockHealthCanvas.value, {
      type: 'doughnut',
      data: {
        labels: ['Aman', 'Kritis', 'Habis'],
        datasets: [
          {
            data: chartModel.value.stockSeries,
            backgroundColor: ['#10b981', '#f59e0b', '#ef4444'],
            borderColor: '#ffffff',
            borderWidth: 2,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: '62%',
        plugins: {
          legend: {
            ...sharedLegend,
            position: 'bottom',
          },
        },
      },
    })
  }

  if (penagihanCanvas.value) {
    chartInstances.penagihan = new Chart(penagihanCanvas.value, {
      type: 'doughnut',
      data: {
        labels: ['Paid', 'Partial', 'Unpaid', 'Cash'],
        datasets: [
          {
            data: chartModel.value.penagihanSeries,
            backgroundColor: ['#0ea5e9', '#f59e0b', '#ef4444', '#14b8a6'],
            borderColor: '#ffffff',
            borderWidth: 2,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: '62%',
        plugins: {
          legend: {
            ...sharedLegend,
            position: 'bottom',
          },
        },
      },
    })
  }

  if (hppCanvas.value) {
    chartInstances.hpp = new Chart(hppCanvas.value, {
      type: 'bar',
      data: {
        labels: chartModel.value.labels,
        datasets: [
          {
            label: 'Omzet',
            data: chartModel.value.salesSeries,
            backgroundColor: 'rgba(37, 99, 235, 0.78)',
            borderRadius: 7,
            maxBarThickness: 26,
          },
          {
            label: 'HPP Estimasi',
            data: chartModel.value.hppSeries,
            backgroundColor: 'rgba(16, 185, 129, 0.82)',
            borderRadius: 7,
            maxBarThickness: 26,
          },
          {
            type: 'line',
            label: 'Margin %',
            data: chartModel.value.marginPctSeries,
            yAxisID: 'y1',
            borderColor: '#f97316',
            backgroundColor: '#f97316',
            borderWidth: 2,
            pointRadius: 2,
            pointHoverRadius: 4,
            tension: 0.33,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: sharedLegend,
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: { color: 'rgba(148, 163, 184, 0.18)' },
            ticks: {
              color: '#475569',
              callback: (val) => formatCompactRp(val),
            },
          },
          y1: {
            position: 'right',
            beginAtZero: true,
            suggestedMax: 100,
            grid: { drawOnChartArea: false },
            ticks: {
              color: '#475569',
              callback: (val) => `${val}%`,
            },
          },
          x: {
            grid: { display: false },
            ticks: { color: '#475569' },
          },
        },
      },
    })
  }

  if (activityCanvas.value) {
    chartInstances.activity = new Chart(activityCanvas.value, {
      type: 'bar',
      data: {
        labels: ['Penjualan', 'Pembelian', 'Pembayaran', 'Adj. Stok'],
        datasets: [
          {
            label: 'Jumlah Aktivitas',
            data: chartModel.value.activitySeries,
            backgroundColor: ['#2563eb', '#f59e0b', '#14b8a6', '#64748b'],
            borderRadius: 8,
            maxBarThickness: 44,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              color: '#475569',
              precision: 0,
            },
            grid: { color: 'rgba(148, 163, 184, 0.18)' },
          },
          x: {
            ticks: { color: '#475569' },
            grid: { display: false },
          },
        },
      },
    })
  }
}

function navigateToModule(index) {
  const selected = moduleLinks[index]
  if (!selected) return
  selectedQuickIndex.value = index
  router.push(selected.route)
}

function showShortcutHelp() {
  toast.add({
    severity: 'info',
    summary: 'Shortcut Dashboard',
    detail: '1-6: buka modul | Enter: refresh | Esc: reset filter | F1: bantuan',
    life: 2600,
  })
}

function handleKeydown(event) {
  const tagName = event.target?.tagName
  if (tagName === 'INPUT' || tagName === 'TEXTAREA' || tagName === 'SELECT') {
    return
  }

  if (event.key === 'F1') {
    event.preventDefault()
    showShortcutHelp()
    return
  }

  if (event.key === 'Enter') {
    event.preventDefault()
    loadDashboardData()
    return
  }

  if (event.key === 'Escape') {
    event.preventDefault()
    if (activeRange.value !== 90) {
      activeRange.value = 90
    }
    loadDashboardData()
    return
  }

  if (event.key >= '1' && event.key <= '9') {
    const index = Number(event.key) - 1
    if (index < moduleLinks.length) {
      event.preventDefault()
      navigateToModule(index)
    }
  }
}

function setRange(days) {
  if (activeRange.value === days) return
  activeRange.value = days
  loadDashboardData()
}

async function loadDashboardData() {
  if (loading.value) return

  loading.value = true
  loadError.value = ''
  schemaWarnings.value = []

  try {
    const now = new Date()
    const startDate = getStartDate(activeRange.value)
    const startDateStr = toDateOnly(startDate)

    const [salesRes, purchasesRes, productsRes, customerCountRes, supplierCountRes] = await Promise.all([
      supabase
        .from('sales')
        .select('id, order_date, subtotal, extra_charge_amount')
        .eq('status', 'completed')
        .gte('order_date', startDateStr)
        .order('order_date', { ascending: true }),
      supabase
        .from('purchases')
        .select('id, order_date, subtotal, status')
        .neq('status', 'draft')
        .gte('order_date', startDateStr)
        .order('order_date', { ascending: true }),
      supabase
        .from('products')
        .select('id, stok, is_archived')
        .eq('is_archived', false),
      supabase
        .from('customers')
        .select('id', { count: 'exact', head: true })
        .eq('aktif', true),
      supabase
        .from('suppliers')
        .select('id', { count: 'exact', head: true })
        .eq('aktif', true),
    ])

    if (salesRes.error) throw salesRes.error
    if (purchasesRes.error) throw purchasesRes.error
    if (productsRes.error) throw productsRes.error
    if (customerCountRes.error) throw customerCountRes.error
    if (supplierCountRes.error) throw supplierCountRes.error

    const salesRows = salesRes.data || []
    const purchasesRows = purchasesRes.data || []
    const productsRows = productsRes.data || []

    const saleItemsRows = await fetchSaleItemsBySaleIds(salesRows.map((row) => row.id))

    const [penagihanRows, paymentRows, productPricesRows, stockAdjustmentCount] = await Promise.all([
      safeSelectRows('v_penagihan_sales', 'payment_status, outstanding_amount, is_overdue, is_credit'),
      safeSelectRows('sales_payments', 'payment_date, amount', (query) => query
        .gte('payment_date', startDateStr)
        .order('payment_date', { ascending: true })),
      safeSelectRows('product_prices', 'product_id, harga_beli, updated_at', (query) => query
        .eq('aktif', true)
        .order('updated_at', { ascending: false })),
      safeCountRows('stock_adjustments', (query) => query.gte('adjustment_date', startDateStr)),
    ])

    const monthKeys = buildMonthKeys(startDate, now)
    const labels = monthKeys.map(monthKeyToLabel)

    const salesByMonth = new Map(monthKeys.map((key) => [key, 0]))
    const purchaseByMonth = new Map(monthKeys.map((key) => [key, 0]))
    const hppByMonth = new Map(monthKeys.map((key) => [key, 0]))
    const salesById = new Map()

    for (const row of salesRows) {
      const monthKey = String(row.order_date || '').slice(0, 7)
      if (!salesByMonth.has(monthKey)) continue

      const grandTotal = Number(row.subtotal || 0) + Number(row.extra_charge_amount || 0)
      salesByMonth.set(monthKey, salesByMonth.get(monthKey) + grandTotal)
      salesById.set(row.id, row)
    }

    for (const row of purchasesRows) {
      const monthKey = String(row.order_date || '').slice(0, 7)
      if (!purchaseByMonth.has(monthKey)) continue

      purchaseByMonth.set(monthKey, purchaseByMonth.get(monthKey) + Number(row.subtotal || 0))
    }

    const latestCostByProduct = new Map()
    for (const row of productPricesRows) {
      if (!row.product_id) continue
      if (latestCostByProduct.has(row.product_id)) continue
      latestCostByProduct.set(row.product_id, Number(row.harga_beli || 0))
    }

    for (const item of saleItemsRows) {
      const saleRow = salesById.get(item.sale_id)
      if (!saleRow) continue

      const monthKey = String(saleRow.order_date || '').slice(0, 7)
      if (!hppByMonth.has(monthKey)) continue

      const qty = Number(item.qty || 0)
      const unitCost = Number(latestCostByProduct.get(item.product_id) || 0)
      hppByMonth.set(monthKey, hppByMonth.get(monthKey) + (qty * unitCost))
    }

    let stockSafe = 0
    let stockLow = 0
    let stockOut = 0

    for (const row of productsRows) {
      const stock = Number(row.stok || 0)
      if (stock <= 0) stockOut += 1
      else if (stock <= 3) stockLow += 1
      else stockSafe += 1
    }

    const paymentStatus = {
      paid: 0,
      partial: 0,
      unpaid: 0,
      cash: 0,
    }

    let outstandingAmount = 0
    let overdueCount = 0

    for (const row of penagihanRows) {
      const status = String(row.payment_status || '')
      if (Object.prototype.hasOwnProperty.call(paymentStatus, status)) {
        paymentStatus[status] += 1
      }

      outstandingAmount += Number(row.outstanding_amount || 0)
      if (row.is_overdue) overdueCount += 1
    }

    const salesSeries = monthKeys.map((key) => round2(salesByMonth.get(key)))
    const purchaseSeries = monthKeys.map((key) => round2(purchaseByMonth.get(key)))
    const hppSeries = monthKeys.map((key) => round2(hppByMonth.get(key)))
    const marginPctSeries = monthKeys.map((key) => {
      const omzet = Number(salesByMonth.get(key) || 0)
      const hpp = Number(hppByMonth.get(key) || 0)
      if (omzet <= 0) return 0
      return round2(((omzet - hpp) / omzet) * 100)
    })

    const omzetTotal = sumValues(salesSeries)
    const pembelianTotal = sumValues(purchaseSeries)
    const hppTotal = sumValues(hppSeries)
    const cashInTotal = sumValues(paymentRows.map((row) => Number(row.amount || 0)))

    kpi.value = {
      omzet: omzetTotal,
      pembelian: pembelianTotal,
      hpp: hppTotal,
      marginPct: omzetTotal > 0 ? ((omzetTotal - hppTotal) / omzetTotal) * 100 : 0,
      outstanding: outstandingAmount,
      overdueCount,
      lowStockCount: stockLow + stockOut,
      cashIn: cashInTotal,
      activeCustomers: Number(customerCountRes.count || 0),
      activeSuppliers: Number(supplierCountRes.count || 0),
    }

    chartModel.value = {
      labels,
      salesSeries,
      purchaseSeries,
      hppSeries,
      marginPctSeries,
      stockSeries: [stockSafe, stockLow, stockOut],
      penagihanSeries: [
        paymentStatus.paid,
        paymentStatus.partial,
        paymentStatus.unpaid,
        paymentStatus.cash,
      ],
      activitySeries: [
        salesRows.length,
        purchasesRows.length,
        paymentRows.length,
        stockAdjustmentCount,
      ],
    }

    lastUpdatedAt.value = new Date().toISOString()

    await nextTick()
    renderCharts()

    if (schemaWarnings.value.length) {
      toast.add({
        severity: 'warn',
        summary: 'Sebagian Data Fallback',
        detail: `Modul fallback: ${schemaWarningsText.value}`,
        life: 3600,
      })
    }
  } catch (error) {
    console.error('[DashboardPage.loadDashboardData]', error)
    loadError.value = String(error?.message || error || 'Gagal memuat data dashboard.')
    toast.add({
      severity: 'error',
      summary: 'Dashboard Gagal Dimuat',
      detail: loadError.value,
      life: 3400,
    })
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  pageEl.value?.focus()
  window.addEventListener('keydown', handleKeydown)
  await loadDashboardData()
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
  destroyCharts()
})
</script>

<style scoped>
@import '@/assets/pages/Dashboard/dashboard-page.css';
</style>
