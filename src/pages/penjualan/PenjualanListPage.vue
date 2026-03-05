<template>
  <div class="penjualan-list-page" ref="pageEl" tabindex="-1">

    <!-- ── PAGE HEADER ──────────────────────────────────── -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Daftar Order Penjualan</h1>
        <p class="g-subtitle">
          <kbd>↑</kbd><kbd>↓</kbd> Navigasi • <kbd>Enter</kbd> Detail • <kbd>F10</kbd> Print • <kbd>Esc</kbd> Kembali
        </p>
      </div>
      <button class="btn-secondary" @click="$router.push('/penjualan')" title="Kembali ke Menu (Esc)">
        <i class="pi pi-arrow-left"></i>
        <span>Menu</span>
      </button>
    </div>

    <!-- ── SEARCH & FILTER BAR ──────────────────────────── -->
    <div class="search-bar">
      <div class="search-dual-input">
        <div class="search-field">
          <label class="search-label">
            <i class="pi pi-hashtag"></i>
            No. Order
          </label>
          <input
            ref="searchInput"
            v-model="searchOrderNo"
            type="text"
            class="search-input"
            placeholder="Contoh: 2600001"
            @input="onOrderNoInput"
            autocomplete="off"
          />
        </div>
        <div class="search-divider">ATAU</div>
        <div class="search-field">
          <label class="search-label">
            <i class="pi pi-calendar"></i>
            Tanggal (DD/MM/YY)
          </label>
          <input
            v-model="searchDate"
            type="text"
            class="search-input"
            placeholder="Contoh: 04/03/26"
            @input="onDateInput"
            autocomplete="off"
          />
        </div>
        <button 
          v-if="searchOrderNo || searchDate" 
          class="clear-btn" 
          @click="clearSearch" 
          title="Clear (Esc)"
        >
          <i class="pi pi-times"></i>
          Clear
        </button>
      </div>

      <div class="filter-group">
        <button 
          class="filter-period-btn"
          :class="{ active: filterPeriod === 'all' }"
          @click="applyPeriodFilter('all')"
        >
          Semua
        </button>
        <button 
          class="filter-period-btn"
          :class="{ active: filterPeriod === 'today' }"
          @click="applyPeriodFilter('today')"
        >
          Hari Ini
        </button>
        <button 
          class="filter-period-btn"
          :class="{ active: filterPeriod === 'week' }"
          @click="applyPeriodFilter('week')"
        >
          Minggu Ini
        </button>
        <button 
          class="filter-period-btn"
          :class="{ active: filterPeriod === 'month' }"
          @click="applyPeriodFilter('month')"
        >
          Bulan Ini
        </button>
      </div>
    </div>

    <!-- ── RESULT META ──────────────────────────────────── -->
    <div class="result-meta">
      <span class="result-count">
        <b>{{ filteredOrders.length }}</b> order
        <span v-if="searchOrderNo || searchDate || filterPeriod !== 'all'" class="meta-filter">
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
              <p v-else-if="searchDate">Tidak ada order pada tanggal "<b>{{ searchDate }}</b>"</p>
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
            @click="selectedRowIndex = idx"
            @dblclick="viewOrder(order)"
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

    <!-- ═══════════════════════════════════════════════════
         MODAL VIEW ORDER DETAIL
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="detailModal.show" class="modal-overlay" @click.self="detailModal.show = false">
          <div class="modal-box modal-box--lg" role="dialog">
            <div class="modal-header">
              <i class="pi pi-file-edit"></i>
              <h3 class="modal-title">Detail Order: {{ detailModal.order?.no_order }}</h3>
              <button class="modal-close" @click="detailModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body" v-if="detailModal.order">
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
const searchInput = ref(null)

// ───────────────────────────────────────────────────────────
// STATE
// ───────────────────────────────────────────────────────────
const loading = ref(false)
const orders = ref([])
const searchOrderNo = ref('')
const searchDate = ref('')
const filterStatus = ref('')
const filterPeriod = ref('all')
const selectedRowIndex = ref(0)
const rowRefs = new Map()

const PAGE_SIZE = 20
const currentPage = ref(1)

const detailModal = reactive({
  show: false,
  order: null,
  items: [],
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
  // Filter by date (DD/MM/YY format)
  else if (searchDate.value) {
    const dateInput = searchDate.value.trim()
    // Parse DD/MM/YY to YYYY-MM-DD for comparison
    const parsedDate = parseDateInput(dateInput)
    if (parsedDate) {
      result = result.filter(order => {
        const orderDate = order.order_date.split('T')[0] // Get YYYY-MM-DD part
        return orderDate === parsedDate
      })
    }
  }

  // Filter by period
  if (filterPeriod.value !== 'all') {
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    
    if (filterPeriod.value === 'today') {
      result = result.filter(order => {
        const orderDate = new Date(order.order_date)
        return orderDate >= today
      })
    } else if (filterPeriod.value === 'week') {
      const startOfWeek = new Date(today)
      startOfWeek.setDate(today.getDate() - today.getDay())
      result = result.filter(order => {
        const orderDate = new Date(order.order_date)
        return orderDate >= startOfWeek
      })
    } else if (filterPeriod.value === 'month') {
      const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1)
      result = result.filter(order => {
        const orderDate = new Date(order.order_date)
        return orderDate >= startOfMonth
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

// ───────────────────────────────────────────────────────────
// LIFECYCLE
// ───────────────────────────────────────────────────────────
onMounted(() => {
  window.addEventListener('keydown', onGlobalKey)
  pageEl.value?.focus()
  loadOrders()
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

function applyPeriodFilter(period) {
  filterPeriod.value = period
  currentPage.value = 1
}

// ───────────────────────────────────────────────────────────────
// SEARCH FUNCTIONS
// ───────────────────────────────────────────────────────────────
function onOrderNoInput() {
  // When order number is typed, clear date
  if (searchOrderNo.value) {
    searchDate.value = ''
  }
  currentPage.value = 1
}

function onDateInput() {
  // When date is typed, clear order number
  if (searchDate.value) {
    searchOrderNo.value = ''
  }
  currentPage.value = 1
}

function clearSearch() {
  searchOrderNo.value = ''
  searchDate.value = ''
  currentPage.value = 1
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
  if (detailModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      detailModal.show = false
    }
    return
  }

  if (printModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      printModal.show = false
    }
    return
  }

  // Escape: Back to menu
  if (e.key === 'Escape') {
    e.preventDefault()
    router.push('/penjualan')
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

  // Esc: Clear search
  // Escape handled earlier in function - back to menu

  // Ctrl+F: Focus search
  if (e.ctrlKey && e.key === 'f') {
    e.preventDefault()
    searchInput.value?.focus()
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

async function deleteOrder(order) {
  const confirm = window.confirm(
    `Hapus order ${order.no_order}?\n\n` +
    `Customer: ${order.customer_nama}\n` +
    `Total: ${formatRp(order.subtotal)}\n\n` +
    `Data yang dihapus tidak dapat dikembalikan.`
  )

  if (!confirm) return

  try {
    const { error } = await supabase
      .from('sales')
      .delete()
      .eq('id', order.id)

    if (error) throw error

    alert(`Order ${order.no_order} berhasil dihapus`)
    loadOrders() // Reload
  } catch (err) {
    console.error('[deleteOrder]', err)
    alert('Gagal menghapus order: ' + err.message)
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