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
      <kbd>F2 Tanggal</kbd>
      <kbd>F3 Filter Status</kbd>
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
          <div class="date-filter-wrap">
            <label class="search-label">
              Tanggal Order
              <kbd class="label-kbd">F2</kbd>
            </label>
            <div class="date-filter-row">
              <input
                ref="dateStartInput"
                v-model="dateFilter.start"
                type="date"
                class="mfield-input date-filter-input"
                @keydown.enter.prevent="onDateStartEnter"
              />
              <span class="date-separator">s/d</span>
              <input
                ref="dateEndInput"
                v-model="dateFilter.end"
                type="date"
                class="mfield-input date-filter-input"
              />
            </div>
          </div>

          <button
            type="button"
            class="btn-filter-popup"
            @click="openStatusFilterModal"
          >
            <i class="pi pi-sliders-h"></i>
            <span>Filter: {{ activeFilterLabel }}</span>
            <kbd>F3</kbd>
          </button>
        </div>
      </div>

      <div class="table-section">
        <div class="result-meta">
          <span class="result-count"><b>{{ rows.length }}</b> transaksi piutang</span>
          <span class="page-info">Total sisa: <b>{{ formatRp(totalOutstanding) }}</b></span>
          <span class="page-info">Status: <b>{{ activeFilterLabel }}</b></span>
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
          <div class="modal-box modal-box--payment" role="dialog" aria-label="Input pembayaran customer">
            <div class="modal-header modal-header--blue">
              <h3 class="modal-title">Input Pembayaran Customer</h3>
              <button class="modal-close" @click="closePaymentModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>

            <form class="modal-body" @submit.prevent="requestPaymentConfirm">
              <div class="mfield-grid">
                <div class="mfield">
                  <label class="mfield-label">No. Order Acuan</label>
                  <input :value="paymentModal.sale?.no_order || '-'" type="text" class="mfield-input mfield-input--readonly" disabled />
                </div>
                <div class="mfield">
                  <label class="mfield-label">Customer</label>
                  <input :value="paymentModal.sale?.customer_nama || '-'" type="text" class="mfield-input mfield-input--readonly" disabled />
                </div>
                <div class="mfield">
                  <label class="mfield-label">Sisa Tagihan Customer</label>
                  <input :value="formatRp(getCustomerOutstanding(paymentModal.sale?.customer_id))" type="text" class="mfield-input mfield-input--readonly" disabled />
                </div>
                <div class="mfield">
                  <label class="mfield-label">Tanggal Bayar <span class="required">*</span></label>
                  <input
                    ref="paymentDateInput"
                    v-model="paymentModal.paymentDate"
                    type="date"
                    class="mfield-input"
                    @keydown="onPaymentFieldArrow"
                    required
                  />
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
                    @keydown="onPaymentFieldArrow"
                    @keydown.enter.prevent="focusPaymentMethod"
                    required
                  />
                </div>
                <div class="mfield">
                  <label class="mfield-label">Metode Bayar</label>
                  <select
                    ref="paymentMethodInput"
                    v-model="paymentModal.method"
                    class="mfield-input"
                    @keydown="onPaymentFieldArrow"
                    @keydown.enter.prevent="focusPaymentNote"
                  >
                    <option v-for="opt in paymentMethodOptions" :key="opt.value" :value="opt.value">
                      {{ opt.label }}
                    </option>
                  </select>
                </div>
                <div class="mfield mfield--full">
                  <label class="mfield-label">Catatan <span class="mfield-optional">(Opsional)</span></label>
                  <textarea
                    ref="paymentNoteInput"
                    v-model="paymentModal.note"
                    class="mfield-input mfield-textarea"
                    rows="3"
                    placeholder=""
                    @keydown="onPaymentFieldArrow"
                    @keydown.enter.exact.prevent="requestPaymentConfirm"
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
              <button ref="paymentSaveButton" type="button" class="btn-primary" :disabled="paymentModal.saving" @click="requestPaymentConfirm">
                <i class="pi pi-check"></i>
                <span>{{ paymentModal.saving ? 'Menyimpan...' : 'Simpan Pembayaran' }}</span>
                <kbd>Enter/F10</kbd>
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="paymentConfirm.show" class="modal-overlay" @click.self="cancelPaymentConfirm">
          <div class="modal-box modal-box--confirm" role="dialog" aria-label="Konfirmasi simpan pembayaran">
            <div class="modal-header modal-header--center">
              <h3 class="modal-title">Konfirmasi Pembayaran</h3>
              <button class="modal-close" @click="cancelPaymentConfirm" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body modal-body--confirm">
              <p class="confirm-message">Simpan pembayaran ini?</p>
              <div class="payment-confirm-box">
                <div>
                  <span class="payment-confirm-label">Customer</span>
                  <strong class="payment-confirm-value">{{ paymentModal.sale?.customer_nama || '-' }}</strong>
                </div>
                <div>
                  <span class="payment-confirm-label">Nominal</span>
                  <strong class="payment-confirm-value">{{ formatRp(paymentConfirm.amount) }}</strong>
                </div>
                <div>
                  <span class="payment-confirm-label">Tanggal Bayar</span>
                  <strong class="payment-confirm-value">{{ paymentModal.paymentDate || '-' }}</strong>
                </div>
                <div>
                  <span class="payment-confirm-label">Metode</span>
                  <strong class="payment-confirm-value">{{ paymentMethodLabel(paymentModal.method) }}</strong>
                </div>
              </div>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn-secondary" @click="cancelPaymentConfirm">Batal <kbd>Esc</kbd></button>
              <button type="button" class="btn-primary" @click="confirmPayment" :disabled="paymentModal.saving">
                <i class="pi pi-check"></i>
                <span>Ya, Simpan</span>
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
                <div class="detail-card detail-card--order">
                  <span class="detail-label">No. Order / No. Faktur</span>
                  <strong class="detail-value">{{ detailModal.sale.no_order }}</strong>
                  <span class="detail-sub">Faktur: {{ detailModal.sale.no_faktur || '-' }}</span>
                </div>
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
                  <span class="detail-sub">Overdue: {{ detailModal.sale.is_overdue ? `${detailModal.sale.overdue_days} hari` : '-' }}</span>
                </div>
                <div class="detail-card detail-card--status">
                  <span class="detail-label">Status Pembayaran</span>
                  <span class="status-pill" :class="statusClass(detailModal.sale.payment_status)">
                    {{ paymentStatusLabel(detailModal.sale.payment_status) }}
                  </span>
                  <span class="detail-sub">Term: {{ detailModal.sale.payment_term_label }}</span>
                </div>
              </div>

              <h4 class="detail-section-title">Item Pada Transaksi</h4>
              <div class="table-wrap detail-table-wrap detail-items-wrap">
                <table class="g-table detail-items-table">
                  <thead>
                    <tr>
                      <th class="col-no">#</th>
                      <th class="col-item">Kode</th>
                      <th class="col-item-name">Nama Item</th>
                      <th class="col-money">Qty</th>
                      <th class="col-money">Harga</th>
                      <th class="col-money">Total</th>
                    </tr>
                  </thead>
                  <tbody v-if="detailModal.itemsLoading">
                    <tr>
                      <td colspan="6" class="empty-cell">Memuat item transaksi...</td>
                    </tr>
                  </tbody>
                  <tbody v-else-if="detailModal.itemsError">
                    <tr>
                      <td colspan="6" class="empty-cell">{{ detailModal.itemsError }}</td>
                    </tr>
                  </tbody>
                  <tbody v-else-if="detailItems.length === 0">
                    <tr>
                      <td colspan="6" class="empty-cell">Item transaksi tidak ditemukan.</td>
                    </tr>
                  </tbody>
                  <tbody v-else>
                    <tr v-for="(item, idx) in detailItems" :key="item.id || idx">
                      <td class="col-no">{{ idx + 1 }}</td>
                      <td class="col-item">{{ item.product_kode || '-' }}</td>
                      <td class="col-item-name">{{ item.product_nama || '-' }}</td>
                      <td class="col-money">{{ Number(item.qty || 0).toLocaleString('id-ID') }}</td>
                      <td class="col-money">{{ formatRp(item.unit_price) }}</td>
                      <td class="col-money"><span class="harga-val">{{ formatRp(item.total) }}</span></td>
                    </tr>
                  </tbody>
                </table>
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

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="statusFilterModal.show" class="modal-overlay" @click.self="closeStatusFilterModal">
          <div class="modal-box modal-box--status-filter" role="dialog" aria-label="Filter status piutang">
            <div class="modal-header modal-header--blue">
              <h3 class="modal-title">Filter Status Piutang</h3>
              <button class="modal-close" @click="closeStatusFilterModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body status-filter-body">
              <button
                v-for="opt in statusFilterLayout"
                :key="opt.id"
                type="button"
                class="status-filter-option"
                :class="[
                  `status-filter-option--${opt.id}`,
                  { 'status-filter-option--active': statusFilterModal.selectedId === opt.id },
                ]"
                @mouseenter="statusFilterModal.selectedId = opt.id"
                @click="applyStatusFilterById(opt.id)"
              >
                <span class="status-filter-label">
                  <i :class="statusFilterIcon(opt.id)"></i>
                  {{ opt.label }}
                </span>
                <i v-if="activeFilter === opt.id" class="pi pi-check"></i>
              </button>
              <p class="status-filter-hint">Arrow: pilih · Enter: terapkan · Esc: batal</p>
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
import { supabase } from '@/lib/supabase'
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
const dateStartInput = ref(null)
const dateEndInput = ref(null)
const paymentDateInput = ref(null)
const paymentAmountInput = ref(null)
const paymentMethodInput = ref(null)
const paymentNoteInput = ref(null)
const paymentSaveButton = ref(null)
const focusKey = ref('')
const loading = ref(false)
const schemaError = ref('')
const searchQuery = ref('')
const activeFilter = ref('all')
const dateFilter = reactive({
  start: '',
  end: toIsoDate(new Date()),
})
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

const paymentConfirm = reactive({
  show: false,
  allocation: null,
  amount: 0,
  openedAt: 0,
})

const detailModal = reactive({
  show: false,
  sale: null,
  items: [],
  itemsLoading: false,
  itemsError: '',
})

const statusFilterModal = reactive({
  show: false,
  selectedId: 'all',
})

const isReadOnly = computed(() => Boolean(route.meta.readOnly))

const filterOptions = [
  { id: 'all', label: 'Semua' },
  { id: 'overdue', label: 'Overdue' },
  { id: 'due_soon', label: 'Jatuh Tempo <= 7 Hari' },
  { id: 'unpaid', label: 'Belum Bayar' },
]

const statusFilterLayout = computed(() => {
  return [
    filterOptions[0],
    filterOptions[2],
    filterOptions[1],
    filterOptions[3],
  ].filter(Boolean)
})

const activeFilterLabel = computed(() => {
  const found = filterOptions.find(opt => opt.id === activeFilter.value)
  return found?.label || 'Semua'
})

const detailItems = computed(() => detailModal.items || [])

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

  const start = String(dateFilter.start || '').trim()
  const end = String(dateFilter.end || '').trim()
  if (start) {
    data = data.filter(row => String(row.order_date || '') >= start)
  }
  if (end) {
    data = data.filter(row => String(row.order_date || '') <= end)
  }

  if (activeFilter.value === 'overdue') {
    data = data.filter(row => row.is_overdue)
  } else if (activeFilter.value === 'due_soon') {
    data = data.filter(row => isDueSoon(row))
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

function onDateStartEnter() {
  if (!dateFilter.end) {
    dateFilter.end = toIsoDate(new Date())
  }
  nextTick(() => dateEndInput.value?.focus())
}

function openStatusFilterModal() {
  statusFilterModal.selectedId = 'all'
  statusFilterModal.show = true
}

function closeStatusFilterModal() {
  statusFilterModal.show = false
}

function applyStatusFilterById(filterId) {
  const opt = filterOptions.find(item => item.id === filterId)
  if (!opt) return
  activeFilter.value = opt.id
  closeStatusFilterModal()
}

function moveStatusFilterSelection(direction) {
  const current = statusFilterModal.selectedId || 'all'
  const nextMap = {
    all: { down: 'overdue', right: 'due_soon', left: 'all', up: 'all' },
    overdue: { up: 'all', right: 'unpaid', down: 'overdue', left: 'overdue' },
    due_soon: { down: 'unpaid', left: 'all', right: 'due_soon', up: 'due_soon' },
    unpaid: { up: 'due_soon', left: 'overdue', right: 'unpaid', down: 'unpaid' },
  }

  const nextId = nextMap[current]?.[direction] || current
  statusFilterModal.selectedId = nextId
}

function statusFilterIcon(filterId) {
  switch (filterId) {
    case 'overdue':
      return 'pi pi-exclamation-circle'
    case 'due_soon':
      return 'pi pi-clock'
    case 'unpaid':
      return 'pi pi-times-circle'
    default:
      return 'pi pi-list'
  }
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
  cancelPaymentConfirm()
  nextTick(() => pageEl.value?.focus())
}

function onPaymentAmountInput(e) {
  const parsed = parseAmountInput(e.target.value)
  paymentModal.amountInput = parsed > 0 ? formatAmountInput(parsed) : ''
}

function focusPaymentMethod() {
  nextTick(() => paymentMethodInput.value?.focus())
}

function focusPaymentNote() {
  nextTick(() => paymentNoteInput.value?.focus())
}

function onPaymentFieldArrow(e) {
  const key = e.key
  if (!['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(key)) return
  e.preventDefault()

  const order = [
    paymentDateInput.value,
    paymentAmountInput.value,
    paymentMethodInput.value,
    paymentNoteInput.value,
  ]

  const current = e.target
  const currentIndex = order.findIndex(el => el === current)
  if (currentIndex === -1) return

  const step = (key === 'ArrowDown' || key === 'ArrowRight') ? 1 : -1
  const nextIndex = Math.min(order.length - 1, Math.max(0, currentIndex + step))
  order[nextIndex]?.focus()
}

async function loadSaleItemsForDetail(saleId) {
  if (!saleId) {
    detailModal.items = []
    detailModal.itemsError = ''
    return
  }

  detailModal.itemsLoading = true
  detailModal.itemsError = ''

  try {
    const { data, error } = await supabase
      .from('sale_items')
      .select('id, product_kode, product_nama, qty, unit_price, total')
      .eq('sale_id', saleId)
      .order('created_at', { ascending: true })

    if (error) throw error
    detailModal.items = data || []
  } catch (err) {
    detailModal.items = []
    detailModal.itemsError = String(err?.message || err || 'Gagal memuat item transaksi.')
  } finally {
    detailModal.itemsLoading = false
  }
}

function buildPaymentAllocation() {
  if (!paymentModal.sale || paymentModal.saving) return null

  const amount = parseAmountInput(paymentModal.amountInput)
  const customerId = paymentModal.sale.customer_id
  const customerOutstanding = getCustomerOutstanding(customerId)
  paymentModal.error = ''

  if (!customerId) {
    paymentModal.error = 'Data customer pada transaksi ini tidak valid.'
    return null
  }

  if (!paymentModal.paymentDate) {
    paymentModal.error = 'Tanggal bayar wajib diisi.'
    return null
  }

  if (!amount || amount <= 0) {
    paymentModal.error = 'Nominal bayar harus lebih dari 0.'
    return null
  }

  if (amount > customerOutstanding) {
    paymentModal.error = `Nominal bayar tidak boleh melebihi sisa tagihan customer (${formatRp(customerOutstanding)}).`
    return null
  }

  const allocation = allocateCustomerPaymentFifo({
    salesRows: billingRows.value,
    customerId,
    amount,
  })

  if (!allocation.allocations.length || allocation.allocatedAmount <= 0) {
    paymentModal.error = 'Tidak ada transaksi yang bisa dialokasikan untuk pembayaran ini.'
    return null
  }

  if (allocation.unallocatedAmount > 0) {
    paymentModal.error = `Sebagian nominal belum teralokasi (${formatRp(allocation.unallocatedAmount)}). Periksa data piutang customer.`
    return null
  }

  return allocation
}

function requestPaymentConfirm() {
  const allocation = buildPaymentAllocation()
  if (!allocation) return
  paymentConfirm.allocation = allocation
  paymentConfirm.amount = allocation.allocatedAmount
  paymentConfirm.show = true
  paymentConfirm.openedAt = Date.now()
}

function cancelPaymentConfirm() {
  paymentConfirm.show = false
  paymentConfirm.allocation = null
  paymentConfirm.amount = 0
  paymentConfirm.openedAt = 0
}

async function confirmPayment() {
  if (!paymentConfirm.allocation) return
  await submitPayment(paymentConfirm.allocation)
}

async function submitPayment(allocation) {
  if (!paymentModal.sale || paymentModal.saving || !allocation) return

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

    cancelPaymentConfirm()
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

async function openDetailModal(row) {
  if (!row) return
  detailModal.sale = row
  detailModal.show = true
  await loadSaleItemsForDetail(row.sale_id)
}

function closeDetailModal() {
  detailModal.show = false
  detailModal.sale = null
  detailModal.items = []
  detailModal.itemsError = ''
  detailModal.itemsLoading = false
  nextTick(() => pageEl.value?.focus())
}

function openPaymentFromDetail() {
  const row = detailModal.sale
  closeDetailModal()
  if (row) openPaymentModal(row)
}

function onGlobalKey(e) {
  if (statusFilterModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      closeStatusFilterModal()
      return
    }
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      moveStatusFilterSelection('down')
      return
    }
    if (e.key === 'ArrowUp') {
      e.preventDefault()
      moveStatusFilterSelection('up')
      return
    }
    if (e.key === 'ArrowLeft') {
      e.preventDefault()
      moveStatusFilterSelection('left')
      return
    }
    if (e.key === 'ArrowRight') {
      e.preventDefault()
      moveStatusFilterSelection('right')
      return
    }
    if (e.key === 'Enter') {
      e.preventDefault()
      applyStatusFilterById(statusFilterModal.selectedId)
      return
    }
  }

  if (paymentConfirm.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      cancelPaymentConfirm()
      return
    }
    if (e.key === 'Enter') {
      e.preventDefault()
      if (Date.now() - (paymentConfirm.openedAt || 0) < 250) return
      confirmPayment()
    }
    return
  }

  if (paymentModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      closePaymentModal()
      return
    }
    if (e.key === 'F10') {
      e.preventDefault()
      requestPaymentConfirm()
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

  if (e.key === 'F2') {
    e.preventDefault()
    focusKey.value = 'date-start'
    nextTick(() => dateStartInput.value?.focus())
    return
  }

  if (e.key === 'F3') {
    e.preventDefault()
    openStatusFilterModal()
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
</style>
