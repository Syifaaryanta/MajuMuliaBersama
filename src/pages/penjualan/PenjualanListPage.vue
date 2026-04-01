<template>
  <div class="penjualan-list-page" ref="pageEl" tabindex="-1">

    <!-- ── PAGE HEADER CARD ──────────────────────────────────── -->
    <div class="page-header-card">
      <div class="page-header">
        <div class="page-header-left">
          <h1 class="page-header-title">Riwayat Order Penjualan</h1>
        </div>
      </div>
    </div>

    <!-- ── FILTER SUMMARY ───────────────────────────────── -->
    <div class="search-bar" v-if="showResults">
      <div class="filter-summary">
        <div class="filter-period-wrap">
          <span class="filter-period-label">Periode</span>
          <span class="filter-chip" v-if="searchOrderNo">
            <i class="pi pi-hashtag"></i>
            No. Order: {{ searchOrderNo }}
          </span>
          <span class="filter-chip" v-else>
            <i class="pi pi-calendar"></i>
            {{ activeFilterLabel }}
          </span>
        </div>
      </div>
    </div>

    <!-- ── TABLE CONTAINER ─────────────────────────────────── -->
    <div class="table-container" v-if="showResults">
      <!-- ── RESULT META ──────────────────────────────────── -->
      <div class="result-meta">
        <span class="result-count">
          <b>{{ filteredOrders.length }}</b> order
          <span v-if="searchOrderNo || searchDateStart || searchDateEnd" class="meta-filter">
            (dari {{ orders.length }} total)
          </span>
        </span>
      </div>

      <!-- ── ORDERS TABLE ─────────────────────────────────── -->
      <div class="table-wrap">
      <table class="g-table g-table--riwayat">
        <thead>
          <tr>
            <th class="col-no">#</th>
            <th class="col-order">No. Order</th>
            <th class="col-date">Tanggal</th>
            <th class="col-customer">Customer</th>
            <th class="col-items-nama">Nama Barang</th>
            <th class="col-items-qty">Qty</th>
            <th class="col-total">Total</th>
            <th class="col-status">Status</th>
          </tr>
        </thead>
        <tbody v-if="loading">
          <tr v-for="n in 10" :key="n">
            <td colspan="8"><div class="skeleton"></div></td>
          </tr>
        </tbody>
        <tbody v-else-if="pagedOrders.length === 0">
          <tr>
            <td colspan="8" class="empty-cell">
              <i class="pi pi-inbox"></i>
              <p v-if="searchOrderNo">Tidak ada order dengan No. Order "<b>{{ searchOrderNo }}</b>"</p>
              <p v-else-if="searchDateStart || searchDateEnd">Tidak ada order pada periode "<b>{{ activeFilterLabel }}</b>"</p>
              <p v-else>Belum ada order penjualan.</p>
            </td>
          </tr>
        </tbody>
        <tbody v-else>
          <tr
            v-for="(order, idx) in pagedOrders"
            :key="order.id"
            :ref="el => setRowRef(el, idx)"
            :class="{ 'g-row--active': selectedRowIndex === idx }"
            @click="onRowClick(order, idx)"
          >
            <td class="col-no">{{ (currentPage - 1) * PAGE_SIZE + idx + 1 }}</td>
            <td class="col-order">
              <span class="order-badge">{{ order.no_order }}</span>
              <div class="customer-addr">Fraktur: {{ order.no_faktur || '-' }}</div>
            </td>
            <td class="col-date">{{ formatDate(order.order_date) }}</td>
            <td class="col-customer">
              <div class="customer-cell">
                <span class="customer-name">{{ order.customer_nama }}</span>
                <span class="customer-addr" v-if="order.customer_alamat">{{ order.customer_alamat }}</span>
              </div>
            </td>
            <td class="col-items-nama">
              <div class="items-list" v-if="order.items && order.items.length > 0">
                <div v-for="(item, idx) in order.items" :key="idx" class="item-row-nama">
                  <span class="item-row-no">{{ idx + 1 }}.</span>
                  <span class="item-row-text">{{ item.product_nama }}</span>
                </div>
              </div>
              <span v-else class="items-empty">-</span>
            </td>
            <td class="col-items-qty">
              <div class="items-qty-list" v-if="order.items && order.items.length > 0">
                <div v-for="(item, idx) in order.items" :key="idx" class="item-qty-val">
                  {{ item.qty }}
                </div>
              </div>
              <span v-else class="items-empty">-</span>
            </td>
            <td class="col-total">
              <span class="harga-val">{{ formatRp(order.subtotal) }}</span>
            </td>
            <td class="col-status">
              <span class="status-badge" :class="`status-${order.status}`">
                {{ order.status === 'completed' ? 'Selesai' : 'Draft' }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    </div><!-- End table-container -->

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showFilterModal" class="modal-overlay" @click.self="onFilterOverlayClick">
          <form class="modal-box modal-box--filter" @submit.prevent="submitFilter">
            <div class="modal-header modal-header--blue">
              <div class="modal-header-left">
                <div class="modal-header-icon">
                  <i class="pi pi-filter"></i>
                </div>
                <h3 class="modal-title">Filter Riwayat Transaksi</h3>
              </div>
            </div>

            <div class="modal-body">
              <p class="modal-helper">Isi No. Order atau rentang tanggal, lalu tekan Enter.</p>

              <div class="filter-modal-grid">
                <div class="search-field">
                  <label class="search-label">
                    <i class="pi pi-calendar"></i>
                    Tanggal Awal (DD/MM/YY)
                  </label>
                  <input
                    ref="inputTglAwal"
                    v-model="searchDateStart"
                    type="text"
                    class="search-input"
                    placeholder="05/03/26"
                    autocomplete="off"
                    :disabled="!!searchOrderNo"
                    @keydown.enter.prevent="onDateStartEnter"
                  />
                </div>

                <div class="search-field">
                  <label class="search-label">
                    <i class="pi pi-calendar"></i>
                    Tanggal Akhir (DD/MM/YY)
                  </label>
                  <input
                    ref="inputTglAkhir"
                    v-model="searchDateEnd"
                    type="text"
                    class="search-input"
                    placeholder="06/03/26"
                    autocomplete="off"
                    :disabled="!!searchOrderNo"
                    @keydown.enter.prevent="onDateEndEnter"
                  />
                </div>

                <div class="search-field filter-full">
                  <label class="search-label">
                    <i class="pi pi-hashtag"></i>
                    No. Order <span class="optional-note">opsional</span>
                  </label>
                  <input
                    ref="inputNoOrder"
                    v-model="searchOrderNo"
                    type="text"
                    class="search-input"
                    placeholder="Kosongkan untuk filter tanggal"
                    autocomplete="off"
                    @keydown.enter.prevent="onNoOrderEnter"
                  />
                </div>
              </div>

              <p v-if="filterError" class="modal-error-inline">{{ filterError }}</p>
            </div>

            <div class="modal-footer">
              <button type="button" class="btn-secondary" @click="onFilterCancel">Batal</button>
              <button type="submit" class="btn-primary">
                <i class="pi pi-check"></i>
                <span>Enter</span>
              </button>
            </div>
          </form>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════
         MODAL VIEW ORDER DETAIL
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="detailModal.show" class="modal-overlay" @click.self="detailModal.show = false">
          <div class="modal-box modal-box--detail modal-box--history-detail" role="dialog">
            <div class="modal-header modal-header--blue">
              <div class="modal-header-left">
                <div class="modal-header-icon">
                  <i class="pi pi-file-edit"></i>
                </div>
                <h3 class="modal-title">Detail Order: {{ detailModal.order?.no_order }}</h3>
                <span class="status-badge detail-header-status" :class="`status-${detailModal.order?.status}`">
                  {{ detailModal.order?.status === 'completed' ? 'Selesai' : 'Draft' }}
                </span>
              </div>
              <button class="modal-close" @click="detailModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body modal-body--detail" v-if="detailModal.order">
              <div class="detail-top-panels">
                <!-- Order Header Info -->
                <div class="detail-section detail-panel">
                  <h4 class="detail-section-title">Informasi Order</h4>
                  <div class="detail-grid">
                    <div class="detail-item">
                      <label>No. Order:</label>
                      <strong>{{ detailModal.order.no_order }}</strong>
                    </div>
                    <div class="detail-item">
                      <label>No. Fraktur:</label>
                      <strong>{{ detailModal.order.no_faktur || '-' }}</strong>
                    </div>
                    <div class="detail-item">
                      <label>Tanggal:</label>
                      <strong>{{ formatDate(detailModal.order.order_date) }}</strong>
                    </div>
                    <div class="detail-item">
                      <label>Pengiriman:</label>
                      <strong>{{ detailModal.order.diantar ? 'Diantar' : 'Diambil' }}</strong>
                    </div>
                    <div class="detail-item">
                      <label>Jatuh Tempo:</label>
                      <strong>{{ detailModal.order.limit_bulan + 1 }} Bulan</strong>
                    </div>
                  </div>
                </div>

                <!-- Customer Info -->
                <div class="detail-section detail-panel">
                  <h4 class="detail-section-title">Customer</h4>
                  <div class="detail-grid">
                    <div class="detail-item detail-item-full">
                      <label>Nama:</label>
                      <strong>{{ detailModal.order.customer_nama }}</strong>
                    </div>
                    <div class="detail-item detail-item-full" v-if="detailModal.order.customer_alamat">
                      <label>Alamat:</label>
                      <span>{{ detailModal.order.customer_alamat }}</span>
                    </div>
                    <div class="detail-item" v-if="detailModal.order.customer_telp">
                      <label>No. Telp:</label>
                      <span>{{ detailModal.order.customer_telp }}</span>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Items Table -->
              <div class="detail-section">
                <h4 class="detail-section-title">Daftar Barang</h4>
                <table class="detail-table">
                  <thead>
                    <tr>
                      <th>#</th>
                      <th>Kode</th>
                      <th>Nama Barang</th>
                      <th>Qty</th>
                      <th>Harga Satuan</th>
                      <th>Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(item, idx) in detailModal.items" :key="item.id">
                      <td>{{ idx + 1 }}</td>
                      <td><span class="item-kode">{{ item.product_kode }}</span></td>
                      <td>{{ item.product_nama }}</td>
                      <td>{{ item.qty }}</td>
                      <td>{{ formatRp(item.unit_price) }}</td>
                      <td><strong>{{ formatRp(item.total) }}</strong></td>
                    </tr>
                    <tr v-if="Number(detailModal.order.extra_charge_amount || 0) !== 0" class="detail-adjustment-row">
                      <td>{{ detailModal.items.length + 1 }}</td>
                      <td><span class="item-kode">-</span></td>
                      <td><strong class="detail-adjustment-label">{{ detailModal.order.extra_charge_desc || 'Biaya Tambahan' }}</strong></td>
                      <td>-</td>
                      <td>-</td>
                      <td><strong class="detail-adjustment-value">{{ formatRp(detailModal.order.extra_charge_amount || 0) }}</strong></td>
                    </tr>
                  </tbody>
                  <tfoot>
                    <tr>
                      <td colspan="5" class="text-right"><strong>Subtotal:</strong></td>
                      <td><strong class="total-value">{{ formatRp(detailModal.order.subtotal) }}</strong></td>
                    </tr>
                  </tfoot>
                </table>
                <p v-if="detailModal.order.sender_note" class="detail-sender-note">
                  <strong class="detail-sender-note-label">Keterangan Pengirim:</strong> {{ detailModal.order.sender_note }}
                </p>
              </div>
            </div>
            <div class="modal-footer modal-footer--history-detail">
              <button class="btn-secondary" @click="detailModal.show = false">
                Tutup <kbd>Esc</kbd>
              </button>
              <button class="btn-primary" @click="printOrder(detailModal.order)">
                <i class="pi pi-print"></i>
                Print <kbd>P</kbd>
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════
         MODAL DELETE CONFIRMATION
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="deleteModal.show" class="modal-overlay" @click.self="cancelDelete">
          <div class="modal-box modal-box--confirm modal-box--delete-confirm" role="dialog">
            <div class="modal-header modal-header--danger">
              <div class="modal-header-icon">
                <i class="pi pi-exclamation-triangle"></i>
              </div>
              <h3 class="modal-title">Konfirmasi Hapus Order</h3>
              <button class="modal-close" @click="cancelDelete" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body modal-body--confirm" v-if="deleteModal.order">
              <p class="confirm-message">Yakin hapus order ini?</p>
              <div class="delete-info">
                <div class="info-row">
                  <span class="info-label">No. Order:</span>
                  <span class="info-value">{{ deleteModal.order.no_order }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">No. Fraktur:</span>
                  <span class="info-value">{{ deleteModal.order.no_faktur || '-' }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">Customer:</span>
                  <span class="info-value">{{ deleteModal.order.customer_nama }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">Total:</span>
                  <span class="info-value">{{ formatRp(deleteModal.order.subtotal) }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">Status:</span>
                  <span class="status-badge" :class="`status-${deleteModal.order.status}`">
                    {{ deleteModal.order.status === 'completed' ? 'Selesai' : 'Draft' }}
                  </span>
                </div>
              </div>
              <div class="delete-warning" v-if="deleteModal.order.status === 'completed'">
                <i class="pi pi-info-circle"></i>
                <span>Stok barang akan dikembalikan ke gudang.</span>
              </div>
            </div>
            <div class="modal-footer">
              <button 
                class="btn-secondary" 
                @click="cancelDelete"
                ref="btnCancelDelete"
              >
                Batal
              </button>
              <button 
                class="btn-danger" 
                @click="confirmDelete"
                ref="btnConfirmDelete"
              >
                Hapus Order
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup>
import { ref, reactive, computed, nextTick, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { sortOrdersNewestFirst } from '@/lib/orderSort'

const router = useRouter()
const route = useRoute()

const SALES_HISTORY_DETAIL_KEY = 'penjualan_list_open_no_order'

// ───────────────────────────────────────────────────────────
// REFS
// ───────────────────────────────────────────────────────────
const pageEl = ref(null)
const inputNoOrder = ref(null)
const inputTglAwal = ref(null)
const inputTglAkhir = ref(null)
const btnCancelDelete = ref(null)
const btnConfirmDelete = ref(null)

// ───────────────────────────────────────────────────────────
// ───────────────────────────────────────────────────────────
// DEFAULT MONTH RANGE
// ───────────────────────────────────────────────────────────
function getDefaultMonthRange() {
  const now = new Date()
  const yy = String(now.getFullYear()).slice(-2)
  const mm = String(now.getMonth() + 1).padStart(2, '0')
  const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
  return {
    start: `01/${mm}/${yy}`,
    end: `${String(lastDay).padStart(2, '0')}/${mm}/${yy}`
  }
}
const _defaultRange = getDefaultMonthRange()

// STATE
// ───────────────────────────────────────────────────────────
const loading = ref(false)
const orders = ref([])
const searchOrderNo = ref('')
const searchDateStart = ref(_defaultRange.start)
const searchDateEnd = ref(_defaultRange.end)
const showFilterModal = ref(true)
const filterError = ref('')
const showResults = ref(false)
const selectedRowIndex = ref(0)
const rowRefs = new Map()

const PAGE_SIZE = 20
const currentPage = ref(1)

const detailModal = reactive({
  show: false,
  order: null,
  items: [],
})

const deleteModal = reactive({
  show: false,
  order: null,
})

// ───────────────────────────────────────────────────────────
// COMPUTED
// ───────────────────────────────────────────────────────────
const filteredOrders = computed(() => {
  let result = orders.value

  // Filter by order number
  if (searchOrderNo.value) {
    const q = searchOrderNo.value.toLowerCase()
    result = result.filter(order =>
      order.no_order.toLowerCase().includes(q)
    )
  }
  // Filter by date range (DD/MM/YY format)
  else if (searchDateStart.value || searchDateEnd.value) {
    const startDate = parseDateInput(searchDateStart.value)
    const endDate = parseDateInput(searchDateEnd.value)
    
    if (startDate && endDate) {
      result = result.filter(order => {
        const orderDate = order.order_date.split('T')[0] // Get YYYY-MM-DD part
        return orderDate >= startDate && orderDate <= endDate
      })
    } else if (startDate) {
      result = result.filter(order => {
        const orderDate = order.order_date.split('T')[0]
        return orderDate >= startDate
      })
    } else if (endDate) {
      result = result.filter(order => {
        const orderDate = order.order_date.split('T')[0]
        return orderDate <= endDate
      })
    }
  }

  return result
})

const totalPages = computed(() => Math.max(1, Math.ceil(filteredOrders.value.length / PAGE_SIZE)))

const pagedOrders = computed(() => {
  const start = (currentPage.value - 1) * PAGE_SIZE
  return filteredOrders.value.slice(start, start + PAGE_SIZE)
})

const activeFilterLabel = computed(() => {
  const start = searchDateStart.value || '-'
  const end = searchDateEnd.value || '-'
  return `${start} s/d ${end}`
})

// ───────────────────────────────────────────────────────────
// LIFECYCLE
// ───────────────────────────────────────────────────────────
onMounted(async () => {
  window.addEventListener('keydown', onGlobalKey)
  pageEl.value?.focus()

  const noOrderFromQuery = String(route.query.no_order || '').trim()
  const openDetailFromQuery = String(route.query.open_detail || '') === '1'

  let noOrderFromSession = ''
  let openDetailFromSession = false
  const rawHistoryIntent = sessionStorage.getItem(SALES_HISTORY_DETAIL_KEY)
  if (rawHistoryIntent) {
    try {
      const parsed = JSON.parse(rawHistoryIntent)
      noOrderFromSession = String(parsed?.noOrder || '').trim()
      openDetailFromSession = Boolean(parsed?.openDetail)
    } catch (err) {
      console.error('[parse SALES_HISTORY_DETAIL_KEY]', err)
    }
    sessionStorage.removeItem(SALES_HISTORY_DETAIL_KEY)
  }

  const targetNoOrder = noOrderFromQuery || noOrderFromSession
  const shouldOpenDetail = openDetailFromQuery || openDetailFromSession

  if (targetNoOrder) {
    searchOrderNo.value = targetNoOrder
    await searchByOrderNo()

    if (shouldOpenDetail) {
      const exact = orders.value.find(o => String(o.no_order || '').trim() === targetNoOrder)
      const fallback = orders.value[0]
      if (exact || fallback) {
        await viewOrder(exact || fallback)
      }
    }

    return
  }

  showFilterModal.value = true
  showResults.value = false
  nextTick(() => {
    inputTglAwal.value?.focus()
  })
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
})

// ───────────────────────────────────────────────────────────
// DATA LOADING
// ───────────────────────────────────────────────────────────
async function loadOrders() {
  loading.value = true
  try {
    // First get all orders
    const { data: ordersData, error: ordersError } = await supabase
      .from('sales')
      .select('*')
      .order('order_date', { ascending: false })
      .order('created_at', { ascending: false })

    if (ordersError) throw ordersError

    // Then get items for each order (first 3 items only for display)
    const ordersWithItems = await Promise.all(
      (ordersData || []).map(async (order) => {
        const { data: items, error: itemsError } = await supabase
          .from('sale_items')
          .select('product_nama, qty')
          .eq('sale_id', order.id)
          .order('created_at')

        if (itemsError) {
          console.error('[loadOrders items]', itemsError)
        }

        return {
          ...order,
          items: items || [],
          total_items: items?.length || 0
        }
      })
    )

    orders.value = sortOrdersNewestFirst(ordersWithItems)
  } catch (err) {
    console.error('[loadOrders]', err)
    alert('Gagal memuat daftar order: ' + err.message)
  } finally {
    loading.value = false
  }
}

// ───────────────────────────────────────────────────────────────
// SEARCH FUNCTIONS - SEQUENTIAL FLOW
// ───────────────────────────────────────────────────────────────
async function onNoOrderEnter() {
  await submitFilter()
}

async function searchByOrderNo() {
  loading.value = true
  showResults.value = false
  filterError.value = ''
  try {
    const { data: ordersData, error: ordersError } = await supabase
      .from('sales')
      .select('*')
      .eq('status', 'completed')
      .ilike('no_order', `%${searchOrderNo.value}%`)
      .order('order_date', { ascending: false })

    if (ordersError) throw ordersError

    const ordersWithItems = await Promise.all(
      (ordersData || []).map(async (order) => {
        const { data: items } = await supabase
          .from('sale_items')
          .select('product_nama, qty')
          .eq('sale_id', order.id)
          .order('created_at')

        return {
          ...order,
          items: items || [],
          total_items: items?.length || 0
        }
      })
    )

    orders.value = sortOrdersNewestFirst(ordersWithItems)
    showResults.value = true
    showFilterModal.value = false
    currentPage.value = 1
    selectedRowIndex.value = 0
    
    // Auto-focus to first row after data loaded
    await nextTick()
    setTimeout(() => {
      pageEl.value?.focus()
    }, 100)
  } catch (err) {
    console.error('[searchByOrderNo]', err)
    alert('Gagal mencari order: ' + err.message)
  } finally {
    loading.value = false
  }
}

function onDateStartEnter() {
  focusDateEnd()
}

async function onDateEndEnter() {
  focusNoOrder()
}

async function searchByDateRange() {
  loading.value = true
  showResults.value = false
  filterError.value = ''
  try {
    const startDate = parseDateInput(searchDateStart.value)
    const endDate = parseDateInput(searchDateEnd.value)

    let query = supabase
      .from('sales')
      .select('*')
      .eq('status', 'completed')
      .order('order_date', { ascending: false })

    if (startDate) {
      query = query.gte('order_date', startDate)
    }
    if (endDate) {
      // Add 1 day to make it inclusive
      const endDateObj = new Date(endDate)
      endDateObj.setDate(endDateObj.getDate() + 1)
      const endDateInclusive = endDateObj.toISOString().split('T')[0]
      query = query.lt('order_date', endDateInclusive)
    }

    const { data: ordersData, error: ordersError } = await query

    if (ordersError) throw ordersError

    const ordersWithItems = await Promise.all(
      (ordersData || []).map(async (order) => {
        const { data: items } = await supabase
          .from('sale_items')
          .select('product_nama, qty')
          .eq('sale_id', order.id)
          .order('created_at')

        return {
          ...order,
          items: items || [],
          total_items: items?.length || 0
        }
      })
    )

    orders.value = sortOrdersNewestFirst(ordersWithItems)
    showResults.value = true
    showFilterModal.value = false
    currentPage.value = 1
    selectedRowIndex.value = 0
    
    // Auto-focus to first row after data loaded
    await nextTick()
    setTimeout(() => {
      pageEl.value?.focus()
    }, 100)
  } catch (err) {
    console.error('[searchByDateRange]', err)
    alert('Gagal mencari order: ' + err.message)
  } finally {
    loading.value = false
  }
}

function focusNoOrder() {
  nextTick(() => {
    inputNoOrder.value?.focus()
  })
}

function focusDateStart() {
  nextTick(() => {
    inputTglAwal.value?.focus()
  })
}

function focusDateEnd() {
  nextTick(() => {
    inputTglAkhir.value?.focus()
  })
}

function clearSearch() {
  searchOrderNo.value = ''
  searchDateStart.value = _defaultRange.start
  searchDateEnd.value = _defaultRange.end
  filterError.value = ''
  orders.value = []
  showResults.value = false
  showFilterModal.value = true
  currentPage.value = 1
  selectedRowIndex.value = 0
  focusDateStart()
}

function openFilterModal() {
  filterError.value = ''
  showFilterModal.value = true
  nextTick(() => {
    inputTglAwal.value?.focus()
  })
}

async function submitFilter() {
  const hasOrderNo = !!searchOrderNo.value.trim()
  const hasDateRange = !!searchDateStart.value || !!searchDateEnd.value

  if (!hasOrderNo && !hasDateRange) {
    filterError.value = 'Isi No. Order atau rentang tanggal terlebih dahulu.'
    return
  }

  if (hasOrderNo) {
    await searchByOrderNo()
    return
  }

  await searchByDateRange()
}

function onFilterCancel() {
  if (!showResults.value) {
    router.push('/penjualan')
    return
  }
  showFilterModal.value = false
}

function onFilterOverlayClick() {
  onFilterCancel()
}

// Parse DD/MM/YY to YYYY-MM-DD
function parseDateInput(dateStr) {
  const parts = dateStr.split('/')
  if (parts.length !== 3) return null
  
  const day = parts[0].padStart(2, '0')
  const month = parts[1].padStart(2, '0')
  let year = parts[2]
  
  // Convert YY to YYYY
  if (year.length === 2) {
    year = '20' + year
  }
  
  return `${year}-${month}-${day}`
}

// ───────────────────────────────────────────────────────────
// KEYBOARD SHORTCUTS
// ───────────────────────────────────────────────────────────
function onGlobalKey(e) {
  if (showFilterModal.value) {
    if (e.key === 'Escape') {
      e.preventDefault()
      if (showResults.value) {
        router.push('/penjualan')
      } else {
        onFilterCancel()
      }
      return
    }
    return
  }

  // Handle delete modal
  if (deleteModal.show) {
    if (e.key === 'Enter') {
      e.preventDefault()
      confirmDelete()
      return
    }
    if (e.key === 'Escape') {
      e.preventDefault()
      cancelDelete()
      return
    }
    return
  }

  // Handle detail modal
  if (detailModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      detailModal.show = false
      return
    }

    if (e.key === 'p' || e.key === 'P') {
      e.preventDefault()
      if (detailModal.order) {
        printOrder(detailModal.order)
      }
    }
    return
  }

  // If no results shown, let input fields handle their own keys
  if (!showResults.value) {
    if (e.key === 'Escape') {
      e.preventDefault()
      router.push('/penjualan')
    }
    return
  }

  // Escape: Hide results and show form again
  if (e.key === 'Escape') {
    e.preventDefault()
    openFilterModal()
    return
  }

  // Enter: View detail
  if (e.key === 'Enter') {
    e.preventDefault()
    if (pagedOrders.value[selectedRowIndex.value]) {
      viewOrder(pagedOrders.value[selectedRowIndex.value])
    }
    return
  }

  // Delete: Delete order
  if (e.key === 'Delete') {
    e.preventDefault()
    if (pagedOrders.value[selectedRowIndex.value]) {
      initiateDelete(pagedOrders.value[selectedRowIndex.value])
    }
    return
  }

  // F10: Print
  if (e.key === 'F10') {
    e.preventDefault()
    if (pagedOrders.value[selectedRowIndex.value]) {
      printOrder(pagedOrders.value[selectedRowIndex.value])
    }
    return
  }

  // Arrow navigation
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    if (selectedRowIndex.value < pagedOrders.value.length - 1) {
      selectedRowIndex.value++
      scrollToSelectedRow()
    }
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    if (selectedRowIndex.value > 0) {
      selectedRowIndex.value--
      scrollToSelectedRow()
    }
  }

  // Page navigation
  if (e.key === 'PageDown') {
    e.preventDefault()
    nextPage()
  } else if (e.key === 'PageUp') {
    e.preventDefault()
    prevPage()
  }
}

// ───────────────────────────────────────────────────────────
// ACTIONS
// ───────────────────────────────────────────────────────────
async function viewOrder(order) {
  detailModal.order = order
  detailModal.show = true

  // Load items
  try {
    const { data, error } = await supabase
      .from('sale_items')
      .select('*')
      .eq('sale_id', order.id)
      .order('created_at')

    if (error) throw error
    detailModal.items = data || []
  } catch (err) {
    console.error('[viewOrder]', err)
    alert('Gagal memuat detail order: ' + err.message)
  }
}

function onRowClick(order, idx) {
  selectedRowIndex.value = idx
  viewOrder(order)
}

function initiateDelete(order) {
  deleteModal.order = order
  deleteModal.show = true
  
  // Auto-focus to confirm button
  nextTick(() => {
    btnConfirmDelete.value?.focus()
  })
}

function cancelDelete() {
  deleteModal.show = false
  deleteModal.order = null
  // Return focus to table
  nextTick(() => {
    pageEl.value?.focus()
  })
}

async function confirmDelete() {
  const order = deleteModal.order
  if (!order) return

  deleteModal.show = false
  loading.value = true

  try {
    // 1. If order status is 'completed', return stock to warehouse
    if (order.status === 'completed') {
      // Get all items from this order
      const { data: items, error: itemsError } = await supabase
        .from('sale_items')
        .select('product_id, qty')
        .eq('sale_id', order.id)

      if (itemsError) throw itemsError

      // Return stock for each item
      for (const item of items || []) {
        const { data: product, error: getError } = await supabase
          .from('products')
          .select('stok')
          .eq('id', item.product_id)
          .single()

        if (getError) throw getError

        const { error: updateError } = await supabase
          .from('products')
          .update({ stok: (product.stok || 0) + item.qty })
          .eq('id', item.product_id)

        if (updateError) throw updateError
      }
    }

    // 2. Delete order items first (foreign key constraint)
    const { error: itemsDeleteError } = await supabase
      .from('sale_items')
      .delete()
      .eq('sale_id', order.id)

    if (itemsDeleteError) throw itemsDeleteError

    // 3. Delete order
    const { error: orderDeleteError } = await supabase
      .from('sales')
      .delete()
      .eq('id', order.id)

    if (orderDeleteError) throw orderDeleteError

    // Reload current search
    if (searchOrderNo.value) {
      await searchByOrderNo()
    } else if (searchDateStart.value || searchDateEnd.value) {
      await searchByDateRange()
    } else {
      // Clear everything
      clearSearch()
    }
  } catch (err) {
    console.error('[confirmDelete]', err)
    alert('Gagal menghapus order: ' + err.message)
  } finally {
    loading.value = false
    deleteModal.order = null
    // Return focus to table
    nextTick(() => {
      pageEl.value?.focus()
    })
  }
}

function printOrder(order) {
  printOrderToNota(order)
}

async function fetchItemsForPrint(orderId) {
  const { data, error } = await supabase
    .from('sale_items')
    .select('product_id, product_kode, product_nama, qty, unit_price, total')
    .eq('sale_id', orderId)
    .order('created_at')

  if (error) throw error
  return data || []
}

function paymentTermLabel(limitBulan) {
  const bulan = Number(limitBulan || 0) + 1
  return `${bulan} BULAN`
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;')
}

function chunkItems(itemsList, size = 15) {
  const chunks = []
  for (let i = 0; i < itemsList.length; i += size) {
    chunks.push(itemsList.slice(i, i + size))
  }
  return chunks.length ? chunks : [[]]
}

function buildNotaPrintHtml(payload, sortedItems) {
  const adjustmentLines = (payload.adjustmentRows || []).map(row => ({
    product_kode: '-',
    product_nama: row.description,
    qty: '-',
    unit_price: row.amount,
    total: row.amount,
  }))

  const allRows = sortedItems.concat(adjustmentLines)
  const pages = chunkItems(allRows, 15)

  const pageHtml = pages.map((pageRows, idx) => {
    const rows = pageRows.map(row => `
      <tr>
        <td>${escapeHtml(row.product_kode || '-')}</td>
        <td>${escapeHtml(row.product_nama || '-')}</td>
        <td class="text-right">${escapeHtml(row.qty)}</td>
        <td class="text-right">${escapeHtml(formatRp(Number(row.unit_price || 0)).replace('Rp ', ''))}</td>
        <td class="text-right">${escapeHtml(formatRp(Number(row.total || 0)).replace('Rp ', ''))}</td>
      </tr>
    `).join('')

    return `
      <section class="nota-page">
        <div class="nota-head">
          <div class="title-left">
            <div class="nama-toko">MAJU MULIA BERSAMA</div>
            <div class="kota">SEMARANG</div>
          </div>
          <div class="title-center">FAKTUR</div>
          <div class="title-right">
            <div>No. Faktur: ${escapeHtml(payload.header.no_faktur || '-')}</div>
            <div>Tanggal: ${escapeHtml(payload.header.order_date || '-')}</div>
            <div>No. Order: ${escapeHtml(payload.header.no_order || '-')}</div>
            <div>Salesmen: -</div>
            <div>Halaman: ${idx + 1}</div>
          </div>
        </div>

        <div class="meta-left">
          <div>Kepada: ${escapeHtml(payload.customer.nama || '-')} (${escapeHtml(payload.customer.kode || '-')})</div>
          <div>${escapeHtml(payload.customer.alamat || '-')}</div>
          <div>Pembayaran: ${escapeHtml(paymentTermLabel(payload.header.limit_bulan))}</div>
        </div>

        <table class="nota-table">
          <thead>
            <tr>
              <th class="col-kode">Kode Barang</th>
              <th class="col-nama">Nama Barang</th>
              <th class="col-qty">Qty</th>
              <th class="col-harga">Harga</th>
              <th class="col-jumlah">Jumlah</th>
            </tr>
          </thead>
          <tbody>
            ${rows}
          </tbody>
        </table>

        <div class="nota-bottom">
          <div class="bottom-left">
            <div>Keterangan: ${escapeHtml(payload.senderNote || '')}</div>
          </div>
          <div class="bottom-sign">
            <div>Dikirim Oleh</div>
            <div class="sign-line"></div>
          </div>
          <div class="bottom-sign">
            <div>Diterima Oleh</div>
            <div class="sign-line"></div>
          </div>
          <div class="subtotal-box">
            <div class="subtotal-label">Subtotal</div>
            <div class="subtotal-val">${escapeHtml(formatRp(payload.subtotal || 0).replace('Rp ', ''))}</div>
          </div>
        </div>
      </section>
    `
  }).join('')

  return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8" />
        <title>Print Nota ${escapeHtml(payload.header.no_order || '')}</title>
        <style>
          @page { size: 23.5cm 14cm; margin: 0; }
          body {
            margin: 0;
            font-family: 'Courier New', Courier, monospace;
            font-size: 12pt;
            font-weight: bold;
            color: black;
          }
          .nota-page {
            width: 23.5cm;
            height: 14cm;
            box-sizing: border-box;
            padding: 0.8cm 0.8cm 0.55cm;
            page-break-after: always;
          }
          .nota-page:last-child { page-break-after: auto; }
          .nota-head {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            align-items: start;
            margin-bottom: 0.35cm;
          }
          .title-center { text-align: center; letter-spacing: 0.22em; }
          .title-right { justify-self: end; text-align: left; font-size: 9.5pt; }
          .nama-toko { letter-spacing: 0.08em; }
          .kota { letter-spacing: 0.32em; font-size: 10pt; }
          .meta-left { margin-bottom: 0.24cm; font-size: 10pt; line-height: 1.25; }
          .nota-table { width: 100%; border-collapse: collapse; font-size: 9.5pt; }
          .nota-table th, .nota-table td { border: 1px solid #000; padding: 0.08cm 0.1cm; }
          .nota-table td { height: 0.42cm; }
          .col-kode { width: 18%; }
          .col-nama { width: 45%; }
          .col-qty { width: 9%; }
          .col-harga { width: 14%; }
          .col-jumlah { width: 14%; }
          .text-right { text-align: right; }
          .nota-bottom {
            margin-top: 0.18cm;
            display: grid;
            grid-template-columns: 1.25fr 0.8fr 0.8fr 0.55fr;
            align-items: end;
            gap: 0.2cm;
          }
          .bottom-left { font-size: 10pt; min-height: 1.1cm; }
          .bottom-sign { text-align: center; font-size: 10pt; }
          .sign-line { border-bottom: 1px solid #000; margin-top: 0.65cm; }
          .subtotal-box {
            border: 1px solid #000;
            min-height: 1.1cm;
            display: flex;
            flex-direction: column;
            justify-content: center;
            text-align: right;
            padding: 0.05cm 0.08cm;
            font-size: 10pt;
          }
          .subtotal-label { font-size: 8.5pt; }
        </style>
      </head>
      <body>${pageHtml}</body>
    </html>
  `
}

async function printOrderToNota(order) {
  if (!order?.id) return

  try {
    const items = await fetchItemsForPrint(order.id)
    if (!items.length) {
      alert('Order tidak memiliki item untuk diprint.')
      return
    }

    const adjustmentRows = Number(order?.extra_charge_amount || 0) !== 0
      ? [{
        description: String(order?.extra_charge_desc || 'Biaya Tambahan').trim(),
        amount: Number(order?.extra_charge_amount || 0),
      }]
      : []

    const payload = {
      header: {
        no_order: order.no_order,
        no_faktur: order.no_faktur,
        order_date: formatDate(order.order_date),
        limit_bulan: Number(order.limit_bulan || 0),
      },
      customer: {
        nama: order.customer_nama,
        kode: order.customer_kode || '-',
        alamat: order.customer_alamat,
      },
      senderNote: order.sender_note || '',
      items,
      adjustmentRows,
      subtotal: Number(order.subtotal || 0),
    }

    const html = buildNotaPrintHtml(payload, items)
    const win = window.open('', '_blank', 'width=1200,height=760')
    if (!win) {
      alert('Popup print diblokir browser. Izinkan popup lalu coba lagi.')
      return
    }

    win.document.open()
    win.document.write(html)
    win.document.close()

    win.onload = () => {
      win.focus()
      win.print()
    }
  } catch (err) {
    console.error('[printOrderToNota]', err)
    alert('Gagal memproses print: ' + err.message)
  }
}

// ───────────────────────────────────────────────────────────
// PAGINATION
// ───────────────────────────────────────────────────────────
function nextPage() {
  if (currentPage.value < totalPages.value) {
    currentPage.value++
    selectedRowIndex.value = 0
  }
}

function prevPage() {
  if (currentPage.value > 1) {
    currentPage.value--
    selectedRowIndex.value = 0
  }
}

// ───────────────────────────────────────────────────────────
// ROW REFS
// ───────────────────────────────────────────────────────────
function setRowRef(el, index) {
  if (el) {
    rowRefs.set(index, el)
  } else {
    rowRefs.delete(index)
  }
}

function scrollToSelectedRow() {
  nextTick(() => {
    const row = rowRefs.get(selectedRowIndex.value)
    if (row) {
      row.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    }
  })
}

// ───────────────────────────────────────────────────────────
// HELPERS
// ───────────────────────────────────────────────────────────
function formatDate(dateStr) {
  if (!dateStr) return '—'
  const d = new Date(dateStr)
  const day = String(d.getDate()).padStart(2, '0')
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const year = d.getFullYear()
  return `${day}/${month}/${year}`
}

function formatRp(val) {
  if (val == null || isNaN(val)) return 'Rp 0'
  return 'Rp ' + Number(val).toLocaleString('id-ID')
}
</script>

<style scoped>
@import '@/assets/styles.css';
@import '@/assets/pages/gudang/gudang-page.css';
@import '@/assets/components/table.css';
@import '@/assets/components/form.css';
@import '@/assets/components/modal.css';
@import '@/assets/pages/penjualan/penjualan-list-page.css';
</style>