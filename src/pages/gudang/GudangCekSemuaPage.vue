<template>
  <div class="gudang-semua-page" ref="pageEl" tabindex="-1">

    <!-- ── PAGE HEADER ──────────────────────────────────── -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Cek Semua Barang</h1>
        <p class="g-subtitle">Daftar lengkap semua produk di gudang</p>
      </div>
      <div v-if="!loading && allRows.length" class="g-header-badge">
        <i class="pi pi-box"></i>
        <span><b>{{ allRows.length }}</b> produk</span>
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
          @input="onSearchInput"
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
      <span>Memuat data...</span>
    </div>

    <!-- ── EMPTY ─────────────────────────────────────────── -->
    <div v-else-if="filteredRows.length === 0" class="empty-state">
      <i class="pi pi-inbox"></i>
      <p v-if="searchQuery">Tidak ada barang yang cocok dengan "<b>{{ searchQuery }}</b>"</p>
      <p v-else>Belum ada barang di gudang</p>
    </div>

    <!-- ── TABLE ─────────────────────────────────────────── -->
    <template v-else>

      <!-- Meta bar -->
      <div class="result-meta">
        <span class="result-count">
          <b>{{ totalRows }}</b> barang
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

      <!-- Table -->
      <div class="table-wrap" ref="tableWrap">
        <table class="g-table cs-table">
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
          <tbody>
            <template v-for="(row, i) in pagedRows" :key="row.product_id">

              <!-- Price rows -->
              <tr
                v-for="(price, priceIdx) in row.prices"
                :key="`${row.product_id}-${price.id}`"
                :ref="el => { if (priceIdx === 0) setRowRef(el, i); }"
                :data-index="i"
                class="g-row"
                :class="{
                  'g-row--active':     selectedRowIndex === i && priceIdx === 0,
                  'g-row--active-sub': selectedRowIndex === i && priceIdx > 0,
                  'g-row--sub':        selectedRowIndex !== i && priceIdx > 0,
                }"
                @click="selectRow(i)"
                @dblclick="viewDetail(row)"
              >
                <td v-if="priceIdx === 0" :rowspan="row.prices.length" class="col-no" style="vertical-align: middle;">
                  <span class="row-num">{{ (currentPage - 1) * PAGE_SIZE + i + 1 }}</span>
                </td>
                <td v-if="priceIdx === 0" :rowspan="row.prices.length" class="col-kode" style="vertical-align: middle;">
                  <span class="kode-badge">{{ row.kode }}</span>
                </td>
                <td v-if="priceIdx === 0" :rowspan="row.prices.length" class="col-nama" style="vertical-align: middle;">
                  <span class="nama-text">{{ row.nama }}</span>
                  <span v-if="row.deskripsi" class="deskripsi-text">{{ row.deskripsi }}</span>
                  <span v-if="row.prices.length > 1" class="multi-sup-badge">
                    {{ row.prices.length }} supplier
                  </span>
                </td>
                <td class="col-stok">
                  <span class="stok-val" :class="{ 'stok-low': price.stok <= 3 }">
                    {{ price.stok }} <span class="stok-satuan">{{ row.satuan }}</span>
                  </span>
                </td>
                <td class="col-supplier">
                  <span class="supplier-chip">{{ price.supplier_nama }}</span>
                </td>
                <td class="col-harga">
                  <span class="harga-val">{{ formatRp(price.harga_beli) }}</span>
                </td>
              </tr>

              <!-- ── Inline Photo Row (shows for selected product) ── -->
              <tr
                v-if="selectedRowIndex === i"
                :key="`photo-${row.product_id}`"
                class="photo-inline-row"
              >
                <td colspan="6" class="photo-inline-cell">
                  <div class="photo-inline-content">
                    <template v-if="row.foto_urls?.length > 0">
                      <div class="photo-inline-strip">
                        <div
                          v-for="(url, idx) in row.foto_urls"
                          :key="url"
                          class="photo-thumb"
                          @click="viewDetail(row)"
                          :title="`${row.nama} — foto ${idx + 1} · klik untuk detail`"
                        >
                          <img :src="url" :alt="`${row.nama} foto ${idx + 1}`" loading="lazy" />
                          <div class="photo-thumb-overlay"><i class="pi pi-search-plus"></i></div>
                        </div>
                      </div>
                      <button class="btn-to-detail" @click="viewDetail(row)">
                        <i class="pi pi-arrow-right"></i> Lihat Detail
                      </button>
                    </template>
                    <div v-else class="photo-no-foto">
                      <i class="pi pi-image"></i>
                      <span>Belum ada foto</span>
                      <button class="btn-to-detail btn-to-detail--outline" @click="viewDetail(row)">
                        <i class="pi pi-external-link"></i> Lihat Detail
                      </button>
                    </div>

                    <!-- Archive action -->
                    <div class="photo-inline-sep"></div>
                    <button class="btn-archive-cs" @click.stop="openArchive(row)" title="Archive barang ini (F3)">
                      <i class="pi pi-inbox"></i>
                      <span>Archive</span>
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

  </div>

  <!-- ── MODAL: KONFIRMASI ARCHIVE ───────────────────── -->
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="archiveModal.show" class="modal-overlay" @click.self="archiveModal.show = false">
        <div class="modal-box modal-box--sm" role="dialog">
          <div class="modal-header modal-header--archive">
            <h3 class="modal-title"><i class="pi pi-inbox"></i> Archive Barang</h3>
            <button class="modal-close" @click="archiveModal.show = false" tabindex="-1">
              <i class="pi pi-times"></i>
            </button>
          </div>
          <div class="modal-body delete-body">
            <i class="pi pi-inbox del-icon" style="color:#f59e0b"></i>
            <p>Archive barang <b>{{ archiveModal.row?.nama }}</b>?</p>
            <p class="del-warn">Barang tidak akan tampil di Cek Harga, Katalog, dan Penjualan. Bisa di-restore kapan saja dari menu Archive.</p>
          </div>
          <div class="modal-footer">
            <button class="btn-cancel" @click="archiveModal.show = false">
              Batal <kbd>Esc</kbd>
            </button>
            <button class="btn-archive" @click="doArchive" :disabled="archiveModal.saving">
              <i v-if="archiveModal.saving" class="pi pi-spin pi-spinner"></i>
              <span v-else><i class="pi pi-inbox"></i> Archive</span>
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>

  <Toast position="top-right" />
</template>

<script setup>
import { ref, computed, reactive, watch, onMounted, onUnmounted, nextTick } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useToast } from 'primevue/usetoast'
import Toast from 'primevue/toast'

const router      = useRouter()
const route       = useRoute()
const toast       = useToast()
const pageEl      = ref(null)
const searchInput = ref(null)
const tableWrap   = ref(null)

const searchQuery   = ref('')
const searchFocused = ref(false)
const loading       = ref(true)
const allRows       = ref([])
const selectedRowIndex = ref(-1)
const rowRefs       = new Map()

const archiveModal = reactive({ show: false, row: null, saving: false })

const PAGE_SIZE   = 20
const currentPage = ref(1)

// ── Reset selection when user types ─────────────────────────
watch(searchQuery, () => {
  selectedRowIndex.value = -1
  currentPage.value = 1
})

// ───────────────────────────────────────────────────────────
// COMPUTED
// ───────────────────────────────────────────────────────────
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

// ───────────────────────────────────────────────────────────
// LOAD DATA
// ───────────────────────────────────────────────────────────
async function loadAllProducts() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('products')
      .select(`
        id,
        kode,
        nama,
        deskripsi,
        satuan,
        foto_urls,
        product_prices (
          id,
          stok,
          harga_beli,
          aktif,
          supplier:suppliers (
            id,
            nama
          )
        )
      `)
      .eq('is_archived', false)
      .order('kode', { ascending: true })

    if (error) throw error

    allRows.value = data.map(p => {
      const activePrices = p.product_prices?.filter(pp => pp.aktif) ?? []
      return {
        product_id: p.id,
        kode:       p.kode,
        nama:       p.nama,
        deskripsi:  p.deskripsi ?? '',
        satuan:     p.satuan,
        foto_urls:  p.foto_urls ?? [],
        prices: activePrices.map(pp => ({
          id:            pp.id,
          stok:          pp.stok,
          harga_beli:    pp.harga_beli,
          supplier_nama: pp.supplier?.nama || '—'
        }))
      }
    }).filter(p => p.prices.length > 0)

  } catch (error) {
    console.error('Error loading products:', error)
  } finally {
    loading.value = false
  }
}

// ───────────────────────────────────────────────────────────
// PAGINATION
// ───────────────────────────────────────────────────────────
function prevPage() {
  if (currentPage.value > 1) {
    currentPage.value--
    selectedRowIndex.value = 0
    nextTick(() => rowRefs.get(0)?.scrollIntoView({ block: 'nearest' }))
  }
}

function nextPage() {
  if (currentPage.value < totalPages.value) {
    currentPage.value++
    selectedRowIndex.value = 0
    nextTick(() => rowRefs.get(0)?.scrollIntoView({ block: 'nearest' }))
  }
}

function setRowRef(el, index) {
  if (el) rowRefs.set(index, el)
  else rowRefs.delete(index)
}

// ───────────────────────────────────────────────────────────
// ROW SELECTION & NAVIGATION
// ───────────────────────────────────────────────────────────
function selectRow(i) {
  selectedRowIndex.value = i
}

function moveRow(delta) {
  const max = pagedRows.value.length - 1
  if (max < 0) return
  if (selectedRowIndex.value < 0) {
    selectedRowIndex.value = delta < 0 ? max : 0
  } else {
    selectedRowIndex.value = Math.max(0, Math.min(max, selectedRowIndex.value + delta))
  }
  nextTick(() => {
    // scroll photo row into view too (it's below the product row)
    const el = rowRefs.get(selectedRowIndex.value)
    el?.scrollIntoView({ block: 'nearest' })
  })
}

// ───────────────────────────────────────────────────────────// ARCHIVE
// ───────────────────────────────────────────────────────────────
function openArchive(row) {
  if (!row) return
  archiveModal.row = row
  archiveModal.saving = false
  archiveModal.show = true
}

async function doArchive() {
  archiveModal.saving = true
  try {
    const { error } = await supabase
      .from('products')
      .update({ is_archived: true })
      .eq('id', archiveModal.row.product_id)
    if (error) throw error
    archiveModal.show = false
    allRows.value = allRows.value.filter(r => r.product_id !== archiveModal.row.product_id)
    selectedRowIndex.value = -1
    toast.add({ severity: 'success', summary: 'Diarsipkan', detail: `${archiveModal.row.nama} berhasil diarsipkan.`, life: 3000 })
  } catch (err) {
    console.error(err)
    toast.add({ severity: 'error', summary: 'Gagal', detail: err.message, life: 4000 })
  } finally {
    archiveModal.saving = false
  }
}

// ───────────────────────────────────────────────────────────────// DETAIL
// ───────────────────────────────────────────────────────────
function viewDetail(row) {
  if (!row) return
  router.push({ path: '/gudang/detail', query: { product_id: row.product_id } })
}

// ───────────────────────────────────────────────────────────
// SEARCH HANDLERS
// ───────────────────────────────────────────────────────────
function onSearchInput() {
  // selectedRowIndex resets via watch on searchQuery
}

function onSearchEnter() {
  if (!filteredRows.value.length) return
  searchInput.value?.blur()
  selectedRowIndex.value = 0
  currentPage.value = 1
  nextTick(() => rowRefs.get(0)?.scrollIntoView({ block: 'nearest' }))
}

function clearSearch() {
  searchQuery.value      = ''
  selectedRowIndex.value = -1
  currentPage.value      = 1
  nextTick(() => searchInput.value?.focus())
}

function handleSearchEsc() {
  if (searchQuery.value) {
    searchQuery.value      = ''
    selectedRowIndex.value = -1
  } else {
    router.push('/gudang')
  }
}

// ───────────────────────────────────────────────────────────
// GLOBAL KEYBOARD
// ───────────────────────────────────────────────────────────
function onGlobalKey(e) {
  // Archive modal guard
  if (archiveModal.show) {
    if (e.key === 'Escape') { e.preventDefault(); archiveModal.show = false }
    return
  }

  const inSearch = document.activeElement === searchInput.value

  if (inSearch) {
    // ArrowDown from search: move focus to first row
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      searchInput.value?.blur()
      selectedRowIndex.value = 0
      currentPage.value = 1
      nextTick(() => rowRefs.get(0)?.scrollIntoView({ block: 'nearest' }))
    }
    return // all other keys handled by input's own events
  }

  switch (e.key) {
    case 'ArrowUp':
      e.preventDefault(); moveRow(-1); break
    case 'ArrowDown':
      e.preventDefault(); moveRow(1); break
    case 'Enter':
    case 'F4': {
      if (e.target.matches('input,textarea,select,button')) break
      const row = pagedRows.value[selectedRowIndex.value]
      if (row) { e.preventDefault(); viewDetail(row) }
      break
    }
    case 'PageUp':
      e.preventDefault(); prevPage(); break
    case 'PageDown':
      e.preventDefault(); nextPage(); break
    case 'Escape':
      e.preventDefault(); router.push('/gudang'); break
    case 'F1':
      e.preventDefault()
      searchInput.value?.focus()
      searchInput.value?.select()
      break
    case 'F3': {
      const row = pagedRows.value[selectedRowIndex.value]
      if (row) { e.preventDefault(); openArchive(row) }
      break
    }
  }
}

// ───────────────────────────────────────────────────────────
// UTILITIES
// ───────────────────────────────────────────────────────────
function formatRp(val) {
  if (val == null) return 'Rp 0'
  return 'Rp ' + Number(val).toLocaleString('id-ID')
}

// ───────────────────────────────────────────────────────────
// LIFECYCLE
// ───────────────────────────────────────────────────────────
onMounted(async () => {
  window.addEventListener('keydown', onGlobalKey)
  await loadAllProducts()
  nextTick(() => { searchInput.value?.focus() })
  const qProductId = route.query.product_id
  if (qProductId) {
    router.replace({ path: '/gudang/detail', query: { product_id: qProductId } })
  }
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
})
</script>

<style scoped>
@import '@/assets/pages/gudang/gudang-cek-semua-page.css';
</style>
