<template>
  <div class="history-menu-page" ref="pageEl" tabindex="-1">
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Pusat Riwayat Transaksi</h1>
        <p class="g-subtitle">Pilih kategori riwayat untuk melihat histori operasional</p>
      </div>
    </div>

    <div class="history-layout">
      <section class="history-main">
        <template v-if="activeHistoryMenu === 'pembelian'">
          <div v-if="hasSubmittedPembelianFilter" class="search-bar">
            <div class="search-sequential">
              <div class="search-field">
                <label class="search-label">No. Order</label>
                <input
                  ref="inputNoPembelian"
                  v-model="searchNoPembelian"
                  type="text"
                  class="search-input"
                  placeholder="Filter No. Order"
                />
              </div>
            </div>
            <div class="filter-summary">
              <div class="filter-chip-wrap">
                <span class="filter-chip">
                  <i class="pi pi-calendar"></i>
                  {{ activePembelianFilterLabel }}
                </span>
                <span v-if="activePembelianFilterSupplier" class="filter-chip filter-chip--supplier">
                  <i class="pi pi-truck"></i>
                  Supplier: {{ activePembelianFilterSupplier }}
                </span>
              </div>
              <button class="btn-secondary btn-filter" @click="openPembelianFilterModal">
                <i class="pi pi-filter"></i>
                <span>Ubah Filter</span>
              </button>
            </div>
          </div>

          <div v-if="hasSubmittedPembelianFilter" class="table-container">
            <div class="result-meta">
              <span class="result-count"><b>{{ filteredPembelian.length }}</b> order pembelian</span>
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
                <tbody v-if="filteredPembelian.length === 0">
                  <tr>
                    <td colspan="7" class="empty-cell">
                      <i class="pi pi-inbox"></i>
                      Belum ada histori pembelian.
                    </td>
                  </tr>
                </tbody>
                <tbody v-else>
                  <tr
                    v-for="(row, idx) in filteredPembelian"
                    :key="row.no_order"
                    :ref="el => setPembelianRowRef(el, idx)"
                    :class="{ 'row-focused': pembelianFocusedRowIndex === idx }"
                    :tabindex="pembelianFocusedRowIndex === idx ? 0 : -1"
                    @focus="pembelianFocusedRowIndex = idx"
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
        </template>

        <template v-else-if="activeHistoryMenu === 'barang'">
          <div v-if="hasSubmittedBarangFilter" class="search-bar">
            <div class="search-sequential">
              <div class="search-field">
                <label class="search-label">No. Order</label>
                <input
                  ref="inputNoBarang"
                  v-model="searchNoBarang"
                  type="text"
                  class="search-input"
                  placeholder="Filter No. Order Penjualan/Pembelian"
                />
              </div>
            </div>
            <div class="filter-summary">
              <div class="filter-chip-wrap">
                <span class="filter-chip">
                  <i class="pi pi-calendar"></i>
                  {{ activeBarangFilterLabel }}
                </span>
                <span v-if="activeBarangFilter?.productName" class="filter-chip filter-chip--supplier">
                  <i class="pi pi-tag"></i>
                  Barang: {{ activeBarangFilter.productName }}
                </span>
              </div>
              <button class="btn-secondary btn-filter" @click="openBarangFilterModal">
                <i class="pi pi-filter"></i>
                <span>Ubah Filter</span>
              </button>
            </div>
          </div>

          <div v-if="hasSubmittedBarangFilter" class="table-container">
            <div class="result-meta">
              <span class="result-count"><b>{{ filteredBarang.length }}</b> mutasi barang</span>
            </div>
            <div class="table-wrap">
              <table class="g-table barang-history-table">
                <thead>
                  <tr>
                    <th class="col-no">#</th>
                    <th class="col-order">No. Order</th>
                    <th class="col-date">Tanggal</th>
                    <th class="col-fraktur">No. Faktur</th>
                    <th class="col-relasi">Supplier/Customer</th>
                    <th class="col-product">Nama Barang</th>
                    <th class="col-stock">Stok Berkurang</th>
                    <th class="col-stock">Stok Bertambah</th>
                  </tr>
                </thead>
                <tbody v-if="barangLoading">
                  <tr>
                    <td colspan="8" class="empty-cell">Memuat histori barang...</td>
                  </tr>
                </tbody>
                <tbody v-else-if="filteredBarang.length === 0">
                  <tr>
                    <td colspan="8" class="empty-cell">
                      <i class="pi pi-inbox"></i>
                      Data histori barang tidak ditemukan.
                    </td>
                  </tr>
                </tbody>
                <tbody v-else>
                  <tr
                    v-for="(row, idx) in filteredBarang"
                    :key="`${row.type}-${row.no_order}-${row.product_name}-${idx}`"
                    :ref="el => setBarangRowRef(el, idx)"
                    :class="{ 'row-focused': barangFocusedRowIndex === idx }"
                    :tabindex="barangFocusedRowIndex === idx ? 0 : -1"
                    @focus="barangFocusedRowIndex = idx"
                  >
                    <td class="col-no">{{ idx + 1 }}</td>
                    <td>
                      <span class="order-badge" :class="row.type === 'penjualan' ? 'order-badge--sale' : ''">
                        {{ row.no_order }}
                      </span>
                    </td>
                    <td><span class="date-chip">{{ row.date }}</span></td>
                    <td>{{ row.no_faktur || '-' }}</td>
                    <td>{{ row.party_name }}</td>
                    <td>{{ row.product_name }}</td>
                    <td class="cell-center">
                      <span v-if="row.stock_out > 0" class="stock-chip stock-chip--out">-{{ row.stock_out }}</span>
                      <span v-else class="stock-chip stock-chip--empty">-</span>
                    </td>
                    <td class="cell-center">
                      <span v-if="row.stock_in > 0" class="stock-chip stock-chip--in">+{{ row.stock_in }}</span>
                      <span v-else class="stock-chip stock-chip--empty">-</span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <p v-if="barangError" class="modal-error-inline table-error">{{ barangError }}</p>
          </div>
        </template>

        <template v-else>
          <div class="history-nav-cards">
            <button
              v-for="(card, idx) in historyCards"
              :key="card.key"
              class="history-nav-main-card"
              :class="{ 'history-nav-main-card--active': selectedHistoryCardIndex === idx }"
              @click="onHistoryCardClick(idx)"
              @dblclick="onHistoryCardEnter"
            >
              <div class="history-nav-main-icon">
                <i :class="card.icon"></i>
              </div>
              <div class="history-nav-main-content">
                <h3>{{ card.title }}</h3>
                <p>{{ card.description }}</p>
              </div>
            </button>
          </div>
          <div class="stats-cards history-stats-cards">
            <div class="stat-card">
              <div class="stat-icon stat-icon--blue">
                <i class="pi pi-th-large"></i>
              </div>
              <div class="stat-content">
                <span class="stat-label">Menu Histori</span>
                <span class="stat-value">{{ historyCards.length }} kategori</span>
              </div>
            </div>
            <div class="stat-card">
              <div class="stat-icon stat-icon--green">
                <i class="pi pi-shopping-cart"></i>
              </div>
              <div class="stat-content">
                <span class="stat-label">Order Pembelian</span>
                <span class="stat-value">{{ historyStats.totalPembelian }} order</span>
              </div>
            </div>
            <div class="stat-card">
              <div class="stat-icon stat-icon--orange">
                <i class="pi pi-check-circle"></i>
              </div>
              <div class="stat-content">
                <span class="stat-label">Sudah Diterima</span>
                <span class="stat-value">{{ historyStats.receivedPembelian }} order</span>
              </div>
            </div>
            <div class="stat-card">
              <div class="stat-icon stat-icon--purple">
                <i class="pi pi-calendar"></i>
              </div>
              <div class="stat-content">
                <span class="stat-label">Periode Default</span>
                <span class="stat-value">Bulan Ini</span>
              </div>
            </div>
          </div>
          <p class="history-kbd-hint">Gunakan panah kiri/kanan lalu Enter untuk membuka menu yang dipilih.</p>
        </template>
      </section>
    </div>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showPembelianFilterModal" class="modal-overlay" @click.self="goToMenu">
          <form class="modal-box modal-box--filter" @submit.prevent="submitPembelianFilter">
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
                    ref="inputPembelianStartDate"
                    v-model="pembelianStartDate"
                    type="date"
                    class="search-input"
                    required
                    @keydown.enter.prevent="onPembelianStartDateEnter"
                  />
                </div>
                <div class="search-field">
                  <label class="search-label">Tanggal Akhir</label>
                  <input
                    ref="inputPembelianEndDate"
                    v-model="pembelianEndDate"
                    type="date"
                    class="search-input"
                    required
                    @keydown.enter.prevent="onPembelianEndDateEnter"
                  />
                </div>
                <div class="search-field filter-full">
                  <label class="search-label">Supplier <span class="optional-note">opsional</span></label>
                  <input
                    ref="inputPembelianSupplier"
                    v-model="pembelianSupplierFilter"
                    type="text"
                    class="search-input"
                    placeholder="Contoh: Denso"
                    @keydown.enter.prevent="submitPembelianFilter"
                  />
                </div>
              </div>

              <p v-if="pembelianFilterError" class="modal-error-inline">{{ pembelianFilterError }}</p>
            </div>

            <div class="modal-footer">
              <button type="button" class="btn-secondary" @click="goToMenu">Batal</button>
              <button type="submit" class="btn-primary">
                <i class="pi pi-check"></i>
                <span>Enter</span>
              </button>
            </div>
          </form>
        </div>
      </Transition>
    </Teleport>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showBarangFilterModal" class="modal-overlay" @click.self="goToMenu">
          <form class="modal-box modal-box--filter" @submit.prevent="submitBarangFilter">
            <div class="modal-header modal-header--blue">
              <div class="modal-header-left">
                <div class="modal-header-icon">
                  <i class="pi pi-box"></i>
                </div>
                <h3 class="modal-title">Filter Histori Barang</h3>
              </div>
            </div>

            <div class="modal-body">
              <p class="modal-helper">Isi tanggal awal, tanggal akhir, dan nama barang lalu Enter.</p>

              <div class="filter-modal-grid">
                <div class="search-field">
                  <label class="search-label">Tanggal Awal</label>
                  <input
                    ref="inputBarangStartDate"
                    v-model="barangStartDate"
                    type="date"
                    class="search-input"
                    required
                    @keydown.enter.prevent="onBarangStartDateEnter"
                  />
                </div>
                <div class="search-field">
                  <label class="search-label">Tanggal Akhir</label>
                  <input
                    ref="inputBarangEndDate"
                    v-model="barangEndDate"
                    type="date"
                    class="search-input"
                    required
                    @keydown.enter.prevent="onBarangEndDateEnter"
                  />
                </div>
                <div class="search-field filter-full">
                  <label class="search-label">Nama Barang <span class="optional-note">opsional</span></label>
                  <input
                    ref="inputBarangName"
                    v-model="barangNameFilter"
                    type="text"
                    class="search-input"
                    placeholder="Contoh: Filter Oli"
                    @keydown.enter.prevent="submitBarangFilter"
                  />
                </div>
              </div>

              <p v-if="barangFilterError" class="modal-error-inline">{{ barangFilterError }}</p>
            </div>

            <div class="modal-footer">
              <button type="button" class="btn-secondary" @click="goToMenu">Batal</button>
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
import { supabase } from '@/lib/supabase'
import { listPurchaseOrders } from '@/lib/pembelianStore'

const router = useRouter()
const pageEl = ref(null)

const activeHistoryMenu = ref('')
const selectedHistoryCardIndex = ref(0)
const historyCards = [
  {
    key: 'barang',
    title: 'Riwayat Barang',
    description: 'Lihat mutasi stok barang masuk dan keluar.',
    icon: 'pi pi-box',
  },
  {
    key: 'penjualan',
    title: 'Riwayat Penjualan',
    description: 'Buka halaman histori transaksi penjualan.',
    icon: 'pi pi-shopping-cart',
  },
  {
    key: 'pembelian',
    title: 'Riwayat Pembelian',
    description: 'Buka halaman histori order dan penerimaan pembelian.',
    icon: 'pi pi-truck',
  },
]

const orders = ref([])
const historyStats = ref({
  totalPembelian: 0,
  receivedPembelian: 0,
})

const inputNoPembelian = ref(null)
const inputPembelianStartDate = ref(null)
const inputPembelianEndDate = ref(null)
const inputPembelianSupplier = ref(null)
const searchNoPembelian = ref('')
const showPembelianFilterModal = ref(false)
const pembelianStartDate = ref('')
const pembelianEndDate = ref('')
const pembelianSupplierFilter = ref('')
const activePembelianFilter = ref(null)
const pembelianFilterError = ref('')
const pembelianRowRefs = ref([])
const pembelianFocusedRowIndex = ref(0)

const inputNoBarang = ref(null)
const inputBarangStartDate = ref(null)
const inputBarangEndDate = ref(null)
const inputBarangName = ref(null)
const searchNoBarang = ref('')
const showBarangFilterModal = ref(false)
const barangStartDate = ref('')
const barangEndDate = ref('')
const barangNameFilter = ref('')
const activeBarangFilter = ref(null)
const barangFilterError = ref('')
const barangError = ref('')
const barangLoading = ref(false)
const barangRows = ref([])
const barangRowRefs = ref([])
const barangFocusedRowIndex = ref(0)

const hasSubmittedPembelianFilter = computed(() => !!activePembelianFilter.value)
const activePembelianFilterSupplier = computed(() => activePembelianFilter.value?.supplier || '')
const activePembelianFilterLabel = computed(() => {
  if (!activePembelianFilter.value) return ''
  return `${activePembelianFilter.value.startDate} s/d ${activePembelianFilter.value.endDate}`
})

const hasSubmittedBarangFilter = computed(() => !!activeBarangFilter.value)
const activeBarangFilterLabel = computed(() => {
  if (!activeBarangFilter.value) return ''
  return `${activeBarangFilter.value.startDate} s/d ${activeBarangFilter.value.endDate}`
})

const pembelianDateFiltered = computed(() => {
  if (!activePembelianFilter.value) return []

  const start = activePembelianFilter.value.startDate
  const end = activePembelianFilter.value.endDate
  const supplier = activePembelianFilter.value.supplier.toLowerCase()

  return orders.value.filter(row => {
    const orderDate = toDateOnly(row.order_date)
    const inRange = orderDate >= start && orderDate <= end
    if (!inRange) return false

    if (!supplier) return true
    const namaSupplier = (row.supplier?.nama || '').toLowerCase()
    return namaSupplier.includes(supplier)
  })
})

const filteredPembelian = computed(() => {
  return pembelianDateFiltered.value
    .filter(row => row.no_order?.toLowerCase().includes(searchNoPembelian.value.toLowerCase()))
    .sort((a, b) => String(toDateOnly(b.order_date)).localeCompare(String(toDateOnly(a.order_date))))
})

const filteredBarang = computed(() => {
  return barangRows.value
    .filter(row => row.no_order.toLowerCase().includes(searchNoBarang.value.toLowerCase()))
    .sort((a, b) => String(b.date).localeCompare(String(a.date)))
})

function todayIso() {
  return new Date().toISOString().slice(0, 10)
}

function setDefaultDateRange(startRef, endRef) {
  const now = new Date()
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)
  startRef.value = monthStart.toISOString().slice(0, 10)
  endRef.value = todayIso()
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

function goPenjualanHistory() {
  router.push('/penjualan/list')
}

function onHistoryCardClick(idx) {
  selectedHistoryCardIndex.value = idx
  onHistoryCardEnter()
}

function onHistoryCardEnter() {
  const selected = historyCards[selectedHistoryCardIndex.value]
  if (!selected) return

  if (selected.key === 'penjualan') {
    activeHistoryMenu.value = 'penjualan'
    goPenjualanHistory()
    return
  }

  if (selected.key === 'barang') {
    openHistoryBarang()
    return
  }

  router.push('/pembelian/history-pembelian')
}

function openHistoryPembelian() {
  activeHistoryMenu.value = 'pembelian'
  showBarangFilterModal.value = false
  if (!hasSubmittedPembelianFilter.value) {
    openPembelianFilterModal()
  } else {
    focusFirstPembelianRow()
  }
}

function openHistoryBarang() {
  activeHistoryMenu.value = 'barang'
  showPembelianFilterModal.value = false
  if (!hasSubmittedBarangFilter.value) {
    openBarangFilterModal()
  } else {
    focusFirstBarangRow()
  }
}

function setPembelianRowRef(el, idx) {
  if (!el) return
  pembelianRowRefs.value[idx] = el
}

function focusPembelianRow(index) {
  if (!filteredPembelian.value.length) return
  const safeIndex = Math.max(0, Math.min(index, filteredPembelian.value.length - 1))
  pembelianFocusedRowIndex.value = safeIndex
  nextTick(() => pembelianRowRefs.value[safeIndex]?.focus())
}

function focusFirstPembelianRow() {
  pembelianRowRefs.value = []
  focusPembelianRow(0)
}

function setBarangRowRef(el, idx) {
  if (!el) return
  barangRowRefs.value[idx] = el
}

function focusBarangRow(index) {
  if (!filteredBarang.value.length) return
  const safeIndex = Math.max(0, Math.min(index, filteredBarang.value.length - 1))
  barangFocusedRowIndex.value = safeIndex
  nextTick(() => barangRowRefs.value[safeIndex]?.focus())
}

function focusFirstBarangRow() {
  barangRowRefs.value = []
  focusBarangRow(0)
}

function openPembelianFilterModal() {
  pembelianFilterError.value = ''
  showPembelianFilterModal.value = true
  nextTick(() => inputPembelianStartDate.value?.focus())
}

function onPembelianStartDateEnter() {
  inputPembelianEndDate.value?.focus()
}

function onPembelianEndDateEnter() {
  inputPembelianSupplier.value?.focus()
}

function submitPembelianFilter() {
  pembelianFilterError.value = ''
  if (!pembelianStartDate.value || !pembelianEndDate.value) {
    pembelianFilterError.value = 'Tanggal awal dan akhir wajib diisi.'
    return
  }
  if (pembelianStartDate.value > pembelianEndDate.value) {
    pembelianFilterError.value = 'Tanggal awal tidak boleh lebih besar dari tanggal akhir.'
    return
  }

  activePembelianFilter.value = {
    startDate: pembelianStartDate.value,
    endDate: pembelianEndDate.value,
    supplier: pembelianSupplierFilter.value.trim(),
  }

  searchNoPembelian.value = ''
  showPembelianFilterModal.value = false
  focusFirstPembelianRow()
}

function openBarangFilterModal() {
  barangFilterError.value = ''
  showBarangFilterModal.value = true
  nextTick(() => inputBarangStartDate.value?.focus())
}

function onBarangStartDateEnter() {
  inputBarangEndDate.value?.focus()
}

function onBarangEndDateEnter() {
  inputBarangName.value?.focus()
}

async function submitBarangFilter() {
  barangFilterError.value = ''
  if (!barangStartDate.value || !barangEndDate.value) {
    barangFilterError.value = 'Tanggal awal dan akhir wajib diisi.'
    return
  }
  if (barangStartDate.value > barangEndDate.value) {
    barangFilterError.value = 'Tanggal awal tidak boleh lebih besar dari tanggal akhir.'
    return
  }

  activeBarangFilter.value = {
    startDate: barangStartDate.value,
    endDate: barangEndDate.value,
    productName: barangNameFilter.value.trim(),
  }

  await loadBarangHistory()
  searchNoBarang.value = ''
  showBarangFilterModal.value = false
  focusFirstBarangRow()
}

async function loadBarangHistory() {
  if (!activeBarangFilter.value) return

  barangLoading.value = true
  barangError.value = ''
  try {
    const byProduct = activeBarangFilter.value.productName.toLowerCase()
    const purchaseRows = orders.value
      .filter(order => {
        if (order.status !== 'received') return false
        const date = toDateOnly(order.received_at || order.order_date)
        return date >= activeBarangFilter.value.startDate && date <= activeBarangFilter.value.endDate
      })
      .flatMap(order =>
        (order.items || [])
          .filter(item => {
            const nama = (item.product_nama || '').toLowerCase()
            return !byProduct || nama.includes(byProduct)
          })
          .map(item => ({
            type: 'pembelian',
            no_order: order.no_order || '-',
            date: toDateOnly(order.received_at || order.order_date),
            no_faktur: order.no_faktur || order.faktur || '-',
            party_name: order.supplier?.nama || '-',
            product_name: item.product_nama || '-',
            stock_out: 0,
            stock_in: Number(item.qty || 0),
          }))
      )

    const { data: salesData, error: salesError } = await supabase
      .from('sales')
      .select('id, no_order, order_date, no_faktur, customer_nama, status')
      .eq('status', 'completed')
      .gte('order_date', activeBarangFilter.value.startDate)
      .lte('order_date', activeBarangFilter.value.endDate)

    if (salesError) throw salesError

    const saleIds = (salesData || []).map(row => row.id)
    let saleItems = []

    if (saleIds.length > 0) {
      const { data: saleItemsData, error: saleItemsError } = await supabase
        .from('sale_items')
        .select('sale_id, product_nama, qty')
        .in('sale_id', saleIds)

      if (saleItemsError) throw saleItemsError
      saleItems = saleItemsData || []
    }

    const saleItemsByOrder = saleItems.reduce((acc, item) => {
      if (!acc[item.sale_id]) acc[item.sale_id] = []
      acc[item.sale_id].push(item)
      return acc
    }, {})

    const saleRows = (salesData || []).flatMap(order =>
      (saleItemsByOrder[order.id] || [])
        .filter(item => {
          const nama = (item.product_nama || '').toLowerCase()
          return !byProduct || nama.includes(byProduct)
        })
        .map(item => ({
          type: 'penjualan',
          no_order: order.no_order || '-',
          date: toDateOnly(order.order_date),
          no_faktur: order.no_faktur || '-',
          party_name: order.customer_nama || '-',
          product_name: item.product_nama || '-',
          stock_out: Number(item.qty || 0),
          stock_in: 0,
        }))
    )

    barangRows.value = [...purchaseRows, ...saleRows]
  } catch (err) {
    console.error('[loadBarangHistory]', err)
    barangError.value = 'Gagal memuat histori barang: ' + err.message
    barangRows.value = []
  } finally {
    barangLoading.value = false
  }
}

function handlePembelianShortcuts(e) {
  if (e.key === 'F1') {
    e.preventDefault()
    if (!showPembelianFilterModal.value && hasSubmittedPembelianFilter.value) {
      inputNoPembelian.value?.focus()
    }
    return true
  }

  if (e.key === 'Escape') {
    e.preventDefault()
    if (showPembelianFilterModal.value) goToMenu()
    else openPembelianFilterModal()
    return true
  }

  if (!showPembelianFilterModal.value && hasSubmittedPembelianFilter.value) {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      focusPembelianRow(pembelianFocusedRowIndex.value + 1)
      return true
    }
    if (e.key === 'ArrowUp') {
      e.preventDefault()
      focusPembelianRow(pembelianFocusedRowIndex.value - 1)
      return true
    }
  }
  return false
}

function handleBarangShortcuts(e) {
  if (e.key === 'F1') {
    e.preventDefault()
    if (!showBarangFilterModal.value && hasSubmittedBarangFilter.value) {
      inputNoBarang.value?.focus()
    }
    return true
  }

  if (e.key === 'Escape') {
    e.preventDefault()
    if (showBarangFilterModal.value) goToMenu()
    else openBarangFilterModal()
    return true
  }

  if (!showBarangFilterModal.value && hasSubmittedBarangFilter.value) {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      focusBarangRow(barangFocusedRowIndex.value + 1)
      return true
    }
    if (e.key === 'ArrowUp') {
      e.preventDefault()
      focusBarangRow(barangFocusedRowIndex.value - 1)
      return true
    }
  }
  return false
}

function moveHistoryCardSelection(step) {
  const max = historyCards.length - 1
  let next = selectedHistoryCardIndex.value + step
  if (next < 0) next = max
  if (next > max) next = 0
  selectedHistoryCardIndex.value = next
}

function handleKeydown(e) {
  if (!activeHistoryMenu.value) {
    if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
      e.preventDefault()
      moveHistoryCardSelection(1)
      return
    }
    if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
      e.preventDefault()
      moveHistoryCardSelection(-1)
      return
    }
    if (e.key === 'Enter') {
      e.preventDefault()
      onHistoryCardEnter()
      return
    }
    if (e.key === 'Escape') {
      e.preventDefault()
      goToMenu()
      return
    }
  }

  if (activeHistoryMenu.value === 'barang') {
    handleBarangShortcuts(e)
    return
  }
  handlePembelianShortcuts(e)
}

onMounted(() => {
  pageEl.value?.focus()
  orders.value = listPurchaseOrders()
  historyStats.value.totalPembelian = orders.value.length
  historyStats.value.receivedPembelian = orders.value.filter(o => o.status === 'received').length

  setDefaultDateRange(pembelianStartDate, pembelianEndDate)
  setDefaultDateRange(barangStartDate, barangEndDate)

  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<style scoped>
@import '@/assets/pages/History/history-page.css';
</style>
