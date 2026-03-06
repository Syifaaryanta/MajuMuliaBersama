<template>
  <div class="gudang-semua-page" ref="pageEl" tabindex="-1">

    <!-- ── PAGE HEADER ──────────────────────────────────── -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Cek Semua Barang</h1>
        <p class="g-subtitle">Daftar lengkap semua produk di gudang</p>
      </div>
    </div>

    <!-- ── SEARCH BAR ───────────────────────────────────── -->
    <div class="search-bar">
      <div class="search-input-wrap">
        <i class="pi pi-search"></i>
        <input
          ref="searchInput"
          v-model="searchQuery"
          type="text"
          class="search-input"
          placeholder="Cari berdasarkan kode atau nama barang..."
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

    <!-- ── META BAR ─────────────────────────────────────── -->
    <div class="result-meta">
      <span class="result-count">
        <b>{{ totalRows }}</b> barang ditemukan
        <span v-if="searchQuery" class="meta-filter">
          · Filter: <b>{{ searchQuery }}</b>
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

    <!-- ── TABLE ────────────────────────────────────────── -->
    <div v-if="loading" class="loading-state">
      <i class="pi pi-spin pi-spinner"></i>
      <span>Memuat data...</span>
    </div>

    <div v-else-if="pagedRows.length === 0" class="empty-state">
      <i class="pi pi-inbox"></i>
      <p v-if="searchQuery">Tidak ada barang yang cocok dengan "<b>{{ searchQuery }}</b>"</p>
      <p v-else>Belum ada barang di gudang</p>
    </div>

    <div v-else class="table-wrap">
      <table class="g-table">
        <thead>
          <tr>
            <th class="col-no">#</th>
            <th class="col-kode">Kode</th>
            <th class="col-nama">Nama Barang</th>
            <th class="col-satuan">Satuan</th>
            <th class="col-stok">Stok</th>
            <th class="col-supplier">Supplier</th>
            <th class="col-harga">Harga Beli</th>
          </tr>
        </thead>
        <tbody>
          <template v-for="(row, i) in pagedRows" :key="row.product_id">
            <tr
              v-for="(price, priceIdx) in row.prices"
              :key="`${row.product_id}-${price.id}`"
              :ref="el => { if (priceIdx === 0) setRowRef(el, i); }"
              :data-index="i"
              class="g-row"
              :class="{
                'g-row--active': selectedRowIndex === i,
              }"
              @click="selectedRowIndex = i"
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
              <td v-if="priceIdx === 0" :rowspan="row.prices.length" class="col-satuan">
                {{ row.satuan }}
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

  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const pageEl = ref(null)
const searchInput = ref(null)
const searchQuery = ref('')
const loading = ref(true)
const allRows = ref([])
const selectedRowIndex = ref(0)
const rowRefs = new Map()

const PAGE_SIZE = 20
const currentPage = ref(1)

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

const totalRows = computed(() => filteredRows.value.length)
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
        satuan,
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
      .order('kode', { ascending: true })

    if (error) throw error

    // Transform data to group prices by product
    allRows.value = data.map(p => {
      const activePrices = p.product_prices?.filter(pp => pp.aktif) ?? []
      return {
        product_id: p.id,
        kode: p.kode,
        nama: p.nama,
        satuan: p.satuan,
        prices: activePrices.map(pp => ({
          id: pp.id,
          stok: pp.stok,
          harga_beli: pp.harga_beli,
          supplier_nama: pp.supplier?.nama || '—'
        }))
      }
    }).filter(p => p.prices.length > 0) // Only show products with active prices

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

// ───────────────────────────────────────────────────────────
// KEYBOARD HANDLERS
// ───────────────────────────────────────────────────────────
function handleSearchEsc(e) {
  e.preventDefault()
  e.stopPropagation()
  
  // If search input is empty, go back to gudang menu
  if (!searchQuery.value.trim()) {
    router.push('/gudang')
  }
}

function onGlobalKey(e) {
  // Arrow Up/Down for table navigation (when not in search input)
  if (e.key === 'ArrowUp' && document.activeElement !== searchInput.value) {
    e.preventDefault()
    moveRow(-1)
  } else if (e.key === 'ArrowDown' && document.activeElement !== searchInput.value) {
    e.preventDefault()
    moveRow(1)
  }
  
  // Page Up/Down for pagination
  else if (e.key === 'PageUp') {
    e.preventDefault()
    prevPage()
  } else if (e.key === 'PageDown') {
    e.preventDefault()
    nextPage()
  }
  
  // Escape - Back to gudang menu
  else if (e.key === 'Escape') {
    e.preventDefault()
    router.push('/gudang')
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
onMounted(() => {
  pageEl.value?.focus()
  window.addEventListener('keydown', onGlobalKey)
  loadAllProducts()
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
})
</script>

<style scoped>
@import '@/assets/components/table.css';
@import '@/assets/pages/gudang/gudang-page.css';
@import '@/assets/pages/master-data/master-data-page.css';

.gudang-semua-page {
  outline: none;
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding-bottom: 2rem;
}

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 4rem 1rem;
  color: #64748b;
  font-size: 1rem;
}

.loading-state .pi-spinner {
  font-size: 2rem;
  color: #3b82f6;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 4rem 1rem;
  color: #94a3b8;
  font-size: 1rem;
  text-align: center;
}

.empty-state .pi {
  font-size: 3rem;
  color: #cbd5e1;
}

.col-satuan {
  width: 80px;
  text-align: center;
  color: #64748b;
  font-weight: 600;
}
</style>
