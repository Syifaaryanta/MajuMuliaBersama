<template>
  <div class="gudang-page" ref="pageEl" tabindex="-1">

    <!-- ── PAGE HEADER ──────────────────────────────────── -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Cek Harga Barang</h1>
        <p class="g-subtitle">Cek stok & harga barang per customer</p>
      </div>
    </div>

    <!-- ── SEARCH SECTION ───────────────────────────────── -->
    <div class="search-section">
      <div class="search-field">
        <label class="search-label">
          Nama / Kode Barang
          <kbd class="label-kbd">F1</kbd>
        </label>
        <div class="search-input-wrap" :class="{ focused: focusedField === 'barang' }">
          <i class="pi pi-search si-icon"></i>
          <input
            ref="inputBarang"
            v-model="searchBarang"
            type="text"
            class="search-input"
            placeholder="Ketik nama atau kode, Enter untuk cari…"
            autocomplete="off"
            @focus="focusedField = 'barang'"
            @blur="onBarangBlur"
            @input="onBarangInput"
            @keydown="onBarangKey"
          />
          <button
            v-if="searchBarang"
            class="clear-btn"
            @click="clearBarang"
            tabindex="-1"
          ><i class="pi pi-times"></i></button>
        </div>
        <!-- Barang suggestions removed - tekan Enter untuk buka popup -->
      </div>

      <div class="search-field">
        <label class="search-label">
          Nama Customer
          <kbd class="label-kbd">F2</kbd>
          <span class="optional-tag">opsional</span>
        </label>
        <div class="search-input-wrap" :class="{ focused: focusedField === 'customer' }">
          <i class="pi pi-user si-icon"></i>
          <input
            ref="inputCustomer"
            v-model="searchCustomer"
            type="text"
            class="search-input"
            placeholder="Ketik nama customer untuk lihat histori harga…"
            autocomplete="off"
            @focus="focusedField = 'customer'"
            @blur="onCustomerBlur"
            @keydown="onCustomerKey"
            @input="onCustomerInput"
          />
          <button
            v-if="searchCustomer"
            class="clear-btn"
            @click="clearCustomer"
            tabindex="-1"
          ><i class="pi pi-times"></i></button>
        </div>
        <!-- Customer suggestions removed - tekan Enter untuk buka popup -->
      </div>
    </div>

    <!-- ── INFO CARDS (always visible) ──────────────────── -->
    <div class="info-cards">
      <div class="info-card" :class="{ 'info-card--filled': infoCards.lastUnitPrice != null }">
        <div class="ic-icon"><i class="pi pi-tag"></i></div>
        <div class="ic-body">
          <span class="ic-label">Last Unit Price</span>
          <span class="ic-value">
            {{ infoCards.lastUnitPrice != null ? formatRp(infoCards.lastUnitPrice) : '—' }}
          </span>
        </div>
      </div>
      <div class="info-card" :class="{ 'info-card--filled': infoCards.lastUnitCost != null }">
        <div class="ic-icon"><i class="pi pi-dollar"></i></div>
        <div class="ic-body">
          <span class="ic-label">Last Unit Cost</span>
          <span class="ic-value">
            {{ infoCards.lastUnitCost != null ? formatRp(infoCards.lastUnitCost) : '—' }}
          </span>
        </div>
      </div>
      <div class="info-card" :class="{ 'info-card--filled': infoCards.lastSaleQty != null }">
        <div class="ic-icon"><i class="pi pi-box"></i></div>
        <div class="ic-body">
          <span class="ic-label">Last Sale Qty</span>
          <span class="ic-value">
            {{ infoCards.lastSaleQty != null ? infoCards.lastSaleQty + ' pcs' : '—' }}
          </span>
        </div>
      </div>
      <div class="info-card" :class="{ 'info-card--filled': infoCards.lastOrderDate != null }">
        <div class="ic-icon"><i class="pi pi-calendar"></i></div>
        <div class="ic-body">
          <span class="ic-label">Last Order Date</span>
          <span class="ic-value">
            {{ infoCards.lastOrderDate != null ? formatDate(infoCards.lastOrderDate) : '—' }}
          </span>
        </div>
      </div>
      <div class="info-card info-card--accent" :class="{ 'info-card--filled': infoCards.newUnitCost != null }">
        <div class="ic-icon"><i class="pi pi-shopping-cart"></i></div>
        <div class="ic-body">
          <span class="ic-label">New Unit Cost</span>
          <span class="ic-value">
            {{ infoCards.newUnitCost != null ? formatRp(infoCards.newUnitCost) : '—' }}
          </span>
        </div>
      </div>
    </div>

    <!-- ── HASIL PENCARIAN ───────────────────────────────── -->
    <div v-if="!hasSearched" class="empty-hint">
      <i class="pi pi-search empty-search-icon"></i>
      <p>Ketik nama atau kode barang di atas untuk mencari</p>
      <span class="empty-hint-sub">Pencarian otomatis setelah 400ms · <kbd>Enter</kbd> untuk langsung cari</span>
    </div>

    <template v-else>
      <!-- Meta bar -->
      <div class="result-meta">
        <span class="result-count">
          <b>{{ totalRows }}</b> baris ditemukan
          <span v-if="selectedCustomer" class="meta-customer">
            · Customer: <b>{{ selectedCustomer.nama }}</b>
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

      <!-- Table -->
      <div class="table-wrap" ref="tableWrap">
        <table class="g-table" ref="tableEl">
          <thead>
            <tr>
              <th class="col-no">#</th>
              <th class="col-kode">Kode</th>
              <th class="col-nama">Nama Barang</th>
              <th class="col-stok">Stok</th>
              <th class="col-supplier">Supplier</th>
              <th class="col-harga">Harga Beli</th>
            </tr>
          </thead>
          <tbody v-if="loading">
            <tr v-for="n in 5" :key="n">
              <td colspan="6"><div class="skeleton"></div></td>
            </tr>
          </tbody>
          <tbody v-else-if="pagedRows.length === 0">
            <tr>
              <td colspan="6" class="empty-cell">
                <i class="pi pi-search-minus"></i>
                Tidak ada barang ditemukan untuk "<b>{{ lastSearch }}</b>"
              </td>
            </tr>
          </tbody>
          <tbody v-else>
            <template v-for="(row, i) in pagedRows" :key="row.product_id">
              <tr
                v-for="(price, priceIdx) in row.prices"
                :key="`${row.product_id}-${price.id}`"
                :ref="el => { if (priceIdx === 0) setRowRef(el, i); }"
                :data-index="i"
                class="g-row"
                :class="{
                  'g-row--active': selectedRowIndex === i,
                  'g-row--lowstok': price.stok <= 3,
                }"
                @click="selectedRowIndex = i"
                @dblclick="viewDetail(row)"
              >
                <td v-if="priceIdx === 0" :rowspan="row.prices.length" class="col-no">
                  {{ (currentPage - 1) * PAGE_SIZE + i + 1 }}
                </td>
                <td v-if="priceIdx === 0" :rowspan="row.prices.length" class="col-kode">
                  <span class="kode-badge">{{ row.kode }}</span>
                </td>
                <td v-if="priceIdx === 0" :rowspan="row.prices.length" class="col-nama">
                  {{ row.nama }}
                </td>
                <td class="col-stok">
                  <span class="stok-val" :class="{ 'stok-low': price.stok <= 3 }">
                    {{ price.stok }} {{ row.satuan }}
                  </span>
                </td>
                <td class="col-supplier">
                  <span class="supplier-chip">{{ price.supplier_nama }}</span>
                </td>
                <td class="col-harga">
                  <span class="harga-val">{{ formatRp(price.harga_beli) }}</span>
                </td>
              </tr>
            </template>
          </tbody>
        </table>
      </div>


    </template>

    <!-- edit modal dipindah ke GudangKatalogPage -->

    <!-- ── MODAL: PILIH BARANG ────────────────────────────── -->
    <Teleport to="body">
      <Transition name="modal-fade">
        <div v-if="barangModal.show" class="modal-backdrop" @click="barangModal.show = false">
          <div class="modal-box modal-lg" @click.stop>
            <div class="modal-header">
              <h3 class="modal-title">Pilih Barang</h3>
              <button class="modal-close" @click="barangModal.show = false">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <div class="search-input-wrap" style="margin-bottom: 1rem;">
                <i class="pi pi-search si-icon"></i>
                <input
                  ref="barangModalInput"
                  v-model="barangModal.query"
                  type="text"
                  class="search-input"
                  placeholder="Ketik untuk filter…"
                  @input="filterBarangModal"
                  @keydown="onBarangModalKey"
                />
              </div>
              <div class="modal-list">
                <div
                  v-for="(p, i) in barangModal.filtered"
                  :key="p.id"
                  class="modal-item"
                  :class="{ 'modal-item--active': barangModal.selectedIndex === i }"
                  @click="selectBarangFromModal(p)"
                  @mouseenter="barangModal.selectedIndex = i"
                >
                  <i class="pi pi-box"></i>
                  <div class="modal-item-detail">
                    <span class="modal-item-nama">{{ p.nama }}</span>
                    <span class="modal-item-meta">{{ p.kode }} · Stok: <b>{{ p.stok }}</b> {{ p.satuan }}</span>
                  </div>
                </div>
                <div v-if="!barangModal.filtered.length" class="empty-state">
                  <i class="pi pi-inbox"></i>
                  <p>Tidak ada barang yang cocok</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ── MODAL: PILIH CUSTOMER ──────────────────────────── -->
    <Teleport to="body">
      <Transition name="modal-fade">
        <div v-if="customerModal.show" class="modal-backdrop" @click="customerModal.show = false">
          <div class="modal-box modal-lg" @click.stop>
            <div class="modal-header">
              <h3 class="modal-title">Pilih Customer</h3>
              <button class="modal-close" @click="customerModal.show = false">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <div class="search-input-wrap" style="margin-bottom: 1rem;">
                <i class="pi pi-search si-icon"></i>
                <input
                  ref="customerModalInput"
                  v-model="customerModal.query"
                  type="text"
                  class="search-input"
                  placeholder="Ketik untuk filter…"
                  @input="filterCustomerModal"
                  @keydown="onCustomerModalKey"
                />
              </div>
              <div class="modal-list">
                <div
                  v-for="(c, i) in customerModal.filtered"
                  :key="c.id"
                  class="modal-item"
                  :class="{ 'modal-item--active': customerModal.selectedIndex === i }"
                  @click="selectCustomerFromModal(c)"
                  @mouseenter="customerModal.selectedIndex = i"
                >
                  <i class="pi pi-user"></i>
                  <div class="modal-item-detail">
                    <span class="modal-item-nama">{{ c.nama }}</span>
                    <span class="modal-item-meta">{{ c.kode }}</span>
                  </div>
                </div>
                <div v-if="!customerModal.filtered.length" class="empty-state">
                  <i class="pi pi-inbox"></i>
                  <p>Tidak ada customer yang cocok</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════
         LIGHTBOX FOTO
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal-fade">
        <div v-if="lightbox.show" class="lightbox-overlay" @click="closeLightbox">
          <div class="lightbox-content" @click.stop>
            <button class="lightbox-close" @click="closeLightbox">
              <i class="pi pi-times"></i>
            </button>
            <button 
              v-if="lightbox.currentIndex > 0"
              class="lightbox-prev" 
              @click="prevPhoto"
            >
              <i class="pi pi-chevron-left"></i>
            </button>
            <div class="lightbox-image-wrap">
              <img 
                :src="lightbox.photos[lightbox.currentIndex]" 
                :alt="`Foto ${lightbox.currentIndex + 1}`"
                class="lightbox-image"
              />
            </div>
            <button 
              v-if="lightbox.currentIndex < lightbox.photos.length - 1"
              class="lightbox-next" 
              @click="nextPhoto"
            >
              <i class="pi pi-chevron-right"></i>
            </button>
            <div class="lightbox-counter">
              {{ lightbox.currentIndex + 1 }} / {{ lightbox.photos.length }}
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { supabase } from '@/lib/supabase'
import { useRouter } from 'vue-router'

const router = useRouter()

// ── Constants ──────────────────────────────────────────────
const PAGE_SIZE = 15

// ── DOM Refs ───────────────────────────────────────────────
const pageEl        = ref(null)
const inputBarang   = ref(null)
const inputCustomer = ref(null)
const firstInput    = ref(null) // kept for compat
const photoViewRef  = ref(null)
const rowRefs       = new Map()
// Edit modal refs
const inputKode     = ref(null)
const inputNama     = ref(null)
const photoAreaRef  = ref(null)
const btnSave       = ref(null)
const priceSupplierRefs = ref({})
const priceStokRefs     = ref({})
const priceHargaRefs    = ref({})

function setRowRef(el, i) {
  if (el) rowRefs.set(i, el)
  else    rowRefs.delete(i)
}

// ── State: search ──────────────────────────────────────────
const searchBarang   = ref('')
const searchCustomer = ref('')
const focusedField   = ref('')
const lastSearch     = ref('')
const hasSearched    = ref(false)
const loading        = ref(false)

// ── State: customer modal ──────────────────────────────────
const customerModal = reactive({
  show: false,
  query: '',
  results: [],
  filtered: [],
  selectedIndex: 0,
})
const customerModalInput = ref(null)
const selectedCustomer   = ref(null)

// ── State: barang modal ────────────────────────────────────
const barangModal = reactive({
  show: false,
  query: '',
  results: [],
  filtered: [],
  selectedIndex: 0,
})
const barangModalInput = ref(null)

// ── State: table & paging ──────────────────────────────────
const allRows          = ref([])
const selectedRowIndex = ref(-1)
const currentPage      = ref(1)

const totalRows  = computed(() => allRows.value.length)
const totalPages = computed(() => Math.max(1, Math.ceil(totalRows.value / PAGE_SIZE)))
const pagedRows  = computed(() => {
  const start = (currentPage.value - 1) * PAGE_SIZE
  return allRows.value.slice(start, start + PAGE_SIZE)
})

// Data barang yang dipilih (untuk tampilan foto)
const selectedRowData = computed(() => {
  if (selectedRowIndex.value >= 0 && pagedRows.value[selectedRowIndex.value]) {
    return pagedRows.value[selectedRowIndex.value]
  }
  return null
})

// ── State: info cards ──────────────────────────────────────
const infoCards = reactive({
  lastUnitPrice : null,
  lastUnitCost  : null,
  lastSaleQty   : null,
  lastOrderDate : null,
  newUnitCost   : null,
})

// ── Debounce timers ────────────────────────────────────────
let barangTimer = null

// ── Suppliers (untuk modal) ────────────────────────────────
const suppliers = ref([])

// ── Modal state ────────────────────────────────────────────
const modal = reactive({
  show: false, mode: 'add', title: '', saving: false, error: '',
  activePriceRow: 0,
})
const dropdownPos = reactive({ top: 0, left: 0, width: 0 })
const form = reactive({
  id: null, kode: '', nama: '', deskripsi: '', stok: 0, satuan: 'pcs',
  prices: [{ supplier_id: '', supplierSearch: '', filteredSuppliers: [], dropdownOpen: false, dropdownIndex: 0, stok: 0, harga_beli: 0 }],
  foto_urls: [],
})

// State untuk foto upload
const photoUpload = reactive({
  uploading: false,
  progress: 0,
  error: '',
})

// State untuk lightbox
const lightbox = reactive({
  show: false,
  photos: [],
  currentIndex: 0,
})
const deleteModal = reactive({ show: false, row: null, saving: false })

// ───────────────────────────────────────────────────────────
// UTILITY
// ───────────────────────────────────────────────────────────
function formatRp(val) {
  return 'Rp ' + Number(val).toLocaleString('id-ID')
}
function formatDate(d) {
  if (!d) return '—'
  return new Date(d).toLocaleDateString('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
  })
}

// ───────────────────────────────────────────────────────────
// GLOBAL KEYBOARD HANDLER
// ───────────────────────────────────────────────────────────
function onGlobalKey(e) {
  // Lightbox takes full keyboard priority
  if (lightbox.show) {
    if (e.key === 'Escape')    { e.preventDefault(); closeLightbox() }
    else if (e.key === 'ArrowLeft')  { e.preventDefault(); prevPhoto() }
    else if (e.key === 'ArrowRight') { e.preventDefault(); nextPhoto() }
    return
  }

  if (modal.show || deleteModal.show) return

  switch (e.key) {
    case 'F1':
      e.preventDefault()
      inputBarang.value?.focus()
      break
    case 'F2':
      e.preventDefault()
      inputCustomer.value?.focus()
      break
    case 'F4':
      if (selectedRowIndex.value >= 0) {
        e.preventDefault()
        viewDetail(pagedRows.value[selectedRowIndex.value])
      }
      break
    case 'Enter':
      if (hasSearched.value && selectedRowIndex.value >= 0 && !e.target.matches('input,textarea,select')) {
        e.preventDefault()
        viewDetail(pagedRows.value[selectedRowIndex.value])
      }
      break
    case 'ArrowDown':
      if (hasSearched.value && !e.target.matches('input,textarea,select')) {
        e.preventDefault()
        e.stopPropagation()
        moveRow(1)
      }
      break
    case 'ArrowUp':
      if (hasSearched.value && !e.target.matches('input,textarea,select')) {
        e.preventDefault()
        e.stopPropagation()
        moveRow(-1)
      }
      break
    case 'PageDown':
      e.preventDefault(); nextPage()
      break
    case 'PageUp':
      e.preventDefault(); prevPage()
      break
    case 'Escape':
      e.preventDefault()
      e.stopPropagation()
      if (hasSearched.value) {
        // ESC saat hasil tampil: reset ke input
        clearBarang()
        nextTick(() => inputBarang.value?.focus())
      } else {
        // ESC saat input kosong: ke menu gudang
        router.push('/gudang')
      }
      break
    case 'n':
    case 'N':
      if (e.altKey) { e.preventDefault(); openAdd() }
      break
  }
}

function onModalEscKey(e) {
  if (e.key !== 'Escape') return
  if (deleteModal.show)   deleteModal.show = false
  else if (modal.show)    closeModal()
}

// ───────────────────────────────────────────────────────────
// INPUT HANDLERS
// ───────────────────────────────────────────────────────────
function onBarangInput() {
  clearTimeout(barangTimer)
  const q = searchBarang.value.trim()
  if (!q) { clearBarang(); return }
  // Tidak perlu fetch dropdown - user akan tekan Enter untuk buka modal
}

function onBarangBlur() {
  focusedField.value = ''
}

function onBarangKey(e) {
  if (e.key === 'Enter') {
    e.preventDefault()
    openBarangModal()
  } else if (e.key === 'ArrowDown' && hasSearched.value) {
    e.preventDefault()
    e.stopPropagation()
    inputBarang.value?.blur()
    moveRow(0)
  } else if (e.key === 'Escape') {
    e.preventDefault()
    e.stopPropagation()
    if (hasSearched.value) {
      // ESC dari input saat hasil tampil: reset
      clearBarang()
    } else if (!searchBarang.value.trim()) {
      // ESC saat kosong & belum ada hasil: ke menu gudang
      router.push('/gudang')
    } else {
      // ESC saat ada teks tapi belum search: clear teks
      searchBarang.value = ''
    }
  }
}

function onCustomerKey(e) {
  if (e.key === 'Enter') {
    e.preventDefault()
    openCustomerModal()
  }
}

function onCustomerBlur() {
  focusedField.value = ''
}

function onCustomerInput() {
  selectedCustomer.value = null
  clearInfoCards()
}

// ───────────────────────────────────────────────────────────
// BARANG MODAL
// ───────────────────────────────────────────────────────────
async function openBarangModal() {
  const q = searchBarang.value.trim()
  if (!q) return
  
  // Fetch barang yang cocok (exclude archived)
  const { data, error } = await supabase
    .from('products')
    .select('*')
    .or(`nama.ilike.%${q}%,kode.ilike.%${q}%`)
    .eq('aktif', true)
    .eq('is_archived', false)
    .order('nama')
  
  if (error) {
    console.error('[openBarangModal]', error)
    return
  }
  
  barangModal.results = data || []
  barangModal.filtered = data || []
  barangModal.query = ''
  barangModal.selectedIndex = 0
  barangModal.show = true
  
  await nextTick()
  barangModalInput.value?.focus()
}

function filterBarangModal() {
  const q = barangModal.query.toLowerCase()
  barangModal.filtered = q 
    ? barangModal.results.filter(p => 
        p.nama.toLowerCase().includes(q) || p.kode.toLowerCase().includes(q)
      )
    : barangModal.results
  barangModal.selectedIndex = 0
}

function selectBarangFromModal(product) {
  barangModal.show = false
  searchBarang.value = product.nama
  doSearch(product.id)
}

function onBarangModalKey(e) {
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    barangModal.selectedIndex = Math.min(barangModal.selectedIndex + 1, barangModal.filtered.length - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    barangModal.selectedIndex = Math.max(barangModal.selectedIndex - 1, 0)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (barangModal.filtered[barangModal.selectedIndex]) {
      selectBarangFromModal(barangModal.filtered[barangModal.selectedIndex])
    }
  } else if (e.key === 'Escape') {
    barangModal.show = false
  }
}

// ───────────────────────────────────────────────────────────
// CUSTOMER MODAL
// ───────────────────────────────────────────────────────────
async function openCustomerModal() {
  const q = searchCustomer.value.trim()
  if (!q) return
  
  // Fetch customer yang cocok
  const { data, error } = await supabase
    .from('customers')
    .select('*')
    .ilike('nama', `%${q}%`)
    .eq('aktif', true)
    .order('nama')
  
  if (error) {
    console.error('[openCustomerModal]', error)
    return
  }
  
  customerModal.results = data || []
  customerModal.filtered = data || []
  customerModal.query = ''
  customerModal.selectedIndex = 0
  customerModal.show = true
  
  await nextTick()
  customerModalInput.value?.focus()
}

function filterCustomerModal() {
  const q = customerModal.query.toLowerCase()
  customerModal.filtered = q 
    ? customerModal.results.filter(c => 
        c.nama.toLowerCase().includes(q) || c.kode.toLowerCase().includes(q)
      )
    : customerModal.results
  customerModal.selectedIndex = 0
}

function selectCustomerFromModal(customer) {
  customerModal.show = false
  selectedCustomer.value = customer
  searchCustomer.value = customer.nama
  // Trigger pencarian ulang dengan customer filter
  if (lastSearch.value) doSearch()
}

function onCustomerModalKey(e) {
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    customerModal.selectedIndex = Math.min(customerModal.selectedIndex + 1, customerModal.filtered.length - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    customerModal.selectedIndex = Math.max(customerModal.selectedIndex - 1, 0)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (customerModal.filtered[customerModal.selectedIndex]) {
      selectCustomerFromModal(customerModal.filtered[customerModal.selectedIndex])
    }
  } else if (e.key === 'Escape') {
    customerModal.show = false
  }
}

// ───────────────────────────────────────────────────────────
// TABLE NAVIGATION
// ───────────────────────────────────────────────────────────
function moveRow(delta) {
  const max = pagedRows.value.length - 1
  if (max < 0) return
  if (delta === 0) { selectedRowIndex.value = 0 }
  else { selectedRowIndex.value = Math.max(0, Math.min(max, selectedRowIndex.value + delta)) }
  nextTick(() => rowRefs.get(selectedRowIndex.value)?.scrollIntoView({ block: 'nearest' }))
}

function prevPage() {
  if (currentPage.value > 1) { currentPage.value--; selectedRowIndex.value = 0 }
}
function nextPage() {
  if (currentPage.value < totalPages.value) { currentPage.value++; selectedRowIndex.value = 0 }
}

// ───────────────────────────────────────────────────────────
// SEARCH BARANG
// ───────────────────────────────────────────────────────────
async function doSearch(productId = null) {
  const q = searchBarang.value.trim()
  if (!productId && !q) return

  loading.value          = true
  hasSearched.value      = true
  lastSearch.value       = q
  currentPage.value      = 1
  selectedRowIndex.value = -1
  allRows.value          = []

  try {
    let query = supabase
      .from('products')
      .select(`
        id, kode, nama, deskripsi, stok, satuan, foto_urls,
        product_prices (
          id, harga_beli, aktif, stok,
          suppliers ( id, nama )
        )
      `)
      .eq('aktif', true)
      .eq('is_archived', false)
      .order('kode')

    if (productId) {
      query = query.eq('id', productId)
    } else {
      query = query.or(`nama.ilike.%${q}%,kode.ilike.%${q}%`)
    }

    const { data, error } = await query
    if (error) throw error

    // Group per product: 1 row per product dengan array prices
    const grouped = []
    for (const p of data ?? []) {
      const activePrices = p.product_prices?.filter(pp => pp.aktif) ?? []
      const prices = activePrices.map(pp => ({
        id: pp.id,
        supplier_id: pp.suppliers?.id ?? null,
        supplier_nama: pp.suppliers?.nama ?? null,
        harga_beli: pp.harga_beli,
        stok: pp.stok ?? 0,
      }))

      grouped.push({
        product_id: p.id,
        kode: p.kode,
        nama: p.nama,
        deskripsi: p.deskripsi,
        stok: p.stok,
        satuan: p.satuan,
        foto_urls: p.foto_urls ?? [],
        prices: prices,  // array of supplier prices
      })
    }
    allRows.value = grouped

    // Auto-select first row and move focus to table
    if (grouped.length > 0) {
      selectedRowIndex.value = 0
      nextTick(() => {
        rowRefs.get(0)?.focus?.() || rowRefs.get(0)?.scrollIntoView({ block: 'nearest' })
      })
    }

    if (selectedCustomer.value && grouped.length) {
      await fetchCustomerHistory(selectedCustomer.value.id, grouped[0].product_id)
    }
  } catch (err) {
    console.error('[Gudang] search:', err.message)
  } finally {
    loading.value = false
  }
}

// ───────────────────────────────────────────────────────────
// CUSTOMER
// ───────────────────────────────────────────────────────────
async function fetchCustomerHistory(customerId, productId) {
  clearInfoCards()
  if (!customerId || !productId) return
  try {
    // Tabel sale_items akan tersedia setelah modul Penjualan diimplementasi
    const { data } = await supabase
      .from('sale_items')
      .select('qty, harga_jual, harga_beli, sales!inner(tanggal, customer_id)')
      .eq('product_id', productId)
      .eq('sales.customer_id', customerId)
      .order('sales(tanggal)', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (data) {
      infoCards.lastUnitPrice = data.harga_jual
      infoCards.lastUnitCost  = data.harga_beli
      infoCards.lastSaleQty   = data.qty
      infoCards.lastOrderDate = data.sales?.tanggal
    }
  } catch { /* modul penjualan belum diimplementasi — kartu tetap tampil dengan '—' */ }
}

function clearInfoCards() {
  infoCards.lastUnitPrice = null
  infoCards.lastUnitCost  = null
  infoCards.lastSaleQty   = null
  infoCards.lastOrderDate = null
  infoCards.newUnitCost   = null
}

function clearCustomer() {
  searchCustomer.value   = ''
  selectedCustomer.value = null
  clearInfoCards()
  inputCustomer.value?.focus()
}

function clearBarang() {
  searchBarang.value        = ''
  hasSearched.value         = false
  allRows.value             = []
  selectedRowIndex.value    = -1
  lastSearch.value          = ''
  clearInfoCards()
}

// Navigate to GudangDetail page
function viewDetail(row) {
  if (!row) return
  router.push({ path: '/gudang/detail', query: { product_id: row.product_id } })
}

// ───────────────────────────────────────────────────────────
// SUPPLIERS
// ───────────────────────────────────────────────────────────
async function loadSuppliers() {
  try {
    const { data, error } = await supabase
      .from('suppliers').select('id, kode, nama').eq('aktif', true).order('nama')
    if (error) {
      console.error('[GudangPage] loadSuppliers error:', error)
    }
    suppliers.value = data ?? []
  } catch (err) {
    console.error('[GudangPage] loadSuppliers exception:', err)
  }
}

// ───────────────────────────────────────────────────────────
// MODAL ADD / EDIT
// ───────────────────────────────────────────────────────────
function makePriceRow(overrides = {}) {
  return {
    price_id: null,
    supplier_id: '',
    supplierSearch: '',
    filteredSuppliers: [],
    dropdownOpen: false,
    dropdownIndex: 0,
    stok: 0,
    harga_beli: 0,
    ...overrides,
  }
}

function resetForm() {
  form.id = null; form.kode = ''; form.nama = ''; form.deskripsi = ''
  form.stok = 0; form.satuan = 'pcs'
  form.prices = [makePriceRow()]
  form.foto_urls = []
  photoUpload.uploading = false
  photoUpload.progress = 0
  photoUpload.error = ''
  priceSupplierRefs.value = {}
  priceStokRefs.value = {}
  priceHargaRefs.value = {}
}

function openAdd() {
  resetForm()
  modal.mode  = 'add'
  modal.title = 'Tambah Barang Baru'
  modal.error = ''
  modal.activePriceRow = 0
  modal.show  = true
  nextTick(() => inputKode.value?.focus())
}

function openEdit(row) {
  if (!row) return
  resetForm()
  form.id        = row.product_id
  form.kode      = row.kode
  form.nama      = row.nama
  form.deskripsi = row.deskripsi ?? ''
  form.stok      = row.stok
  form.satuan    = row.satuan
  form.foto_urls = row.foto_urls ?? []

  // Populate prices with supplier search support
  form.prices = row.prices?.length
    ? row.prices.map(p => makePriceRow({
        price_id: p.id,
        supplier_id: p.supplier_id ?? '',
        supplierSearch: p.supplier_nama ?? '',
        stok: p.stok ?? 0,
        harga_beli: p.harga_beli ?? 0,
      }))
    : [makePriceRow()]

  modal.mode  = 'edit'
  modal.title = 'Edit Barang'
  modal.error = ''
  modal.activePriceRow = 0
  modal.show  = true
  nextTick(() => inputKode.value?.focus())
}

function closeModal() { modal.show = false }

function addPriceRow() {
  form.prices.push(makePriceRow())
  const newIdx = form.prices.length - 1
  modal.activePriceRow = newIdx
  nextTick(() => priceSupplierRefs.value[newIdx]?.focus())
}

function removePriceRow(i) {
  if (form.prices.length > 1) form.prices.splice(i, 1)
}

// ───────────────────────────────────────────────────────────
// MODAL KEYBOARD NAV
// ───────────────────────────────────────────────────────────
function focusField(refName) {
  const refMap = { inputKode, inputNama, photoAreaRef, btnSave }
  nextTick(() => refMap[refName]?.value?.focus())
}

function triggerFileInput() {
  fileInput.value?.click()
}

function focusFirstSupplier() {
  nextTick(() => priceSupplierRefs.value[0]?.focus())
}

// Global keydown inside the modal overlay
function onModalKeydown(e) {
  if (e.key === 'Escape') {
    e.preventDefault()
    closeModal()
  } else if (e.key === 'y' || e.key === 'Y') {
    // Y shortcut to save - only if not in a text input
    if (!e.target.matches('input[type=text],input[type=number],textarea,select')) {
      e.preventDefault()
      submitModal()
    }
  } else if (e.key === 'Delete') {
    // Del on active price row (when not in an input)
    if (!e.target.matches('input,textarea,select')) {
      e.preventDefault()
      removePriceRow(modal.activePriceRow)
    }
  }
}

// Supplier search
function calcDropdownPos(idx) {
  const el = priceSupplierRefs.value[idx]
  if (!el) return
  const rect = el.getBoundingClientRect()
  dropdownPos.top = rect.bottom + 4
  dropdownPos.left = rect.left
  dropdownPos.width = rect.width
}

function openSupplierDropdown(idx) {
  if (!form.prices[idx]) return
  // Close other dropdowns first
  form.prices.forEach((p, i) => { if (i !== idx) p.dropdownOpen = false })
  form.prices[idx].filteredSuppliers = suppliers.value.slice(0, 10)
  form.prices[idx].dropdownOpen = true
  form.prices[idx].dropdownIndex = 0
  nextTick(() => calcDropdownPos(idx))
}

function filterSuppliers(idx) {
  const pr = form.prices[idx]
  if (!pr) return
  pr.supplier_id = ''
  const q = pr.supplierSearch.toLowerCase()
  pr.filteredSuppliers = suppliers.value.filter(s => s.nama.toLowerCase().includes(q)).slice(0, 8)
  pr.dropdownOpen = pr.filteredSuppliers.length > 0
  pr.dropdownIndex = 0
  if (pr.dropdownOpen) nextTick(() => calcDropdownPos(idx))
}

function selectSupplier(idx, supplier) {
  const pr = form.prices[idx]
  if (!pr) return
  pr.supplier_id = supplier.id
  pr.supplierSearch = supplier.nama
  pr.dropdownOpen = false
  // Move focus to stok
  nextTick(() => priceStokRefs.value[idx]?.focus())
}

function onSupplierSearchKey(e, idx) {
  const pr = form.prices[idx]
  if (!pr) return
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    pr.dropdownIndex = Math.min((pr.dropdownIndex ?? 0) + 1, (pr.filteredSuppliers?.length ?? 1) - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    pr.dropdownIndex = Math.max((pr.dropdownIndex ?? 0) - 1, 0)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    const selected = pr.filteredSuppliers?.[pr.dropdownIndex]
    if (pr.dropdownOpen && selected) {
      selectSupplier(idx, selected)
    } else {
      // No dropdown: move to stok
      priceStokRefs.value[idx]?.focus()
    }
  } else if (e.key === 'Escape') {
    e.preventDefault()
    pr.dropdownOpen = false
  } else if (e.key === 'Tab') {
    pr.dropdownOpen = false
  }
}

function focusPriceHarga(idx) {
  priceHargaRefs.value[idx]?.focus()
}

function onHargaEnter(idx) {
  // If not the last row - move to next supplier search
  if (idx < form.prices.length - 1) {
    modal.activePriceRow = idx + 1
    nextTick(() => priceSupplierRefs.value[idx + 1]?.focus())
  } else {
    // Last row: add new row
    addPriceRow()
  }
}

// ───────────────────────────────────────────────────────────
// FOTO UPLOAD - CLOUDINARY
// ───────────────────────────────────────────────────────────
const fileInput = ref(null)

// Fungsi kompresi gambar
async function compressImage(file, maxSizeKB = 150, maxWidth = 800) {
  // Small files: skip compression entirely
  if (file.size / 1024 <= maxSizeKB) return file

  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onerror = () => reject(new Error('Gagal membaca file'))
    reader.onload = (e) => {
      const img = new Image()
      img.onerror = () => reject(new Error('Gagal memproses gambar'))
      img.onload = () => {
        const canvas = document.createElement('canvas')
        let w = img.width, h = img.height
        if (w > maxWidth) { h = Math.round(h * maxWidth / w); w = maxWidth }
        canvas.width = w; canvas.height = h
        canvas.getContext('2d').drawImage(img, 0, 0, w, h)

        // Estimate quality in one shot based on size ratio, then one fallback pass
        const ratio = (maxSizeKB * 1024) / file.size
        // Clamp quality between 0.4 and 0.82
        const q1 = Math.min(0.82, Math.max(0.4, Math.sqrt(ratio) * 0.9))

        canvas.toBlob((blob) => {
          if (!blob) { resolve(file); return }
          if (blob.size / 1024 <= maxSizeKB || q1 <= 0.4) {
            resolve(new File([blob], file.name, { type: 'image/jpeg', lastModified: Date.now() }))
          } else {
            // One extra pass at lower quality if still too big
            const q2 = Math.max(0.35, q1 * (maxSizeKB * 1024 / blob.size) * 0.85)
            canvas.toBlob((blob2) => {
              resolve(new File([blob2 || blob], file.name, { type: 'image/jpeg', lastModified: Date.now() }))
            }, 'image/jpeg', q2)
          }
        }, 'image/jpeg', q1)
      }
      img.src = e.target.result
    }
    reader.readAsDataURL(file)
  })
}

function removeFoto(index) {
  form.foto_urls.splice(index, 1)
  if (fileInput.value) fileInput.value.value = ''
}

function removeLastFoto() {
  if (form.foto_urls.length > 0) {
    form.foto_urls.splice(form.foto_urls.length - 1, 1)
    if (fileInput.value) fileInput.value.value = ''
  }
}

async function handleFileSelect(event) {
  const files = Array.from(event.target.files || [])
  
  if (files.length === 0) return
  
  // Validasi jumlah foto
  const remainingSlots = 3 - form.foto_urls.length
  if (files.length > remainingSlots) {
    photoUpload.error = `Maksimal 3 foto. Anda hanya bisa menambah ${remainingSlots} foto lagi.`
    toast.add({ 
      severity: 'warn', 
      summary: 'Terlalu Banyak Foto', 
      detail: `Maksimal 3 foto per barang. Anda hanya bisa menambah ${remainingSlots} foto lagi.`,
      life: 4000 
    })
    setTimeout(() => { photoUpload.error = '' }, 4000)
    return
  }
  
  // Validasi tipe file
  const invalidFiles = files.filter(f => !f.type.startsWith('image/'))
  if (invalidFiles.length > 0) {
    photoUpload.error = 'Hanya file gambar yang diperbolehkan.'
    toast.add({ 
      severity: 'error', 
      summary: 'Format File Salah', 
      detail: 'Hanya file gambar (JPG, PNG, dsb) yang diperbolehkan.',
      life: 4000 
    })
    setTimeout(() => { photoUpload.error = '' }, 4000)
    return
  }
  
  // Validasi ukuran file (max 5MB per file)
  const MAX_SIZE = 5 * 1024 * 1024 // 5MB
  const oversizedFiles = files.filter(f => f.size > MAX_SIZE)
  if (oversizedFiles.length > 0) {
    photoUpload.error = 'Ukuran file maksimal 5MB.'
    toast.add({ 
      severity: 'error', 
      summary: 'File Terlalu Besar', 
      detail: 'Ukuran setiap foto maksimal 5MB.',
      life: 4000 
    })
    setTimeout(() => { photoUpload.error = '' }, 4000)
    return
  }
  
  // Upload semua file
  photoUpload.error = ''
  photoUpload.uploading = true
  
  try {
    // Compress dan upload semua file
    const uploadPromises = files.map(async (file, index) => {
      const compressedFile = await compressImage(file)
      return uploadToCloudinary(compressedFile, index, files.length)
    })
    const urls = await Promise.all(uploadPromises)
    
    // Tambahkan URL yang berhasil ke form
    form.foto_urls.push(...urls.filter(url => url))
    
    // Reset input
    if (fileInput.value) {
      fileInput.value.value = ''
    }
    
    toast.add({ 
      severity: 'success', 
      summary: 'Upload Berhasil', 
      detail: `${urls.length} foto berhasil diupload.`,
      life: 3000 
    })
  } catch (error) {
    photoUpload.error = error.message || 'Gagal mengupload foto.'
    toast.add({ 
      severity: 'error', 
      summary: 'Upload Gagal', 
      detail: error.message || 'Terjadi kesalahan saat mengupload foto.',
      life: 5000 
    })
  } finally {
    photoUpload.uploading = false
    photoUpload.progress = 0
  }
}

async function uploadToCloudinary(file, index, total) {
  const CLOUD_NAME = 'dtueroxgq'
  const UPLOAD_PRESET = 'mmb_preset'
  const CLOUDINARY_URL = `https://api.cloudinary.com/v1_1/${CLOUD_NAME}/image/upload`
  
  const formData = new FormData()
  formData.append('file', file)
  formData.append('upload_preset', UPLOAD_PRESET)
  formData.append('folder', 'mmb-spareparts') // Optional: organize by folder
  
  try {
    const response = await fetch(CLOUDINARY_URL, {
      method: 'POST',
      body: formData,
    })
    
    if (!response.ok) {
      const errorData = await response.json()
      throw new Error(errorData.error?.message || 'Upload gagal')
    }
    
    const data = await response.json()
    
    // Update progress
    photoUpload.progress = Math.round(((index + 1) / total) * 100)
    
    return data.secure_url
  } catch (error) {
    console.error('Upload error:', error)
    throw new Error(`Gagal upload foto ${file.name}: ${error.message}`)
  }
}

async function submitModal() {
  modal.saving = true; modal.error = ''
  try {
    // Hitung total stok dari semua supplier
    const totalStok = form.prices.reduce((sum, pr) => {
      return pr.supplier_id ? sum + (pr.stok ?? 0) : sum
    }, 0)

    const payload = {
      kode: form.kode.trim(), 
      nama: form.nama.trim().toUpperCase(),
      stok: totalStok, 
      foto_urls: form.foto_urls.length > 0 ? form.foto_urls : null,
      aktif: true,
    }
    let productId = form.id

    if (modal.mode === 'add') {
      const { data, error } = await supabase.from('products').insert(payload).select('id').single()
      if (error) throw error
      productId = data.id
    } else {
      const { error } = await supabase.from('products').update(payload).eq('id', form.id)
      if (error) throw error
    }

    for (const pr of form.prices) {
      if (!pr.supplier_id) continue
      await supabase.from('product_prices').upsert({
        ...(pr.price_id ? { id: pr.price_id } : {}),
        product_id: productId, 
        supplier_id: pr.supplier_id,
        stok: pr.stok ?? 0,
        harga_beli: pr.harga_beli ?? 0, 
        aktif: true,
      }, { onConflict: 'product_id,supplier_id' })
    }

    closeModal()
    if (hasSearched.value) await doSearch()
    
    toast.add({ 
      severity: 'success', 
      summary: 'Berhasil', 
      detail: modal.mode === 'add' ? 'Barang berhasil ditambahkan' : 'Barang berhasil diupdate',
      life: 3000 
    })
  } catch (err) {
    modal.error = err.message
  } finally {
    modal.saving = false
  }
}

// ───────────────────────────────────────────────────────────
// LIGHTBOX FOTO
// ───────────────────────────────────────────────────────────
function openPhotoLightbox(index) {
  if (!selectedRowData.value?.foto_urls?.length) return
  lightbox.photos = selectedRowData.value.foto_urls
  lightbox.currentIndex = index
  lightbox.show = true
}

function closeLightbox() {
  lightbox.show = false
  lightbox.photos = []
  lightbox.currentIndex = 0
}

function prevPhoto() {
  if (lightbox.currentIndex > 0) {
    lightbox.currentIndex--
  }
}

function nextPhoto() {
  if (lightbox.currentIndex < lightbox.photos.length - 1) {
    lightbox.currentIndex++
  }
}

// ───────────────────────────────────────────────────────────
// DELETE
// ───────────────────────────────────────────────────────────
function openDelete(row) {
  if (!row) return
  deleteModal.row = row; deleteModal.saving = false; deleteModal.show = true
}

async function doDelete() {
  deleteModal.saving = true
  try {
    const { error } = await supabase
      .from('products').update({ aktif: false }).eq('id', deleteModal.row.product_id)
    if (error) throw error
    deleteModal.show = false
    if (hasSearched.value) await doSearch()
  } catch (err) {
    console.error(err)
  } finally {
    deleteModal.saving = false
  }
}

// ───────────────────────────────────────────────────────────
// LIFECYCLE
// ───────────────────────────────────────────────────────────
function onLightboxKey(e) {
  if (!lightbox.show) return
  if (e.key === 'Escape') {
    closeLightbox()
  } else if (e.key === 'ArrowLeft') {
    prevPhoto()
  } else if (e.key === 'ArrowRight') {
    nextPhoto()
  }
}

onMounted(() => {
  window.addEventListener('keydown', onGlobalKey)
  window.addEventListener('keydown', onLightboxKey)
  nextTick(() => inputBarang.value?.focus())
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
  window.removeEventListener('keydown', onLightboxKey)
  clearTimeout(barangTimer)
})

watch(allRows, () => { currentPage.value = 1 })

// update New Unit Cost when row selection changes
watch([selectedRowIndex, pagedRows], ([idx]) => {
  if (idx >= 0 && pagedRows.value[idx]) {
    const row = pagedRows.value[idx]
    // Ambil harga pertama jika ada
    infoCards.newUnitCost = row.prices?.[0]?.harga_beli ?? null
  } else {
    infoCards.newUnitCost = null
  }
})
</script>

<style scoped>
@import '@/assets/pages/gudang/gudang-cek-harga-page.css';
</style>