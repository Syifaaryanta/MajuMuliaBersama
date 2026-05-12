<template>
  <div class="laporan-detail" ref="pageEl" tabindex="-1">
    <div class="g-header laporan-detail-header">
      <div class="g-header-left">
        <h1 class="g-title">Penagihan dan Piutang</h1>
        <p class="g-subtitle">Kontrol piutang dan jatuh tempo pembayaran customer.</p>
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
        <h3>Daftar Piutang</h3>
        <div class="table-wrap">
          <table class="g-table">
            <thead>
              <tr>
                <th>Tanggal</th>
                <th>No Order</th>
                <th>Customer</th>
                <th>Jatuh Tempo</th>
                <th>Total</th>
                <th>Terbayar</th>
                <th>Sisa</th>
                <th>Status</th>
                <th>Overdue (hari)</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in billingRows" :key="row.saleId">
                <td>{{ row.orderDate }}</td>
                <td>{{ row.noOrder }}</td>
                <td>{{ row.customer }}</td>
                <td>{{ row.dueDate }}</td>
                <td>{{ formatRp(row.total) }}</td>
                <td>{{ formatRp(row.paid) }}</td>
                <td>{{ formatRp(row.outstanding) }}</td>
                <td>{{ row.statusLabel }}</td>
                <td>{{ row.overdueDays }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </article>

      <article class="laporan-detail-card" v-if="paymentRows.length">
        <h3>Pembayaran Per Periode</h3>
        <div class="table-wrap">
          <table class="g-table">
            <thead>
              <tr>
                <th>Tanggal</th>
                <th>No Order</th>
                <th>Customer</th>
                <th>Metode</th>
                <th>Nominal</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in paymentRows" :key="row.id">
                <td>{{ row.paymentDate }}</td>
                <td>{{ row.noOrder }}</td>
                <td>{{ row.customer }}</td>
                <td>{{ row.method }}</td>
                <td>{{ formatRp(row.amount) }}</td>
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
import { formatRp, formatDate, paymentStatusLabel, paymentMethodLabel, toIsoDate } from '@/lib/penagihanService'
import { exportWorkbook } from '@/lib/reportingExport'

const router = useRouter()
const route = useRoute()
const pageEl = ref(null)
const startInputRef = ref(null)
const loading = ref(false)
const error = ref('')
const billingRows = ref([])
const paymentRows = ref([])

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
    const [billingResp, paymentResp] = await Promise.all([
      supabase
        .from('v_penagihan_sales')
        .select('*')
        .gte('order_date', startDate)
        .lte('order_date', endDate)
        .order('order_date', { ascending: false }),
      supabase
        .from('v_penagihan_payments')
        .select('*')
        .gte('payment_date', startDate)
        .lte('payment_date', endDate)
        .order('payment_date', { ascending: false }),
    ])

    if (billingResp.error) throw billingResp.error
    if (paymentResp.error) throw paymentResp.error

    billingRows.value = (billingResp.data || []).map(row => ({
      saleId: row.sale_id,
      orderDate: formatDate(row.order_date),
      noOrder: row.no_order,
      customer: row.customer_nama,
      dueDate: formatDate(row.due_date),
      total: Number(row.grand_total || 0),
      paid: Number(row.total_paid || 0),
      outstanding: Number(row.outstanding_amount || 0),
      statusLabel: paymentStatusLabel(row.payment_status),
      overdueDays: Number(row.overdue_days || 0),
    }))

    paymentRows.value = (paymentResp.data || []).map(row => ({
      id: row.id,
      paymentDate: formatDate(row.payment_date),
      noOrder: row.no_order,
      customer: row.customer_nama,
      method: paymentMethodLabel(row.payment_method),
      amount: Number(row.amount || 0),
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
    fileName: 'laporan-penagihan-piutang',
    sheets: [
      {
        name: 'Piutang',
        columns: [
          { header: 'Tanggal', key: 'orderDate', width: 16 },
          { header: 'No Order', key: 'noOrder', width: 16 },
          { header: 'Customer', key: 'customer', width: 24 },
          { header: 'Jatuh Tempo', key: 'dueDate', width: 16 },
          { header: 'Total', key: 'total', width: 16 },
          { header: 'Terbayar', key: 'paid', width: 16 },
          { header: 'Sisa', key: 'outstanding', width: 16 },
          { header: 'Status', key: 'statusLabel', width: 14 },
          { header: 'Overdue (hari)', key: 'overdueDays', width: 14 },
        ],
        rows: billingRows.value,
      },
      {
        name: 'Pembayaran',
        columns: [
          { header: 'Tanggal', key: 'paymentDate', width: 16 },
          { header: 'No Order', key: 'noOrder', width: 16 },
          { header: 'Customer', key: 'customer', width: 24 },
          { header: 'Metode', key: 'method', width: 14 },
          { header: 'Nominal', key: 'amount', width: 16 },
        ],
        rows: paymentRows.value,
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
