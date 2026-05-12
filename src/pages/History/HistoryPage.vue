<template>
  <div class="history-menu-page" ref="pageEl" tabindex="-1">
    <div class="g-header" v-if="activeHistoryMenu !== 'barang' && !showPembelianFilterModal && !showBarangFilterModal">
      <div class="g-header-left">
        <h1 class="g-title">Pusat Riwayat Transaksi</h1>
        <p class="g-subtitle">Pilih kategori riwayat untuk melihat histori operasional</p>
      </div>
    </div>

    <div class="history-layout">
      <section class="history-main">
        <template v-if="activeHistoryMenu === 'pembelian'">
          <div v-if="hasSubmittedPembelianFilter && !showPembelianFilterModal" class="search-bar">
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

          <div v-if="hasSubmittedPembelianFilter && !showPembelianFilterModal" class="table-container">
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
          <div v-if="hasSubmittedBarangFilter && !showBarangFilterModal" class="search-bar history-barang-header-card">
            <div class="history-barang-header">
              <h2 class="history-barang-title">Pusat History Barang</h2>
              <p class="history-barang-period">
                <i class="pi pi-calendar"></i>
                <span>{{ activeBarangFilterLabel }}</span>
              </p>
            </div>

            <div class="search-sequential history-barang-search-sequential">
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
              <div class="search-field">
                <label class="search-label">Supplier/Customer/Staff</label>
                <input
                  ref="inputBarangParty"
                  v-model="searchPartyBarang"
                  type="text"
                  class="search-input"
                  placeholder="Filter nama supplier/customer/staff"
                />
              </div>
              <div class="search-field">
                <label class="search-label">Nama/Kode Item</label>
                <input
                  ref="inputBarangItem"
                  v-model="searchItemBarang"
                  type="text"
                  class="search-input"
                  placeholder="Filter nama atau kode item"
                />
              </div>
            </div>
            <div class="filter-summary history-barang-filter-summary">
              <div class="filter-chip-wrap">
                <span v-if="activeBarangFilter?.productName" class="filter-chip filter-chip--supplier">
                  <i class="pi pi-tag"></i>
                  Barang: {{ activeBarangFilter.productName }}
                </span>
              </div>
            </div>
          </div>

          <div v-if="hasSubmittedBarangFilter && !showBarangFilterModal" class="table-container">
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
                    <th class="col-relasi-supplier">Supplier</th>
                    <th class="col-relasi-customer">Customer</th>
                    <th class="col-relasi-staff">Staff</th>
                    <th class="col-product">Nama Barang</th>
                    <th class="col-stock">Stok Berkurang</th>
                    <th class="col-stock">Stok Bertambah</th>
                  </tr>
                </thead>
                <tbody v-if="barangLoading">
                  <tr>
                    <td colspan="10" class="empty-cell">Memuat histori barang...</td>
                  </tr>
                </tbody>
                <tbody v-else-if="filteredBarang.length === 0">
                  <tr>
                    <td colspan="10" class="empty-cell">
                      <i class="pi pi-inbox"></i>
                      Data histori barang tidak ditemukan.
                    </td>
                  </tr>
                </tbody>
                <tbody v-else>
                  <tr
                    v-for="(row, idx) in filteredBarang"
                    :key="`${row.type}-${row.id || row.no_order}-${row.product_name}-${idx}`"
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
                    <td><span class="barang-date-text">{{ formatDateDdMmYyyy(row.date) }}</span></td>
                    <td>
                      <span
                        class="fraktur-badge"
                        :class="{ 'fraktur-badge--empty': !row.no_faktur || row.no_faktur === '-' }"
                      >
                        {{ row.no_faktur || '-' }}
                      </span>
                    </td>
                    <td>
                      <span
                        class="party-badge party-badge--supplier"
                        :class="{ 'party-badge--empty': !(row.supplier_name || (row.type === 'pembelian' ? row.party_name || '-' : '-')) || (row.supplier_name || (row.type === 'pembelian' ? row.party_name || '-' : '-')) === '-' }"
                      >
                        {{ row.supplier_name || (row.type === 'pembelian' ? row.party_name || '-' : '-') }}
                      </span>
                    </td>
                    <td>
                      <span
                        class="party-badge party-badge--customer"
                        :class="{ 'party-badge--empty': !(row.customer_name || (row.type === 'penjualan' ? row.party_name || '-' : '-')) || (row.customer_name || (row.type === 'penjualan' ? row.party_name || '-' : '-')) === '-' }"
                      >
                        {{ row.customer_name || (row.type === 'penjualan' ? row.party_name || '-' : '-') }}
                      </span>
                    </td>
                    <td>
                      <div class="staff-cell" :class="{ 'staff-cell--empty': !row.staff_name || row.staff_name === '-' }">
                        <span class="staff-name">{{ row.staff_name || '-' }}</span>
                        <span v-if="row.staff_reason && row.staff_reason !== '-'" class="staff-reason">{{ row.staff_reason }}</span>
                      </div>
                    </td>
                    <td><span class="barang-product-name">{{ row.product_name }}</span></td>
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
            <div class="stat-card stat-card--blue">
              <div class="stat-icon stat-icon--blue">
                <i class="pi pi-th-large"></i>
              </div>
              <div class="stat-content">
                <span class="stat-label">Menu Histori</span>
                <span class="stat-value">{{ historyCards.length }} kategori</span>
              </div>
            </div>
            <div class="stat-card stat-card--green">
              <div class="stat-icon stat-icon--green">
                <i class="pi pi-shopping-cart"></i>
              </div>
              <div class="stat-content">
                <span class="stat-label">Order Pembelian</span>
                <span class="stat-value">{{ historyStats.totalPembelian }} order</span>
              </div>
            </div>
            <div class="stat-card stat-card--orange">
              <div class="stat-icon stat-icon--orange">
                <i class="pi pi-check-circle"></i>
              </div>
              <div class="stat-content">
                <span class="stat-label">Sudah Diterima</span>
                <span class="stat-value">{{ historyStats.receivedPembelian }} order</span>
              </div>
            </div>
            <div class="stat-card stat-card--purple">
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
        <div v-if="showPembelianFilterModal" class="modal-overlay" @click.self="backToHistoryMenu">
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
              <button type="button" class="btn-secondary" @click="backToHistoryMenu">Batal</button>
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
        <div v-if="showBarangFilterModal" class="modal-overlay" @click.self="backToHistoryMenu">
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
              <button type="button" class="btn-secondary" @click="backToHistoryMenu">Batal</button>
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
import { ref, computed, nextTick, onMounted, onUnmounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { listPurchaseOrders, getPurchaseReceivingItemKey } from '@/lib/pembelianStore'

const router = useRouter()
const HISTORY_PAGE_STATE_KEY = 'history_page_state_v1'
const pageEl = ref(null)

const activeHistoryMenu = ref('')
const selectedHistoryCardIndex = ref(0)
const historyCards = [
  {
    key: 'barang',
    title: 'History Barang',
    description: 'Lihat mutasi stok barang masuk dan keluar.',
    icon: 'pi pi-box',
  },
  {
    key: 'penjualan',
    title: 'History Penjualan',
    description: 'Buka halaman histori transaksi penjualan.',
    icon: 'pi pi-shopping-cart',
  },
  {
    key: 'pembelian',
    title: 'History Pembelian',
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
const inputBarangParty = ref(null)
const inputBarangItem = ref(null)
const inputBarangStartDate = ref(null)
const inputBarangEndDate = ref(null)
const inputBarangName = ref(null)
const searchNoBarang = ref('')
const searchPartyBarang = ref('')
const searchItemBarang = ref('')
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
  const start = formatDateDdMmYyyy(activeBarangFilter.value.startDate)
  const end = formatDateDdMmYyyy(activeBarangFilter.value.endDate)
  return `${start} s/d ${end}`
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
  const noOrderQuery = searchNoBarang.value.toLowerCase().trim()
  const partyQuery = searchPartyBarang.value.toLowerCase().trim()
  const itemQuery = searchItemBarang.value.toLowerCase().trim()

  return barangRows.value
    .filter(row => {
      const byNoOrder = !noOrderQuery || String(row.no_order || '').toLowerCase().includes(noOrderQuery)
      if (!byNoOrder) return false

      const supplierName = String(row.supplier_name || '').toLowerCase()
      const customerName = String(row.customer_name || '').toLowerCase()
      const partyName = String(row.party_name || '').toLowerCase()
      const staffName = String(row.staff_name || '').toLowerCase()
      const byParty =
        !partyQuery ||
        supplierName.includes(partyQuery) ||
        customerName.includes(partyQuery) ||
        partyName.includes(partyQuery) ||
        staffName.includes(partyQuery)
      if (!byParty) return false

      const itemName = String(row.product_name || '').toLowerCase()
      const itemCode = String(row.product_kode || '').toLowerCase()
      const byItem = !itemQuery || itemName.includes(itemQuery) || itemCode.includes(itemQuery)
      return byItem
    })
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

function isMissingRelationError(err) {
  const code = String(err?.code || '')
  if (code === 'PGRST205' || code === '42P01') return true
  const message = String(err?.message || '').toLowerCase()
  return message.includes('could not find the table') || message.includes('relation')
}

function isMissingColumnError(err) {
  const code = String(err?.code || '')
  if (code === '42703') return true
  const message = String(err?.message || '').toLowerCase()
  return message.includes('column') && message.includes('does not exist')
}

function formatDateDdMmYyyy(value) {
  const base = toDateOnly(value)
  if (!base) return '-'

  const parts = base.split('-')
  if (parts.length === 3) {
    const [year, month, day] = parts
    if (year && month && day) return `${day}/${month}/${year}`
  }

  const parsed = new Date(value)
  if (Number.isNaN(parsed.getTime())) return base

  const day = String(parsed.getDate()).padStart(2, '0')
  const month = String(parsed.getMonth() + 1).padStart(2, '0')
  const year = parsed.getFullYear()
  return `${day}/${month}/${year}`
}

function formatRp(val) {
  return 'Rp ' + Number(val || 0).toLocaleString('id-ID')
}

async function loadPurchaseStatsFromDatabase() {
  const { count: totalPembelian, error: totalError } = await supabase
    .from('purchases')
    .select('id', { count: 'exact', head: true })

  if (totalError) throw totalError

  const { count: receivedPembelian, error: receivedError } = await supabase
    .from('purchases')
    .select('id', { count: 'exact', head: true })
    .eq('status', 'received')

  if (receivedError) throw receivedError

  historyStats.value.totalPembelian = Number(totalPembelian || 0)
  historyStats.value.receivedPembelian = Number(receivedPembelian || 0)
}

function persistHistoryState() {
  const persistableMenu =
    activeHistoryMenu.value === 'barang' || activeHistoryMenu.value === 'pembelian'
      ? activeHistoryMenu.value
      : ''

  const payload = {
    activeHistoryMenu: persistableMenu,
    selectedHistoryCardIndex: selectedHistoryCardIndex.value,
    pembelian: {
      activeFilter: activePembelianFilter.value,
      searchNo: searchNoPembelian.value,
      showFilterModal: showPembelianFilterModal.value,
      startDate: pembelianStartDate.value,
      endDate: pembelianEndDate.value,
      supplierFilter: pembelianSupplierFilter.value,
      focusedRowIndex: pembelianFocusedRowIndex.value,
    },
    barang: {
      activeFilter: activeBarangFilter.value,
      searchNo: searchNoBarang.value,
      searchParty: searchPartyBarang.value,
      searchItem: searchItemBarang.value,
      showFilterModal: showBarangFilterModal.value,
      startDate: barangStartDate.value,
      endDate: barangEndDate.value,
      nameFilter: barangNameFilter.value,
      focusedRowIndex: barangFocusedRowIndex.value,
      rows: barangRows.value,
    },
  }
  sessionStorage.setItem(HISTORY_PAGE_STATE_KEY, JSON.stringify(payload))
}

async function restoreHistoryState() {
  const raw = sessionStorage.getItem(HISTORY_PAGE_STATE_KEY)
  if (!raw) return false

  try {
    const state = JSON.parse(raw)

    activeHistoryMenu.value =
      state?.activeHistoryMenu === 'barang' || state?.activeHistoryMenu === 'pembelian'
        ? state.activeHistoryMenu
        : ''
    selectedHistoryCardIndex.value = Number.isInteger(state?.selectedHistoryCardIndex)
      ? state.selectedHistoryCardIndex
      : 0

    if (state?.pembelian) {
      activePembelianFilter.value = state.pembelian.activeFilter || null
      searchNoPembelian.value = String(state.pembelian.searchNo || '')
      showPembelianFilterModal.value = Boolean(state.pembelian.showFilterModal)
      pembelianStartDate.value = state.pembelian.startDate || pembelianStartDate.value
      pembelianEndDate.value = state.pembelian.endDate || pembelianEndDate.value
      pembelianSupplierFilter.value = String(state.pembelian.supplierFilter || '')
      pembelianFocusedRowIndex.value = Number.isInteger(state.pembelian.focusedRowIndex)
        ? state.pembelian.focusedRowIndex
        : 0
    }

    if (state?.barang) {
      activeBarangFilter.value = state.barang.activeFilter || null
      searchNoBarang.value = String(state.barang.searchNo || '')
      searchPartyBarang.value = String(state.barang.searchParty || '')
      searchItemBarang.value = String(state.barang.searchItem || '')
      showBarangFilterModal.value = Boolean(state.barang.showFilterModal)
      barangStartDate.value = state.barang.startDate || barangStartDate.value
      barangEndDate.value = state.barang.endDate || barangEndDate.value
      barangNameFilter.value = String(state.barang.nameFilter || '')
      barangFocusedRowIndex.value = Number.isInteger(state.barang.focusedRowIndex)
        ? state.barang.focusedRowIndex
        : 0
      if (Array.isArray(state.barang.rows)) {
        barangRows.value = state.barang.rows
      }
    }

    if (activeHistoryMenu.value !== 'pembelian') {
      showPembelianFilterModal.value = false
    }
    if (activeHistoryMenu.value !== 'barang') {
      showBarangFilterModal.value = false
    }

    if (activeHistoryMenu.value === 'barang' && activeBarangFilter.value) {
      // Selalu refresh dari DB agar pembatalan validasi receiving langsung tercermin.
      await loadBarangHistory()
      if (!showBarangFilterModal.value && filteredBarang.value.length) {
        focusBarangRow(barangFocusedRowIndex.value)
      } else if (showBarangFilterModal.value) {
        nextTick(() => inputBarangStartDate.value?.focus())
      }
      return true
    }

    if (activeHistoryMenu.value === 'pembelian' && activePembelianFilter.value) {
      if (!showPembelianFilterModal.value && filteredPembelian.value.length) {
        focusPembelianRow(pembelianFocusedRowIndex.value)
      } else if (showPembelianFilterModal.value) {
        nextTick(() => inputPembelianStartDate.value?.focus())
      }
      return true
    }

    if (activeHistoryMenu.value === 'barang' && showBarangFilterModal.value) {
      nextTick(() => inputBarangStartDate.value?.focus())
      return true
    }

    if (activeHistoryMenu.value === 'pembelian' && showPembelianFilterModal.value) {
      nextTick(() => inputPembelianStartDate.value?.focus())
      return true
    }

    return true
  } catch (err) {
    console.error('[restoreHistoryState]', err)
    return false
  }
}

function goToMenu() {
  router.push('/dashboard')
}

function backToHistoryMenu() {
  activeHistoryMenu.value = ''
  showPembelianFilterModal.value = false
  showBarangFilterModal.value = false
  nextTick(() => pageEl.value?.focus())
}

function goPenjualanHistory() {
  router.push({
    path: '/penjualan/list',
    query: { from: 'history' },
  })
}

function onHistoryCardClick(idx) {
  selectedHistoryCardIndex.value = idx
  onHistoryCardEnter()
}

function onHistoryCardEnter() {
  const selected = historyCards[selectedHistoryCardIndex.value]
  if (!selected) return

  if (selected.key === 'penjualan') {
    goPenjualanHistory()
    return
  }

  if (selected.key === 'barang') {
    openHistoryBarang()
    return
  }

  router.push({
    path: '/pembelian/history-pembelian',
    query: { from: 'history' },
  })
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

async function openHistoryBarang() {
  activeHistoryMenu.value = 'barang'
  showPembelianFilterModal.value = false
  if (!hasSubmittedBarangFilter.value) {
    openBarangFilterModal()
  } else {
    await loadBarangHistory()
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
  searchPartyBarang.value = ''
  searchItemBarang.value = ''
  showBarangFilterModal.value = false
  focusFirstBarangRow()
}

function resolvePurchaseValidationState(order, item, idx) {
  const validations = order?.receiving_validations && typeof order.receiving_validations === 'object'
    ? order.receiving_validations
    : {}
  const validatedAtMap = order?.receiving_validated_at && typeof order.receiving_validated_at === 'object'
    ? order.receiving_validated_at
    : {}

  const explicitKey = String(item?.receiving_key || '').trim()
  const generatedKey = String(getPurchaseReceivingItemKey(item, idx) || '').trim()
  const candidateKeys = []

  if (explicitKey) {
    candidateKeys.push(explicitKey)
  } else if (generatedKey) {
    candidateKeys.push(generatedKey)
  }

  const baseDate = order?.received_at || order?.updated_at || order?.order_date || null
  const validationKeys = Object.keys(validations)
  const hasValidationEntries = validationKeys.length > 0
  const orderLooksReceived = String(order?.status || '') === 'received' || Boolean(order?.received_at)

  // Jika map validasi tersedia, jadikan itu satu-satunya sumber kebenaran.
  if (hasValidationEntries) {
    for (const key of candidateKeys) {
      if (!key) continue
      if (Boolean(validations[key])) {
        return {
          isValidated: true,
          matchedKey: key,
          movementDate: validatedAtMap[key] || baseDate,
        }
      }
    }

    // Fallback khusus data lama tanpa receiving_key item.
    // Untuk mencegah false-positive, fallback hanya dipakai jika match valid tepat 1 key.
    if (!explicitKey) {
      const prefix = `${String(item?.product_id ?? '')}|${String(item?.product_kode ?? '')}|${String(item?.product_nama ?? '')}|${Number(item?.unit_cost || 0)}|`
      const matchedKeys = validationKeys.filter(key => key.startsWith(prefix) && Boolean(validations[key]))
      if (matchedKeys.length === 1) {
        const fallbackKey = matchedKeys[0]
        return {
          isValidated: true,
          matchedKey: fallbackKey,
          movementDate: validatedAtMap[fallbackKey] || baseDate,
        }
      }
    }

    return {
      isValidated: false,
      matchedKey: candidateKeys[0] || '',
      movementDate: null,
    }
  }

  // Legacy fallback (data lama tanpa map validasi).
  if (orderLooksReceived) {
    return {
      isValidated: true,
      matchedKey: candidateKeys[0] || '',
      movementDate: baseDate,
    }
  }

  return {
    isValidated: false,
    matchedKey: candidateKeys[0] || '',
    movementDate: null,
  }
}

function buildLocalPurchaseRows(filter, byProduct) {
  return orders.value
    .flatMap(order =>
      (order.items || [])
        .map((item, idx) => {
          const validationState = resolvePurchaseValidationState(order, item, idx)
          if (!validationState.isValidated) return null

          const movementDate = toDateOnly(validationState.movementDate || order.received_at || order.updated_at || order.order_date)
          if (!movementDate || movementDate < filter.startDate || movementDate > filter.endDate) {
            return null
          }

          return {
            ...item,
            __movement_date: movementDate,
          }
        })
        .filter(Boolean)
        .filter(item => {
          const nama = (item.product_nama || '').toLowerCase()
          return !byProduct || nama.includes(byProduct)
        })
        .map(item => ({
          type: 'pembelian',
          no_order: order.no_order || '-',
          date: item.__movement_date || toDateOnly(order.received_at || order.order_date),
          no_faktur: order.no_faktur || order.faktur || '-',
          party_name: order.supplier?.nama || '-',
          supplier_name: order.supplier?.nama || '-',
          staff_name: '-',
          staff_reason: '-',
          customer_name: '-',
          product_kode: item.product_kode || '-',
          product_name: item.product_nama || '-',
          stock_out: 0,
          stock_in: Number(item.qty || 0),
        }))
    )
}

async function loadPurchaseRowsFromDatabase(filter, byProduct) {
  const { data: purchasesData, error: purchasesError } = await supabase
    .from('purchases')
    .select('id, no_order, order_date, received_at, updated_at, no_faktur, supplier_nama, status, receiving_validations, receiving_validated_at')
    .neq('status', 'draft')

  if (purchasesError) throw purchasesError

  const allPurchases = purchasesData || []
  const purchaseIds = allPurchases.map(row => row.id).filter(Boolean)
  if (!purchaseIds.length) return []

  const { data: purchaseItemsData, error: purchaseItemsError } = await supabase
    .from('purchase_items')
    .select('purchase_id, product_id, product_kode, product_nama, qty, unit_cost, receiving_key')
    .in('purchase_id', purchaseIds)

  if (purchaseItemsError) throw purchaseItemsError

  const itemsByPurchase = (purchaseItemsData || []).reduce((acc, item) => {
    if (!acc[item.purchase_id]) acc[item.purchase_id] = []
    acc[item.purchase_id].push(item)
    return acc
  }, {})

  return allPurchases.flatMap(order =>
    (itemsByPurchase[order.id] || [])
      .map((item, idx) => {
        const validationState = resolvePurchaseValidationState(order, item, idx)
        if (!validationState.isValidated) return null

        const movementDate = toDateOnly(validationState.movementDate || order.received_at || order.updated_at || order.order_date)
        if (!movementDate || movementDate < filter.startDate || movementDate > filter.endDate) {
          return null
        }

        return {
          ...item,
          __movement_date: movementDate,
        }
      })
      .filter(Boolean)
      .filter(item => {
        const nama = (item.product_nama || '').toLowerCase()
        return !byProduct || nama.includes(byProduct)
      })
      .map(item => ({
        type: 'pembelian',
        no_order: order.no_order || '-',
        date: item.__movement_date || toDateOnly(order.received_at || order.order_date),
        no_faktur: order.no_faktur || '-',
        party_name: order.supplier_nama || '-',
        supplier_name: order.supplier_nama || '-',
        staff_name: '-',
        staff_reason: '-',
        customer_name: '-',
        product_kode: item.product_kode || '-',
        product_name: item.product_nama || '-',
        stock_out: 0,
        stock_in: Number(item.qty || 0),
      }))
  )
}

async function loadLegacyPurchaseRowsFromDatabase(filter, byProduct) {
  const { data: purchasesData, error: purchasesError } = await supabase
    .from('purchases')
    .select('id, no_order, order_date, received_at, updated_at, no_faktur, supplier_nama, status')
    .neq('status', 'draft')

  if (purchasesError) throw purchasesError

  const allPurchases = purchasesData || []
  const purchaseIds = allPurchases.map(row => row.id).filter(Boolean)
  if (!purchaseIds.length) return []

  const { data: purchaseItemsData, error: purchaseItemsError } = await supabase
    .from('purchase_items')
    .select('purchase_id, product_id, product_kode, product_nama, qty, unit_cost')
    .in('purchase_id', purchaseIds)

  if (purchaseItemsError) throw purchaseItemsError

  const itemsByPurchase = (purchaseItemsData || []).reduce((acc, item) => {
    if (!acc[item.purchase_id]) acc[item.purchase_id] = []
    acc[item.purchase_id].push(item)
    return acc
  }, {})

  return allPurchases.flatMap(order => {
    const isReceived = String(order?.status || '') === 'received' || Boolean(order?.received_at)
    if (!isReceived) return []

    return (itemsByPurchase[order.id] || [])
      .filter(item => {
        const nama = (item.product_nama || '').toLowerCase()
        return !byProduct || nama.includes(byProduct)
      })
      .map(item => {
        const movementDate = toDateOnly(order.received_at || order.updated_at || order.order_date)
        if (!movementDate || movementDate < filter.startDate || movementDate > filter.endDate) {
          return null
        }

        return {
          type: 'pembelian',
          no_order: order.no_order || '-',
          date: movementDate,
          no_faktur: order.no_faktur || '-',
          party_name: order.supplier_nama || '-',
          supplier_name: order.supplier_nama || '-',
          staff_name: '-',
          staff_reason: '-',
          customer_name: '-',
          product_kode: item.product_kode || '-',
          product_name: item.product_nama || '-',
          stock_out: 0,
          stock_in: Number(item.qty || 0),
        }
      })
      .filter(Boolean)
  })
}

async function loadStaffAdjustmentRowsFromDatabase(filter, byProduct) {
  const { data, error } = await supabase
    .from('stock_adjustments')
    .select('id, product_id, product_kode, product_nama, adjustment_date, qty_delta, staff_nama, alasan, created_at')
    .gte('adjustment_date', filter.startDate)
    .lte('adjustment_date', filter.endDate)
    .order('adjustment_date', { ascending: false })
    .order('created_at', { ascending: false })

  if (error) throw error

  return (data || [])
    .filter(row => {
      const nama = String(row.product_nama || '').toLowerCase()
      const kode = String(row.product_kode || '').toLowerCase()
      return !byProduct || nama.includes(byProduct) || kode.includes(byProduct)
    })
    .map(row => {
      const qtyDelta = Number(row.qty_delta || 0)
      return {
        id: row.id,
        type: 'staff',
        no_order: '-',
        date: toDateOnly(row.adjustment_date || row.created_at),
        no_faktur: '-',
        party_name: '-',
        supplier_name: '-',
        staff_name: row.staff_nama || '-',
        staff_reason: row.alasan || '-',
        customer_name: '-',
        product_kode: row.product_kode || '-',
        product_name: row.product_nama || '-',
        stock_out: qtyDelta < 0 ? Math.abs(qtyDelta) : 0,
        stock_in: qtyDelta > 0 ? qtyDelta : 0,
      }
    })
}

async function loadBarangHistory() {
  if (!activeBarangFilter.value) return

  barangLoading.value = true
  barangError.value = ''
  try {
    const byProduct = activeBarangFilter.value.productName.toLowerCase()
    let purchaseRows = []

    try {
      purchaseRows = await loadPurchaseRowsFromDatabase(activeBarangFilter.value, byProduct)
    } catch (purchaseError) {
      console.warn('[loadBarangHistory] fallback purchase rows', purchaseError)

      try {
        purchaseRows = await loadLegacyPurchaseRowsFromDatabase(activeBarangFilter.value, byProduct)
      } catch (legacyError) {
        console.warn('[loadBarangHistory] fallback local purchase rows', legacyError)
        purchaseRows = buildLocalPurchaseRows(activeBarangFilter.value, byProduct)

        if (!isMissingRelationError(legacyError) && !isMissingColumnError(legacyError)) {
          barangError.value =
            'Riwayat pembelian detail gagal dimuat, menampilkan data sinkron order pembelian dari database.'
        }
      }

      if (!purchaseRows.length && isMissingColumnError(purchaseError)) {
        barangError.value =
          'Sebagian kolom history pembelian belum tersedia di database. Jalankan migrasi schema terbaru agar data barang masuk tampil lengkap.'
      }
    }

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
        .select('sale_id, product_kode, product_nama, qty')
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
          supplier_name: '-',
          staff_name: '-',
          staff_reason: '-',
          customer_name: order.customer_nama || '-',
          product_kode: item.product_kode || '-',
          product_name: item.product_nama || '-',
          stock_out: Number(item.qty || 0),
          stock_in: 0,
        }))
    )

    let staffRows = []
    try {
      staffRows = await loadStaffAdjustmentRowsFromDatabase(activeBarangFilter.value, byProduct)
    } catch (staffError) {
      console.warn('[loadBarangHistory] load staff adjustment rows', staffError)
      if (!isMissingRelationError(staffError) && !isMissingColumnError(staffError)) {
        if (!barangError.value) {
          barangError.value = 'Sebagian histori perubahan stok staff gagal dimuat dari database.'
        }
      } else if (!barangError.value) {
        barangError.value =
          'Tabel histori penyesuaian stok staff belum tersedia. Jalankan migrasi schema terbaru agar data edit stok gudang tampil di history barang.'
      }
    }

    barangRows.value = [...purchaseRows, ...saleRows, ...staffRows]
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
    if (showPembelianFilterModal.value) {
      backToHistoryMenu()
    } else {
      openPembelianFilterModal()
    }
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

  if (e.key === 'F2') {
    e.preventDefault()
    if (!showBarangFilterModal.value && hasSubmittedBarangFilter.value) {
      inputBarangParty.value?.focus()
    }
    return true
  }

  if (e.key === 'F3') {
    e.preventDefault()
    if (!showBarangFilterModal.value && hasSubmittedBarangFilter.value) {
      inputBarangItem.value?.focus()
    }
    return true
  }

  if (e.key === 'F4') {
    e.preventDefault()
    if (!showBarangFilterModal.value && hasSubmittedBarangFilter.value) {
      focusFirstBarangRow()
    }
    return true
  }

  if (e.key === 'Escape') {
    e.preventDefault()
    if (showBarangFilterModal.value) {
      backToHistoryMenu()
    } else {
      openBarangFilterModal()
    }
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

watch(
  [
    activeHistoryMenu,
    selectedHistoryCardIndex,
    activePembelianFilter,
    searchNoPembelian,
    showPembelianFilterModal,
    pembelianStartDate,
    pembelianEndDate,
    pembelianSupplierFilter,
    pembelianFocusedRowIndex,
    activeBarangFilter,
    searchNoBarang,
    searchPartyBarang,
    searchItemBarang,
    showBarangFilterModal,
    barangStartDate,
    barangEndDate,
    barangNameFilter,
    barangFocusedRowIndex,
    barangRows,
  ],
  () => {
    persistHistoryState()
  },
  { deep: true }
)

onMounted(async () => {
  pageEl.value?.focus()
  try {
    orders.value = await listPurchaseOrders()
  } catch (err) {
    console.error('[listPurchaseOrders history menu]', err)
    orders.value = []
  }
  historyStats.value.totalPembelian = orders.value.length
  historyStats.value.receivedPembelian = orders.value.filter(o => o.status === 'received').length

  try {
    await loadPurchaseStatsFromDatabase()
  } catch (statsError) {
    if (!isMissingRelationError(statsError)) {
      console.warn('[loadPurchaseStatsFromDatabase]', statsError)
    }
  }

  setDefaultDateRange(pembelianStartDate, pembelianEndDate)
  setDefaultDateRange(barangStartDate, barangEndDate)

  await restoreHistoryState()

  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<style scoped>
@import '@/assets/Styles/History/history-page.css';
</style>
