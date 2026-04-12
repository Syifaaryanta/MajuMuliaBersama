<template>
  <div class="penagihan-sub-page penagihan-riwayat-page" ref="pageEl" tabindex="-1">
    <Toast position="top-right" />

    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Riwayat Bayar</h1>
        <p class="g-subtitle">Log seluruh cicilan dan pelunasan customer dari menu Piutang Aktif</p>
      </div>
    </div>

    <div class="shortcut-strip">
      <kbd>F1 Cari</kbd>
      <kbd>Arrow Pilih Baris</kbd>
      <kbd>Enter Detail</kbd>
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
      <div class="toolbar-card">
        <div class="search-field toolbar-search">
          <label class="search-label">
            No. Order / Customer / Catatan
            <kbd class="label-kbd">F1</kbd>
          </label>
          <div class="search-input-wrap" :class="{ focused: focusKey === 'search' }">
            <i class="pi pi-search si-icon"></i>
            <input
              ref="searchInput"
              v-model="searchQuery"
              type="text"
              class="search-input"
              placeholder="Ketik untuk filter data..."
              @focus="focusKey = 'search'"
              @blur="focusKey = ''"
            />
            <button v-if="searchQuery" class="clear-btn" @click="searchQuery = ''" tabindex="-1">
              <i class="pi pi-times"></i>
            </button>
          </div>
        </div>

        <div class="toolbar-actions toolbar-actions--riwayat">
          <div class="filter-chip-group">
            <button
              v-for="chip in periodOptions"
              :key="chip.id"
              type="button"
              class="filter-chip"
              :class="{ 'filter-chip--active': activePeriod === chip.id }"
              @click="activePeriod = chip.id"
            >
              {{ chip.label }}
            </button>
          </div>

          <div class="method-filter-wrap">
            <span class="method-filter-label">Metode</span>
            <select v-model="methodFilter" class="method-filter-input">
              <option value="all">Semua</option>
              <option v-for="item in paymentMethodOptions" :key="item.value" :value="item.value">
                {{ item.label }}
              </option>
            </select>
          </div>
        </div>
      </div>

      <div class="table-section">
        <div class="result-meta">
          <span class="result-count"><b>{{ rows.length }}</b> pembayaran tampil</span>
          <span class="page-info">Total nominal: <b>{{ formatRp(totalPaymentAmount) }}</b></span>
        </div>

        <div class="table-wrap">
          <table class="g-table">
            <thead>
              <tr>
                <th class="col-no">#</th>
                <th class="col-date">Tanggal</th>
                <th class="col-order">No. Order</th>
                <th class="col-customer">Customer</th>
                <th class="col-method">Metode</th>
                <th class="col-money">Nominal</th>
                <th class="col-note">Catatan</th>
                <th class="col-aksi">Aksi</th>
              </tr>
            </thead>
            <tbody v-if="loading">
              <tr v-for="n in 6" :key="`loading-${n}`">
                <td colspan="8"><div class="skeleton"></div></td>
              </tr>
            </tbody>
            <tbody v-else-if="rows.length === 0">
              <tr>
                <td colspan="8" class="empty-cell">
                  <i class="pi pi-inbox"></i>
                  Belum ada data pembayaran sesuai filter.
                </td>
              </tr>
            </tbody>
            <tbody v-else>
              <tr
                v-for="(row, idx) in rows"
                :key="row.id"
                :ref="el => setRowRef(el, idx)"
                :class="{ 'g-row--active': selectedRowIndex === idx }"
                @click="selectedRowIndex = idx"
                @dblclick="openDetailModal(row)"
              >
                <td class="col-no">{{ idx + 1 }}</td>
                <td class="col-date">{{ formatDate(row.payment_date) }}</td>
                <td class="col-order">
                  <span class="kode-badge">{{ row.no_order }}</span>
                  <div class="row-sub">Fraktur: {{ row.no_faktur || '-' }}</div>
                </td>
                <td class="col-customer">
                  <div class="customer-cell">
                    <span class="customer-name">{{ row.customer_nama }}</span>
                    <span class="customer-addr">{{ getSaleAddress(row.sale_id) }}</span>
                  </div>
                </td>
                <td class="col-method">{{ paymentMethodLabel(row.payment_method) }}</td>
                <td class="col-money"><span class="harga-val">{{ formatRp(row.amount) }}</span></td>
                <td class="col-note">{{ row.note || '-' }}</td>
                <td class="col-aksi">
                  <div class="aksi-wrap">
                    <button class="aksi-btn aksi-view" @click.stop="openDetailModal(row)">
                      <i class="pi pi-eye"></i>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </template>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="detailModal.show" class="modal-overlay" @click.self="closeDetailModal">
          <div class="modal-box modal-box--detail" role="dialog" aria-label="Detail pembayaran customer">
            <div class="modal-header">
              <h3 class="modal-title">Detail Pembayaran: {{ detailModal.payment?.no_order }}</h3>
              <button class="modal-close" @click="closeDetailModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>

            <div class="modal-body" v-if="detailModal.payment">
              <div class="detail-grid">
                <div class="detail-card">
                  <span class="detail-label">Customer</span>
                  <strong class="detail-value">{{ detailModal.payment.customer_nama }}</strong>
                  <span class="detail-sub">{{ detailModal.sale?.customer_alamat || '-' }}</span>
                </div>
                <div class="detail-card">
                  <span class="detail-label">Pembayaran</span>
                  <strong class="detail-value">{{ formatDate(detailModal.payment.payment_date) }}</strong>
                  <span class="detail-sub">Metode: {{ paymentMethodLabel(detailModal.payment.payment_method) }}</span>
                </div>
                <div class="detail-card">
                  <span class="detail-label">Nominal Bayar</span>
                  <strong class="detail-value">{{ formatRp(detailModal.payment.amount) }}</strong>
                  <span class="detail-sub">No. Order: {{ detailModal.payment.no_order }}</span>
                </div>
                <div class="detail-card">
                  <span class="detail-label">Status Tagihan Saat Ini</span>
                  <strong class="detail-value">
                    {{ detailModal.sale ? formatRp(detailModal.sale.outstanding_amount) : '-' }}
                  </strong>
                  <span class="detail-sub" v-if="detailModal.sale">
                    {{ paymentStatusLabel(detailModal.sale.payment_status) }}
                  </span>
                </div>
                <div class="detail-card detail-card--full">
                  <span class="detail-label">Catatan</span>
                  <strong class="detail-value">{{ detailModal.payment.note || '-' }}</strong>
                </div>
              </div>
            </div>

            <div class="modal-footer">
              <button class="btn-secondary" @click="closeDetailModal">Tutup <kbd>Esc</kbd></button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup>
import { computed, nextTick, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import Toast from 'primevue/toast'
import {
  fetchPenagihanBundle,
  filterBySearch,
  paymentMethodOptions,
  paymentMethodLabel,
  paymentStatusLabel,
  formatDate,
  formatRp,
  isSchemaIssue,
  toIsoDate,
  subscribePenagihanAutoSync,
} from '@/lib/penagihanService'

const router = useRouter()
const toast = useToast()

const pageEl = ref(null)
const searchInput = ref(null)
const focusKey = ref('')
const loading = ref(false)
const schemaError = ref('')
const searchQuery = ref('')
const activePeriod = ref('all')
const methodFilter = ref('all')
const selectedRowIndex = ref(0)
const rowRefs = ref({})
let stopAutoSync = () => {}

const paymentRows = ref([])
const salesRows = ref([])

const detailModal = reactive({
  show: false,
  payment: null,
  sale: null,
})

const periodOptions = [
  { id: 'all', label: 'Semua Periode' },
  { id: 'today', label: 'Hari Ini' },
  { id: 'week', label: '7 Hari Terakhir' },
  { id: 'month', label: '30 Hari Terakhir' },
]

const saleById = computed(() => {
  const map = new Map()
  for (const row of salesRows.value) {
    map.set(row.sale_id, row)
  }
  return map
})

const rows = computed(() => {
  let data = paymentRows.value.slice()

  if (methodFilter.value !== 'all') {
    data = data.filter(row => String(row.payment_method || '').toLowerCase() === methodFilter.value)
  }

  if (activePeriod.value !== 'all') {
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    data = data.filter(row => {
      if (!row.payment_date) return false
      const paymentDate = new Date(`${row.payment_date}T00:00:00`)
      if (Number.isNaN(paymentDate.getTime())) return false

      const diff = Math.floor((today.getTime() - paymentDate.getTime()) / 86400000)
      if (activePeriod.value === 'today') {
        return String(row.payment_date || '') === toIsoDate(today)
      }
      if (activePeriod.value === 'week') {
        return diff >= 0 && diff <= 7
      }
      if (activePeriod.value === 'month') {
        return diff >= 0 && diff <= 30
      }
      return true
    })
  }

  return filterBySearch(data, searchQuery.value, row => {
    return [row.no_order, row.no_faktur, row.customer_nama, row.note].join(' ')
  })
})

const totalPaymentAmount = computed(() => {
  return rows.value.reduce((sum, row) => sum + Number(row.amount || 0), 0)
})

const selectedRow = computed(() => rows.value[selectedRowIndex.value] || null)

watch(rows, (data) => {
  rowRefs.value = {}

  if (!data.length) {
    selectedRowIndex.value = 0
    return
  }

  if (selectedRowIndex.value >= data.length) {
    selectedRowIndex.value = data.length - 1
  }

  nextTick(() => ensureSelectedRowVisible())
}, { immediate: true })

watch(selectedRowIndex, () => {
  nextTick(() => ensureSelectedRowVisible())
})

async function loadData() {
  loading.value = true
  schemaError.value = ''

  try {
    const { sales, payments } = await fetchPenagihanBundle()
    salesRows.value = sales
    paymentRows.value = payments
  } catch (err) {
    const message = String(err?.message || err || '')
    console.error('[PenagihanRiwayatPage.loadData]', err)

    if (isSchemaIssue(message)) {
      schemaError.value = 'Database belum memiliki view/tabel penagihan terbaru.'
      return
    }

    toast.add({
      severity: 'error',
      summary: 'Gagal Memuat Data',
      detail: message,
      life: 3200,
    })
  } finally {
    loading.value = false
  }
}

function getSaleAddress(saleId) {
  return saleById.value.get(saleId)?.customer_alamat || '-'
}

function setRowRef(el, idx) {
  if (!el) return
  rowRefs.value[idx] = el
}

function ensureSelectedRowVisible() {
  const rowEl = rowRefs.value[selectedRowIndex.value]
  if (!rowEl || typeof rowEl.scrollIntoView !== 'function') return
  rowEl.scrollIntoView({ block: 'nearest' })
}

function moveSelection(delta) {
  if (!rows.value.length) return
  const max = rows.value.length - 1
  selectedRowIndex.value = Math.min(max, Math.max(0, selectedRowIndex.value + delta))
}

function openDetailModal(payment) {
  if (!payment) return
  detailModal.payment = payment
  detailModal.sale = saleById.value.get(payment.sale_id) || null
  detailModal.show = true
}

function closeDetailModal() {
  detailModal.show = false
  detailModal.payment = null
  detailModal.sale = null
  nextTick(() => pageEl.value?.focus())
}

function onGlobalKey(e) {
  if (detailModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      closeDetailModal()
    }
    return
  }

  if (e.key === 'Escape') {
    e.preventDefault()
    router.push('/penagihan')
    return
  }

  if (e.key === 'F1') {
    e.preventDefault()
    focusKey.value = 'search'
    nextTick(() => searchInput.value?.focus())
    return
  }

  const targetTag = e.target?.tagName
  const isTyping = ['INPUT', 'TEXTAREA', 'SELECT'].includes(targetTag)
  if (isTyping) return

  if (e.key === 'ArrowDown') {
    e.preventDefault()
    moveSelection(1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    moveSelection(-1)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (selectedRow.value) openDetailModal(selectedRow.value)
  }
}

onMounted(async () => {
  pageEl.value?.focus()
  window.addEventListener('keydown', onGlobalKey)
  await loadData()
  stopAutoSync = subscribePenagihanAutoSync({
    key: 'riwayat',
    onSync: loadData,
  })
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
  stopAutoSync()
})
</script>

<style scoped>
@import '@/assets/pages/penagihan/penagihan-riwayat-page.css';

.toolbar-actions--riwayat {
  align-items: center;
}

.method-filter-wrap {
  display: flex;
  align-items: center;
  gap: 0.45rem;
}

.method-filter-label {
  font-size: 0.74rem;
  color: #64748b;
  font-weight: 700;
  white-space: nowrap;
}

.method-filter-input {
  min-width: 140px;
  padding: 0.45rem 0.55rem;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  background: #fff;
  color: #1e293b;
  font-size: 0.78rem;
}

.detail-card--full {
  grid-column: 1 / -1;
}

@media (max-width: 1000px) {
  .method-filter-wrap {
    width: 100%;
  }

  .method-filter-input {
    flex: 1;
    min-width: 0;
  }
}
</style>
