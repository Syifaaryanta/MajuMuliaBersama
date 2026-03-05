<template>
  <div class="supplier-page" ref="pageEl" tabindex="-1">

    <!-- ── PAGE HEADER ──────────────────────────────────── -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Supplier</h1>
        <p class="g-subtitle">Kelola data supplier</p>
      </div>
      <button class="btn-primary" @click="openAdd" title="Tambah Supplier (Alt+N)">
        <i class="pi pi-plus"></i>
        <span>Tambah Supplier</span>
      </button>
    </div>

    <!-- ── SEARCH SECTION ───────────────────────────────── -->
    <div class="search-section">
      <div class="search-field">
        <label class="search-label">
          Nama / Kode Supplier
          <kbd class="label-kbd">F1</kbd>
        </label>
        <div class="search-input-wrap" :class="{ focused: focusedField === 'supplier' }">
          <i class="pi pi-search si-icon"></i>
          <input
            ref="inputSupplier"
            v-model="searchQuery"
            type="text"
            class="search-input"
            placeholder="Ketik nama atau kode, Enter untuk cari…"
            autocomplete="off"
            @focus="focusedField = 'supplier'"
            @blur="onSearchBlur"
            @input="onSearchInput"
            @keydown="onSearchKey"
          />
          <button
            v-if="searchQuery"
            class="clear-btn"
            @click="clearSearch"
            tabindex="-1"
          ><i class="pi pi-times"></i></button>
        </div>
      </div>
    </div>

    <!-- ── HASIL PENCARIAN ───────────────────────────────── -->
    <div v-if="!hasSearched" class="empty-hint">
      <i class="pi pi-search empty-search-icon"></i>
      <p>Ketik nama atau kode supplier di atas untuk mencari</p>
      <span class="empty-hint-sub">Pencarian otomatis setelah 400ms · <kbd>Enter</kbd> untuk langsung cari</span>
    </div>

    <template v-else>
      <!-- Meta bar -->
      <div class="result-meta">
        <span class="result-count">
          <b>{{ totalRows }}</b> supplier ditemukan
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
          <tbody v-else-if="pagedRows.length === 0">
            <tr>
              <td colspan="6" class="empty-cell">
                <i class="pi pi-search-minus"></i>
                Tidak ada supplier ditemukan untuk "<b>{{ lastSearch }}</b>"
              </td>
            </tr>
          </tbody>
          <tbody v-else>
            <tr
              v-for="(row, i) in pagedRows"
              :key="row.id"
              :ref="el => setRowRef(el, i)"
              :data-index="i"
              class="g-row"
              :class="{
                'g-row--active': selectedRowIndex === i,
              }"
              @click="selectedRowIndex = i"
              @dblclick="openEdit(row)"
            >
              <td class="col-no">
                {{ (currentPage - 1) * PAGE_SIZE + i + 1 }}
              </td>
              <td class="col-kode">
                <span class="kode-badge">{{ row.kode }}</span>
              </td>
              <td class="col-nama">{{ row.nama }}</td>
              <td class="col-alamat">{{ row.alamat || '—' }}</td>
              <td class="col-telp">{{ row.no_telp || '—' }}</td>
              <td class="col-aksi">
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
          </tbody>
        </table>
      </div>
    </template>

    <!-- ═══════════════════════════════════════════════════
         MODAL TAMBAH / EDIT SUPPLIER
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
                  <label class="mfield-label">Kode Supplier <span class="required">*</span></label>
                  <input
                    v-model="form.kode"
                    ref="inputKode"
                    type="text"
                    class="mfield-input"
                    placeholder="Contoh: SUP001"
                    required
                    :disabled="modal.mode === 'edit'"
                  />
                </div>

                <div class="mfield">
                  <label class="mfield-label">Nama Supplier <span class="required">*</span></label>
                  <input
                    v-model="form.nama"
                    type="text"
                    class="mfield-input"
                    placeholder="Nama supplier"
                    required
                  />
                </div>

                <div class="mfield mfield-full">
                  <label class="mfield-label">Alamat</label>
                  <textarea
                    v-model="form.alamat"
                    class="mfield-textarea"
                    placeholder="Alamat lengkap supplier"
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
              </div>

              <div class="modal-footer">
                <button type="button" class="btn-secondary" @click="closeModal">
                  Batal <kbd>Esc</kbd>
                </button>
                <button type="submit" class="btn-primary" :disabled="saving">
                  <i class="pi pi-check"></i>
                  <span>{{ saving ? 'Menyimpan...' : 'Simpan' }}</span>
                  <kbd>Enter</kbd>
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
              <h3 class="modal-title">Hapus Supplier?</h3>
            </div>
            <div class="modal-body">
              <p>Yakin ingin menghapus supplier <b>{{ deleteModal.row?.nama }}</b>?</p>
              <p class="warn-text">Data yang sudah dihapus tidak bisa dikembalikan.</p>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="deleteModal.show = false">
                Batal <kbd>Esc</kbd>
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

    <!-- ═══════════════════════════════════════════════════
         MODAL SEARCH
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="searchModal.show" class="modal-overlay" @click.self="searchModal.show = false">
          <div class="modal-box modal-search" role="dialog">
            <div class="modal-header">
              <i class="pi pi-search"></i>
              <h3 class="modal-title">Pilih Supplier</h3>
              <button class="modal-close" @click="searchModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <div class="search-modal-input-wrap">
                <i class="pi pi-search"></i>
                <input
                  ref="searchModalInput"
                  v-model="searchModal.query"
                  type="text"
                  class="search-modal-input"
                  placeholder="Ketik untuk filter hasil..."
                  @input="filterSearchModal"
                  @keydown="onSearchModalKey"
                />
              </div>
              <div class="search-modal-results">
                <div
                  v-for="(item, idx) in searchModal.filtered"
                  :key="item.id"
                  class="search-modal-item"
                  :class="{ active: idx === searchModal.selectedIndex }"
                  @click="selectFromModal(item)"
                  @mouseenter="searchModal.selectedIndex = idx"
                >
                  <span class="smi-kode">{{ item.kode }}</span>
                  <span class="smi-nama">{{ item.nama }}</span>
                </div>
                <div v-if="searchModal.filtered.length === 0" class="search-modal-empty">
                  <i class="pi pi-inbox"></i>
                  <p>Tidak ada supplier yang cocok</p>
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
import { ref, reactive, computed, nextTick, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'

// ───────────────────────────────────────────────────────────
// REFS
// ───────────────────────────────────────────────────────────
const pageEl = ref(null)
const inputSupplier = ref(null)
const inputKode = ref(null)
const searchModalInput = ref(null)
const tableEl = ref(null)
const tableWrap = ref(null)

// ───────────────────────────────────────────────────────────
// STATE
// ───────────────────────────────────────────────────────────
const searchQuery = ref('')
const focusedField = ref('')
const lastSearch = ref('')
const hasSearched = ref(false)
const loading = ref(false)
const saving = ref(false)
const deleting = ref(false)

const allRows = ref([])
const selectedRowIndex = ref(0)
const rowRefs = new Map()

const PAGE_SIZE = 20
const currentPage = ref(1)

const modal = reactive({
  show: false,
  title: '',
  mode: '', // 'add' | 'edit'
})

const form = reactive({
  id: null,
  kode: '',
  nama: '',
  alamat: '',
  no_telp: '',
})

const deleteModal = reactive({
  show: false,
  row: null,
})

const searchModal = reactive({
  show: false,
  results: [],
  filtered: [],
  query: '',
  selectedIndex: 0,
})

let searchTimer = null

// ───────────────────────────────────────────────────────────
// COMPUTED
// ───────────────────────────────────────────────────────────
const totalRows = computed(() => allRows.value.length)
const totalPages = computed(() => Math.max(1, Math.ceil(totalRows.value / PAGE_SIZE)))
const pagedRows = computed(() => {
  const start = (currentPage.value - 1) * PAGE_SIZE
  return allRows.value.slice(start, start + PAGE_SIZE)
})

const selectedRowData = computed(() => pagedRows.value[selectedRowIndex.value] || null)

// ───────────────────────────────────────────────────────────
// LIFECYCLE
// ───────────────────────────────────────────────────────────
onMounted(() => {
  window.addEventListener('keydown', onGlobalKey)
  window.addEventListener('keydown', onModalEscKey)
  pageEl.value?.focus()
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
  window.removeEventListener('keydown', onModalEscKey)
})

// ───────────────────────────────────────────────────────────
// KEYBOARD SHORTCUTS
// ───────────────────────────────────────────────────────────
function onGlobalKey(e) {
  if (modal.show || deleteModal.show || searchModal.show) return

  switch (e.key) {
    case 'F1':
      e.preventDefault()
      inputSupplier.value?.focus()
      break
    case 'F4':
      if (selectedRowData.value) {
        e.preventDefault()
        openEdit(selectedRowData.value)
      }
      break
    case 'Delete':
      if (selectedRowData.value) {
        e.preventDefault()
        openDelete(selectedRowData.value)
      }
      break
    case 'ArrowUp':
      if (document.activeElement === inputSupplier.value) break
      e.preventDefault()
      moveRow(-1)
      break
    case 'ArrowDown':
      if (document.activeElement === inputSupplier.value) break
      e.preventDefault()
      moveRow(1)
      break
    case 'PageUp':
      e.preventDefault()
      prevPage()
      break
    case 'PageDown':
      e.preventDefault()
      nextPage()
      break
    case 'n':
    case 'N':
      if (e.altKey) {
        e.preventDefault()
        openAdd()
      }
      break
  }
}

function onModalEscKey(e) {
  if (e.key !== 'Escape') return
  if (deleteModal.show) deleteModal.show = false
  else if (searchModal.show) searchModal.show = false
  else if (modal.show) closeModal()
}

// ───────────────────────────────────────────────────────────
// INPUT HANDLERS
// ───────────────────────────────────────────────────────────
function onSearchInput() {
  clearTimeout(searchTimer)
  const q = searchQuery.value.trim()
  if (!q) {
    clearSearch()
    return
  }
  searchTimer = setTimeout(() => {
    doSearch()
  }, 400)
}

function onSearchBlur() {
  focusedField.value = ''
}

function onSearchKey(e) {
  if (e.key === 'Enter') {
    e.preventDefault()
    openSearchModal()
  } else if (e.key === 'ArrowDown' && hasSearched.value) {
    e.preventDefault()
    inputSupplier.value?.blur()
    moveRow(0)
  }
}

function clearSearch() {
  searchQuery.value = ''
  allRows.value = []
  hasSearched.value = false
  lastSearch.value = ''
  selectedRowIndex.value = 0
  currentPage.value = 1
}

// ───────────────────────────────────────────────────────────
// SEARCH MODAL
// ───────────────────────────────────────────────────────────
async function openSearchModal() {
  const q = searchQuery.value.trim()
  if (!q) return

  const { data, error } = await supabase
    .from('suppliers')
    .select('*')
    .or(`nama.ilike.%${q}%,kode.ilike.%${q}%`)
    .eq('aktif', true)
    .order('nama')

  if (error) {
    console.error('[openSearchModal]', error)
    return
  }

  searchModal.results = data || []
  searchModal.filtered = data || []
  searchModal.query = ''
  searchModal.selectedIndex = 0
  searchModal.show = true

  await nextTick()
  searchModalInput.value?.focus()
}

function filterSearchModal() {
  const q = searchModal.query.toLowerCase()
  searchModal.filtered = q
    ? searchModal.results.filter(s =>
        s.nama.toLowerCase().includes(q) || s.kode.toLowerCase().includes(q)
      )
    : searchModal.results
  searchModal.selectedIndex = 0
}

function selectFromModal(supplier) {
  searchModal.show = false
  searchQuery.value = supplier.nama
  doSearch(supplier.id)
}

function onSearchModalKey(e) {
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    searchModal.selectedIndex = Math.min(searchModal.selectedIndex + 1, searchModal.filtered.length - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    searchModal.selectedIndex = Math.max(searchModal.selectedIndex - 1, 0)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (searchModal.filtered[searchModal.selectedIndex]) {
      selectFromModal(searchModal.filtered[searchModal.selectedIndex])
    }
  } else if (e.key === 'Escape') {
    searchModal.show = false
  }
}

// ───────────────────────────────────────────────────────────
// TABLE NAVIGATION
// ───────────────────────────────────────────────────────────
function moveRow(delta) {
  const max = pagedRows.value.length - 1
  if (max < 0) return
  if (delta === 0) {
    selectedRowIndex.value = 0
  } else {
    selectedRowIndex.value = Math.max(0, Math.min(max, selectedRowIndex.value + delta))
  }
  nextTick(() => rowRefs.get(selectedRowIndex.value)?.scrollIntoView({ block: 'nearest' }))
}

function prevPage() {
  if (currentPage.value > 1) {
    currentPage.value--
    selectedRowIndex.value = 0
  }
}

function nextPage() {
  if (currentPage.value < totalPages.value) {
    currentPage.value++
    selectedRowIndex.value = 0
  }
}

function setRowRef(el, index) {
  if (el) rowRefs.set(index, el)
  else rowRefs.delete(index)
}

// ───────────────────────────────────────────────────────────
// SEARCH
// ───────────────────────────────────────────────────────────
async function doSearch(supplierId = null) {
  const q = searchQuery.value.trim()
  if (!q && !supplierId) return

  loading.value = true
  lastSearch.value = q

  try {
    let query = supabase
      .from('suppliers')
      .select('*')
      .eq('aktif', true)

    if (supplierId) {
      query = query.eq('id', supplierId)
    } else {
      query = query.or(`nama.ilike.%${q}%,kode.ilike.%${q}%`)
    }

    const { data, error } = await query.order('nama')

    if (error) throw error

    allRows.value = data || []
    hasSearched.value = true
    currentPage.value = 1
    selectedRowIndex.value = 0
  } catch (err) {
    console.error('[doSearch]', err)
    alert('Gagal mencari supplier: ' + err.message)
  } finally {
    loading.value = false
  }
}

// ───────────────────────────────────────────────────────────
// MODAL ADD / EDIT
// ───────────────────────────────────────────────────────────
function openAdd() {
  modal.mode = 'add'
  modal.title = 'Tambah Supplier'
  Object.assign(form, {
    id: null,
    kode: '',
    nama: '',
    alamat: '',
    no_telp: '',
  })
  modal.show = true
  nextTick(() => inputKode.value?.focus())
}

function openEdit(row) {
  modal.mode = 'edit'
  modal.title = 'Edit Supplier'
  Object.assign(form, {
    id: row.id,
    kode: row.kode,
    nama: row.nama,
    alamat: row.alamat || '',
    no_telp: row.no_telp || '',
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

    if (modal.mode === 'add') {
      const { error } = await supabase.from('suppliers').insert([payload])
      if (error) throw error
      alert('Supplier berhasil ditambahkan!')
    } else {
      const { error } = await supabase
        .from('suppliers')
        .update(payload)
        .eq('id', form.id)
      if (error) throw error
      alert('Supplier berhasil diperbarui!')
    }

    closeModal()
    doSearch()
  } catch (err) {
    console.error('[submitModal]', err)
    alert('Gagal menyimpan supplier: ' + err.message)
  } finally {
    saving.value = false
  }
}

// ───────────────────────────────────────────────────────────
// DELETE
// ───────────────────────────────────────────────────────────
function openDelete(row) {
  deleteModal.row = row
  deleteModal.show = true
}

async function confirmDelete() {
  if (deleting.value) return
  deleting.value = true

  try {
    const { error } = await supabase
      .from('suppliers')
      .update({ aktif: false })
      .eq('id', deleteModal.row.id)

    if (error) throw error

    alert('Supplier berhasil dihapus!')
    deleteModal.show = false
    doSearch()
  } catch (err) {
    console.error('[confirmDelete]', err)
    alert('Gagal menghapus supplier: ' + err.message)
  } finally {
    deleting.value = false
  }
}
</script>

<style scoped>
@import '@/assets/styles.css';
@import '@/assets/pages/gudang/gudang-page.css';
@import '@/assets/components/table.css';
@import '@/assets/components/form.css';
@import '@/assets/components/modal.css';
@import '@/assets/pages/master-data/supplier-page.css';
</style>
