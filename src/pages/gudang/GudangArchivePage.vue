<template>
  <div class="gudang-archive-page" ref="pageEl" tabindex="-1">

    <!-- ── PAGE HEADER ──────────────────────────────────── -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Archive Barang</h1>
        <p class="g-subtitle">Barang yang diarsipkan · tidak tampil di halaman lain</p>
      </div>
      <div v-if="!loading && allRows.length" class="g-header-badge">
        <i class="pi pi-inbox"></i>
        <span><b>{{ allRows.length }}</b> diarsipkan</span>
      </div>
    </div>

    <!-- ── SEARCH BAR ───────────────────────────────────── -->
    <div class="cs-search-wrap">
      <div class="cs-search-inner" :class="{ focused: searchFocused }">
        <i class="pi pi-search cs-search-icon"></i>
        <input
          ref="searchInput"
          v-model="searchQuery"
          type="text"
          class="cs-search-input"
          placeholder="Ketik nama atau kode barang, Enter untuk navigasi…"
          autocomplete="off"
          @focus="searchFocused = true"
          @blur="searchFocused = false"
          @keydown.esc.prevent.stop="handleSearchEsc"
          @keydown.enter.prevent="onSearchEnter"
        />
        <span v-if="searchQuery && filteredRows.length" class="cs-match-badge">
          {{ filteredRows.length }}
        </span>
        <button v-if="searchQuery" class="cs-clear-btn" @click="clearSearch" tabindex="-1">
          <i class="pi pi-times"></i>
        </button>
      </div>
    </div>

    <!-- ── LOADING ───────────────────────────────────────── -->
    <div v-if="loading" class="loading-state">
      <i class="pi pi-spin pi-spinner"></i>
      <span>Memuat data arsip...</span>
    </div>

    <!-- ── EMPTY ─────────────────────────────────────────── -->
    <div v-else-if="filteredRows.length === 0" class="empty-state">
      <i class="pi pi-inbox"></i>
      <p v-if="searchQuery">Tidak ada barang arsip yang cocok dengan "<b>{{ searchQuery }}</b>"</p>
      <p v-else>Tidak ada barang yang diarsipkan</p>
      <span class="empty-sub">Arsipkan barang dari halaman Cek Semua Barang dengan tombol <b>Archive (F3)</b></span>
    </div>

    <!-- ── TABLE ─────────────────────────────────────────── -->
    <template v-else>

      <!-- Meta bar -->
      <div class="result-meta">
        <span class="result-count">
          <b>{{ totalRows }}</b> barang diarsipkan
          <span v-if="searchQuery" class="meta-filter">
            · "<b>{{ searchQuery }}</b>"
          </span>
          <span v-if="selectedRowIndex >= 0" class="meta-selected">
            · baris <b>{{ selectedRowIndex + 1 }}</b>
          </span>
        </span>
        <div v-if="totalPages > 1" class="pagination-wrap">
          <button class="icon-btn" :disabled="currentPage <= 1" @click="prevPage">
            <i class="pi pi-chevron-left"></i>
          </button>
          <span class="page-indicator">{{ currentPage }}&nbsp;/&nbsp;{{ totalPages }}</span>
          <button class="icon-btn" :disabled="currentPage >= totalPages" @click="nextPage">
            <i class="pi pi-chevron-right"></i>
          </button>
        </div>
      </div>

      <!-- Hints bar -->
      <div class="arc-kbd-bar">
        <span><kbd>↑</kbd><kbd>↓</kbd> navigasi</span>
        <span><kbd>F3</kbd> buka archive</span>
        <span><kbd>Enter</kbd> buka archive</span>
        <span><kbd>F1</kbd> cari</span>
        <span><kbd>Esc</kbd> kembali</span>
      </div>

      <!-- Table -->
      <div class="table-wrap" ref="tableWrap">
        <table class="g-table arc-table">
          <thead>
            <tr>
              <th class="col-no">#</th>
              <th class="col-kode">Kode</th>
              <th class="col-nama">Nama Barang</th>
            </tr>
          </thead>
          <tbody>
            <template v-for="(row, i) in pagedRows" :key="row.id">
              <tr
                :ref="el => setRowRef(el, i)"
                :data-index="i"
                class="g-row"
                :class="{ 'g-row--active': selectedRowIndex === i }"
                @click="selectRow(i)"
                @dblclick="openUnarchiveConfirm(row)"
              >
                <td class="col-no" style="vertical-align: middle;">
                  <span class="row-num">{{ (currentPage - 1) * PAGE_SIZE + i + 1 }}</span>
                </td>
                <td class="col-kode" style="vertical-align: middle;">
                  <span class="kode-badge kode-badge--archived">{{ row.kode }}</span>
                </td>
                <td class="col-nama" style="vertical-align: middle;">
                  <span class="nama-text">{{ row.nama }}</span>
                  <span v-if="row.deskripsi" class="deskripsi-text">{{ row.deskripsi }}</span>
                </td>
              </tr>

              <!-- ── Inline Row (foto + restore btn) ── -->
              <tr
                v-if="selectedRowIndex === i"
                :key="`inline-${row.id}`"
                class="photo-inline-row"
              >
                <td colspan="3" class="photo-inline-cell">
                  <div class="photo-inline-content">
                    <template v-if="row.foto_urls?.length > 0">
                      <div class="photo-inline-strip">
                        <div
                          v-for="(url, idx) in row.foto_urls"
                          :key="url"
                          class="photo-thumb"
                          :title="`${row.nama} — foto ${idx + 1}`"
                        >
                          <img :src="url" :alt="`${row.nama} foto ${idx + 1}`" loading="lazy" />
                        </div>
                      </div>
                    </template>
                    <div v-else class="photo-no-foto">
                      <i class="pi pi-image"></i>
                      <span>Belum ada foto</span>
                    </div>

                    <!-- Buka Archive action -->
                    <div class="photo-inline-sep"></div>
                    <button class="btn-restore-cs" @click.stop="openUnarchiveConfirm(row)" title="Buka Archive (F3)">
                      <i class="pi pi-folder-open"></i>
                      <span>Buka Archive</span>
                      <kbd class="kbd-cs">F3</kbd>
                    </button>
                  </div>
                </td>
              </tr>

            </template>
          </tbody>
        </table>
      </div>

    </template>

    <!-- ── MODAL: KONFIRMASI BUKA ARCHIVE ─────────────── -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="unarchiveModal.show" class="modal-overlay" @click.self="unarchiveModal.show = false">
          <div class="modal-box modal-box--sm" role="dialog">
            <div class="modal-header modal-header--green">
              <h3 class="modal-title"><i class="pi pi-folder-open"></i> Buka Archive</h3>
              <button class="modal-close" @click="unarchiveModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="arc-confirm-body">
              <div class="arc-confirm-icon">
                <i class="pi pi-folder-open"></i>
              </div>
              <div class="arc-confirm-text">
                <p class="arc-confirm-nama">{{ unarchiveModal.row?.nama }}</p>
                <p class="arc-confirm-desc">Barang akan tampil kembali di Cek Semua, Katalog, Cek Harga, dan Penjualan.</p>
              </div>
            </div>
            <div class="arc-confirm-footer">
              <button class="arc-btn-cancel" @click="unarchiveModal.show = false">
                <i class="pi pi-times"></i>
                <span>Batal</span>
                <kbd>Esc</kbd>
              </button>
              <button class="arc-btn-confirm" @click="doUnarchive" :disabled="unarchiveModal.saving">
                <i v-if="unarchiveModal.saving" class="pi pi-spin pi-spinner"></i>
                <template v-else>
                  <i class="pi pi-folder-open"></i>
                  <span>Buka Archive</span>
                  <kbd>F3</kbd>
                </template>
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <Toast position="top-right" />
  </div>
</template>

<script setup>
import { ref, computed, reactive, watch, onMounted, onUnmounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useToast } from 'primevue/usetoast'
import Toast from 'primevue/toast'

const router      = useRouter()
const toast       = useToast()
const pageEl      = ref(null)
const searchInput = ref(null)
const tableWrap   = ref(null)

const searchQuery      = ref('')
const searchFocused    = ref(false)
const loading          = ref(true)
const allRows          = ref([])
const selectedRowIndex = ref(-1)
const rowRefs          = new Map()

const PAGE_SIZE   = 20
const currentPage = ref(1)

const unarchiveModal = reactive({ show: false, row: null, saving: false })

watch(searchQuery, () => {
  selectedRowIndex.value = -1
  currentPage.value = 1
})

const filteredRows = computed(() => {
  if (!searchQuery.value) return allRows.value
  const q = searchQuery.value.toLowerCase()
  return allRows.value.filter(row =>
    row.kode.toLowerCase().includes(q) ||
    row.nama.toLowerCase().includes(q)
  )
})

const totalRows  = computed(() => filteredRows.value.length)
const totalPages = computed(() => Math.ceil(totalRows.value / PAGE_SIZE) || 1)

const pagedRows = computed(() => {
  const start = (currentPage.value - 1) * PAGE_SIZE
  return filteredRows.value.slice(start, start + PAGE_SIZE)
})

async function loadArchivedProducts() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('products')
      .select('id, kode, nama, deskripsi, satuan, foto_urls')
      .eq('is_archived', true)
      .order('kode', { ascending: true })
    if (error) throw error
    allRows.value = (data ?? []).map(p => ({ ...p, foto_urls: p.foto_urls ?? [] }))
  } catch (err) {
    console.error('[Archive] load:', err.message)
  } finally {
    loading.value = false
  }
}

function openUnarchiveConfirm(row) {
  unarchiveModal.row    = row
  unarchiveModal.saving = false
  unarchiveModal.show   = true
}

async function doUnarchive() {
  if (!unarchiveModal.row) return
  unarchiveModal.saving = true
  try {
    const { error } = await supabase
      .from('products')
      .update({ is_archived: false })
      .eq('id', unarchiveModal.row.id)
    if (error) throw error
    toast.add({ severity: 'success', summary: 'Berhasil', detail: `${unarchiveModal.row.nama} berhasil di-restore.`, life: 3000 })
    allRows.value = allRows.value.filter(r => r.id !== unarchiveModal.row.id)
    unarchiveModal.show   = false
    selectedRowIndex.value = -1
  } catch (err) {
    toast.add({ severity: 'error', summary: 'Gagal', detail: err.message, life: 4000 })
  } finally {
    unarchiveModal.saving = false
  }
}

function prevPage() {
  if (currentPage.value > 1) { currentPage.value--; selectedRowIndex.value = 0 }
}
function nextPage() {
  if (currentPage.value < totalPages.value) { currentPage.value++; selectedRowIndex.value = 0 }
}
function setRowRef(el, index) {
  if (el) rowRefs.set(index, el)
  else rowRefs.delete(index)
}
function selectRow(i) { selectedRowIndex.value = i }

function moveRow(delta) {
  const max = pagedRows.value.length - 1
  if (max < 0) return
  if (selectedRowIndex.value < 0) {
    selectedRowIndex.value = delta < 0 ? max : 0
  } else {
    selectedRowIndex.value = Math.max(0, Math.min(max, selectedRowIndex.value + delta))
  }
  nextTick(() => rowRefs.get(selectedRowIndex.value)?.scrollIntoView({ block: 'nearest' }))
}

function onSearchEnter() {
  if (!filteredRows.value.length) return
  searchInput.value?.blur()
  selectedRowIndex.value = 0
  currentPage.value = 1
  nextTick(() => rowRefs.get(0)?.scrollIntoView({ block: 'nearest' }))
}
function clearSearch() {
  searchQuery.value = ''
  selectedRowIndex.value = -1
  currentPage.value = 1
  nextTick(() => searchInput.value?.focus())
}
function handleSearchEsc() {
  if (searchQuery.value) {
    searchQuery.value = ''
    selectedRowIndex.value = -1
  } else {
    router.push('/gudang')
  }
}

function onGlobalKey(e) {
  if (unarchiveModal.show) {
    if (e.key === 'Escape') { e.preventDefault(); unarchiveModal.show = false }
    return
  }
  const inSearch = document.activeElement === searchInput.value
  if (inSearch) {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      searchInput.value?.blur()
      selectedRowIndex.value = 0
      currentPage.value = 1
      nextTick(() => rowRefs.get(0)?.scrollIntoView({ block: 'nearest' }))
    }
    return
  }
  switch (e.key) {
    case 'ArrowUp':   e.preventDefault(); moveRow(-1); break
    case 'ArrowDown': e.preventDefault(); moveRow(1);  break
    case 'Enter': {
      if (e.target.matches('input,textarea,select,button')) break
      const row = pagedRows.value[selectedRowIndex.value]
      if (row) { e.preventDefault(); openUnarchiveConfirm(row) }
      break
    }
    case 'PageUp':   e.preventDefault(); prevPage(); break
    case 'PageDown': e.preventDefault(); nextPage(); break
    case 'Escape':   e.preventDefault(); router.push('/gudang'); break
    case 'F3': {
      e.preventDefault()
      const rowF3 = pagedRows.value[selectedRowIndex.value]
      if (rowF3) openUnarchiveConfirm(rowF3)
      break
    }
    case 'F1':
      e.preventDefault()
      searchInput.value?.focus()
      searchInput.value?.select()
      break
  }
}

onMounted(async () => {
  window.addEventListener('keydown', onGlobalKey)
  await loadArchivedProducts()
  nextTick(() => { searchInput.value?.focus() })
})
onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
})
</script>

<style scoped>
@import '@/assets/pages/gudang/gudang-archive-page.css';
</style>
