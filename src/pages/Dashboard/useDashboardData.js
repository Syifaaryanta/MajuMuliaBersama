import { computed, nextTick, onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { Chart, registerables } from 'chart.js'
import { supabase } from '@/lib/supabase'
import { stockCategoryGroups } from './dashboardCategories'

Chart.register(...registerables)

export function useDashboardData() {
  const router = useRouter()
  const toast = useToast()

  const pageEl = ref(null)
  const loading = ref(false)
  const loadError = ref('')
  const lastUpdatedAt = ref(null)
  const schemaWarnings = ref([])

  const defaultRangeKey = 'month-1'
  const activeRange = ref(defaultRangeKey)
  const rangeOptions = [
    { key: 'month-1', label: '30 Hari', months: 1 },
    { key: 'month-6', label: '6 Bulan', months: 6 },
    { key: 'month-12', label: '1 Tahun', months: 12 },
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
    omzetHppSeries: [],
  })

  const soldTodaySummary = ref([])
  const salesTodaySummary = ref([])
  const monthlySalesTarget = 1_000_000_000
  const calendarWeekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
  const salesCalendar = ref({
    monthLabel: '',
    dailyTarget: 0,
    cells: [],
  })

  const salesPurchaseCanvas = ref(null)

  const chartInstances = {
    salesPurchase: null,
  }

  const selectedRangeLabel = computed(() => {
    const found = rangeOptions.find((item) => item.key === activeRange.value)
    return found ? found.label : '30 Hari'
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

  function getRangeStartDate(rangeKey) {
    const option = rangeOptions.find((item) => item.key === rangeKey)
    const months = option?.months || 1
    const now = new Date()
    now.setHours(0, 0, 0, 0)

    const start = new Date(now.getFullYear(), now.getMonth(), 1)
    start.setMonth(start.getMonth() - (months - 1))
    return start
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

  function normalizeKey(value) {
    return String(value || '')
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim()
  }

  function matchPrefix(value, matcher) {
    return value === matcher || value.startsWith(`${matcher} `)
  }

  function buildCategoryMatcherList() {
    const list = []

    stockCategoryGroups.forEach((group) => {
      group.items.forEach((item) => {
        const matchers = (item.matchers || [item.label])
          .map(normalizeKey)
          .filter(Boolean)
        if (!matchers.length) return

        const maxWords = Math.max(...matchers.map((matcher) => matcher.split(' ').length))
        list.push({
          label: item.label,
          level: group.level || 0,
          matchers,
          maxWords,
        })
      })
    })

    list.sort((a, b) => {
      if (b.level !== a.level) return b.level - a.level
      return b.maxWords - a.maxWords
    })

    return list
  }

  function buildSoldTodaySummary(salesRows, saleItemsRows) {
    const todayKey = toDateOnly(new Date())
    const salesDateMap = new Map(
      salesRows.map((row) => [row.id, String(row.order_date || '').slice(0, 10)])
    )
    const matcherList = buildCategoryMatcherList()
    const totals = new Map()
    let otherQty = 0

    saleItemsRows.forEach((item) => {
      const saleDate = salesDateMap.get(item.sale_id)
      if (saleDate !== todayKey) return

      const qty = Number(item.qty || 0)
      if (!Number.isFinite(qty) || qty <= 0) return

      const nameKey = normalizeKey(item.product_nama)
      let label = ''

      if (nameKey) {
        for (const def of matcherList) {
          if (def.matchers.some((matcher) => matchPrefix(nameKey, matcher))) {
            label = def.label
            break
          }
        }
      }

      if (!label) {
        otherQty += qty
        return
      }

      totals.set(label, (totals.get(label) || 0) + qty)
    })

    const summary = []
    stockCategoryGroups.forEach((group) => {
      group.items.forEach((item) => {
        const qty = totals.get(item.label)
        if (!qty) return
        summary.push({ label: item.label, qty })
      })
    })

    if (otherQty > 0) {
      summary.push({ label: 'Lainnya', qty: otherQty })
    }

    return summary
  }

  function buildSalesTodaySummary(salesRows) {
    const todayKey = toDateOnly(new Date())
    const totals = new Map()

    salesRows.forEach((row) => {
      const orderDate = String(row.order_date || '').slice(0, 10)
      if (orderDate !== todayKey) return

      const name = String(row.customer_nama || '-').trim() || '-'
      const subtotal = Number(row.subtotal || 0)
      if (!Number.isFinite(subtotal)) return
      totals.set(name, (totals.get(name) || 0) + subtotal)
    })

    return Array.from(totals.entries())
      .map(([name, subtotal]) => ({ name, subtotal }))
      .sort((a, b) => {
        if (b.subtotal !== a.subtotal) return b.subtotal - a.subtotal
        return a.name.localeCompare(b.name, 'id-ID')
      })
  }

  function buildSalesCalendar(salesRows) {
    const now = new Date()
    const year = now.getFullYear()
    const monthIndex = now.getMonth()
    const daysInMonth = new Date(year, monthIndex + 1, 0).getDate()
    const firstDay = new Date(year, monthIndex, 1).getDay()
    const startOffset = (firstDay + 6) % 7
    const dailyTarget = monthlySalesTarget / daysInMonth
    const totals = new Map()

    salesRows.forEach((row) => {
      const orderDate = String(row.order_date || '')
      if (!orderDate) return

      const [y, m, d] = orderDate.split('-').map(Number)
      if (y !== year || m !== monthIndex + 1) return

      const amount = Number(row.subtotal || 0) + Number(row.extra_charge_amount || 0)
      if (!Number.isFinite(amount)) return

      totals.set(d, (totals.get(d) || 0) + amount)
    })

    const cells = []
    for (let i = 0; i < startOffset; i += 1) {
      cells.push({ key: `empty-${i}`, inMonth: false })
    }

    for (let day = 1; day <= daysInMonth; day += 1) {
      const amount = totals.get(day) || 0
      const ratio = dailyTarget > 0 ? amount / dailyTarget : 0
      const isFuture = day > now.getDate()
      let level = 'low'
      if (isFuture) level = 'future'
      else if (ratio >= 1) level = 'high'
      else if (ratio >= 0.5) level = 'mid'

      cells.push({
        key: `day-${day}`,
        inMonth: true,
        day,
        amount,
        level,
        isToday: day === now.getDate(),
      })
    }

    while (cells.length % 7 !== 0) {
      cells.push({ key: `empty-tail-${cells.length}`, inMonth: false })
    }

    const monthLabel = new Date(year, monthIndex, 1).toLocaleDateString('id-ID', {
      month: 'long',
      year: 'numeric',
    })

    return {
      monthLabel,
      dailyTarget,
      cells,
    }
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

  async function fetchSaleItemsBySaleIds(saleIds) {
    if (!saleIds.length) return []

    const chunkSize = 150
    const rows = []

    for (let i = 0; i < saleIds.length; i += chunkSize) {
      const chunkIds = saleIds.slice(i, i + chunkSize)
      const { data, error } = await supabase
        .from('sale_items')
        .select('sale_id, product_id, product_nama, qty')
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
              label: 'Penjualan',
              data: chartModel.value.salesSeries,
              borderColor: '#2563eb',
              backgroundColor: 'rgba(37, 99, 235, 0.16)',
              borderWidth: 2.3,
              pointRadius: 2,
              tension: 0.34,
              fill: true,
            },
            {
              label: 'Pembelian',
              data: chartModel.value.purchaseSeries,
              borderColor: '#f59e0b',
              backgroundColor: 'rgba(245, 158, 11, 0.14)',
              borderWidth: 2.3,
              pointRadius: 2,
              tension: 0.34,
              fill: true,
            },
            {
              label: 'Omzet/HPP',
              data: chartModel.value.omzetHppSeries,
              yAxisID: 'y1',
              borderColor: '#16a34a',
              backgroundColor: 'rgba(22, 163, 74, 0.12)',
              borderWidth: 2.3,
              pointRadius: 2,
              tension: 0.34,
              fill: false,
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
            y1: {
              position: 'right',
              beginAtZero: true,
              suggestedMax: 3,
              grid: { drawOnChartArea: false },
              ticks: {
                color: '#475569',
                callback: (val) => `${val}x`,
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
  }

  function navigateToModule(index) {
    const selected = moduleLinks[index]
    if (!selected) return
    selectedQuickIndex.value = index
    router.push(selected.route)
  }

  function handleKeydown(event) {
    const tagName = event.target?.tagName
    if (tagName === 'INPUT' || tagName === 'TEXTAREA' || tagName === 'SELECT') {
      return
    }

    if (event.key === 'F1') {
      event.preventDefault()
      setRange('month-1')
      return
    }

    if (event.key === 'F2') {
      event.preventDefault()
      setRange('month-6')
      return
    }

    if (event.key === 'F3') {
      event.preventDefault()
      setRange('month-12')
      return
    }

    if (event.key === 'F5') {
      event.preventDefault()
      loadDashboardData()
      return
    }

    if (event.key === 'Escape') {
      event.preventDefault()
      if (activeRange.value !== defaultRangeKey) {
        activeRange.value = defaultRangeKey
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

  function setRange(rangeKey) {
    if (activeRange.value === rangeKey) return
    activeRange.value = rangeKey
    loadDashboardData()
  }

  async function loadDashboardData() {
    if (loading.value) return

    loading.value = true
    loadError.value = ''
    schemaWarnings.value = []

    try {
      const now = new Date()
      const startDate = getRangeStartDate(activeRange.value)
      const startDateStr = toDateOnly(startDate)

      const [salesRes, purchasesRes, productsRes, customerCountRes, supplierCountRes] = await Promise.all([
        supabase
          .from('sales')
          .select('id, order_date, customer_nama, subtotal, extra_charge_amount')
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
          .select('id, nama, stok, is_archived')
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

      const [penagihanRows, paymentRows, productPricesRows] = await Promise.all([
        safeSelectRows('v_penagihan_sales', 'payment_status, outstanding_amount, is_overdue, is_credit'),
        safeSelectRows('sales_payments', 'payment_date, amount', (query) => query
          .gte('payment_date', startDateStr)
          .order('payment_date', { ascending: true })),
        safeSelectRows('product_prices', 'product_id, harga_beli, updated_at', (query) => query
          .eq('aktif', true)
          .order('updated_at', { ascending: false })),
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
        else if (stock <= 2) stockLow += 1
        else stockSafe += 1
      }

      soldTodaySummary.value = buildSoldTodaySummary(salesRows, saleItemsRows)
      salesTodaySummary.value = buildSalesTodaySummary(salesRows)
      salesCalendar.value = buildSalesCalendar(salesRows)

      let outstandingAmount = 0
      let overdueCount = 0

      for (const row of penagihanRows) {
        outstandingAmount += Number(row.outstanding_amount || 0)
        if (row.is_overdue) overdueCount += 1
      }

      const salesSeries = monthKeys.map((key) => round2(salesByMonth.get(key)))
      const purchaseSeries = monthKeys.map((key) => round2(purchaseByMonth.get(key)))
      const hppSeries = monthKeys.map((key) => round2(hppByMonth.get(key)))
      const omzetHppSeries = monthKeys.map((key) => {
        const omzet = Number(salesByMonth.get(key) || 0)
        const hpp = Number(hppByMonth.get(key) || 0)
        if (hpp <= 0) return 0
        return round2(omzet / hpp)
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
        omzetHppSeries,
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

  return {
    router,
    pageEl,
    loading,
    loadError,
    lastUpdatedLabel,
    schemaWarnings,
    schemaWarningsText,
    rangeOptions,
    activeRange,
    selectedRangeLabel,
    setRange,
    moduleLinks,
    selectedQuickIndex,
    navigateToModule,
    kpi,
    formatRp,
    formatPercent,
    formatCount,
    formatCompactRp,
    salesPurchaseCanvas,
    soldTodaySummary,
    salesTodaySummary,
    monthlySalesTarget,
    calendarWeekdays,
    salesCalendar,
  }
}
