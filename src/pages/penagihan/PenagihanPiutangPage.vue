<template>
  <div class="penagihan-sub-page penagihan-piutang-page" ref="pageEl" tabindex="-1">
    <Toast position="top-right" />

    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Piutang Aktif</h1>
        <p class="g-subtitle">Input pembayaran parsial/lunas untuk transaksi termin 1-3 bulan</p>
      </div>
      <span v-if="isReadOnly" class="read-only-badge">
        <i class="pi pi-lock"></i>
        Mode Read Only
      </span>
    </div>

    <div class="shortcut-strip">
      <kbd>F1 Cari</kbd>
      <kbd>Arrow Pilih Baris</kbd>
      <kbd>Enter Bayar</kbd>
      <kbd>F4 Detail</kbd>
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
          <span class="result-count"><b>{{ rows.length }}</b> transaksi piutang</span>
          <span class="page-info">Total sisa: <b>{{ formatRp(totalOutstanding) }}</b></span>
          <span class="page-info">Mode tampil: <b>per No. Order</b></span>
        </div>

        <div class="table-wrap">
          <table class="g-table">
            <thead>
              <tr>
                <th class="col-no">#</th>
                <th class="col-order">No. Order</th>
                <th class="col-customer">Customer</th>
                <th class="col-date">Tanggal</th>
                <th class="col-date">Jatuh Tempo</th>
                <th class="col-term">Term</th>
                <th class="col-money">Total</th>
                <th class="col-money">Terbayar</th>
                <th class="col-money">Sisa</th>
                <th class="col-status">Status</th>
                <th class="col-overdue">Overdue</th>
                <th class="col-aksi">Aksi</th>
              </tr>
            </thead>
            <tbody v-if="loading">
              <tr v-for="n in 6" :key="`loading-${n}`">
                <td colspan="12"><div class="skeleton"></div></td>
              </tr>
            </tbody>
            <tbody v-else-if="rows.length === 0">
              <tr>
                <td colspan="12" class="empty-cell">
                  <i class="pi pi-inbox"></i>
                  Tidak ada transaksi piutang sesuai filter.
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
                @dblclick="openPaymentModal(row)"
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
                <td class="col-date">{{ formatDate(row.due_date) }}</td>
                <td class="col-term"><span class="term-badge">{{ row.payment_term_label }}</span></td>
                <td class="col-money"><span class="harga-val">{{ formatRp(row.grand_total) }}</span></td>
                <td class="col-money">{{ formatRp(row.total_paid) }}</td>
                <td class="col-money"><strong class="outstanding-val">{{ formatRp(row.outstanding_amount) }}</strong></td>
                <td class="col-status">
                  <span class="status-pill" :class="statusClass(row.payment_status)">
                    {{ paymentStatusLabel(row.payment_status) }}
                  </span>
                </td>
                <td class="col-overdue">
                  <span v-if="row.is_overdue" class="overdue-badge">{{ row.overdue_days }} hari</span>
                  <span v-else class="dash">-</span>
                </td>
                <td class="col-aksi">
                  <div class="aksi-wrap">
                    <button
                      class="aksi-btn aksi-edit"
                      :disabled="isReadOnly"
                      @click.stop="openPaymentModal(row)"
                      :title="isReadOnly ? 'Mode read only' : 'Input pembayaran'"
                    >
                      <i class="pi pi-money-bill"></i>
                    </button>
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
        <div v-if="paymentModal.show" class="modal-overlay" @click.self="closePaymentModal">
          <div class="modal-box" role="dialog" aria-label="Input pembayaran customer">
            <div class="modal-header modal-header--blue">
              <h3 class="modal-title">Input Pembayaran Customer</h3>
              <button class="modal-close" @click="closePaymentModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>

            <form class="modal-body" @submit.prevent="submitPayment">
              <div class="mfield-grid">
                <div class="mfield">
                  <label class="mfield-label">No. Order Acuan</label>
                  <input :value="paymentModal.sale?.no_order || '-'" type="text" class="mfield-input" disabled />
                </div>
                <div class="mfield">
                  <label class="mfield-label">Customer</label>
                  <input :value="paymentModal.sale?.customer_nama || '-'" type="text" class="mfield-input" disabled />
                </div>
                <div class="mfield">
                  <label class="mfield-label">Sisa Tagihan Customer</label>
                  <input :value="formatRp(getCustomerOutstanding(paymentModal.sale?.customer_id))" type="text" class="mfield-input" disabled />
                </div>
                <div class="mfield">
                  <label class="mfield-label">Tanggal Bayar <span class="required">*</span></label>
                  <input v-model="paymentModal.paymentDate" type="date" class="mfield-input" required />
                </div>
                <div class="mfield">
                  <label class="mfield-label">Nominal Bayar <span class="required">*</span></label>
                  <input
                    ref="paymentAmountInput"
                    v-model="paymentModal.amountInput"
                    type="text"
                    class="mfield-input"
                    placeholder="Contoh: 1.250.000"
                    @input="onPaymentAmountInput"
                    required
                  />
                </div>
                <div class="mfield">
                  <label class="mfield-label">Metode Bayar</label>
                  <select v-model="paymentModal.method" class="mfield-input">
                    <option v-for="opt in paymentMethodOptions" :key="opt.value" :value="opt.value">
                      {{ opt.label }}
                    </option>
                  </select>
                </div>
                <div class="mfield mfield--full">
                  <label class="mfield-label">Catatan</label>
                  <textarea
                    v-model="paymentModal.note"
                    class="mfield-input mfield-textarea"
                    rows="3"
                    placeholder="Contoh: Cicilan pertama, transfer BCA"
                  ></textarea>
                </div>
                <div class="mfield mfield--full">
                  <label class="inline-check">
                    <input type="checkbox" v-model="paymentModal.autoSyncNota" />
                    <span>Auto update manajemen nota sesuai sisa hutang setelah pembayaran</span>
                  </label>
                </div>
                <div class="mfield mfield--full">
                  <p class="row-sub">Pembayaran akan dialokasikan otomatis ke transaksi paling lama (FIFO) customer yang sama.</p>
                </div>

                <div class="mfield mfield--full allocation-preview" v-if="paymentModal.sale">
                  <h4 class="allocation-preview-title">Preview Breakdown Alokasi</h4>
                  <div class="allocation-preview-meta">
                    <span>Nominal Input: <b>{{ formatRp(paymentPreview.requestedAmount) }}</b></span>
                    <span>Teralokasi: <b>{{ formatRp(paymentPreview.allocatedAmount) }}</b></span>
                    <span>Sisa Tidak Teralokasi: <b :class="{ 'allocation-preview-warn': paymentPreview.unallocatedAmount > 0 }">{{ formatRp(paymentPreview.unallocatedAmount) }}</b></span>
                  </div>

                  <p v-if="paymentPreview.overLimit" class="allocation-preview-error">
                    Nominal input melebihi total sisa tagihan customer.
                  </p>

                  <div class="table-wrap allocation-preview-table-wrap" v-if="paymentPreview.allocations.length">
                    <table class="g-table allocation-preview-table">
                      <thead>
                        <tr>
                          <th class="col-no">#</th>
                          <th class="col-order">No. Order</th>
                          <th class="col-date">Tanggal</th>
                          <th class="col-money">Sisa Sebelum</th>
                          <th class="col-money">Dialokasikan</th>
                          <th class="col-money">Sisa Setelah</th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr v-for="(item, idx) in paymentPreview.allocations" :key="`preview-${item.row.sale_id}`">
                          <td class="col-no">{{ idx + 1 }}</td>
                          <td class="col-order">{{ item.row.no_order }}</td>
                          <td class="col-date">{{ formatDate(item.row.order_date) }}</td>
                          <td class="col-money">{{ formatRp(item.previousOutstanding) }}</td>
                          <td class="col-money"><strong>{{ formatRp(item.amount) }}</strong></td>
                          <td class="col-money">
                            <span :class="{ 'allocation-preview-paid': item.nextOutstanding <= 0 }">
                              {{ formatRp(item.nextOutstanding) }}
                            </span>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>

                  <p v-else class="allocation-preview-empty">
                    Belum ada alokasi. Isi nominal bayar untuk melihat breakdown.
                  </p>
                </div>
              </div>
              <p v-if="paymentModal.error" class="modal-error-inline">{{ paymentModal.error }}</p>
            </form>

            <div class="modal-footer">
              <button type="button" class="btn-secondary" @click="closePaymentModal">Batal <kbd>Esc</kbd></button>
              <button type="button" class="btn-primary" :disabled="paymentModal.saving" @click="submitPayment">
                <i class="pi pi-check"></i>
                <span>{{ paymentModal.saving ? 'Menyimpan...' : 'Simpan Pembayaran' }}</span>
                <kbd>Enter</kbd>
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="detailModal.show" class="modal-overlay" @click.self="closeDetailModal">
          <div class="modal-box modal-box--detail" role="dialog" aria-label="Detail penagihan">
            <div class="modal-header">
              <h3 class="modal-title">Detail Penagihan: {{ detailModal.sale?.no_order }}</h3>
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
                  <span class="detail-label">Term</span>
                  <strong class="detail-value">{{ detailModal.sale.payment_term_label }}</strong>
                  <span class="detail-sub">Jatuh Tempo: {{ formatDate(detailModal.sale.due_date) }}</span>
                </div>
                <div class="detail-card">
                  <span class="detail-label">Total Tagihan</span>
                  <strong class="detail-value">{{ formatRp(detailModal.sale.grand_total) }}</strong>
                  <span class="detail-sub">Terbayar: {{ formatRp(detailModal.sale.total_paid) }}</span>
                </div>
                <div class="detail-card">
                  <span class="detail-label">Sisa</span>
                  <strong class="detail-value">{{ formatRp(detailModal.sale.outstanding_amount) }}</strong>
                  <span class="detail-sub" :class="statusClass(detailModal.sale.payment_status)">
                    {{ paymentStatusLabel(detailModal.sale.payment_status) }}
                  </span>
                </div>
              </div>

              <h4 class="detail-section-title">Riwayat Pembayaran</h4>
              <div class="table-wrap detail-table-wrap">
                <table class="g-table">
                  <thead>
                    <tr>
                      <th class="col-no">#</th>
                      <th class="col-date">Tanggal</th>
                      <th class="col-method">Metode</th>
                      <th class="col-money">Nominal</th>
                      <th class="col-note">Catatan</th>
                    </tr>
                  </thead>
                  <tbody v-if="detailPayments.length === 0">
                    <tr>
                      <td colspan="5" class="empty-cell">Belum ada pembayaran pada transaksi ini.</td>
                    </tr>
                  </tbody>
                  <tbody v-else>
                    <tr v-for="(pay, idx) in detailPayments" :key="pay.id">
                      <td class="col-no">{{ idx + 1 }}</td>
                      <td class="col-date">{{ formatDate(pay.payment_date) }}</td>
                      <td class="col-method">{{ paymentMethodLabel(pay.payment_method) }}</td>
                      <td class="col-money"><span class="harga-val">{{ formatRp(pay.amount) }}</span></td>
                      <td class="col-note">{{ pay.note || '-' }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <div class="modal-footer">
              <button class="btn-secondary" @click="closeDetailModal">Tutup <kbd>Esc</kbd></button>
              <button
                class="btn-primary"
                @click="openPaymentFromDetail"
                :disabled="isReadOnly || !detailModal.sale || detailModal.sale.outstanding_amount <= 0"
              >
                Input Bayar
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
  fetchPenagihanBundle,
  filterBySearch,
  paymentMethodOptions,
  paymentStatusLabel,
  paymentMethodLabel,
  statusClass,
  formatDate,
  formatRp,
  toIsoDate,
  parseAmountInput,
  formatAmountInput,
  isDueSoon,
  isSchemaIssue,
  insertSalesPayments,
  updateSalesNotes,
  buildAutoNotePayload,
  getCustomerOutstandingAmount,
  allocateCustomerPaymentFifo,
  subscribePenagihanAutoSync,
} from '@/lib/penagihanService'

const router = useRouter()
const route = useRoute()
const toast = useToast()

const pageEl = ref(null)
const searchInput = ref(null)
const paymentAmountInput = ref(null)
const focusKey = ref('')
const loading = ref(false)
const schemaError = ref('')
const searchQuery = ref('')
const activeFilter = ref('all')
const selectedRowIndex = ref(0)
const rowRefs = ref({})
let stopAutoSync = () => {}

const billingRows = ref([])
const paymentRows = ref([])

const paymentModal = reactive({
  show: false,
  sale: null,
  paymentDate: toIsoDate(new Date()),
  amountInput: '',
  method: 'cash',
  note: '',
  autoSyncNota: true,
  error: '',
  saving: false,
})

const detailModal = reactive({
  show: false,
  sale: null,
})

const isReadOnly = computed(() => Boolean(route.meta.readOnly))

const filterOptions = [
  { id: 'all', label: 'Semua' },
  { id: 'overdue', label: 'Overdue' },
  { id: 'due_soon', label: 'Jatuh Tempo <= 7 Hari' },
  { id: 'partial', label: 'Cicilan' },
  { id: 'unpaid', label: 'Belum Bayar' },
]

function comparePiutangByOrder(a, b) {
  const dateA = String(a?.order_date || '')
  const dateB = String(b?.order_date || '')
  if (dateA !== dateB) {
    return dateA < dateB ? 1 : -1
  }

  const orderA = String(a?.no_order || '')
  const orderB = String(b?.no_order || '')
  if (orderA !== orderB) {
    return orderA < orderB ? 1 : -1
  }

  const idA = String(a?.sale_id || '')
  const idB = String(b?.sale_id || '')
  return idA < idB ? 1 : idA > idB ? -1 : 0
}

const rows = computed(() => {
  let data = billingRows.value.filter(row => row.is_credit && Number(row.outstanding_amount || 0) > 0)

  if (activeFilter.value === 'overdue') {
    data = data.filter(row => row.is_overdue)
  } else if (activeFilter.value === 'due_soon') {
    data = data.filter(row => isDueSoon(row))
  } else if (activeFilter.value === 'partial') {
    data = data.filter(row => row.payment_status === 'partial')
  } else if (activeFilter.value === 'unpaid') {
    data = data.filter(row => row.payment_status === 'unpaid')
  }

  data = data.slice().sort(comparePiutangByOrder)

  return filterBySearch(data, searchQuery.value, row => {
    return [row.no_order, row.no_faktur, row.customer_nama, row.customer_alamat].join(' ')
  })
})

const totalOutstanding = computed(() => {
  return rows.value.reduce((sum, row) => sum + Number(row.outstanding_amount || 0), 0)
})

const selectedRow = computed(() => rows.value[selectedRowIndex.value] || null)

const detailPayments = computed(() => {
  const saleId = detailModal.sale?.sale_id
  if (!saleId) return []
  return paymentRows.value
    .filter(row => row.sale_id === saleId)
    .slice()
    .sort((a, b) => {
      const dateA = `${a.payment_date || ''} ${a.created_at || ''}`
      const dateB = `${b.payment_date || ''} ${b.created_at || ''}`
      return dateA < dateB ? 1 : -1
    })
})

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
    billingRows.value = sales
    paymentRows.value = payments
  } catch (err) {
    const message = String(err?.message || err || '')
    console.error('[PenagihanPiutangPage.loadData]', err)

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

function getCustomerOutstanding(customerId) {
  return getCustomerOutstandingAmount(billingRows.value, customerId)
}

const paymentPreview = computed(() => {
  const sale = paymentModal.sale
  const customerId = sale?.customer_id
  if (!customerId) {
    return {
      requestedAmount: 0,
      allocatedAmount: 0,
      unallocatedAmount: 0,
      allocations: [],
      overLimit: false,
    }
  }

  const requestedAmount = Math.max(0, parseAmountInput(paymentModal.amountInput))
  const customerOutstanding = getCustomerOutstanding(customerId)
  const allocation = allocateCustomerPaymentFifo({
    salesRows: billingRows.value,
    customerId,
    amount: requestedAmount,
  })

  return {
    requestedAmount,
    allocatedAmount: allocation.allocatedAmount,
    unallocatedAmount: allocation.unallocatedAmount,
    allocations: allocation.allocations,
    overLimit: requestedAmount > customerOutstanding,
  }
})

function summarizeAllocation(allocations) {
  const totalRows = allocations.length
  const fullPaidRows = allocations.filter(item => item.isFullyPaid).length
  const partialRows = totalRows - fullPaidRows
  return {
    totalRows,
    fullPaidRows,
    partialRows,
  }
}

function openPaymentModal(row) {
  if (!row) return

  if (isReadOnly.value) {
    toast.add({
      severity: 'warn',
      summary: 'Akses Read Only',
      detail: 'Akun ini tidak memiliki izin input pembayaran.',
      life: 2500,
    })
    return
  }

  paymentModal.sale = row
  paymentModal.paymentDate = toIsoDate(new Date())
  paymentModal.amountInput = formatAmountInput(getCustomerOutstanding(row.customer_id))
  paymentModal.method = 'cash'
  paymentModal.note = ''
  paymentModal.autoSyncNota = true
  paymentModal.error = ''
  paymentModal.show = true

  nextTick(() => paymentAmountInput.value?.focus())
}

function closePaymentModal() {
  paymentModal.show = false
  paymentModal.sale = null
  paymentModal.error = ''
  paymentModal.saving = false
  nextTick(() => pageEl.value?.focus())
}

function onPaymentAmountInput(e) {
  const parsed = parseAmountInput(e.target.value)
  paymentModal.amountInput = parsed > 0 ? formatAmountInput(parsed) : ''
}

async function submitPayment() {
  if (!paymentModal.sale || paymentModal.saving) return

  const amount = parseAmountInput(paymentModal.amountInput)
  const customerId = paymentModal.sale.customer_id
  const customerOutstanding = getCustomerOutstanding(customerId)
  paymentModal.error = ''

  if (!customerId) {
    paymentModal.error = 'Data customer pada transaksi ini tidak valid.'
    return
  }

  if (!paymentModal.paymentDate) {
    paymentModal.error = 'Tanggal bayar wajib diisi.'
    return
  }

  if (!amount || amount <= 0) {
    paymentModal.error = 'Nominal bayar harus lebih dari 0.'
    return
  }

  if (amount > customerOutstanding) {
    paymentModal.error = `Nominal bayar tidak boleh melebihi sisa tagihan customer (${formatRp(customerOutstanding)}).`
    return
  }

  const allocation = allocateCustomerPaymentFifo({
    salesRows: billingRows.value,
    customerId,
    amount,
  })

  if (!allocation.allocations.length || allocation.allocatedAmount <= 0) {
    paymentModal.error = 'Tidak ada transaksi yang bisa dialokasikan untuk pembayaran ini.'
    return
  }

  if (allocation.unallocatedAmount > 0) {
    paymentModal.error = `Sebagian nominal belum teralokasi (${formatRp(allocation.unallocatedAmount)}). Periksa data piutang customer.`
    return
  }

  paymentModal.saving = true

  try {
    const noteText = paymentModal.note.trim()
    await insertSalesPayments(
      allocation.allocations.map(item => ({
        saleId: item.row.sale_id,
        paymentDate: paymentModal.paymentDate,
        amount: item.amount,
        paymentMethod: paymentModal.method,
        note: noteText,
      }))
    )

    let noteSyncWarning = false
    if (paymentModal.autoSyncNota) {
      for (const item of allocation.allocations) {
        try {
          await updateSalesNotes(item.row.sale_id, buildAutoNotePayload(item.nextOutstanding))
        } catch (noteErr) {
          noteSyncWarning = true
          console.error('[PenagihanPiutangPage.submitPayment.noteSync]', item.row.no_order, noteErr)
        }
      }
    }

    closePaymentModal()
    await loadData()

    const summary = summarizeAllocation(allocation.allocations)

    toast.add({
      severity: noteSyncWarning ? 'warn' : 'success',
      summary: noteSyncWarning ? 'Pembayaran Tersimpan, Nota Sebagian Belum Sinkron' : 'Pembayaran Tersimpan',
      detail: `Pembayaran ${formatRp(allocation.allocatedAmount)} dialokasikan FIFO ke ${summary.totalRows} transaksi (lunas ${summary.fullPaidRows}, parsial ${summary.partialRows}).`,
      life: 3600,
    })
  } catch (err) {
    paymentModal.error = String(err?.message || err || 'Gagal menyimpan pembayaran.')
  } finally {
    paymentModal.saving = false
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

function openPaymentFromDetail() {
  const row = detailModal.sale
  closeDetailModal()
  if (row) openPaymentModal(row)
}

function onGlobalKey(e) {
  if (paymentModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      closePaymentModal()
    }
    return
  }

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
    if (selectedRow.value) openPaymentModal(selectedRow.value)
  } else if (e.key === 'F4') {
    e.preventDefault()
    if (selectedRow.value) openDetailModal(selectedRow.value)
  }
}

onMounted(async () => {
  pageEl.value?.focus()
  window.addEventListener('keydown', onGlobalKey)
  await loadData()
  stopAutoSync = subscribePenagihanAutoSync({
    key: 'piutang',
    onSync: loadData,
  })
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
  stopAutoSync()
})
</script>

<style scoped>
@import '@/assets/pages/penagihan/penagihan-piutang-page.css';

.allocation-preview {
  border: 1px solid #dbe6f3;
  border-radius: 10px;
  background: #f8fbff;
  padding: 0.65rem 0.75rem;
}

.allocation-preview-title {
  font-size: 0.84rem;
  color: #334155;
  margin-bottom: 0.4rem;
}

.allocation-preview-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.65rem;
  font-size: 0.74rem;
  color: #475569;
  margin-bottom: 0.5rem;
}

.allocation-preview-warn {
  color: #b91c1c;
}

.allocation-preview-error {
  margin: 0 0 0.45rem;
  color: #b91c1c;
  font-size: 0.74rem;
}

.allocation-preview-table-wrap {
  max-height: 220px;
}

.allocation-preview-table {
  min-width: 760px;
}

.allocation-preview-paid {
  color: #166534;
  font-weight: 700;
}

.allocation-preview-empty {
  margin: 0;
  color: #64748b;
  font-size: 0.74rem;
}
</style>
