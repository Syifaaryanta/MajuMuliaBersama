<template>
  <div class="gudang-page" ref="pageEl" tabindex="-1">

    <!-- ── PAGE HEADER ──────────────────────────────────── -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Gudang</h1>
        <p class="g-subtitle">Cek stok & harga barang</p>
      </div>
      <button class="btn-primary" @click="openAdd" title="Tambah Barang (Alt+N)">
        <i class="pi pi-plus"></i>
        <span>Tambah Barang</span>
      </button>
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
              <th class="col-aksi">Aksi</th>
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
                @dblclick="openEdit(row)"
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
                <td v-if="priceIdx === 0" :rowspan="row.prices.length" class="col-aksi">
                  <div class="aksi-wrap">
                    <button
                      class="aksi-btn aksi-edit"
                      @click.stop="openEdit(row)"
                      title="Edit (F4)"
                    ><i class="pi pi-pencil"></i></button>
                    <button
                      class="aksi-btn aksi-del"
                      @click.stop="openDelete(row)"
                      title="Hapus (Del)"
                    ><i class="pi pi-trash"></i></button>
                  </div>
                </td>
              </tr>
            </template>
          </tbody>
        </table>
      </div>
    </template>

    <!-- ═══════════════════════════════════════════════════
         MODAL TAMBAH / EDIT BARANG
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="modal.show" class="modal-overlay" @click.self="closeModal">
          <div class="modal-box" role="dialog" :aria-label="modal.title">
            <div class="modal-header">
              <h3 class="modal-title">{{ modal.title }}</h3>
              <button class="modal-close" @click="closeModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>

            <form @submit.prevent="submitModal" class="modal-body">
              <div class="mfield-grid">
                <div class="mfield">
                  <label class="mfield-label">Kode Barang</label>
                  <input
                    v-model="form.kode"
                    ref="firstInput"
                    class="mfield-input"
                    placeholder="Mis. CDX-001"
                    required
                  />
                </div>
                <div class="mfield mfield--full">
                  <label class="mfield-label">Nama Barang</label>
                  <input
                    v-model="form.nama"
                    class="mfield-input"
                    placeholder="Mis. Condensor Xenia Std"
                    required
                  />
                </div>
                <div class="mfield mfield--full">
                  <label class="mfield-label">Deskripsi</label>
                  <input
                    v-model="form.deskripsi"
                    class="mfield-input"
                    placeholder="Opsional"
                  />
                </div>
                <div class="mfield">
                  <label class="mfield-label">Satuan</label>
                  <input
                    v-model="form.satuan"
                    class="mfield-input"
                    placeholder="pcs"
                  />
                </div>
              </div>

              <!-- Harga per Supplier -->
              <div class="price-section">
                <div class="price-section-header">
                  <span class="price-section-title">Stok & Harga per Supplier</span>
                  <button type="button" class="btn-add-supplier" @click="addPriceRow">
                    <i class="pi pi-plus"></i> Tambah Supplier
                  </button>
                </div>
                <div
                  v-for="(pr, idx) in form.prices"
                  :key="idx"
                  class="price-row"
                >
                  <select v-model="pr.supplier_id" class="price-select" required>
                    <option value="">— Pilih Supplier —</option>
                    <option v-for="s in suppliers" :key="s.id" :value="s.id">
                      {{ s.nama }}
                    </option>
                  </select>
                  <div class="price-input-wrap price-input-wrap--stok">
                    <input
                      v-model.number="pr.stok"
                      type="number"
                      class="price-input"
                      min="0"
                      placeholder="Stok"
                      required
                    />
                    <span class="price-suffix">{{ form.satuan }}</span>
                  </div>
                  <div class="price-input-wrap">
                    <span class="price-prefix">Rp</span>
                    <input
                      v-model.number="pr.harga_beli"
                      type="number"
                      class="price-input"
                      min="0"
                      placeholder="0"
                      required
                    />
                  </div>
                  <button
                    type="button"
                    class="btn-rm-supplier"
                    @click="removePriceRow(idx)"
                    :disabled="form.prices.length === 1"
                  ><i class="pi pi-trash"></i></button>
                </div>
              </div>

              <div v-if="modal.error" class="modal-error">
                <i class="pi pi-exclamation-triangle"></i> {{ modal.error }}
              </div>

              <div class="modal-footer">
                <button type="button" class="btn-cancel" @click="closeModal">
                  Batal <kbd>Esc</kbd>
                </button>
                <button type="submit" class="btn-save" :disabled="modal.saving">
                  <i v-if="modal.saving" class="pi pi-spin pi-spinner"></i>
                  <span v-else>{{ modal.mode === 'add' ? 'Simpan' : 'Update' }}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════
         MODAL KONFIRMASI HAPUS
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="deleteModal.show" class="modal-overlay" @click.self="deleteModal.show = false">
          <div class="modal-box modal-box--sm" role="dialog">
            <div class="modal-header modal-header--danger">
              <h3 class="modal-title">Hapus Barang</h3>
              <button class="modal-close" @click="deleteModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body delete-body">
              <i class="pi pi-exclamation-triangle del-icon"></i>
              <p>Yakin hapus barang <b>{{ deleteModal.row?.nama }}</b>?</p>
              <p class="del-warn">Semua data harga dari semua supplier akan ikut terhapus.</p>
            </div>
            <div class="modal-footer">
              <button class="btn-cancel" @click="deleteModal.show = false">
                Batal <kbd>Esc</kbd>
              </button>
              <button class="btn-danger" @click="doDelete" :disabled="deleteModal.saving">
                <i v-if="deleteModal.saving" class="pi pi-spin pi-spinner"></i>
                <span v-else>Hapus</span>
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

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

  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { supabase } from '@/lib/supabase'

// ── Constants ──────────────────────────────────────────────
const PAGE_SIZE = 15

// ── DOM Refs ───────────────────────────────────────────────
const pageEl        = ref(null)
const inputBarang   = ref(null)
const inputCustomer = ref(null)
const firstInput    = ref(null)
const rowRefs       = new Map()

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
})
const form = reactive({
  id: null, kode: '', nama: '', deskripsi: '', stok: 0, satuan: 'pcs',
  prices: [{ supplier_id: '', harga_beli: 0 }],
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
        openEdit(pagedRows.value[selectedRowIndex.value])
      }
      break
    case 'Delete':
      if (selectedRowIndex.value >= 0 && !e.target.matches('input,textarea,select')) {
        e.preventDefault()
        openDelete(pagedRows.value[selectedRowIndex.value])
      }
      break
    case 'ArrowDown':
      if (hasSearched.value && !e.target.matches('input,textarea,select')) {
        e.preventDefault(); moveRow(1)
      }
      break
    case 'ArrowUp':
      if (hasSearched.value && !e.target.matches('input,textarea,select')) {
        e.preventDefault(); moveRow(-1)
      }
      break
    case 'PageDown':
      e.preventDefault(); nextPage()
      break
    case 'PageUp':
      e.preventDefault(); prevPage()
      break
    case 'Escape':
      clearBarang()
      inputBarang.value?.focus()
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
    inputBarang.value?.blur()
    moveRow(0)
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
  
  // Fetch barang yang cocok
  const { data, error } = await supabase
    .from('products')
    .select('*')
    .or(`nama.ilike.%${q}%,kode.ilike.%${q}%`)
    .eq('aktif', true)
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
        id, kode, nama, deskripsi, stok, satuan,
        product_prices (
          id, harga_beli, aktif, stok,
          suppliers ( id, nama )
        )
      `)
      .eq('aktif', true)
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
        prices: prices,  // array of supplier prices
      })
    }
    allRows.value = grouped

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
function resetForm() {
  form.id = null; form.kode = ''; form.nama = ''; form.deskripsi = ''
  form.stok = 0; form.satuan = 'pcs'
  form.prices = [{ supplier_id: '', stok: 0, harga_beli: 0 }]
}

function openAdd() {
  resetForm()
  modal.mode  = 'add'
  modal.title = 'Tambah Barang Baru'
  modal.error = ''
  modal.show  = true
  nextTick(() => firstInput.value?.focus())
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
  
  // Populate prices dari row.prices array
  form.prices = row.prices?.length
    ? row.prices.map(p => ({ 
        price_id: p.id, 
        supplier_id: p.supplier_id ?? '', 
        stok: p.stok ?? 0,
        harga_beli: p.harga_beli ?? 0 
      }))
    : [{ supplier_id: '', stok: 0, harga_beli: 0 }]
  
  modal.mode  = 'edit'
  modal.title = 'Edit Barang'
  modal.error = ''
  modal.show  = true
  nextTick(() => firstInput.value?.focus())
}

function closeModal()      { modal.show = false }
function addPriceRow()     { form.prices.push({ supplier_id: '', stok: 0, harga_beli: 0 }) }
function removePriceRow(i) { if (form.prices.length > 1) form.prices.splice(i, 1) }

async function submitModal() {
  modal.saving = true; modal.error = ''
  try {
    // Hitung total stok dari semua supplier
    const totalStok = form.prices.reduce((sum, pr) => {
      return pr.supplier_id ? sum + (pr.stok ?? 0) : sum
    }, 0)

    const payload = {
      kode: form.kode.trim(), 
      nama: form.nama.trim().toUpperCase(),  // UPPERCASE!
      deskripsi: form.deskripsi.trim() || null,
      stok: totalStok, 
      satuan: form.satuan.trim() || 'pcs', 
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
  } catch (err) {
    modal.error = err.message
  } finally {
    modal.saving = false
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
onMounted(() => {
  window.addEventListener('keydown', onGlobalKey)
  window.addEventListener('keydown', onModalEscKey)
  loadSuppliers()
  nextTick(() => inputBarang.value?.focus())
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
  window.removeEventListener('keydown', onModalEscKey)
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
/* ── PAGE ─────────────────────────────────────────────────── */
.gudang-page {
  outline: none;
  display: flex;
  flex-direction: column;
  gap: 1.4rem;
  padding-bottom: 2.5rem;
}

/* ── HEADER ──────────────────────────────────────────────── */
.g-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  flex-wrap: wrap;
}
.g-title {
  font-size: 1.55rem;
  font-weight: 800;
  color: #0f172a;
  margin: 0 0 .2rem 0;
}
.g-subtitle {
  font-size: .88rem;
  color: #64748b;
  margin: 0;
}
.btn-primary {
  display: flex;
  align-items: center;
  gap: .5rem;
  padding: .75rem 1.4rem;
  background: linear-gradient(90deg,#1d4ed8,#3b82f6);
  color: #fff;
  border: none;
  border-radius: 10px;
  font-size: .92rem;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  box-shadow: 0 2px 10px rgba(59,130,246,.35);
  transition: opacity .15s, transform .1s;
  font-family: 'Inter', sans-serif;
}
.btn-primary:hover { opacity: .9; transform: translateY(-1px); }

/* ── SEARCH ──────────────────────────────────────────────── */
.search-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.2rem;
  align-items: start;
}
.search-field {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: .5rem;
}
.search-label {
  font-size: .82rem;
  font-weight: 600;
  color: #374151;
  text-transform: uppercase;
  letter-spacing: .4px;
  display: flex;
  align-items: center;
  gap: .4rem;
}
.label-kbd {
  background: #dbeafe;
  border: 1px solid #bfdbfe;
  color: #1d4ed8;
  border-radius: 4px;
  padding: 1px 5px;
  font-size: .68rem;
  font-family: monospace;
}
.optional-tag {
  font-size: .68rem;
  color: #94a3b8;
  font-weight: 400;
  text-transform: none;
  letter-spacing: 0;
}
.search-input-wrap {
  display: flex;
  align-items: center;
  border: 1.5px solid #e2e8f0;
  border-radius: 12px;
  background: #f8fafc;
  transition: border-color .2s, box-shadow .2s, background .2s;
}
.search-input-wrap.focused {
  border-color: #3b82f6;
  box-shadow: 0 0 0 4px rgba(59,130,246,.1);
  background: #fff;
}
.si-icon {
  padding: 0 1rem;
  color: #94a3b8;
  font-size: 1rem;
  flex-shrink: 0;
}
.search-input {
  flex: 1;
  border: none;
  outline: none;
  background: transparent;
  font-size: 1rem;
  color: #0f172a;
  padding: .9rem .5rem .9rem 0;
  font-family: 'Inter', sans-serif;
}
.search-input::placeholder { color: #cbd5e1; font-size: .95rem; }
.clear-btn {
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 0 .9rem;
  font-size: .85rem;
  display: flex;
  align-items: center;
  transition: color .15s;
}
.clear-btn:hover { color: #ef4444; }

/* Customer dropdown */
.customer-dropdown {
  position: absolute;
  top: calc(100% + 4px);
  left: 0; right: 0;
  background: #fff;
  border: 1.5px solid #e2e8f0;
  border-radius: 10px;
  box-shadow: 0 8px 24px rgba(0,0,0,.12);
  z-index: 50;
  overflow: hidden;
}
.cd-item {
  display: flex;
  align-items: center;
  gap: .6rem;
  padding: .65rem .9rem;
  cursor: pointer;
  transition: background .12s;
}
.cd-item:hover, .cd-item--active { background: #eff6ff; }
.cd-icon { color: #3b82f6; font-size: .8rem; }
.cd-info { display: flex; flex-direction: column; }
.cd-nama { font-size: .85rem; font-weight: 600; color: #1e293b; }
.cd-kode { font-size: .72rem; color: #94a3b8; }

/* ── INFO CARDS ──────────────────────────────────────────── */
.info-cards {
  display: grid;
  grid-template-columns: repeat(5,1fr);
  gap: .85rem;
}
.info-card {
  background: #fff;
  border: 1.5px solid #e2e8f0;
  border-radius: 14px;
  padding: 1rem 1.1rem;
  display: flex;
  align-items: center;
  gap: .85rem;
  transition: border-color .2s, box-shadow .2s;
}
.info-card--filled {
  border-color: #bfdbfe;
  box-shadow: 0 2px 14px rgba(59,130,246,.1);
}
.info-card--accent.info-card--filled {
  border-color: #a7f3d0;
  box-shadow: 0 2px 14px rgba(16,185,129,.12);
}
.info-card--accent .ic-icon { background: #ecfdf5; color: #059669; }
.info-card--accent.info-card--filled .ic-icon { background: #059669; color: #fff; }
.ic-icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: #eff6ff;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #3b82f6;
  font-size: 1rem;
  flex-shrink: 0;
}
.info-card--filled .ic-icon { background: #3b82f6; color: #fff; }
.ic-body { display: flex; flex-direction: column; gap: .18rem; min-width: 0; }
.ic-label {
  font-size: .72rem;
  font-weight: 600;
  color: #94a3b8;
  text-transform: uppercase;
  letter-spacing: .4px;
  white-space: nowrap;
}
.ic-value {
  font-size: 1rem;
  font-weight: 700;
  color: #0f172a;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* ── EMPTY HINT ──────────────────────────────────────────── */
.empty-hint {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: .65rem;
  padding: 3.5rem 1rem;
  color: #94a3b8;
  font-size: .95rem;
  text-align: center;
}
.empty-search-icon {
  font-size: 2.5rem;
  color: #cbd5e1;
  margin-bottom: .25rem;
}
.empty-hint-sub {
  font-size: .8rem;
  color: #cbd5e1;
}
.empty-hint kbd {
  background: #e2e8f0;
  border-radius: 4px;
  padding: 1px 6px;
  font-size: .8rem;
  color: #475569;
}

/* ── RESULT META ─────────────────────────────────────────── */
.result-meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: .85rem;
  color: #64748b;
  flex-wrap: wrap;
  gap: .5rem;
}
.result-count b { color: #0f172a; }
.meta-customer { color: #3b82f6; }
.result-meta-right { display: flex; align-items: center; gap: .5rem; }
.page-info { font-size: .82rem; color: #94a3b8; }
.icon-btn {
  background: none;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  padding: .25rem .5rem;
  cursor: pointer;
  color: #64748b;
  font-size: .75rem;
  transition: background .12s, color .12s;
}
.icon-btn:hover:not(:disabled) { background: #eff6ff; color: #3b82f6; }
.icon-btn:disabled { opacity: .4; cursor: not-allowed; }

/* ── TABLE ───────────────────────────────────────────────── */
.table-wrap {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  overflow: hidden;
  overflow-x: auto;
}
.g-table {
  width: 100%;
  border-collapse: collapse;
  font-size: .93rem;
}
.g-table thead tr {
  background: #f8fafc;
  border-bottom: 1.5px solid #e2e8f0;
}
.g-table th {
  padding: .85rem 1rem;
  text-align: left;
  font-size: .76rem;
  font-weight: 700;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: .4px;
  white-space: nowrap;
}
.g-row {
  border-bottom: 1px solid #f1f5f9;
  cursor: pointer;
  transition: background .1s;
}
.g-row:hover             { background: #f8fafc; }
.g-row--active           { background: #eff6ff !important; }
.g-row--lowstok          { border-left: 3px solid #f97316; }
.g-table td {
  padding: .8rem 1rem;
  color: #374151;
  vertical-align: middle;
}
.col-no       { width: 44px; color: #94a3b8; font-size: .8rem; }
.col-kode     { width: 120px; }
.col-nama     { width: auto; min-width: 220px; }
.col-stok     { width: 100px; text-align: center; }
.col-supplier { width: 160px; }
.col-harga    { width: 140px; text-align: right; }
.col-aksi     { width: 90px; }
.kode-badge {
  background: #f1f5f9;
  border: 1px solid #e2e8f0;
  border-radius: 5px;
  padding: 2px 7px;
  font-size: .75rem;
  font-weight: 600;
  color: #475569;
  font-family: monospace;
}
.stok-val { font-weight: 700; color: #0f172a; }
.stok-low { color: #f97316; }

.supplier-chip {
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  color: #166534;
  border-radius: 5px;
  padding: 2px 8px;
  font-size: .78rem;
  font-weight: 500;
  white-space: nowrap;
}
.harga-val {
  font-weight: 600;
  color: #1d4ed8;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
.text-muted { color: #cbd5e1; }
.aksi-wrap { display: flex; gap: .35rem; }
.aksi-btn {
  width: 34px; height: 34px;
  border: none; border-radius: 8px;
  cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  font-size: .85rem;
  transition: background .12s, transform .1s;
}
.aksi-btn:active      { transform: scale(.92); }
.aksi-edit            { background: #eff6ff; color: #3b82f6; }
.aksi-edit:hover      { background: #dbeafe; }
.aksi-del             { background: #fef2f2; color: #ef4444; }
.aksi-del:hover       { background: #fee2e2; }
.skeleton {
  height: 18px;
  border-radius: 4px;
  background: linear-gradient(90deg,#f1f5f9 25%,#e2e8f0 50%,#f1f5f9 75%);
  background-size: 200% 100%;
  animation: shimmer 1.2s infinite;
}
@keyframes shimmer {
  0%   { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
.empty-cell {
  text-align: center;
  padding: 3rem 1rem !important;
  color: #94a3b8;
  font-size: .85rem;
}
.empty-cell .pi { font-size: 1.4rem; display: block; margin-bottom: .5rem; color: #cbd5e1; }

/* ── MODAL ───────────────────────────────────────────────── */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.6);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 300;
  padding: 1rem;
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,.45);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 300;
  padding: 1rem;
}
.modal-box {
  background: #fff;
  border-radius: 16px;
  width: 100%;
  max-width: 560px;
  box-shadow: 0 20px 60px rgba(0,0,0,.2);
  overflow: hidden;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
}
.modal-box--sm { max-width: 400px; }
.modal-lg { max-width: 680px; }
.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.1rem 1.4rem;
  border-bottom: 1px solid #f1f5f9;
  background: #f8fafc;
  flex-shrink: 0;
}
.modal-header--danger { background: #fef2f2; border-bottom-color: #fecaca; }
.modal-title { font-size: 1rem; font-weight: 700; color: #0f172a; margin: 0; }
.modal-close {
  background: none; border: none; color: #94a3b8;
  cursor: pointer; font-size: .9rem; padding: .25rem; border-radius: 5px;
  transition: color .12s;
}
.modal-close:hover { color: #ef4444; }
.modal-body {
  padding: 1.4rem;
  overflow-y: auto;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
.mfield-grid { display: grid; grid-template-columns: 1fr 1fr; gap: .85rem; }
.mfield      { display: flex; flex-direction: column; gap: .35rem; }
.mfield--full { grid-column: 1 / -1; }
.mfield-label {
  font-size: .75rem; font-weight: 600; color: #374151;
  text-transform: uppercase; letter-spacing: .4px;
}
.mfield-input {
  border: 1.5px solid #e2e8f0;
  border-radius: 8px;
  padding: .65rem .85rem;
  font-size: .9rem; color: #0f172a;
  background: #f8fafc; outline: none;
  font-family: 'Inter', sans-serif;
  transition: border-color .2s, background .2s;
  width: 100%;
}
.mfield-input:focus {
  border-color: #3b82f6; background: #fff;
  box-shadow: 0 0 0 3px rgba(59,130,246,.1);
}
.price-section {
  border: 1px solid #e2e8f0; border-radius: 10px; overflow: hidden;
}
.price-section-header {
  display: flex; align-items: center; justify-content: space-between;
  padding: .65rem .9rem; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
}
.price-section-title {
  font-size: .75rem; font-weight: 700; color: #374151;
  text-transform: uppercase; letter-spacing: .4px;
}
.btn-add-supplier {
  background: none; border: 1px solid #3b82f6; color: #3b82f6;
  border-radius: 6px; padding: .25rem .65rem; font-size: .75rem;
  cursor: pointer; display: flex; align-items: center; gap: .3rem;
  transition: background .12s; font-family: 'Inter', sans-serif;
}
.btn-add-supplier:hover { background: #eff6ff; }
.price-row {
  display: grid; grid-template-columns: 1fr auto 1fr auto;
  gap: .5rem; padding: .65rem .9rem;
  border-bottom: 1px solid #f1f5f9; align-items: center;
}
.price-row:last-child { border-bottom: none; }
.price-select {
  border: 1.5px solid #e2e8f0; border-radius: 7px; padding: .5rem .65rem;
  font-size: .85rem; color: #0f172a; background: #f8fafc;
  outline: none; font-family: 'Inter', sans-serif; width: 100%;
}
.price-select:focus { border-color: #3b82f6; background: #fff; }
.price-input-wrap {
  display: flex; align-items: center;
  border: 1.5px solid #e2e8f0; border-radius: 7px; background: #f8fafc;
  overflow: hidden; transition: border-color .2s;
}
.price-input-wrap:focus-within { border-color: #3b82f6; background: #fff; }
.price-input-wrap--stok {
  max-width: 140px;
}
.price-prefix, .price-suffix {
  padding: 0 .5rem; font-size: .78rem; color: #94a3b8;
  flex-shrink: 0;
}
.price-prefix {
  border-right: 1px solid #e2e8f0;
}
.price-suffix {
  border-left: 1px solid #e2e8f0;
}
.price-input {
  flex: 1; border: none; outline: none; background: transparent;
  padding: .5rem .6rem; font-size: .88rem;
  font-family: 'Inter', sans-serif; color: #0f172a; min-width: 0;
}
.btn-rm-supplier {
  background: #fef2f2; color: #ef4444; border: none; border-radius: 7px;
  width: 32px; height: 32px; display: flex; align-items: center; justify-content: center;
  cursor: pointer; font-size: .75rem; transition: background .12s; flex-shrink: 0;
}
.btn-rm-supplier:hover:not(:disabled) { background: #fee2e2; }
.btn-rm-supplier:disabled { opacity: .4; cursor: not-allowed; }
.modal-error {
  background: #fef2f2; border: 1px solid #fecaca; color: #dc2626;
  border-radius: 8px; padding: .65rem .9rem; font-size: .82rem;
  display: flex; align-items: center; gap: .5rem;
}
.modal-footer {
  display: flex; align-items: center; justify-content: flex-end; gap: .65rem;
  padding: 1rem 1.4rem; border-top: 1px solid #f1f5f9;
  background: #f8fafc; flex-shrink: 0;
}
.btn-cancel {
  background: none; border: 1.5px solid #e2e8f0; color: #64748b;
  border-radius: 8px; padding: .6rem 1rem; font-size: .85rem;
  cursor: pointer; display: flex; align-items: center; gap: .4rem;
  transition: background .12s; font-family: 'Inter', sans-serif;
}
.btn-cancel:hover { background: #f1f5f9; }
.btn-cancel kbd {
  background: #e2e8f0; border-radius: 3px; padding: 0 4px; font-size: .7rem;
}
.btn-save {
  background: linear-gradient(90deg,#1d4ed8,#3b82f6); color: #fff;
  border: none; border-radius: 8px; padding: .6rem 1.25rem;
  font-size: .85rem; font-weight: 600; cursor: pointer;
  display: flex; align-items: center; gap: .4rem;
  box-shadow: 0 2px 10px rgba(59,130,246,.3); transition: opacity .15s;
  font-family: 'Inter', sans-serif;
}
.btn-save:hover:not(:disabled) { opacity: .9; }
.btn-save:disabled { opacity: .6; cursor: not-allowed; }
.btn-danger {
  background: linear-gradient(90deg,#dc2626,#ef4444); color: #fff;
  border: none; border-radius: 8px; padding: .6rem 1.25rem;
  font-size: .85rem; font-weight: 600; cursor: pointer;
  display: flex; align-items: center; gap: .4rem;
  box-shadow: 0 2px 10px rgba(239,68,68,.3); font-family: 'Inter', sans-serif;
}
.btn-danger:disabled { opacity: .6; cursor: not-allowed; }
.delete-body {
  text-align: center; padding: 2rem 1.5rem; gap: .5rem;
}
.del-icon { font-size: 2.5rem; color: #f97316; margin-bottom: .5rem; }
.delete-body p { font-size: .9rem; color: #374151; }
.del-warn { font-size: .78rem; color: #94a3b8; margin-top: .25rem; }

/* Modal transition */
.modal-enter-active, .modal-leave-active { transition: opacity .2s ease; }
.modal-enter-active .modal-box, .modal-leave-active .modal-box {
  transition: transform .2s ease, opacity .2s ease;
}
.modal-enter-from, .modal-leave-to { opacity: 0; }
.modal-enter-from .modal-box, .modal-leave-to .modal-box {
  transform: scale(.95) translateY(8px); opacity: 0;
}

/* Modal fade transition (untuk barang & customer modal) */
.modal-fade-enter-active, .modal-fade-leave-active { 
  transition: opacity .25s ease; 
}
.modal-fade-enter-active .modal-box, .modal-fade-leave-active .modal-box {
  transition: transform .25s cubic-bezier(0.4, 0, 0.2, 1), opacity .25s ease;
}
.modal-fade-enter-from, .modal-fade-leave-to { 
  opacity: 0; 
}
.modal-fade-enter-from .modal-box, .modal-fade-leave-to .modal-box {
  transform: scale(0.92) translateY(20px); 
  opacity: 0;
}

/* ── RESPONSIVE ──────────────────────────────────────────── */
@media (max-width: 1100px) {
  .info-cards { grid-template-columns: repeat(3, 1fr); }
}
@media (max-width: 820px) {
  .search-section        { grid-template-columns: 1fr; gap: .9rem; }
  .info-cards            { grid-template-columns: repeat(2, 1fr); }
  .g-header              { flex-direction: column; align-items: stretch; }
  .g-header .btn-primary { justify-content: center; }
  .g-title               { font-size: 1.3rem; }
}
@media (max-width: 600px) {
  .gudang-page           { gap: 1rem; }
  .info-cards            { grid-template-columns: 1fr 1fr; }
  .col-kode              { display: none; }
  .g-table th, .g-table td { padding: .65rem .75rem; font-size: .85rem; }
  .result-meta           { font-size: .8rem; }
  .search-input          { font-size: .92rem; }
  .search-input-wrap     { border-radius: 10px; }
}
@media (max-width: 480px) {
  .info-cards            { grid-template-columns: 1fr 1fr; }
  .ic-value              { font-size: .88rem; }
  .mfield-grid           { grid-template-columns: 1fr; }
  .mfield--full          { grid-column: 1; }
  .price-row             { grid-template-columns: 1fr auto; }
  .price-select          { grid-column: 1 / -1; }
  .modal-footer          { flex-direction: column-reverse; }
  .btn-cancel, .btn-save, .btn-danger { width: 100%; justify-content: center; }
  .modal-box             { border-radius: 12px; }
  .g-header .btn-primary { padding: .7rem 1rem; font-size: .88rem; }
}

/* ──────────────────────────────────────────────────────────
   MODAL LIST (untuk barang & customer modal)
   ────────────────────────────────────────────────────────── */
.modal-list {
  max-height: 450px;
  overflow-y: auto;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  background: #f8fafc;
}
.modal-item {
  display: flex;
  align-items: center;
  gap: .85rem;
  padding: .9rem 1rem;
  background: #fff;
  border-bottom: 1px solid #e2e8f0;
  cursor: pointer;
  transition: background .15s, box-shadow .15s;
}
.modal-item:last-child {
  border-bottom: none;
}
.modal-item:hover {
  background: #f1f5f9;
}
.modal-item--active {
  background: linear-gradient(90deg, #dbeafe, #e0f2fe);
  box-shadow: inset 3px 0 0 #3b82f6;
}
.modal-item i {
  font-size: 1.3rem;
  color: #3b82f6;
  flex-shrink: 0;
}
.modal-item-detail {
  display: flex;
  flex-direction: column;
  gap: .2rem;
  flex: 1;
  min-width: 0;
}
.modal-item-nama {
  font-size: .95rem;
  font-weight: 600;
  color: #0f172a;
}
.modal-item-meta {
  font-size: .8rem;
  color: #64748b;
}
.empty-state {
  padding: 3rem 1.5rem;
  text-align: center;
  color: #94a3b8;
}
.empty-state i {
  font-size: 2.5rem;
  margin-bottom: .75rem;
  display: block;
}
.empty-state p {
  margin: 0;
  font-size: .9rem;
}
</style>
