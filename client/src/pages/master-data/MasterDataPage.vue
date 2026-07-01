<template>
  <div class="master-data-page" ref="pageEl" tabindex="-1">

    <!-- ── PAGE HEADER ──────────────────────────────────── -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Pusat Master Data</h1>
        <p class="g-subtitle">Kelola data customer, supplier, dan referensi bisnis inti</p>
      </div>
    </div>

    <!-- ── QUICK MENU (3 OPTIONS) ────────────────────────── -->
    <div class="md-menu-grid">
      <button
        class="md-menu-card"
        :class="{ 'md-menu-card--active': activeTab === 'customer', 'md-menu-card--focus': focusedMenuIndex === 0 }"
        @click="chooseMenu(0)"
        @dblclick="chooseMenu(0, true)"
        :title="'Data Customer (1)'"
      >
        <div class="md-menu-icon md-menu-icon--blue"><i class="pi pi-users"></i></div>
        <div class="md-menu-body">
          <h3>Data Customer</h3>
          <p>Lihat dan kelola master customer</p>
        </div>
        <span class="md-menu-count">{{ customerRows.length }}</span>
      </button>

      <button
        class="md-menu-card"
        :class="{ 'md-menu-card--active': activeTab === 'supplier', 'md-menu-card--focus': focusedMenuIndex === 1 }"
        @click="chooseMenu(1)"
        @dblclick="chooseMenu(1, true)"
        :title="'Data Supplier (2)'"
      >
        <div class="md-menu-icon md-menu-icon--teal"><i class="pi pi-truck"></i></div>
        <div class="md-menu-body">
          <h3>Data Supplier</h3>
          <p>Lihat dan kelola master supplier</p>
        </div>
        <span class="md-menu-count">{{ supplierRows.length }}</span>
      </button>

      <button
        class="md-menu-card"
        :class="{ 'md-menu-card--focus': focusedMenuIndex === 2, 'md-menu-card--active-soft': showAddPicker }"
        @click="chooseMenu(2)"
        @dblclick="chooseMenu(2, true)"
        :title="'Tambah Data Baru (3)'"
      >
        <div class="md-menu-icon md-menu-icon--indigo"><i class="pi pi-plus"></i></div>
        <div class="md-menu-body">
          <h3>Tambah Data</h3>
          <p>Pilih tambah customer atau supplier</p>
        </div>
        <span class="md-menu-count">Pilih</span>
      </button>

      <button
        class="md-menu-card"
        :class="{ 'md-menu-card--focus': focusedMenuIndex === 3 }"
        @click="chooseMenu(3)"
        @dblclick="chooseMenu(3, true)"
        :title="'Ubah/Edit Data (4)'"
      >
        <div class="md-menu-icon md-menu-icon--amber"><i class="pi pi-pencil"></i></div>
        <div class="md-menu-body">
          <h3>Ubah/Edit Data</h3>
          <p>Edit data baris terpilih sesuai tab aktif</p>
        </div>
        <span class="md-menu-count">{{ selectedRowData ? 'Ready' : 'Pilih Data' }}</span>
      </button>
    </div>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showAddPicker" class="modal-overlay" @click.self="closeAddPicker">
          <div class="modal-box modal-box--sm add-choice-modal" role="dialog" aria-label="Pilih jenis data baru">
            <div class="modal-header">
              <h3 class="modal-title">Pilih Data Yang Akan Ditambah</h3>
              <button class="modal-close" @click="closeAddPicker" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>

            <div class="modal-body add-choice-body">
              <button
                class="add-choice-option"
                :class="{ 'add-choice-option--active': addPickerIndex === 0 }"
                @click="setAddPickerIndex(0)"
                @dblclick="confirmAddPickerChoice()"
              >
                <i class="pi pi-users"></i>
                <span>Tambah Customer</span>
              </button>

              <button
                class="add-choice-option"
                :class="{ 'add-choice-option--active': addPickerIndex === 1 }"
                @click="setAddPickerIndex(1)"
                @dblclick="confirmAddPickerChoice()"
              >
                <i class="pi pi-truck"></i>
                <span>Tambah Supplier</span>
              </button>

              <p class="add-choice-hint">
                Gunakan Arrow untuk pilih, lalu Enter untuk lanjut isi form.
              </p>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ── SEARCH BAR ───────────────────────────────────── -->
    <div v-if="hasDataTabSelected" class="search-bar">
      <div class="search-input-wrap">
        <i class="pi pi-search"></i>
        <input
          ref="searchInput"
          v-model="searchQuery"
          type="text"
          class="search-input"
          :placeholder="activeTab === 'customer' ? 'Cari customer berdasarkan nama atau kode...' : 'Cari supplier berdasarkan nama atau kode...'"
          autocomplete="off"
          @keydown.esc="handleSearchEsc"
        />
        <button
          v-if="searchQuery"
          class="clear-btn"
          @click="searchQuery = ''"
          tabindex="-1"
        ><i class="pi pi-times"></i></button>
      </div>
    </div>

    <div v-else class="md-empty-state">
      <i class="pi pi-th-large"></i>
      <p>Pilih menu Data Customer atau Data Supplier untuk menampilkan tabel.</p>
    </div>

    <!-- ── CUSTOMER TAB CONTENT ──────────────────────────── -->
    <div v-if="hasDataTabSelected" v-show="activeTab === 'customer'" class="tab-content">
      <!-- Meta bar -->
      <div class="result-meta">
        <span class="result-count">
          <b>{{ filteredCustomerRows.length }}</b> customer 
          <span v-if="searchQuery" class="meta-filter">
            (dari {{ customerRows.length }} total)
          </span>
        </span>
      </div>

      <!-- Table -->
      <div class="table-wrap" ref="tableWrap">
        <table class="data-table">
          <thead>
            <tr>
              <th class="col-no">#</th>
              <th class="col-kode">Kode</th>
              <th class="col-nama">Nama Customer</th>
              <th class="col-alamat">Alamat</th>
              <th class="col-telp">No. Telp</th>
              <th class="col-kredit">Limit Kredit</th>
              <th class="col-tempo">Jatuh Tempo</th>
              <th class="col-piutang">Saldo Piutang</th>
            </tr>
          </thead>
          <tbody v-if="loading">
            <tr v-for="n in 5" :key="n">
              <td colspan="8"><div class="skeleton"></div></td>
            </tr>
          </tbody>
          <tbody v-else-if="pagedCustomerRows.length === 0">
            <tr>
              <td colspan="8" class="empty-cell">
                <i class="pi pi-inbox"></i>
                <p v-if="searchQuery">Tidak ada customer yang cocok dengan "<b>{{ searchQuery }}</b>"</p>
                <p v-else>Belum ada data customer.</p>
              </td>
            </tr>
          </tbody>
          <tbody v-else>
            <tr
              v-for="(row, i) in pagedCustomerRows"
              :key="row.id"
              :ref="el => setRowRef(el, i)"
              class="data-row"
              :class="{ 'data-row--active': selectedRowIndex === i }"
              @click="selectedRowIndex = i"
            >
              <td class="col-no">{{ (currentCustomerPage - 1) * PAGE_SIZE + i + 1 }}</td>
              <td class="col-kode"><span class="kode-badge">{{ row.kode }}</span></td>
              <td class="col-nama">{{ row.nama }}</td>
              <td class="col-alamat">{{ row.alamat || '—' }}</td>
              <td class="col-telp">{{ row.no_telp || '—' }}</td>
              <td class="col-kredit"><span class="harga-val">{{ formatRp(row.limit_kredit) }}</span></td>
              <td class="col-tempo">{{ formatJatuhTempo(row.jatuh_tempo_bulan) }}</td>
              <td class="col-piutang"><span class="harga-val">{{ formatRp(row.saldo_piutang) }}</span></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- ── SUPPLIER TAB CONTENT ──────────────────────────── -->
    <div v-if="hasDataTabSelected" v-show="activeTab === 'supplier'" class="tab-content">
      <!-- Meta bar -->
      <div class="result-meta">
        <span class="result-count">
          <b>{{ filteredSupplierRows.length }}</b> supplier
          <span v-if="searchQuery" class="meta-filter">
            (dari {{ supplierRows.length }} total)
          </span>
        </span>
      </div>

      <!-- Table -->
      <div class="table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th class="col-no">#</th>
              <th class="col-kode">Kode</th>
              <th class="col-nama">Nama Supplier</th>
              <th class="col-alamat">Alamat</th>
              <th class="col-telp">No. Telp</th>
              <th class="col-tempo">Jatuh Tempo</th>
            </tr>
          </thead>
          <tbody v-if="loading">
            <tr v-for="n in 5" :key="n">
              <td colspan="6"><div class="skeleton"></div></td>
            </tr>
          </tbody>
          <tbody v-else-if="pagedSupplierRows.length === 0">
            <tr>
              <td colspan="6" class="empty-cell">
                <i class="pi pi-inbox"></i>
                <p v-if="searchQuery">Tidak ada supplier yang cocok dengan "<b>{{ searchQuery }}</b>"</p>
                <p v-else>Belum ada data supplier.</p>
              </td>
            </tr>
          </tbody>
          <tbody v-else>
            <tr
              v-for="(row, i) in pagedSupplierRows"
              :key="row.id"
              :ref="el => setRowRef(el, i)"
              class="data-row"
              :class="{ 'data-row--active': selectedRowIndex === i }"
              @click="selectedRowIndex = i"
            >
              <td class="col-no">{{ (currentSupplierPage - 1) * PAGE_SIZE + i + 1 }}</td>
              <td class="col-kode"><span class="kode-badge">{{ row.kode }}</span></td>
              <td class="col-nama">{{ row.nama }}</td>
              <td class="col-alamat">{{ row.alamat || '—' }}</td>
              <td class="col-telp">{{ row.no_telp || '—' }}</td>
              <td class="col-tempo">{{ formatJatuhTempo(row.jatuh_tempo_bulan) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════
         MODAL TAMBAH / EDIT
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="modal.show" class="modal-overlay" @click.self="closeModal">
          <div class="modal-box modal-box--orderlike" role="dialog" :aria-label="modal.title">
            <div class="modal-header">
              <h3 class="modal-title">{{ modal.title }}</h3>
              <button class="modal-close" @click="closeModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>

            <form @submit.prevent="submitModal" class="modal-body">
              <div class="mfield-grid">
                <div class="mfield">
                  <label class="mfield-label">Kode {{ modal.type === 'customer' ? 'Customer' : 'Supplier' }} <span class="required">*</span></label>
                  <input
                    v-model="form.kode"
                    ref="inputKode"
                    type="text"
                    class="mfield-input"
                    :placeholder="modal.type === 'customer' ? 'Contoh: CUST001' : 'Contoh: SUP001'"
                    required
                    @keydown.enter.prevent="focusModalField('nama')"
                    @keydown.down.prevent="moveModalLinear('kode', 1)"
                  />
                </div>

                <div class="mfield">
                  <label class="mfield-label">Nama {{ modal.type === 'customer' ? 'Customer' : 'Supplier' }} <span class="required">*</span></label>
                  <input
                    v-model="form.nama"
                    ref="inputNama"
                    type="text"
                    class="mfield-input"
                    :placeholder="`Nama ${modal.type === 'customer' ? 'customer' : 'supplier'}`"
                    required
                    @keydown.enter.prevent="focusModalField('alamat')"
                    @keydown.up.prevent="moveModalLinear('nama', -1)"
                    @keydown.down.prevent="moveModalLinear('nama', 1)"
                  />
                </div>

                <div class="mfield mfield-full">
                  <label class="mfield-label">Alamat</label>
                  <textarea
                    v-model="form.alamat"
                    ref="inputAlamat"
                    class="mfield-textarea"
                    :placeholder="`Alamat lengkap ${modal.type === 'customer' ? 'customer' : 'supplier'}`"
                    rows="3"
                    @keydown.enter.prevent="focusModalField('telp')"
                    @keydown.up.prevent="moveModalLinear('alamat', -1)"
                    @keydown.down.prevent="moveModalLinear('alamat', 1)"
                  ></textarea>
                </div>

                <div class="mfield">
                  <label class="mfield-label">No. Telp</label>
                  <input
                    v-model="form.no_telp"
                    ref="inputTelp"
                    type="text"
                    class="mfield-input"
                    placeholder="08xxxxxxxxxx"
                    @keydown.enter.prevent="focusModalField('tempo')"
                    @keydown.up.prevent="moveModalLinear('telp', -1)"
                    @keydown.down.prevent="moveModalLinear('telp', 1)"
                  />
                </div>

                <div class="mfield mfield-full mfield-tempo-center">
                  <label class="mfield-label">Jatuh Tempo</label>
                  <div class="choice-group" ref="tempoGroupRef" tabindex="0" @keydown.enter.prevent="onTempoEnter" @keydown.left.prevent="moveTempoChoice(-1)" @keydown.right.prevent="moveTempoChoice(1)" @keydown.up.prevent="moveModalLinear('tempo', -1)" @keydown.down.prevent="moveModalLinear('tempo', 1)">
                    <button type="button" class="choice-btn" :class="{ 'choice-btn--active': form.jatuh_tempo_bulan === 1 }" @click="form.jatuh_tempo_bulan = 1">1 Bulan</button>
                    <button type="button" class="choice-btn" :class="{ 'choice-btn--active': form.jatuh_tempo_bulan === 2 }" @click="form.jatuh_tempo_bulan = 2">2 Bulan</button>
                    <button type="button" class="choice-btn" :class="{ 'choice-btn--active': form.jatuh_tempo_bulan === 3 }" @click="form.jatuh_tempo_bulan = 3">3 Bulan</button>
                  </div>
                </div>

                <div v-if="modal.type === 'customer'" class="mfield">
                  <label class="mfield-label">Limit Kredit</label>
                  <input
                    :value="formatNumberId(form.limit_kredit)"
                    ref="inputLimit"
                    type="text"
                    inputmode="numeric"
                    class="mfield-input"
                    placeholder="10.000.000"
                    @input="onCurrencyInput('limit_kredit', $event)"
                    @keydown.enter.prevent="focusModalField('saldo')"
                    @keydown.up.prevent="moveModalLinear('limit', -1)"
                    @keydown.down.prevent="moveModalLinear('limit', 1)"
                  />
                </div>

                <div v-if="modal.type === 'customer'" class="mfield">
                  <label class="mfield-label">Saldo Piutang</label>
                  <input
                    :value="formatNumberId(form.saldo_piutang)"
                    ref="inputSaldo"
                    type="text"
                    inputmode="numeric"
                    class="mfield-input"
                    placeholder="0"
                    @input="onCurrencyInput('saldo_piutang', $event)"
                    @keydown.enter.prevent="submitModal"
                    @keydown.up.prevent="moveModalLinear('saldo', -1)"
                  />
                </div>
              </div>

              <div class="modal-footer">
                <button type="button" class="btn-secondary" @click="closeModal">
                  Batal
                </button>
                <button type="submit" class="btn-primary" :disabled="saving">
                  <i class="pi pi-check"></i>
                  <span>{{ saving ? 'Menyimpan...' : 'Simpan' }}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup>
import { ref, reactive, computed, nextTick, onMounted, onUnmounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

// ───────────────────────────────────────────────────────────
// ROUTER
// ───────────────────────────────────────────────────────────
const route = useRoute()
const router = useRouter()

// ───────────────────────────────────────────────────────────
// REFS
// ───────────────────────────────────────────────────────────
const pageEl = ref(null)
const inputKode = ref(null)
const inputNama = ref(null)
const inputAlamat = ref(null)
const inputTelp = ref(null)
const inputLimit = ref(null)
const inputSaldo = ref(null)
const tempoGroupRef = ref(null)
const searchInput = ref(null)
const tableWrap = ref(null)

// ───────────────────────────────────────────────────────────
// STATE
// ───────────────────────────────────────────────────────────
const activeTab = ref('')
const focusedMenuIndex = ref(0)
const showAddPicker = ref(false)
const addPickerIndex = ref(0)
const searchQuery = ref('')
const loading = ref(false)
const saving = ref(false)
const deleting = ref(false)

const customerRows = ref([])
const supplierRows = ref([])
const selectedRowIndex = ref(0)
const rowRefs = new Map()

const PAGE_SIZE = 20
const currentCustomerPage = ref(1)
const currentSupplierPage = ref(1)

const modal = reactive({
  show: false,
  title: '',
  mode: '', // 'add' | 'edit'
  type: '', // 'customer' | 'supplier'
})

const form = reactive({
  id: null,
  kode: '',
  nama: '',
  alamat: '',
  no_telp: '',
  jatuh_tempo_bulan: 1,
  limit_kredit: 10000000,
  saldo_piutang: 0,
})

// ───────────────────────────────────────────────────────────
// COMPUTED
// ───────────────────────────────────────────────────────────
const filteredCustomerRows = computed(() => {
  if (!searchQuery.value) return customerRows.value
  const q = searchQuery.value.toLowerCase()
  return customerRows.value.filter(row =>
    row.kode.toLowerCase().includes(q) ||
    row.nama.toLowerCase().includes(q) ||
    (row.alamat && row.alamat.toLowerCase().includes(q)) ||
    (row.no_telp && row.no_telp.toLowerCase().includes(q))
  )
})

const filteredSupplierRows = computed(() => {
  if (!searchQuery.value) return supplierRows.value
  const q = searchQuery.value.toLowerCase()
  return supplierRows.value.filter(row =>
    row.kode.toLowerCase().includes(q) ||
    row.nama.toLowerCase().includes(q) ||
    (row.alamat && row.alamat.toLowerCase().includes(q)) ||
    (row.no_telp && row.no_telp.toLowerCase().includes(q))
  )
})

const totalCustomerPages = computed(() => Math.max(1, Math.ceil(filteredCustomerRows.value.length / PAGE_SIZE)))
const totalSupplierPages = computed(() => Math.max(1, Math.ceil(filteredSupplierRows.value.length / PAGE_SIZE)))

const pagedCustomerRows = computed(() => {
  const start = (currentCustomerPage.value - 1) * PAGE_SIZE
  return filteredCustomerRows.value.slice(start, start + PAGE_SIZE)
})

const pagedSupplierRows = computed(() => {
  const start = (currentSupplierPage.value - 1) * PAGE_SIZE
  return filteredSupplierRows.value.slice(start, start + PAGE_SIZE)
})

const currentPagedRows = computed(() => {
  if (activeTab.value !== 'customer' && activeTab.value !== 'supplier') return []
  return activeTab.value === 'customer' ? pagedCustomerRows.value : pagedSupplierRows.value
})

const selectedRowData = computed(() => currentPagedRows.value[selectedRowIndex.value] || null)
const hasDataTabSelected = computed(() => activeTab.value === 'customer' || activeTab.value === 'supplier')
// ───────────────────────────────────────────────────────────
// LIFECYCLE
// ───────────────────────────────────────────────────────────
onMounted(async () => {
  window.addEventListener('keydown', onGlobalKey)
  window.addEventListener('keydown', onModalEscKey)
  pageEl.value?.focus()
  
  // Load data first
  await loadAllData()
  
  // Check if coming from Penjualan page for quick add
  if (route.query.quickAdd === 'customer') {
    activeTab.value = 'customer'
    await nextTick()
    openAdd()
    // Clear query param
    router.replace({ query: {} })
  }
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
  window.removeEventListener('keydown', onModalEscKey)
})

// Reset selected row when switching tabs
watch(activeTab, () => {
  selectedRowIndex.value = 0
  searchQuery.value = ''
  showAddPicker.value = false
})

// ───────────────────────────────────────────────────────────
// DATA LOADING
// ───────────────────────────────────────────────────────────
async function loadAllData() {
  loading.value = true
  try {
    await Promise.all([loadCustomers(), loadSuppliers()])
  } finally {
    loading.value = false
  }
}

async function loadCustomers() {
  try {
    const { data, error } = await supabase
      .from('customers')
      .select('*')
      .eq('aktif', true)
      .order('nama')

    if (error) throw error
    customerRows.value = data || []
  } catch (err) {
    console.error('[loadCustomers]', err)
    alert('Gagal memuat data customer: ' + err.message)
  }
}

async function loadSuppliers() {
  try {
    const { data, error } = await supabase
      .from('suppliers')
      .select('*')
      .eq('aktif', true)
      .order('nama')

    if (error) throw error
    supplierRows.value = data || []
  } catch (err) {
    console.error('[loadSuppliers]', err)
    alert('Gagal memuat data supplier: ' + err.message)
  }
}

// ───────────────────────────────────────────────────────────
// TAB SWITCHING
// ───────────────────────────────────────────────────────────
function switchTab(tab) {
  activeTab.value = tab
  focusedMenuIndex.value = tab === 'customer' ? 0 : 1
}

function chooseMenu(index, shouldRunAction = false) {
  focusedMenuIndex.value = index

  if (index === 0) {
    showAddPicker.value = false
    switchTab('customer')
    return
  }

  if (index === 1) {
    showAddPicker.value = false
    switchTab('supplier')
    return
  }

  if (index === 2) {
    openAddPicker()
    return
  }

  showAddPicker.value = false
  if (index === 3 && (shouldRunAction || selectedRowData.value)) {
    if (selectedRowData.value) {
      openEdit(selectedRowData.value, activeTab.value)
    }
  }
}

function moveMenu(delta) {
  const max = 3
  if (delta > 0) {
    focusedMenuIndex.value = focusedMenuIndex.value >= max ? 0 : focusedMenuIndex.value + 1
  } else {
    focusedMenuIndex.value = focusedMenuIndex.value <= 0 ? max : focusedMenuIndex.value - 1
  }
}

function openAddPicker() {
  addPickerIndex.value = activeTab.value === 'supplier' ? 1 : 0
  showAddPicker.value = true
}

function closeAddPicker() {
  showAddPicker.value = false
}

function setAddPickerIndex(index) {
  addPickerIndex.value = index === 1 ? 1 : 0
}

function moveAddPicker(delta) {
  if (delta === 0) return
  addPickerIndex.value = addPickerIndex.value === 0 ? 1 : 0
}

function confirmAddPickerChoice() {
  openAddFor(addPickerIndex.value === 0 ? 'customer' : 'supplier')
}

function isTypingTarget(target) {
  if (!target) return false
  const tag = target.tagName?.toLowerCase?.()
  return tag === 'input' || tag === 'textarea' || tag === 'select' || target.isContentEditable
}

// ───────────────────────────────────────────────────────────
// KEYBOARD SHORTCUTS
// ───────────────────────────────────────────────────────────
function onGlobalKey(e) {
  if (showAddPicker.value) {
    switch (e.key) {
      case 'ArrowLeft':
      case 'ArrowUp':
        e.preventDefault()
        moveAddPicker(-1)
        return
      case 'ArrowRight':
      case 'ArrowDown':
        e.preventDefault()
        moveAddPicker(1)
        return
      case 'Enter':
        e.preventDefault()
        confirmAddPickerChoice()
        return
      case 'Escape':
        e.preventDefault()
        closeAddPicker()
        return
    }
  }

  if (modal.show) return
  const typing = isTypingTarget(e.target)

  switch (e.key) {
    case 'F1':
      e.preventDefault()
      searchInput.value?.focus()
      break
    case 'F2':
      e.preventDefault()
      openAddPicker()
      focusedMenuIndex.value = 2
      break
    case 'F3':
      if (selectedRowData.value) {
        e.preventDefault()
        openEdit(selectedRowData.value, activeTab.value)
      }
      break
    case 'F4':
      if (selectedRowData.value) {
        e.preventDefault()
        openEdit(selectedRowData.value, activeTab.value)
      }
      break
    case 'Delete':
      if (selectedRowData.value) {
        e.preventDefault()
        deleteSelectedRow()
      }
      break
    case 'ArrowLeft':
      if (typing) break
      e.preventDefault()
      moveMenu(-1)
      break
    case 'ArrowRight':
      if (typing) break
      e.preventDefault()
      moveMenu(1)
      break
    case 'ArrowUp':
      if (typing) break
      e.preventDefault()
      moveRow(-1)
      break
    case 'ArrowDown':
      if (typing) break
      e.preventDefault()
      moveRow(1)
      break
    case 'Enter':
      if (typing) break
      if (focusedMenuIndex.value === 3) {
        if (selectedRowData.value) {
          e.preventDefault()
          openEdit(selectedRowData.value, activeTab.value)
        }
      } else {
        e.preventDefault()
        chooseMenu(focusedMenuIndex.value, true)
      }
      break
    case 'PageUp':
      e.preventDefault()
      if (activeTab.value === 'customer') prevCustomerPage()
      else prevSupplierPage()
      break
    case 'PageDown':
      e.preventDefault()
      if (activeTab.value === 'customer') nextCustomerPage()
      else nextSupplierPage()
      break
    case '1':
      if (typing) break
      e.preventDefault()
      chooseMenu(0, true)
      break
    case '2':
      if (typing) break
      e.preventDefault()
      chooseMenu(1, true)
      break
    case '3':
      if (typing) break
      e.preventDefault()
      chooseMenu(2, true)
      break
    case '4':
      if (typing) break
      e.preventDefault()
      chooseMenu(3, true)
      break
    case 'Escape':
      e.preventDefault()
      router.push('/dashboard')
      break
  }
}

function onModalEscKey(e) {
  if (e.key !== 'Escape') return
  if (showAddPicker.value) closeAddPicker()
  else if (modal.show) closeModal()
}

function handleSearchEsc(e) {
  e.preventDefault()
  e.stopPropagation()
  
  // If search input is empty, go to dashboard
  if (!searchQuery.value.trim()) {
    router.push('/dashboard')
  }
}

// ───────────────────────────────────────────────────────────
// TABLE NAVIGATION
// ───────────────────────────────────────────────────────────
function moveRow(delta) {
  const max = currentPagedRows.value.length - 1
  if (max < 0) return
  if (delta === 0) {
    selectedRowIndex.value = 0
  } else {
    selectedRowIndex.value = Math.max(0, Math.min(max, selectedRowIndex.value + delta))
  }
  nextTick(() => rowRefs.get(selectedRowIndex.value)?.scrollIntoView({ block: 'nearest' }))
}

function prevCustomerPage() {
  if (currentCustomerPage.value > 1) {
    currentCustomerPage.value--
    selectedRowIndex.value = 0
  }
}

function nextCustomerPage() {
  if (currentCustomerPage.value < totalCustomerPages.value) {
    currentCustomerPage.value++
    selectedRowIndex.value = 0
  }
}

function prevSupplierPage() {
  if (currentSupplierPage.value > 1) {
    currentSupplierPage.value--
    selectedRowIndex.value = 0
  }
}

function nextSupplierPage() {
  if (currentSupplierPage.value < totalSupplierPages.value) {
    currentSupplierPage.value++
    selectedRowIndex.value = 0
  }
}

function setRowRef(el, index) {
  if (el) rowRefs.set(index, el)
  else rowRefs.delete(index)
}

// ───────────────────────────────────────────────────────────
// MODAL ADD / EDIT
// ───────────────────────────────────────────────────────────
function openAdd(type = null) {
  const resolvedType = type || (activeTab.value === 'customer' || activeTab.value === 'supplier'
    ? activeTab.value
    : focusedMenuIndex.value === 1
      ? 'supplier'
      : 'customer')
  if (!hasDataTabSelected.value) {
    switchTab(resolvedType)
  }
  modal.mode = 'add'
  modal.type = resolvedType
  modal.title = `Tambah ${resolvedType === 'customer' ? 'Customer' : 'Supplier'}`
  Object.assign(form, {
    id: null,
    kode: '',
    nama: '',
    alamat: '',
    no_telp: '',
    jatuh_tempo_bulan: 1,
    limit_kredit: 10000000,
    saldo_piutang: 0,
  })
  showAddPicker.value = false
  modal.show = true
  nextTick(() => inputKode.value?.focus())
}

function openAddFor(type) {
  switchTab(type)
  openAdd(type)
}

function openEdit(row, type) {
  modal.mode = 'edit'
  modal.type = type
  modal.title = `Edit ${type === 'customer' ? 'Customer' : 'Supplier'}`
  Object.assign(form, {
    id: row.id,
    kode: row.kode,
    nama: row.nama,
    alamat: row.alamat || '',
    no_telp: row.no_telp || '',
    jatuh_tempo_bulan: clampTempo(row.jatuh_tempo_bulan),
    limit_kredit: Number(row.limit_kredit || 10000000),
    saldo_piutang: Number(row.saldo_piutang || 0),
  })
  showAddPicker.value = false
  modal.show = true
  nextTick(() => inputKode.value?.focus())
}

function closeModal() {
  modal.show = false
}

function isMissingColumnSchemaCacheError(err) {
  return err?.code === 'PGRST204' && /could not find/i.test(String(err?.message || ''))
}

function extractMissingColumnName(err) {
  const msg = String(err?.message || '')
  const singleQuote = msg.match(/Could not find the '([^']+)' column/i)
  if (singleQuote?.[1]) return singleQuote[1]

  const doubleQuote = msg.match(/Could not find the "([^"]+)" column/i)
  if (doubleQuote?.[1]) return doubleQuote[1]

  return null
}

async function saveMasterDataRow(table, mode, payload, rowId) {
  if (mode === 'add') {
    return supabase.from(table).insert([payload])
  }

  return supabase
    .from(table)
    .update(payload)
    .eq('id', rowId)
}

async function submitModal() {
  if (saving.value) return
  saving.value = true

  try {
    const payload = {
      kode: form.kode.trim(),
      nama: form.nama.trim(),
      alamat: form.alamat.trim() || null,
      no_telp: form.no_telp.trim() || null,
      jatuh_tempo_bulan: clampTempo(form.jatuh_tempo_bulan),
      aktif: true,
    }

    if (modal.type === 'customer') {
      payload.limit_kredit = Number(form.limit_kredit) || 10000000
      payload.saldo_piutang = Number(form.saldo_piutang) || 0
    }

    const table = modal.type === 'customer' ? 'customers' : 'suppliers'

    const retryPayload = { ...payload }
    const skippedColumns = []

    let { error } = await saveMasterDataRow(table, modal.mode, retryPayload, form.id)

    // Retry otomatis jika PostgREST schema cache belum mengenali kolom tertentu.
    for (let i = 0; i < 5 && error && isMissingColumnSchemaCacheError(error); i += 1) {
      const missingColumn = extractMissingColumnName(error)
      if (!missingColumn || !(missingColumn in retryPayload)) break

      delete retryPayload[missingColumn]
      skippedColumns.push(missingColumn)

      const retry = await saveMasterDataRow(table, modal.mode, retryPayload, form.id)
      error = retry.error
    }

    if (error) throw error

    if (skippedColumns.length > 0) {
      alert(
        `Data ${modal.type === 'customer' ? 'customer' : 'supplier'} tersimpan, ` +
        `tetapi kolom ${skippedColumns.join(', ')} belum aktif di database. ` +
        `Jalankan ulang SQL sinkronisasi schema.`
      )
    } else {
      alert(`${modal.type === 'customer' ? 'Customer' : 'Supplier'} berhasil ${modal.mode === 'add' ? 'ditambahkan' : 'diperbarui'}!`)
    }

    closeModal()
    if (modal.type === 'customer') loadCustomers()
    else loadSuppliers()
  } catch (err) {
    console.error('[submitModal]', err)
    alert(`Gagal menyimpan ${modal.type === 'customer' ? 'customer' : 'supplier'}: ` + err.message)
  } finally {
    saving.value = false
  }
}

async function deleteSelectedRow() {
  if (!selectedRowData.value || !hasDataTabSelected.value) return
  if (deleting.value) return

  const row = selectedRowData.value
  const type = activeTab.value
  const entityLabel = type === 'customer' ? 'customer' : 'supplier'
  const confirmed = window.confirm(`Hapus ${entityLabel} ${row.nama}?`)
  if (!confirmed) return

  deleting.value = true

  try {
    const table = type === 'customer' ? 'customers' : 'suppliers'
    const { error } = await supabase
      .from(table)
      .update({ aktif: false })
      .eq('id', row.id)

    if (error) throw error

    alert(`${type === 'customer' ? 'Customer' : 'Supplier'} berhasil dihapus!`)
    
    if (type === 'customer') {
      await loadCustomers()
      selectedRowIndex.value = Math.min(selectedRowIndex.value, Math.max(0, pagedCustomerRows.value.length - 1))
    } else {
      await loadSuppliers()
      selectedRowIndex.value = Math.min(selectedRowIndex.value, Math.max(0, pagedSupplierRows.value.length - 1))
    }
  } catch (err) {
    console.error('[deleteSelectedRow]', err)
    alert(`Gagal menghapus ${entityLabel}: ` + err.message)
  } finally {
    deleting.value = false
  }
}

// ───────────────────────────────────────────────────────────
// HELPERS
// ───────────────────────────────────────────────────────────
function formatRp(val) {
  if (val == null || isNaN(val)) return 'Rp 0'
  return 'Rp ' + Number(val).toLocaleString('id-ID')
}

function formatNumberId(val) {
  const num = Number(val || 0)
  if (!Number.isFinite(num)) return '0'
  return Math.max(0, Math.trunc(num)).toLocaleString('id-ID')
}

function onCurrencyInput(field, e) {
  const raw = String(e?.target?.value || '').replace(/\D/g, '')
  const parsed = raw ? Number(raw) : 0
  form[field] = Number.isFinite(parsed) ? parsed : 0
}

function clampTempo(val) {
  const tempo = Number(val)
  if (![1, 2, 3].includes(tempo)) return 1
  return tempo
}

function moveTempoChoice(delta) {
  const options = [1, 2, 3]
  const current = options.indexOf(clampTempo(form.jatuh_tempo_bulan))
  const next = Math.max(0, Math.min(options.length - 1, current + delta))
  form.jatuh_tempo_bulan = options[next]
}

function focusModalField(field) {
  if (field === 'nama') {
    inputNama.value?.focus()
    return
  }
  if (field === 'alamat') {
    inputAlamat.value?.focus()
    return
  }
  if (field === 'telp') {
    inputTelp.value?.focus()
    return
  }
  if (field === 'limit' && modal.type === 'customer') {
    inputLimit.value?.focus()
    inputLimit.value?.select?.()
    return
  }
  if (field === 'saldo' && modal.type === 'customer') {
    inputSaldo.value?.focus()
    inputSaldo.value?.select?.()
    return
  }
  if (field === 'tempo') {
    tempoGroupRef.value?.focus()
    return
  }
}

function getModalFieldOrder() {
  if (modal.type === 'customer') {
    return ['kode', 'nama', 'alamat', 'telp', 'tempo', 'limit', 'saldo']
  }
  return ['kode', 'nama', 'alamat', 'telp', 'tempo']
}

function moveModalLinear(currentField, direction) {
  const order = getModalFieldOrder()
  const idx = order.indexOf(currentField)
  if (idx < 0) return
  const nextIdx = Math.max(0, Math.min(order.length - 1, idx + direction))
  if (nextIdx === idx) return
  focusModalField(order[nextIdx])
}

function onTempoEnter() {
  if (modal.type === 'customer') {
    focusModalField('limit')
    return
  }
  submitModal()
}

function formatJatuhTempo(val) {
  return `${clampTempo(val)} Bulan`
}
</script>

<style scoped>
@import '@/assets/styles.css';
@import '@/assets/components/table.css';
@import '@/assets/components/form.css';
@import '@/assets/components/modal.css';
@import '@/assets/Styles/master-data/master-data-page.css';
</style>