<template>
  <div class="penagihan-sub-page penagihan-tunai-page" ref="pageEl" tabindex="-1">
    <Toast position="top-right" />

    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Tunai Selesai</h1>
        <p class="g-subtitle">Monitoring transaksi customer yang dibayar langsung saat penjualan</p>
      </div>
      <span v-if="isReadOnly" class="read-only-badge">
        <i class="pi pi-lock"></i>
        Mode Read Only
      </span>
    </div>

    <div class="shortcut-strip">
      <kbd>F1 Cari</kbd>
      <kbd>Arrow Pilih Baris</kbd>
      <kbd>Enter Detail</kbd>
      <kbd>F4 Normalisasi Nota</kbd>
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
            No. Order / No. Faktur / Customer
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

        <div class="toolbar-actions">
          <div class="filter-chip-group">
            <button
              v-for="chip in filterOptions"
              :key="chip.id"
              type="button"
              class="filter-chip"
              :class="{ 'filter-chip--active': activeFilter === chip.id }"
              @click="activeFilter = chip.id"
            >
              {{ chip.label }}
            </button>
          </div>
        </div>
      </div>

      <div class="table-section">
        <div class="result-meta">
          <span class="result-count"><b>{{ rows.length }}</b> transaksi tunai</span>
          <span class="page-info">Total omzet: <b>{{ formatRp(totalCashAmount) }}</b></span>
        </div>

        <div class="table-wrap">
          <table class="g-table">
            <thead>
              <tr>
                <th class="col-no">#</th>
                <th class="col-order">No. Order</th>
                <th class="col-customer">Customer</th>
                <th class="col-date">Tanggal</th>
                <th class="col-money">Grand Total</th>
                <th class="col-status">Status</th>
                <th class="col-nota">Merah</th>
                <th class="col-nota">Putih</th>
                <th class="col-nota">Kuning</th>
                <th class="col-aksi">Aksi</th>
              </tr>
            </thead>
            <tbody v-if="loading">
              <tr v-for="n in 6" :key="`loading-${n}`">
                <td colspan="10"><div class="skeleton"></div></td>
              </tr>
            </tbody>
            <tbody v-else-if="rows.length === 0">
              <tr>
                <td colspan="10" class="empty-cell">
                  <i class="pi pi-inbox"></i>
                  Tidak ada data tunai sesuai filter.
                </td>
              </tr>
            </tbody>
            <tbody v-else>
              <tr
                v-for="(row, idx) in rows"
                :key="row.sale_id"
                :ref="el => setRowRef(el, idx)"
                :class="{ 'g-row--active': selectedRowIndex === idx }"
                @click="selectedRowIndex = idx"
                @dblclick="openDetailModal(row)"
              >
                <td class="col-no">{{ idx + 1 }}</td>
                <td class="col-order">
                  <span class="kode-badge">{{ row.no_order }}</span>
                  <div class="row-sub">Fraktur: {{ row.no_faktur || '-' }}</div>
                </td>
                <td class="col-customer">
                  <div class="customer-cell">
                    <span class="customer-name">{{ row.customer_nama }}</span>
                    <span class="customer-addr">{{ row.customer_alamat || '-' }}</span>
                  </div>
                </td>
                <td class="col-date">{{ formatDate(row.order_date) }}</td>
                <td class="col-money"><span class="harga-val">{{ formatRp(row.grand_total) }}</span></td>
                <td class="col-status">
                  <span class="status-pill" :class="statusClass(row.payment_status)">
                    {{ paymentStatusLabel(row.payment_status) }}
                  </span>
                </td>
                <td class="col-nota">
                  <span class="note-state" :class="{ 'note-state--on': row.nota_merah }">
                    {{ row.nota_merah ? 'Ya' : 'Tidak' }}
                  </span>
                </td>
                <td class="col-nota">
                  <span class="note-state" :class="{ 'note-state--on': row.nota_putih }">
                    {{ row.nota_putih ? 'Ya' : 'Tidak' }}
                  </span>
                </td>
                <td class="col-nota">
                  <span class="note-state" :class="{ 'note-state--on': row.nota_kuning }">
                    {{ row.nota_kuning ? 'Ya' : 'Tidak' }}
                  </span>
                </td>
                <td class="col-aksi">
                  <div class="aksi-wrap">
                    <button class="aksi-btn aksi-view" @click.stop="openDetailModal(row)">
                      <i class="pi pi-eye"></i>
                    </button>
                    <button
                      class="aksi-btn aksi-edit"
                      :disabled="isReadOnly || isRowNormalizing(row) || !isCashNotesMismatch(row)"
                      :title="isReadOnly ? 'Mode read only' : 'Normalisasi nota transaksi tunai'"
                      @click.stop="normalizeCashNotes(row)"
                    >
                      <i :class="isRowNormalizing(row) ? 'pi pi-spin pi-spinner' : 'pi pi-check-square'"></i>
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
          <div class="modal-box modal-box--detail" role="dialog" aria-label="Detail transaksi tunai">
            <div class="modal-header">
              <h3 class="modal-title">Detail Transaksi Tunai: {{ detailModal.sale?.no_order }}</h3>
              <button class="modal-close" @click="closeDetailModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>

            <div class="modal-body" v-if="detailModal.sale">
              <div class="detail-grid">
                <div class="detail-card">
                  <span class="detail-label">Customer</span>
                  <strong class="detail-value">{{ detailModal.sale.customer_nama }}</strong>
                  <span class="detail-sub">{{ detailModal.sale.customer_alamat || '-' }}</span>
                </div>
                <div class="detail-card">
                  <span class="detail-label">Tanggal</span>
                  <strong class="detail-value">{{ formatDate(detailModal.sale.order_date) }}</strong>
                  <span class="detail-sub">Term: {{ detailModal.sale.payment_term_label }}</span>
                </div>
                <div class="detail-card">
                  <span class="detail-label">Total</span>
                  <strong class="detail-value">{{ formatRp(detailModal.sale.grand_total) }}</strong>
                  <span class="detail-sub">Status: {{ paymentStatusLabel(detailModal.sale.payment_status) }}</span>
                </div>
                <div class="detail-card">
                  <span class="detail-label">Kelengkapan Nota</span>
                  <div class="detail-note-summary">
                    <span class="note-chip" :class="{ 'note-chip--on': detailModal.sale.nota_merah }">Merah</span>
                    <span class="note-chip" :class="{ 'note-chip--on': detailModal.sale.nota_putih }">Putih</span>
                    <span class="note-chip" :class="{ 'note-chip--on': detailModal.sale.nota_kuning }">Kuning</span>
                  </div>
                  <span v-if="isCashNotesMismatch(detailModal.sale)" class="detail-sub">Perlu normalisasi nota</span>
                  <span v-else class="detail-sub">Nota sudah sinkron</span>
                </div>
              </div>
            </div>

            <div class="modal-footer">
              <button class="btn-secondary" @click="closeDetailModal">Tutup <kbd>Esc</kbd></button>
              <button
                class="btn-primary"
                :disabled="isReadOnly || !detailModal.sale || !isCashNotesMismatch(detailModal.sale)"
                @click="normalizeFromDetail"
              >
                Normalisasi Nota
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup>
import { computed, nextTick, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import Toast from 'primevue/toast'
import {
  fetchPenagihanSales,
  filterBySearch,
  paymentStatusLabel,
  statusClass,
  formatDate,
  formatRp,
  isSchemaIssue,
  updateSalesNotes,
  buildAutoNotePayload,
  toIsoDate,
  subscribePenagihanAutoSync,
} from '@/lib/penagihanService'

const router = useRouter()
const route = useRoute()
const toast = useToast()

const pageEl = ref(null)
const searchInput = ref(null)
const focusKey = ref('')
const loading = ref(false)
const schemaError = ref('')
const searchQuery = ref('')
const activeFilter = ref('all')
const selectedRowIndex = ref(0)
const rowRefs = ref({})
const normalizingSaleId = ref('')
let stopAutoSync = () => {}

const salesRows = ref([])

const detailModal = reactive({
  show: false,
  sale: null,
})

const isReadOnly = computed(() => Boolean(route.meta.readOnly))

const filterOptions = [
  { id: 'all', label: 'Semua' },
  { id: 'today', label: 'Hari Ini' },
  { id: 'week', label: '7 Hari Terakhir' },
  { id: 'need_sync', label: 'Nota Belum Sinkron' },
]

function getCashExpectedNotes() {
  return buildAutoNotePayload(0)
}

function isCashNotesMismatch(row) {
  const expected = getCashExpectedNotes()
  return (
    Boolean(row.nota_merah) !== Boolean(expected.nota_merah) ||
    Boolean(row.nota_putih) !== Boolean(expected.nota_putih) ||
    Boolean(row.nota_kuning) !== Boolean(expected.nota_kuning)
  )
}

const rows = computed(() => {
  let data = salesRows.value.filter(row => row.is_cash)

  if (activeFilter.value === 'today') {
    const today = toIsoDate(new Date())
    data = data.filter(row => String(row.order_date || '') === today)
  } else if (activeFilter.value === 'week') {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    data = data.filter(row => {
      if (!row.order_date) return false
      const orderDate = new Date(`${row.order_date}T00:00:00`)
      if (Number.isNaN(orderDate.getTime())) return false
      const diff = Math.floor((today.getTime() - orderDate.getTime()) / 86400000)
      return diff >= 0 && diff <= 7
    })
  } else if (activeFilter.value === 'need_sync') {
    data = data.filter(row => isCashNotesMismatch(row))
  }

  return filterBySearch(data, searchQuery.value, row => {
    return [row.no_order, row.no_faktur, row.customer_nama, row.customer_alamat].join(' ')
  })
})

const totalCashAmount = computed(() => {
  return rows.value.reduce((sum, row) => sum + Number(row.grand_total || 0), 0)
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
    salesRows.value = await fetchPenagihanSales()
  } catch (err) {
    const message = String(err?.message || err || '')
    console.error('[PenagihanTunaiPage.loadData]', err)

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

function isRowNormalizing(row) {
  return normalizingSaleId.value === row.sale_id
}

async function normalizeCashNotes(row) {
  if (!row || isRowNormalizing(row)) return

  if (isReadOnly.value) {
    toast.add({
      severity: 'warn',
      summary: 'Akses Read Only',
      detail: 'Akun ini tidak memiliki izin ubah nota.',
      life: 2500,
    })
    return
  }

  if (!isCashNotesMismatch(row)) {
    toast.add({
      severity: 'info',
      summary: 'Sudah Sinkron',
      detail: 'Nota transaksi ini sudah sesuai.',
      life: 2200,
    })
    return
  }

  normalizingSaleId.value = row.sale_id

  try {
    const payload = getCashExpectedNotes()
    await updateSalesNotes(row.sale_id, payload)
    row.nota_merah = payload.nota_merah
    row.nota_putih = payload.nota_putih
    row.nota_kuning = payload.nota_kuning

    if (detailModal.sale?.sale_id === row.sale_id) {
      detailModal.sale = row
    }

    toast.add({
      severity: 'success',
      summary: 'Nota Disesuaikan',
      detail: `Nota transaksi ${row.no_order} berhasil dinormalisasi.`,
      life: 2500,
    })
  } catch (err) {
    toast.add({
      severity: 'error',
      summary: 'Gagal Normalisasi',
      detail: String(err?.message || err || ''),
      life: 3200,
    })
  } finally {
    normalizingSaleId.value = ''
  }
}

function openDetailModal(row) {
  detailModal.sale = row
  detailModal.show = true
}

function closeDetailModal() {
  detailModal.show = false
  detailModal.sale = null
  nextTick(() => pageEl.value?.focus())
}

async function normalizeFromDetail() {
  const row = detailModal.sale
  if (!row) return
  await normalizeCashNotes(row)
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
  } else if (e.key === 'F4') {
    e.preventDefault()
    if (selectedRow.value) normalizeCashNotes(selectedRow.value)
  }
}

onMounted(async () => {
  pageEl.value?.focus()
  window.addEventListener('keydown', onGlobalKey)
  await loadData()
  stopAutoSync = subscribePenagihanAutoSync({
    key: 'tunai',
    onSync: loadData,
  })
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
  stopAutoSync()
})
</script>

<style scoped>
@import '@/assets/pages/penagihan/penagihan-tunai-page.css';
</style>
