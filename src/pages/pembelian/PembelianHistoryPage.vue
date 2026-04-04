<template>
  <div class="pembelian-history-page" ref="pageEl" tabindex="-1">
    <template v-if="!showFilterModal">
      <template v-if="showResults && !isDetailView">
        <div class="page-header-card">
          <div class="page-header">
            <div class="page-header-left">
              <h1 class="page-header-title">History Pembelian</h1>
              <div class="page-header-meta">
                <span class="filter-chip">
                  <i class="pi pi-calendar"></i>
                  {{ activeFilterLabel }}
                </span>
                <span v-if="activeFilterSupplier" class="filter-chip filter-chip--supplier">
                  <i class="pi pi-truck"></i>
                  Supplier: {{ activeFilterSupplier }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <div class="table-container">
          <div class="result-meta">
            <span class="result-count"><b>{{ filteredRows.length }}</b> order pembelian</span>
          </div>
          <div class="table-wrap">
            <table class="g-table g-table--riwayat history-table history-table--master">
              <thead>
                <tr>
                  <th class="col-no">#</th>
                  <th class="col-order">No. Order</th>
                  <th class="col-date">Tanggal</th>
                  <th class="col-supplier-name">Supplier</th>
                  <th class="col-items">Jumlah Item</th>
                  <th class="col-subtotal">Subtotal</th>
                  <th class="col-status">Status</th>
                </tr>
              </thead>
              <tbody v-if="filteredRows.length === 0">
                <tr>
                  <td colspan="7" class="empty-cell">
                    <i class="pi pi-inbox"></i>
                    Tidak ada order pembelian sesuai filter.
                  </td>
                </tr>
              </tbody>
              <tbody v-else>
                <tr
                  v-for="(row, idx) in filteredRows"
                  :key="row.no_order"
                  :ref="el => setRowRef(el, idx)"
                  :class="{
                    'row-focused': focusedRowIndex === idx,
                    'row-selected': selectedOrder?.no_order === row.no_order,
                  }"
                  :tabindex="focusedRowIndex === idx ? 0 : -1"
                  @focus="focusedRowIndex = idx"
                  @click="onMasterRowClick(row, idx)"
                >
                  <td class="col-no">{{ idx + 1 }}</td>
                  <td><span class="order-badge">{{ row.no_order }}</span></td>
                  <td>{{ historyDisplayDate(row) }}</td>
                  <td>
                    <div class="supplier-name">{{ row.supplier?.nama || '-' }}</div>
                  </td>
                  <td class="cell-center">
                    <span class="item-count">{{ row.items?.length || 0 }}</span>
                  </td>
                  <td class="subtotal-cell">{{ formatRp(row.subtotal) }}</td>
                  <td class="col-status">
                    <span class="status-badge" :class="historyStatusClass(row)">
                      {{ historyStatusLabel(row) }}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </template>

      <template v-else-if="isDetailView">
        <section class="history-detail-section">
        <article class="history-detail-summary-card">
          <div class="history-detail-summary-header">
            <h3 class="history-detail-title">Detail Order</h3>
          </div>

          <div class="history-detail-summary-grid">
            <div class="history-detail-summary-item">
              <span class="history-detail-summary-label">No. Order</span>
              <span class="history-detail-summary-value">{{ selectedOrder.no_order }}</span>
            </div>
            <div class="history-detail-summary-item">
              <span class="history-detail-summary-label">Supplier</span>
              <span class="history-detail-summary-value">{{ selectedOrder.supplier?.nama || '-' }}</span>
            </div>
            <div class="history-detail-summary-item">
              <span class="history-detail-summary-label">Jumlah Item</span>
              <span class="history-detail-summary-value">{{ selectedOrderItems.length }}</span>
            </div>
            <div class="history-detail-summary-item history-detail-summary-item--subtotal">
              <span class="history-detail-summary-label">Subtotal</span>
              <span class="history-detail-summary-value history-detail-summary-value--money">{{ formatRp(selectedOrder.subtotal) }}</span>
            </div>
            <div class="history-detail-summary-item">
              <span class="history-detail-summary-label">Status</span>
              <span class="status-badge" :class="historyStatusClass(selectedOrder)">
                {{ historyStatusLabel(selectedOrder) }}
              </span>
            </div>
          </div>
        </article>

        <div class="table-container history-detail-card">
          <div class="result-meta history-detail-meta">
            <span class="result-count"><b>Item Pembelian</b> · {{ selectedOrderItems.length }} item</span>
          </div>
          <div class="table-wrap">
            <table class="detail-table history-detail-table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Kode Item</th>
                  <th>Nama Item</th>
                  <th>Order Date</th>
                  <th>Receive Date</th>
                  <th>Harga/Pcs</th>
                  <th>QTY</th>
                  <th>Total</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(item, idx) in selectedOrderItems" :key="`${selectedOrder.no_order}-${item.product_id}-${idx}`">
                  <td>{{ idx + 1 }}</td>
                  <td>{{ item.product_kode || '-' }}</td>
                  <td>{{ item.product_nama || '-' }}</td>
                  <td>{{ formatDateDisplay(selectedOrder.order_date) }}</td>
                  <td>{{ formatDateDisplay(getItemReceiveDate(selectedOrder, item, idx)) }}</td>
                  <td class="cell-money">{{ formatRp(item.unit_cost) }}</td>
                  <td class="cell-center">{{ item.qty || 0 }}</td>
                  <td class="cell-money">{{ formatRp(item.total) }}</td>
                </tr>
              </tbody>
              <tfoot>
                <tr>
                  <td colspan="6" class="subtotal-spacer"></td>
                  <td class="subtotal-label-cell"><strong>Subtotal:</strong></td>
                  <td class="subtotal-value-cell"><strong class="total-value">{{ formatRp(selectedOrder.subtotal) }}</strong></td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
        </section>
      </template>
    </template>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showFilterModal" class="modal-overlay" @click.self="onFilterOverlayClick">
          <form class="modal-box modal-box--filter" @submit.prevent="submitFilter">
            <div class="modal-header modal-header--blue">
              <div class="modal-header-left">
                <div class="modal-header-icon">
                  <i class="pi pi-filter"></i>
                </div>
                <h3 class="modal-title">Filter History Pembelian</h3>
              </div>
            </div>

            <div class="modal-body">
              <p class="modal-helper"></p>

              <div class="filter-modal-grid">
                <div class="search-field">
                  <label class="search-label">Tanggal Awal</label>
                  <input
                    ref="inputStartDate"
                    v-model="startDate"
                    type="date"
                    class="search-input"
                    required
                    @keydown.enter.stop.prevent="focusFilterField(1)"
                    @keydown.down.prevent="focusFilterField(1)"
                    @keydown.up.prevent="focusFilterField(2)"
                  />
                </div>
                <div class="search-field">
                  <label class="search-label">Tanggal Akhir</label>
                  <input
                    ref="inputEndDate"
                    v-model="endDate"
                    type="date"
                    class="search-input"
                    required
                    @keydown.enter.stop.prevent="focusFilterField(2)"
                    @keydown.down.prevent="focusFilterField(2)"
                    @keydown.up.prevent="focusFilterField(0)"
                  />
                </div>
                <div class="search-field filter-full">
                  <label class="search-label">Supplier <span class="optional-note"></span></label>
                  <input
                    ref="inputSupplier"
                    v-model="supplierFilter"
                    type="text"
                    class="search-input"
                    placeholder="Kosongkan untuk filter berdasarkan tanggal"
                    @keydown.enter.stop.prevent="submitFilter"
                    @keydown.down.prevent="focusFilterField(0)"
                    @keydown.up.prevent="focusFilterField(1)"
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
  </div>
</template>

<script setup>
import { ref, computed, nextTick, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { listPurchaseOrders, getPurchaseReceivingItemKey } from '@/lib/pembelianStore'

const router = useRouter()
const route = useRoute()
const pageEl = ref(null)
const orders = ref([])

const inputStartDate = ref(null)
const inputEndDate = ref(null)
const inputSupplier = ref(null)
const startDate = ref('')
const endDate = ref('')
const supplierFilter = ref('')
const showFilterModal = ref(false)
const filterError = ref('')
const activeFilter = ref(null)

const rowRefs = ref([])
const focusedRowIndex = ref(0)
const selectedOrderNo = ref('')
const detailOpen = ref(false)

const showResults = computed(() => !!activeFilter.value)
const activeFilterSupplier = computed(() => activeFilter.value?.supplier || '')
const activeFilterLabel = computed(() => {
  if (!activeFilter.value) return ''
  return `${formatDateDisplay(activeFilter.value.startDate)} s/d ${formatDateDisplay(activeFilter.value.endDate)}`
})

function pad2(value) {
  return String(value).padStart(2, '0')
}

function toDateKeyFromDateObj(date) {
  if (!(date instanceof Date) || Number.isNaN(date.getTime())) return ''
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`
}

function toDateKey(value) {
  const raw = String(value || '').trim()
  if (!raw) return ''

  const isoDateOnlyMatch = raw.match(/^(\d{4})-(\d{2})-(\d{2})$/)
  if (isoDateOnlyMatch) return `${isoDateOnlyMatch[1]}-${isoDateOnlyMatch[2]}-${isoDateOnlyMatch[3]}`

  const isoWithTimeMatch = raw.match(/^(\d{4})-(\d{2})-(\d{2})T/)
  if (isoWithTimeMatch) {
    return toDateKeyFromDateObj(new Date(raw))
  }

  const idMatch = raw.match(/^(\d{2})\/(\d{2})\/(\d{4})/)
  if (idMatch) return `${idMatch[3]}-${idMatch[2]}-${idMatch[1]}`

  const dashIdMatch = raw.match(/^(\d{2})-(\d{2})-(\d{4})/)
  if (dashIdMatch) return `${dashIdMatch[3]}-${dashIdMatch[2]}-${dashIdMatch[1]}`

  return toDateKeyFromDateObj(new Date(raw))
}

function getHistoryDateKey(row) {
  return toDateKey(row?.updated_at) || toDateKey(row?.created_at) || toDateKey(row?.order_date)
}

function getHistorySortTime(row) {
  return new Date(row?.updated_at || row?.created_at || row?.order_date || 0).getTime()
}

function historyDisplayDate(row) {
  return formatDateDisplay(getHistoryDateKey(row))
}

const filteredRows = computed(() => {
  if (!activeFilter.value) return []

  const start = activeFilter.value.startDate
  const end = activeFilter.value.endDate
  const supplier = activeFilter.value.supplier.toLowerCase()

  return orders.value
    .filter(row => {
      if (!row?.no_order || row.status === 'draft') return false
      const dateKey = getHistoryDateKey(row)
      const inRange = dateKey && dateKey >= start && dateKey <= end
      if (!inRange) return false
      if (!supplier) return true
      const supplierName = (row.supplier?.nama || '').toLowerCase()
      return supplierName.includes(supplier)
    })
    .slice()
    .sort((a, b) => {
      const diff = getHistorySortTime(b) - getHistorySortTime(a)
      if (diff !== 0) return diff
      return String(b.no_order || '').localeCompare(String(a.no_order || ''))
    })
})

const selectedOrder = computed(() => {
  if (!selectedOrderNo.value) return null
  return filteredRows.value.find(row => row.no_order === selectedOrderNo.value) || null
})

const isDetailView = computed(() => showResults.value && detailOpen.value && !!selectedOrder.value)

const selectedOrderItems = computed(() => selectedOrder.value?.items || [])

function formatDateDisplay(value) {
  const key = toDateKey(value)
  if (!key) return '-'
  const parts = key.split('-')
  if (parts.length !== 3) return '-'
  return `${parts[2]}/${parts[1]}/${parts[0]}`
}

function formatRp(val) {
  return 'Rp ' + Number(val || 0).toLocaleString('id-ID')
}

function setDefaultDateRange() {
  const now = new Date()
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)
  startDate.value = toDateKeyFromDateObj(monthStart)
  endDate.value = toDateKeyFromDateObj(now)
}

function getValidatedCount(row) {
  const items = Array.isArray(row?.items) ? row.items : []
  const validations = row?.receiving_validations || {}
  if (!items.length) return 0

  let count = 0
  items.forEach((item, idx) => {
    const key = getPurchaseReceivingItemKey(item, idx)
    if (validations[key]) count += 1
  })
  return count
}

function historyStatusLabel(row) {
  const totalItems = Array.isArray(row?.items) ? row.items.length : 0
  const validatedItems = getValidatedCount(row)

  if ((row?.status === 'received' && totalItems > 0) || (totalItems > 0 && validatedItems >= totalItems)) {
    return 'Sudah Validasi'
  }
  if (validatedItems > 0) {
    return 'Sebagian Validasi'
  }
  return 'Belum Validasi'
}

function historyStatusClass(row) {
  const label = historyStatusLabel(row)
  if (label === 'Sudah Validasi') return 'status-received'
  if (label === 'Sebagian Validasi') return 'status-partial'
  return 'status-ordered'
}

function getItemReceiveDate(order, item, idx) {
  const key = getPurchaseReceivingItemKey(item, idx)
  const validatedAtMap = order?.receiving_validated_at || {}
  const mapDate = validatedAtMap[key]
  if (mapDate) return mapDate

  if (item?.received_at) return item.received_at
  if (item?.receive_date) return item.receive_date

  const validations = order?.receiving_validations || {}
  if (validations[key]) return order?.received_at || null
  return null
}

function goToMenu() {
  const from = String(route.query.from || '').toLowerCase()
  if (from === 'history') {
    router.push('/pembelian/history')
    return
  }
  router.push('/pembelian')
}

function setRowRef(el, idx) {
  if (!el) return
  rowRefs.value[idx] = el
}

function focusRow(index) {
  if (!filteredRows.value.length) return
  const safeIndex = Math.max(0, Math.min(index, filteredRows.value.length - 1))
  focusedRowIndex.value = safeIndex
  nextTick(() => rowRefs.value[safeIndex]?.focus())
}

function focusFirstRow() {
  rowRefs.value = []
  focusRow(0)
}

function selectFocusedOrder() {
  const row = filteredRows.value[focusedRowIndex.value]
  if (!row) return
  selectedOrderNo.value = row.no_order
  detailOpen.value = true
}

function onMasterRowClick(row, idx) {
  focusedRowIndex.value = idx
  if (!row?.no_order) return
  selectedOrderNo.value = row.no_order
  detailOpen.value = true
}

function focusFilterField(index) {
  if (index === 0) {
    inputStartDate.value?.focus()
    return
  }
  if (index === 1) {
    inputEndDate.value?.focus()
    return
  }
  inputSupplier.value?.focus()
}

function openFilterModal() {
  filterError.value = ''
  showFilterModal.value = true
  nextTick(() => inputStartDate.value?.focus())
}

function submitFilter() {
  filterError.value = ''

  if (!startDate.value || !endDate.value) {
    filterError.value = 'Tanggal awal dan akhir wajib diisi.'
    return
  }

  if (startDate.value > endDate.value) {
    filterError.value = 'Tanggal awal tidak boleh lebih besar dari tanggal akhir.'
    return
  }

  activeFilter.value = {
    startDate: startDate.value,
    endDate: endDate.value,
    supplier: supplierFilter.value.trim(),
  }

  showFilterModal.value = false
  selectedOrderNo.value = ''
  detailOpen.value = false
  nextTick(() => focusFirstRow())
}

function onFilterCancel() {
  goToMenu()
}

function onFilterOverlayClick() {
  onFilterCancel()
}

function handleKeydown(e) {
  if (showFilterModal.value) {
    if (e.key === 'Escape') {
      e.preventDefault()
      onFilterCancel()
    }
    return
  }

  if (e.key === 'Escape') {
    e.preventDefault()
    if (detailOpen.value && selectedOrder.value) {
      detailOpen.value = false
      nextTick(() => focusRow(focusedRowIndex.value))
      return
    }
    goToMenu()
    return
  }

  if (e.key === 'F1') {
    e.preventDefault()
    openFilterModal()
    return
  }

  if (isDetailView.value) {
    return
  }

  if (e.key === 'ArrowDown') {
    e.preventDefault()
    focusRow(focusedRowIndex.value + 1)
    return
  }

  if (e.key === 'ArrowUp') {
    e.preventDefault()
    focusRow(focusedRowIndex.value - 1)
    return
  }

  if (e.key === 'Enter') {
    e.preventDefault()
    selectFocusedOrder()
  }
}

onMounted(async () => {
  try {
    orders.value = await listPurchaseOrders()
  } catch (err) {
    console.error('[listPurchaseOrders history pembelian]', err)
    orders.value = []
  }
  setDefaultDateRange()
  openFilterModal()
  pageEl.value?.focus()
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<style scoped>
@import '@/assets/pages/History/history-page.css';
</style>
