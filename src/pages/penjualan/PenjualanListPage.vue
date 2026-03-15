<template>
  <div class="penjualan-list-page" ref="pageEl" tabindex="-1">

    <!-- ── PAGE HEADER CARD ──────────────────────────────────── -->
    <div class="page-header-card">
      <div class="page-header">
        <div class="page-header-left">
          <h1 class="page-header-title">Riwayat Order Penjualan</h1>
        </div>
        <button class="btn-secondary" @click="$router.push('/penjualan')" title="Kembali ke Menu (Esc)">
          <i class="pi pi-arrow-left"></i>
          <span>Menu</span>
        </button>
      </div>
    </div>

    <!-- ── FILTER SUMMARY ───────────────────────────────── -->
    <div class="search-bar" v-if="showResults">
      <div class="filter-summary">
        <div class="filter-chip-wrap">
          <span class="filter-chip" v-if="searchOrderNo">
            <i class="pi pi-hashtag"></i>
            No. Order: {{ searchOrderNo }}
          </span>
          <span class="filter-chip" v-else>
            <i class="pi pi-calendar"></i>
            {{ activeFilterLabel }}
          </span>
        </div>
        <button class="btn-secondary btn-filter" @click="openFilterModal" title="Esc">
          <i class="pi pi-filter"></i>
          <span>Ubah Filter</span>
        </button>
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
        <div class="result-meta-right">
          <span class="page-info">Hal {{ currentPage }} / {{ totalPages }}</span>
          <button class="icon-btn" :disabled="currentPage <= 1" @click="prevPage" title="PgUp">
            <i class="pi pi-chevron-left"></i>
          </button>
          <button class="icon-btn" :disabled="currentPage >= totalPages" @click="nextPage" title="PgDn">
            <i class="pi pi-chevron-right"></i>
          </button>
        </div>
      </div>

      <!-- ── ORDERS TABLE ─────────────────────────────────── -->
      <div class="table-wrap">
      <table class="g-table">
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
                <div v-for="(item, idx) in order.items.slice(0, 3)" :key="idx" class="item-row-nama">
                  {{ item.product_nama }}
                </div>
                <div v-if="order.items.length > 3" class="item-more">
                  +{{ order.items.length - 3 }} lainnya
                </div>
              </div>
              <span v-else class="items-empty">-</span>
            </td>
            <td class="col-items-qty">
              <div class="items-qty-list" v-if="order.items && order.items.length > 0">
                <div v-for="(item, idx) in order.items.slice(0, 3)" :key="idx" class="item-qty-val">
                  {{ item.qty }}
                </div>
                <div v-if="order.items.length > 3" class="item-more">
                   
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
          <div class="modal-box modal-box--detail" role="dialog">
            <div class="modal-header modal-header--blue">
              <div class="modal-header-icon">
                <i class="pi pi-file-edit"></i>
              </div>
              <h3 class="modal-title">Detail Order: {{ detailModal.order?.no_order }}</h3>
              <button class="modal-close" @click="detailModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body modal-body--detail" v-if="detailModal.order">
              <!-- Order Header Info -->
              <div class="detail-section">
                <h4 class="detail-section-title">Informasi Order</h4>
                <div class="detail-grid">
                  <div class="detail-item">
                    <label>No. Order:</label>
                    <strong>{{ detailModal.order.no_order }}</strong>
                  </div>
                  <div class="detail-item">
                    <label>Tanggal:</label>
                    <strong>{{ formatDate(detailModal.order.order_date) }}</strong>
                  </div>
                  <div class="detail-item">
                    <label>Status:</label>
                    <span class="status-badge" :class="`status-${detailModal.order.status}`">
                      {{ detailModal.order.status === 'completed' ? 'Selesai' : 'Draft' }}
                    </span>
                  </div>
                  <div class="detail-item">
                    <label>Pengiriman:</label>
                    <strong>{{ detailModal.order.diantar ? 'Diantar' : 'Diambil' }}</strong>
                  </div>
                  <div class="detail-item">
                    <label>Jatuh Tempo:</label>
                    <strong>{{ detailModal.order.limit_bulan + 1 }} Bulan</strong>
                  </div>
                  <div class="detail-item">
                    <label>Salesman:</label>
                    <strong>Sales {{ detailModal.order.salesman }}</strong>
                  </div>
                </div>
              </div>

              <!-- Customer Info -->
              <div class="detail-section">
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
                  </tbody>
                  <tfoot>
                    <tr>
                      <td colspan="5" class="text-right"><strong>Subtotal:</strong></td>
                      <td><strong class="total-value">{{ formatRp(detailModal.order.subtotal) }}</strong></td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="detailModal.show = false">
                Tutup <kbd>Esc</kbd>
              </button>
              <button class="btn-primary" @click="printOrder(detailModal.order)">
                <i class="pi pi-print"></i>
                Print
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════
         MODAL PRINT OPTIONS
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="printModal.show" class="modal-overlay" @click.self="printModal.show = false">
          <div class="modal-box modal-box--sm" role="dialog">
            <div class="modal-header">
              <i class="pi pi-print"></i>
              <h3 class="modal-title">Print Order</h3>
              <button class="modal-close" @click="printModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body" v-if="printModal.order">
              <div class="print-info">
                <p><strong>No. Order:</strong> {{ printModal.order.no_order }}</p>
                <p><strong>Customer:</strong> {{ printModal.order.customer_nama }}</p>
                <p><strong>Total:</strong> {{ formatRp(printModal.order.subtotal) }}</p>
              </div>
              <div class="print-options">
                <p class="print-note">
                  <i class="pi pi-info-circle"></i>
                  Fitur print akan segera ditambahkan. Saat ini Anda dapat:
                </p>
                <ul class="print-list">
                  <li>Lihat detail order untuk melihat informasi lengkap</li>
                  <li>Gunakan Ctrl+P untuk print halaman ini</li>
                </ul>
              </div>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="printModal.show = false">
                Tutup <kbd>Esc</kbd>
              </button>
              <button class="btn-primary" @click="viewOrder(printModal.order); printModal.show = false">
                <i class="pi pi-eye"></i>
                Lihat Detail
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
          <div class="modal-box modal-box--confirm" role="dialog">
            <div class="modal-header modal-header--danger">
              <div class="modal-header-icon">
                <i class="pi pi-exclamation-triangle"></i>
              </div>
              <h3 class="modal-title">Konfirmasi Hapus Order</h3>
            </div>
            <div class="modal-body modal-body--confirm" v-if="deleteModal.order">
              <p class="confirm-message">Yakin hapus order ini?</p>
              <div class="delete-info">
                <div class="info-row">
                  <span class="info-label">No. Order:</span>
                  <span class="info-value">{{ deleteModal.order.no_order }}</span>
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
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()

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

const printModal = reactive({
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
onMounted(() => {
  window.addEventListener('keydown', onGlobalKey)
  pageEl.value?.focus()
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
          .limit(3)

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

    orders.value = ordersWithItems
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
          .limit(3)

        return {
          ...order,
          items: items || [],
          total_items: items?.length || 0
        }
      })
    )

    orders.value = ordersWithItems
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
          .limit(3)

        return {
          ...order,
          items: items || [],
          total_items: items?.length || 0
        }
      })
    )

    orders.value = ordersWithItems
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
      onFilterCancel()
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
    }
    return
  }

  // Handle print modal
  if (printModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      printModal.show = false
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
        const { error: stockError } = await supabase.rpc('increment_product_stock', {
          p_product_id: item.product_id,
          p_qty: item.qty
        })

        // If RPC doesn't exist, fallback to manual update
        if (stockError && stockError.code === '42883') {
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
        } else if (stockError) {
          throw stockError
        }
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
  printModal.order = order
  printModal.show = true
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