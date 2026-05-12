<template>
  <div class="penjualan-list-page pembelian-draft-page" ref="pageEl" tabindex="-1">
    <div class="page-header-card">
      <div class="page-header">
        <div class="page-header-left">
          <h1 class="page-header-title">Order Tertunda Pembelian</h1>
        </div>
      </div>
    </div>

    <div class="search-bar">
      <div class="search-sequential">
        <div class="search-field">
          <label class="search-label">
            <i class="pi pi-hashtag"></i>
            No. Order
          </label>
          <input
            ref="inputNoOrder"
            v-model="searchOrderNo"
            type="text"
            class="search-input"
            placeholder="Tekan F1 lalu ketik no order"
            autocomplete="off"
            @keydown.enter="onNoOrderEnter"
            @keydown.esc="clearSearch"
          />
        </div>

        <div class="search-divider"></div>

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
            placeholder="Tekan F2 untuk isi default"
            autocomplete="off"
            :disabled="!!searchOrderNo"
            @keydown.enter="onDateStartEnter"
            @keydown.esc="focusNoOrder"
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
            placeholder="Tekan F2 untuk isi default"
            autocomplete="off"
            :disabled="!!searchOrderNo"
            @keydown.enter="onDateEndEnter"
            @keydown.esc="focusDateStart"
          />
        </div>
      </div>
    </div>

    <div class="table-container" v-if="showResults">
      <div class="result-meta">
        <span class="result-count">
          <b>{{ filteredOrders.length }}</b> order tertunda
          <span v-if="searchOrderNo || searchDateStart || searchDateEnd" class="meta-filter">
            (dari {{ orders.length }} total)
          </span>
        </span>
      </div>

      <div class="table-wrap">
        <table class="g-table">
          <thead>
            <tr>
              <th class="col-no">#</th>
              <th class="col-order">No. Order</th>
              <th class="col-date">Tanggal</th>
              <th class="col-supplier">Supplier</th>
              <th class="col-items-nama">Nama Barang</th>
              <th class="col-items-qty">Qty</th>
              <th class="col-total">Total</th>
              <th class="col-status">Status</th>
            </tr>
          </thead>
          <tbody v-if="loading">
            <tr v-for="n in 8" :key="n">
              <td colspan="8"><div class="skeleton"></div></td>
            </tr>
          </tbody>
          <tbody v-else-if="pagedOrders.length === 0">
            <tr>
              <td colspan="8" class="empty-cell">
                <i class="pi pi-inbox"></i>
                <p v-if="searchOrderNo">Tidak ada order tertunda dengan No. Order "<b>{{ searchOrderNo }}</b>"</p>
                <p v-else-if="searchDateStart || searchDateEnd">Tidak ada order tertunda pada rentang tanggal tersebut.</p>
                <p v-else>Belum ada order tertunda pembelian.</p>
              </td>
            </tr>
          </tbody>
          <tbody v-else>
            <tr
              v-for="(order, idx) in pagedOrders"
              :key="order.no_order"
              :ref="el => setRowRef(el, idx)"
              :class="{ 'g-row--active': selectedRowIndex === idx }"
              @click="selectedRowIndex = idx"
              @dblclick="viewOrder(order)"
            >
              <td class="col-no">{{ (currentPage - 1) * PAGE_SIZE + idx + 1 }}</td>
              <td class="col-order">
                <span class="order-badge">{{ order.no_order }}</span>
                <div class="customer-addr">Terms: {{ getTermLabel(order.terms || 'tunai') }}</div>
              </td>
              <td class="col-date">{{ formatDate(order.order_date) }}</td>
              <td class="col-supplier">
                <div class="customer-cell">
                  <span class="customer-name">{{ order.supplier?.nama || '-' }}</span>
                  <span class="customer-addr" v-if="order.supplier?.alamat">{{ order.supplier.alamat }}</span>
                </div>
              </td>
              <td class="col-items-nama">
                <div class="items-list" v-if="order.items && order.items.length > 0">
                  <div v-for="(item, itemIdx) in order.items.slice(0, 3)" :key="itemIdx" class="item-row-nama">
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
                  <div v-for="(item, itemIdx) in order.items.slice(0, 3)" :key="itemIdx" class="item-qty-val">
                    {{ item.qty }}
                  </div>
                  <div v-if="order.items.length > 3" class="item-more"></div>
                </div>
                <span v-else class="items-empty">-</span>
              </td>
              <td class="col-total">
                <span class="harga-val">{{ formatRp(order.subtotal) }}</span>
              </td>
              <td class="col-status">
                <span class="status-badge status-draft">Tertunda</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="detailModal.show" class="modal-overlay" @click.self="detailModal.show = false">
          <div class="modal-box modal-box--detail" role="dialog">
            <div class="modal-header modal-header--blue">
              <div class="modal-header-left">
                <div class="modal-header-icon">
                  <i class="pi pi-file-edit"></i>
                </div>
                <h3 class="modal-title">Detail Order: {{ detailModal.order?.no_order }}</h3>
                <span class="status-badge status-draft detail-header-status">Tertunda</span>
              </div>
              <button class="modal-close" @click="detailModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body modal-body--detail" v-if="detailModal.order">
              <div class="detail-top-panels">
                <div class="detail-section detail-panel">
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
                      <label>Terms:</label>
                      <strong>{{ getTermLabel(detailModal.order.terms || 'tunai') }}</strong>
                    </div>
                    <div class="detail-item">
                      <label>Status:</label>
                      <strong>Tertunda</strong>
                    </div>
                  </div>
                </div>

                <div class="detail-section detail-panel">
                  <h4 class="detail-section-title">Supplier</h4>
                  <div class="detail-grid">
                    <div class="detail-item detail-item-full">
                      <label>Nama:</label>
                      <strong>{{ detailModal.order.supplier?.nama || '-' }}</strong>
                    </div>
                    <div class="detail-item detail-item-full" v-if="detailModal.order.supplier?.alamat">
                      <label>Alamat:</label>
                      <span>{{ detailModal.order.supplier.alamat }}</span>
                    </div>
                    <div class="detail-item" v-if="detailModal.order.supplier?.no_telp">
                      <label>No. Telp:</label>
                      <span>{{ detailModal.order.supplier.no_telp }}</span>
                    </div>
                  </div>
                </div>
              </div>

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
                    <tr v-for="(item, idx) in detailModal.items" :key="`${item.product_id}-${idx}`">
                      <td>{{ idx + 1 }}</td>
                      <td><span class="item-kode">{{ item.product_kode }}</span></td>
                      <td>{{ item.product_nama }}</td>
                      <td>{{ item.qty }}</td>
                      <td>{{ formatRp(item.unit_cost) }}</td>
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
              <button class="btn-secondary" @click="detailModal.show = false">Tutup <kbd>Esc</kbd></button>
              <button class="btn-secondary" @click="editDraft(detailModal.order)">
                <i class="pi pi-pencil"></i>
                Edit <kbd>Enter</kbd>
              </button>
              <button class="btn-primary" @click="saveDraftToReceiving(detailModal.order)">
                <i class="pi pi-save"></i>
                Simpan <kbd>F10</kbd>
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="deleteModal.show" class="modal-overlay" @click.self="cancelDelete">
          <div class="modal-box modal-box--confirm modal-box--delete-confirm" role="dialog">
            <div class="modal-header modal-header--danger">
              <div class="modal-header-icon">
                <i class="pi pi-exclamation-triangle"></i>
              </div>
              <h3 class="modal-title">Konfirmasi Hapus Order Tertunda</h3>
              <button class="modal-close" @click="cancelDelete" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body modal-body--confirm" v-if="deleteModal.order">
              <p class="confirm-message">Yakin hapus order tertunda ini?</p>
              <div class="delete-info">
                <div class="info-row">
                  <span class="info-label">No. Order:</span>
                  <span class="info-value">{{ deleteModal.order.no_order }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">Supplier:</span>
                  <span class="info-value">{{ deleteModal.order.supplier?.nama || '-' }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">Tanggal:</span>
                  <span class="info-value">{{ formatDate(deleteModal.order.order_date) }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">Total:</span>
                  <span class="info-value">{{ formatRp(deleteModal.order.subtotal) }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">Status:</span>
                  <span class="status-badge status-draft">Tertunda</span>
                </div>
              </div>
              <div class="delete-warning">
                <i class="pi pi-info-circle"></i>
                <span>Data order tertunda akan dihapus permanen.</span>
              </div>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" ref="btnCancelDelete" @click="cancelDelete">Batal</button>
              <button class="btn-danger" ref="btnConfirmDelete" @click="confirmDelete">Hapus Order</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, nextTick, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { sortOrdersNewestFirst } from '@/lib/orderSort'
import { listPurchaseOrders, removePurchaseOrder, getTermLabel, upsertPurchaseOrder } from '@/lib/pembelianStore'

const router = useRouter()
const PEMBELIAN_FLASH_KEY = 'pembelian_flash_notice'

const pageEl = ref(null)
const inputNoOrder = ref(null)
const inputTglAwal = ref(null)
const inputTglAkhir = ref(null)
const btnCancelDelete = ref(null)
const btnConfirmDelete = ref(null)

const loading = ref(false)
const orders = ref([])
const searchOrderNo = ref('')
const searchDateStart = ref('')
const searchDateEnd = ref('')
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

function getDefaultF2DateRange() {
  const now = new Date()
  const yy = String(now.getFullYear()).slice(-2)
  const mm = String(now.getMonth() + 1).padStart(2, '0')
  const today = String(now.getDate()).padStart(2, '0')
  return {
    start: `01/${mm}/${yy}`,
    end: `${today}/${mm}/${yy}`,
  }
}

const defaultRange = getDefaultF2DateRange()

const filteredOrders = computed(() => {
  let result = orders.value

  if (searchOrderNo.value.trim()) {
    const q = searchOrderNo.value.trim().toLowerCase()
    result = result.filter(order => String(order.no_order || '').toLowerCase().includes(q))
  } else if (searchDateStart.value || searchDateEnd.value) {
    const startDate = parseDateInput(searchDateStart.value)
    const endDate = parseDateInput(searchDateEnd.value)

    if (startDate && endDate) {
      result = result.filter(order => {
        const orderDate = String(order.order_date || '').slice(0, 10)
        return orderDate >= startDate && orderDate <= endDate
      })
    } else if (startDate) {
      result = result.filter(order => String(order.order_date || '').slice(0, 10) >= startDate)
    } else if (endDate) {
      result = result.filter(order => String(order.order_date || '').slice(0, 10) <= endDate)
    }
  }

  return result
})

const totalPages = computed(() => Math.max(1, Math.ceil(filteredOrders.value.length / PAGE_SIZE)))

const pagedOrders = computed(() => {
  const start = (currentPage.value - 1) * PAGE_SIZE
  return filteredOrders.value.slice(start, start + PAGE_SIZE)
})

watch(filteredOrders, () => {
  if (currentPage.value > totalPages.value) {
    currentPage.value = totalPages.value
  }
  if (selectedRowIndex.value >= pagedOrders.value.length) {
    selectedRowIndex.value = Math.max(0, pagedOrders.value.length - 1)
  }
})

function formatDate(value) {
  if (!value) return '-'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '-'
  const dd = String(date.getDate()).padStart(2, '0')
  const mm = String(date.getMonth() + 1).padStart(2, '0')
  const yy = String(date.getFullYear()).slice(-2)
  return `${dd}/${mm}/${yy}`
}

function formatRp(val) {
  return 'Rp ' + Number(val || 0).toLocaleString('id-ID')
}

function parseDateInput(dateStr) {
  const raw = String(dateStr || '').trim()
  if (!raw) return null

  const parts = raw.split('/')
  if (parts.length !== 3) return null

  const day = parts[0].padStart(2, '0')
  const month = parts[1].padStart(2, '0')
  let year = parts[2]

  if (year.length === 2) {
    year = `20${year}`
  }

  const iso = `${year}-${month}-${day}`
  const probe = new Date(iso)
  if (Number.isNaN(probe.getTime())) return null
  return iso
}

function setRowRef(el, idx) {
  if (!el) return
  rowRefs.set(idx, el)
}

function scrollToSelectedRow() {
  const rowEl = rowRefs.get(selectedRowIndex.value)
  if (rowEl) {
    rowEl.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
  }
}

function focusNoOrder() {
  nextTick(() => inputNoOrder.value?.focus())
}

function focusDateStart() {
  nextTick(() => inputTglAwal.value?.focus())
}

function focusDateEnd() {
  nextTick(() => inputTglAkhir.value?.focus())
}

async function getPendingOrders() {
  const rows = await listPurchaseOrders()
  return rows.filter(order => order.status === 'draft')
}

async function loadAllDrafts() {
  loading.value = true
  showResults.value = false
  rowRefs.clear()

  try {
    const pendingRows = await getPendingOrders()
    orders.value = sortOrdersNewestFirst(pendingRows)
    showResults.value = true
    currentPage.value = 1
    selectedRowIndex.value = 0
  } catch (err) {
    console.error('[loadAllDrafts]', err)
    orders.value = []
    showResults.value = true
  } finally {
    loading.value = false
  }
}

async function onNoOrderEnter() {
  await loadAllDrafts()
}

function onDateStartEnter() {
  if (!searchDateStart.value.trim()) {
    searchDateStart.value = defaultRange.start
  }
  if (!searchDateEnd.value.trim()) {
    searchDateEnd.value = defaultRange.end
  }
  focusDateEnd()
}

async function onDateEndEnter() {
  await loadAllDrafts()
}

function activateDateFilterByShortcut() {
  searchOrderNo.value = ''
  if (!searchDateStart.value.trim()) {
    searchDateStart.value = defaultRange.start
  }
  if (!searchDateEnd.value.trim()) {
    searchDateEnd.value = defaultRange.end
  }
  focusDateStart()
}

function clearSearch() {
  searchOrderNo.value = ''
  searchDateStart.value = ''
  searchDateEnd.value = ''
  loadAllDrafts()
  currentPage.value = 1
  selectedRowIndex.value = 0
  focusNoOrder()
}

function nextPage() {
  if (currentPage.value >= totalPages.value) return
  currentPage.value += 1
  selectedRowIndex.value = 0
  nextTick(scrollToSelectedRow)
}

function prevPage() {
  if (currentPage.value <= 1) return
  currentPage.value -= 1
  selectedRowIndex.value = 0
  nextTick(scrollToSelectedRow)
}

function viewOrder(order) {
  detailModal.order = order
  detailModal.items = order?.items || []
  detailModal.show = true
}

function editDraft(order) {
  if (!order?.no_order) return
  sessionStorage.setItem('pembelian_edit_search_no_order', String(order.no_order))
  router.push('/pembelian/edit-order')
}

async function saveDraftToReceiving(order) {
  if (!order?.no_order) return

  await upsertPurchaseOrder({
    ...order,
    status: 'ordered',
    received_at: null,
  })

  sessionStorage.setItem(
    PEMBELIAN_FLASH_KEY,
    JSON.stringify({
      severity: 'success',
      summary: 'Masuk Receiving',
      detail: `No. Order ${order.no_order} dipindahkan ke halaman Receiving.`,
      life: 3200,
    })
  )

  detailModal.show = false
  router.push('/pembelian')
}

function initiateDelete(order) {
  if (!order) return
  deleteModal.order = order
  deleteModal.show = true

  nextTick(() => {
    btnConfirmDelete.value?.focus()
  })
}

function cancelDelete() {
  deleteModal.show = false
  deleteModal.order = null
  nextTick(() => pageEl.value?.focus())
}

async function confirmDelete() {
  const order = deleteModal.order
  if (!order?.no_order) return

  const removed = await removePurchaseOrder(order.no_order)
  if (!removed) {
    alert('Order tidak ditemukan atau sudah dihapus sebelumnya.')
    cancelDelete()
    return
  }

  deleteModal.show = false
  deleteModal.order = null
  if (detailModal.order?.no_order === order.no_order) {
    detailModal.show = false
    detailModal.order = null
    detailModal.items = []
  }

  await loadAllDrafts()
  nextTick(() => pageEl.value?.focus())
}

function onGlobalKey(e) {
  if (deleteModal.show) {
    if (e.key === 'Enter') {
      e.preventDefault()
      void confirmDelete()
      return
    }
    if (e.key === 'Escape') {
      e.preventDefault()
      cancelDelete()
      return
    }
    return
  }

  if (detailModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      detailModal.show = false
      return
    }

    if (e.key === 'Enter') {
      e.preventDefault()
      if (detailModal.order) {
        editDraft(detailModal.order)
      }
      return
    }

    if (e.key === 'F10') {
      e.preventDefault()
      if (detailModal.order) {
        void saveDraftToReceiving(detailModal.order)
      }
      return
    }
    return
  }

  const target = e.target
  const isInputActive = target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA')

  if (e.key === 'F1') {
    e.preventDefault()
    searchDateStart.value = ''
    searchDateEnd.value = ''
    focusNoOrder()
    return
  }

  if (e.key === 'F2') {
    e.preventDefault()
    activateDateFilterByShortcut()
    return
  }

  if (isInputActive) {
    if (e.key === 'Escape' && !searchOrderNo.value && !searchDateStart.value && !searchDateEnd.value) {
      e.preventDefault()
      router.push('/pembelian')
    }
    return
  }

  if (!showResults.value) {
    if (e.key === 'Escape' && !searchOrderNo.value && !searchDateStart.value && !searchDateEnd.value) {
      e.preventDefault()
      router.push('/pembelian')
    }
    return
  }

  if (e.key === 'Escape') {
    e.preventDefault()
    clearSearch()
    return
  }

  if (e.key === 'Enter') {
    e.preventDefault()
    const order = pagedOrders.value[selectedRowIndex.value]
    if (order) {
      viewOrder(order)
    }
    return
  }

  if (e.key === 'ArrowDown') {
    e.preventDefault()
    if (selectedRowIndex.value < pagedOrders.value.length - 1) {
      selectedRowIndex.value += 1
      scrollToSelectedRow()
    }
    return
  }

  if (e.key === 'ArrowUp') {
    e.preventDefault()
    if (selectedRowIndex.value > 0) {
      selectedRowIndex.value -= 1
      scrollToSelectedRow()
    }
    return
  }

  if (e.key === 'PageDown') {
    e.preventDefault()
    nextPage()
    return
  }

  if (e.key === 'PageUp') {
    e.preventDefault()
    prevPage()
  }
}

onMounted(async () => {
  window.addEventListener('keydown', onGlobalKey)
  pageEl.value?.focus()
  await loadAllDrafts()
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
})
</script>

<style scoped>
@import '@/assets/styles.css';
@import '@/assets/Styles/gudang/gudang-page.css';
@import '@/assets/components/table.css';
@import '@/assets/components/form.css';
@import '@/assets/components/modal.css';
@import '@/assets/Styles/pembelian/pembelian-draft-page.css';
</style>
