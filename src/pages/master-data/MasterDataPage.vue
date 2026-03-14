<template>
  <div class="master-data-page" ref="pageEl" tabindex="-1">

    <!-- ── PAGE HEADER ──────────────────────────────────── -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Data Master</h1>
        <p class="g-subtitle">Kelola data customer, supplier, dan pembaruan data master</p>
      </div>
      <button
        class="btn-primary"
        @click="openAdd"
        :disabled="!hasDataTabSelected"
        :title="hasDataTabSelected ? `Tambah ${activeEntityLabel}` : 'Pilih menu Customer atau Supplier dulu'"
      >
        <i class="pi pi-plus"></i>
        <span>Tambah {{ activeEntityLabel }}</span>
      </button>
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
        :class="{ 'md-menu-card--focus': focusedMenuIndex === 2 }"
        @click="chooseMenu(2)"
        @dblclick="chooseMenu(2, true)"
        :title="'Ubah/Edit Data'"
      >
        <div class="md-menu-icon md-menu-icon--amber"><i class="pi pi-pencil"></i></div>
        <div class="md-menu-body">
          <h3>Ubah/Edit Data</h3>
          <p>Edit data baris terpilih sesuai tab aktif</p>
        </div>
        <span class="md-menu-count">{{ selectedRowData ? 'Ready' : 'Pilih Data' }}</span>
      </button>
    </div>

    <!-- ── SEARCH BAR ───────────────────────────────────── -->
    <div v-if="hasDataTabSelected" class="search-bar">
      <div class="search-input-wrap">
        <i class="pi pi-search"></i>
        <input
          ref="searchInput"
          v-model="searchQuery"
          type="text"
          class="search-input"
          :placeholder="`Cari ${activeTab === 'customer' ? 'customer' : 'supplier'} berdasarkan kode atau nama...`"
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
        <div class="result-meta-right">
          <span class="page-info">Hal {{ currentCustomerPage }} / {{ totalCustomerPages }}</span>
          <button class="icon-btn" :disabled="currentCustomerPage <= 1" @click="prevCustomerPage" title="Sebelumnya">
            <i class="pi pi-chevron-left"></i>
          </button>
          <button class="icon-btn" :disabled="currentCustomerPage >= totalCustomerPages" @click="nextCustomerPage" title="Selanjutnya">
            <i class="pi pi-chevron-right"></i>
          </button>
        </div>
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
              <th class="col-piutang">Saldo Piutang</th>
              <th class="col-aksi">Aksi</th>
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
              @dblclick="openEdit(row, 'customer')"
            >
              <td class="col-no">{{ (currentCustomerPage - 1) * PAGE_SIZE + i + 1 }}</td>
              <td class="col-kode"><span class="kode-badge">{{ row.kode }}</span></td>
              <td class="col-nama">{{ row.nama }}</td>
              <td class="col-alamat">{{ row.alamat || '—' }}</td>
              <td class="col-telp">{{ row.no_telp || '—' }}</td>
              <td class="col-kredit"><span class="harga-val">{{ formatRp(row.limit_kredit) }}</span></td>
              <td class="col-piutang"><span class="harga-val">{{ formatRp(row.saldo_piutang) }}</span></td>
              <td class="col-aksi">
                <div class="aksi-wrap">
                  <button class="aksi-btn aksi-edit" @click.stop="openEdit(row, 'customer')" title="Edit">
                    <i class="pi pi-pencil"></i>
                  </button>
                  <button class="aksi-btn aksi-del" @click.stop="openDelete(row, 'customer')" title="Hapus">
                    <i class="pi pi-trash"></i>
                  </button>
                </div>
              </td>
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
        <div class="result-meta-right">
          <span class="page-info">Hal {{ currentSupplierPage }} / {{ totalSupplierPages }}</span>
          <button class="icon-btn" :disabled="currentSupplierPage <= 1" @click="prevSupplierPage" title="Sebelumnya">
            <i class="pi pi-chevron-left"></i>
          </button>
          <button class="icon-btn" :disabled="currentSupplierPage >= totalSupplierPages" @click="nextSupplierPage" title="Selanjutnya">
            <i class="pi pi-chevron-right"></i>
          </button>
        </div>
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
              <th class="col-aksi">Aksi</th>
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
              @dblclick="openEdit(row, 'supplier')"
            >
              <td class="col-no">{{ (currentSupplierPage - 1) * PAGE_SIZE + i + 1 }}</td>
              <td class="col-kode"><span class="kode-badge">{{ row.kode }}</span></td>
              <td class="col-nama">{{ row.nama }}</td>
              <td class="col-alamat">{{ row.alamat || '—' }}</td>
              <td class="col-telp">{{ row.no_telp || '—' }}</td>
              <td class="col-aksi">
                <div class="aksi-wrap">
                  <button class="aksi-btn aksi-edit" @click.stop="openEdit(row, 'supplier')" title="Edit">
                    <i class="pi pi-pencil"></i>
                  </button>
                  <button class="aksi-btn aksi-del" @click.stop="openDelete(row, 'supplier')" title="Hapus">
                    <i class="pi pi-trash"></i>
                  </button>
                </div>
              </td>
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
                  <label class="mfield-label">Kode {{ modal.type === 'customer' ? 'Customer' : 'Supplier' }} <span class="required">*</span></label>
                  <input
                    v-model="form.kode"
                    ref="inputKode"
                    type="text"
                    class="mfield-input"
                    :placeholder="modal.type === 'customer' ? 'Contoh: CUST001' : 'Contoh: SUP001'"
                    required
                    :disabled="modal.mode === 'edit'"
                  />
                </div>

                <div class="mfield">
                  <label class="mfield-label">Nama {{ modal.type === 'customer' ? 'Customer' : 'Supplier' }} <span class="required">*</span></label>
                  <input
                    v-model="form.nama"
                    type="text"
                    class="mfield-input"
                    :placeholder="`Nama ${modal.type === 'customer' ? 'customer' : 'supplier'}`"
                    required
                  />
                </div>

                <div class="mfield mfield-full">
                  <label class="mfield-label">Alamat</label>
                  <textarea
                    v-model="form.alamat"
                    class="mfield-textarea"
                    :placeholder="`Alamat lengkap ${modal.type === 'customer' ? 'customer' : 'supplier'}`"
                    rows="3"
                  ></textarea>
                </div>

                <div class="mfield">
                  <label class="mfield-label">No. Telp</label>
                  <input
                    v-model="form.no_telp"
                    type="text"
                    class="mfield-input"
                    placeholder="08xxxxxxxxxx"
                  />
                </div>

                <div v-if="modal.type === 'customer'" class="mfield">
                  <label class="mfield-label">Limit Kredit</label>
                  <input
                    v-model="form.limit_kredit"
                    type="number"
                    class="mfield-input"
                    placeholder="10000000"
                    min="0"
                    step="1000"
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

    <!-- ═══════════════════════════════════════════════════
         MODAL DELETE CONFIRMATION
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="deleteModal.show" class="modal-overlay" @click.self="deleteModal.show = false">
          <div class="modal-box modal-box--sm" role="alertdialog">
            <div class="modal-header modal-header--danger">
              <i class="pi pi-exclamation-triangle"></i>
              <h3 class="modal-title">Hapus {{ deleteModal.type === 'customer' ? 'Customer' : 'Supplier' }}?</h3>
            </div>
            <div class="modal-body">
              <p>Yakin ingin menghapus {{ deleteModal.type === 'customer' ? 'customer' : 'supplier' }} <b>{{ deleteModal.row?.nama }}</b>?</p>
              <p class="warn-text">Data yang sudah dihapus tidak bisa dikembalikan.</p>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="deleteModal.show = false">
                Batal
              </button>
              <button class="btn-danger" @click="confirmDelete" :disabled="deleting">
                <i class="pi pi-trash"></i>
                <span>{{ deleting ? 'Menghapus...' : 'Hapus' }}</span>
              </button>
            </div>
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
const searchInput = ref(null)
const tableWrap = ref(null)

// ───────────────────────────────────────────────────────────
// STATE
// ───────────────────────────────────────────────────────────
const activeTab = ref('')
const focusedMenuIndex = ref(0)
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
  limit_kredit: 10000000,
})

const deleteModal = reactive({
  show: false,
  row: null,
  type: '', // 'customer' | 'supplier'
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
const activeEntityLabel = computed(() => {
  if (activeTab.value === 'customer') return 'Customer'
  if (activeTab.value === 'supplier') return 'Supplier'
  return 'Data'
})

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
    switchTab('customer')
    return
  }

  if (index === 1) {
    switchTab('supplier')
    return
  }

  if (index === 2 && (shouldRunAction || selectedRowData.value)) {
    if (selectedRowData.value) {
      openEdit(selectedRowData.value, activeTab.value)
    }
  }
}

function moveMenu(delta) {
  const max = 2
  if (delta > 0) {
    focusedMenuIndex.value = focusedMenuIndex.value >= max ? 0 : focusedMenuIndex.value + 1
  } else {
    focusedMenuIndex.value = focusedMenuIndex.value <= 0 ? max : focusedMenuIndex.value - 1
  }
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
  if (modal.show || deleteModal.show) return
  const typing = isTypingTarget(e.target)

  switch (e.key) {
    case 'F1':
      e.preventDefault()
      searchInput.value?.focus()
      break
    case 'F2':
      e.preventDefault()
      openAdd()
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
        openDelete(selectedRowData.value, activeTab.value)
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
      if (focusedMenuIndex.value === 2) {
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
    case 'Escape':
      e.preventDefault()
      router.push('/dashboard')
      break
  }
}

function onModalEscKey(e) {
  if (e.key !== 'Escape') return
  if (deleteModal.show) deleteModal.show = false
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
function openAdd() {
  const type = activeTab.value === 'customer' || activeTab.value === 'supplier'
    ? activeTab.value
    : focusedMenuIndex.value === 1
      ? 'supplier'
      : 'customer'
  if (!hasDataTabSelected.value) {
    switchTab(type)
  }
  modal.mode = 'add'
  modal.type = type
  modal.title = `Tambah ${type === 'customer' ? 'Customer' : 'Supplier'}`
  Object.assign(form, {
    id: null,
    kode: '',
    nama: '',
    alamat: '',
    no_telp: '',
    limit_kredit: 10000000,
  })
  modal.show = true
  nextTick(() => inputKode.value?.focus())
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
    limit_kredit: row.limit_kredit || 10000000,
  })
  modal.show = true
  nextTick(() => inputKode.value?.focus())
}

function closeModal() {
  modal.show = false
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
      aktif: true,
    }

    if (modal.type === 'customer') {
      payload.limit_kredit = Number(form.limit_kredit) || 10000000
    }

    const table = modal.type === 'customer' ? 'customers' : 'suppliers'

    if (modal.mode === 'add') {
      const { error } = await supabase.from(table).insert([payload])
      if (error) throw error
      alert(`${modal.type === 'customer' ? 'Customer' : 'Supplier'} berhasil ditambahkan!`)
    } else {
      const { error } = await supabase
        .from(table)
        .update(payload)
        .eq('id', form.id)
      if (error) throw error
      alert(`${modal.type === 'customer' ? 'Customer' : 'Supplier'} berhasil diperbarui!`)
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

// ───────────────────────────────────────────────────────────
// DELETE
// ───────────────────────────────────────────────────────────
function openDelete(row, type) {
  deleteModal.row = row
  deleteModal.type = type
  deleteModal.show = true
}

async function confirmDelete() {
  if (deleting.value) return
  deleting.value = true

  try {
    const table = deleteModal.type === 'customer' ? 'customers' : 'suppliers'
    const { error } = await supabase
      .from(table)
      .update({ aktif: false })
      .eq('id', deleteModal.row.id)

    if (error) throw error

    alert(`${deleteModal.type === 'customer' ? 'Customer' : 'Supplier'} berhasil dihapus!`)
    deleteModal.show = false
    
    if (deleteModal.type === 'customer') loadCustomers()
    else loadSuppliers()
  } catch (err) {
    console.error('[confirmDelete]', err)
    alert(`Gagal menghapus ${deleteModal.type === 'customer' ? 'customer' : 'supplier'}: ` + err.message)
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
</script>

<style scoped>
@import '@/assets/styles.css';
@import '@/assets/components/table.css';
@import '@/assets/components/form.css';
@import '@/assets/components/modal.css';
@import '@/assets/pages/master-data/master-data-page.css';
</style>