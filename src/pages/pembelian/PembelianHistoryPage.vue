<template>
  <div class="pembelian-history-page" ref="pageEl" tabindex="-1">
    <div class="page-header-card">
      <div class="page-header">
        <div class="page-header-left">
          <h1 class="page-header-title">Riwayat Order Pembelian</h1>
        </div>
        <button class="btn-secondary" @click="goToMenu" title="Kembali ke Menu (Esc)">
          <i class="pi pi-arrow-left"></i>
          <span>Menu</span>
        </button>
      </div>
    </div>

    <div class="search-bar" v-if="hasSubmittedFilter">
      <div class="filter-summary">
        <div class="filter-chip-wrap">
          <span class="filter-chip">
            <i class="pi pi-calendar"></i>
            {{ activeFilterLabel }}
          </span>
          <span v-if="activeFilterSupplier" class="filter-chip filter-chip--supplier">
            <i class="pi pi-truck"></i>
            Supplier: {{ activeFilterSupplier }}
          </span>
        </div>
        <button class="btn-secondary btn-filter" @click="openFilterModal" title="Esc">
          <i class="pi pi-filter"></i>
          <span>Ubah Filter</span>
        </button>
      </div>
    </div>

    <div class="table-container" v-if="hasSubmittedFilter">
      <div class="result-meta">
        <span class="result-count"><b>{{ filteredRows.length }}</b> order pembelian</span>
      </div>
      <div class="table-wrap">
        <table class="g-table history-table">
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
                Belum ada histori pembelian.
              </td>
            </tr>
          </tbody>
          <tbody v-else>
            <tr
              v-for="(row, idx) in filteredRows"
              :key="row.no_order"
              :ref="el => setRowRef(el, idx)"
              :class="{ 'row-focused': focusedRowIndex === idx }"
              :tabindex="focusedRowIndex === idx ? 0 : -1"
              @focus="focusedRowIndex = idx"
            >
              <td class="col-no">{{ idx + 1 }}</td>
              <td><span class="order-badge">{{ row.no_order }}</span></td>
              <td><span class="date-chip">{{ toDateOnly(row.order_date) }}</span></td>
              <td>
                <div class="supplier-name">{{ row.supplier?.nama || '-' }}</div>
              </td>
              <td class="cell-center">
                <span class="item-count">{{ row.items?.length || 0 }}</span>
              </td>
              <td class="subtotal-cell">{{ formatRp(row.subtotal) }}</td>
              <td class="cell-center">
                <span class="status-badge" :class="row.status === 'received' ? 'status-received' : 'status-ordered'">
                  {{ row.status === 'received' ? 'Sudah Diterima' : 'Belum Diterima' }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

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
              <p class="modal-helper">Pilih tanggal awal, tanggal akhir, lalu supplier (opsional).</p>

              <div class="filter-modal-grid">
                <div class="search-field">
                  <label class="search-label">Tanggal Awal</label>
                  <input
                    ref="inputStartDate"
                    v-model="startDate"
                    type="date"
                    class="search-input"
                    required
                    @keydown.enter.prevent="onStartDateEnter"
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
                    @keydown.enter.prevent="onEndDateEnter"
                  />
                </div>
                <div class="search-field filter-full">
                  <label class="search-label">Supplier <span class="optional-note">opsional</span></label>
                  <input
                    ref="inputSupplier"
                    v-model="supplierFilter"
                    type="text"
                    class="search-input"
                    placeholder="Contoh: Denso"
                    @keydown.enter.prevent="submitFilter"
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
import { useRouter } from 'vue-router'
import { listPurchaseOrders } from '@/lib/pembelianStore'

const router = useRouter()
const pageEl = ref(null)
const orders = ref([])

const inputStartDate = ref(null)
const inputEndDate = ref(null)
const inputSupplier = ref(null)
const startDate = ref('')
const endDate = ref('')
const supplierFilter = ref('')
const showFilterModal = ref(true)
const filterError = ref('')
const activeFilter = ref(null)

const rowRefs = ref([])
const focusedRowIndex = ref(0)

const hasSubmittedFilter = computed(() => !!activeFilter.value)
const activeFilterSupplier = computed(() => activeFilter.value?.supplier || '')
const activeFilterLabel = computed(() => {
  if (!activeFilter.value) return ''
  return `${activeFilter.value.startDate} s/d ${activeFilter.value.endDate}`
})

const dateFilteredRows = computed(() => {
  if (!activeFilter.value) return []

  const start = activeFilter.value.startDate
  const end = activeFilter.value.endDate
  const supplier = activeFilter.value.supplier.toLowerCase()

  return orders.value.filter(row => {
    const orderDate = toDateOnly(row.order_date)
    const inRange = orderDate >= start && orderDate <= end
    if (!inRange) return false

    if (!supplier) return true
    const supplierName = (row.supplier?.nama || '').toLowerCase()
    return supplierName.includes(supplier)
  })
})

const filteredRows = computed(() => {
  return dateFilteredRows.value
    .slice()
    .sort((a, b) => String(toDateOnly(b.order_date)).localeCompare(String(toDateOnly(a.order_date))))
})

function todayIso() {
  return new Date().toISOString().slice(0, 10)
}

function setDefaultDateRange() {
  const now = new Date()
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)
  startDate.value = monthStart.toISOString().slice(0, 10)
  endDate.value = todayIso()
}

function toDateOnly(value) {
  return String(value || '').slice(0, 10)
}

function formatRp(val) {
  return 'Rp ' + Number(val || 0).toLocaleString('id-ID')
}

function goToMenu() {
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

function openFilterModal() {
  filterError.value = ''
  showFilterModal.value = true
  nextTick(() => inputStartDate.value?.focus())
}

function onStartDateEnter() {
  inputEndDate.value?.focus()
}

function onEndDateEnter() {
  inputSupplier.value?.focus()
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
  focusFirstRow()
}

function onFilterCancel() {
  if (!hasSubmittedFilter.value) {
    goToMenu()
    return
  }
  showFilterModal.value = false
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
    openFilterModal()
    return
  }

  if (e.key === 'F1') {
    e.preventDefault()
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
}

onMounted(() => {
  orders.value = listPurchaseOrders()
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
