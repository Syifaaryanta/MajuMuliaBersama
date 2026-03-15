<template>
  <div class="penjualan-input-page" ref="pageEl" tabindex="-1">

    <!-- ── FORM CARD WITH HEADER ─────────────────────────────────────── -->
    <div class="form-card">
      <div class="form-header">
        <h1 class="form-header-title">Input Item Penjualan</h1>
        <p class="form-header-subtitle">Tahap 2: Tambahkan item yang akan dijual</p>
      </div>

      <!-- Order Info Card -->
      <div class="order-info-section">
        <div v-if="orderData.customer" class="order-info-card">
          <div class="info-row">
            <div class="info-col">
              <label>No. Order:</label>
              <strong class="order-number-preview">
                {{ orderData.no_order || generatePreviewOrderNumber() }}
              </strong>
            </div>
            <div class="info-col">
              <label>Tanggal:</label>
              <strong>{{ orderData.order_date }}</strong>
            </div>
            <div class="info-col">
              <label>Pengiriman:</label>
              <strong>{{ orderData.diantar ? 'Diantar' : 'Diambil' }}</strong>
            </div>
            <div class="info-col">
              <label>Tempo:</label>
              <strong>{{ (orderData.limit_bulan || 0) + 1 }} Bulan</strong>
            </div>
            <div class="info-col">
              <label>Sales:</label>
              <strong>{{ orderData.salesman }}</strong>
            </div>
          </div>
          <div class="info-row info-customer">
            <div class="info-col-full">
              <label>Customer:</label>
              <strong>{{ orderData.customer.nama }}</strong>
              <span class="customer-details">
                {{ orderData.customer.alamat || 'Alamat tidak tersedia' }}
                <span v-if="orderData.customer.no_telp"> · {{ orderData.customer.no_telp }}</span>
              </span>
            </div>
          </div>
        </div>
        <div v-else class="order-info-card">
          <div class="loading-state">
            <i class="pi pi-spin pi-spinner"></i>
            <p>Memuat data order...</p>
          </div>
        </div>
      </div>
    </div>

    <!-- ── ITEMS TABLE ──────────────────────────────────── -->
    <div class="items-section">
      <div class="table-card">
        <div class="table-header">
          <h3 class="table-title">
            <i class="pi pi-list"></i>
            Daftar Barang ({{ items.length }} item)
          </h3>
        </div>

        <div class="table-wrap">
          <table class="items-table">
            <thead>
              <tr>
                <th class="col-no">#</th>
                <th class="col-kode">Kode</th>
                <th class="col-nama">Nama Barang</th>
                <th class="col-qty">Qty</th>
                <th class="col-price">Harga Satuan</th>
                <th class="col-total">Total</th>
                <th class="col-action">Aksi</th>
              </tr>
            </thead>
            <tbody>
              <!-- Existing Items -->
              <tr 
                v-for="(item, idx) in items" 
                :key="idx"
                class="item-row"
                :class="{ 'item-row--warning': item.stok_warning }"
              >
                <td class="col-no">{{ idx + 1 }}</td>
                <td class="col-kode">
                  <span class="item-kode">{{ item.product_kode }}</span>
                </td>
                <td class="col-nama">
                  <div class="item-info">
                    <span class="item-nama">{{ item.product_nama }}</span>
                    <span v-if="item.stok_warning" class="stock-warning">
                      <i class="pi pi-exclamation-triangle"></i>
                      Stok: {{ item.stok_available }}
                    </span>
                  </div>
                </td>
                <td class="col-qty">
                  <input
                    :ref="el => setQtyRef(el, idx)"
                    v-model.number="item.qty"
                    type="number"
                    class="qty-input"
                    min="1"
                    @input="updateItemTotal(idx)"
                    @keydown="handleTableKeydown($event, idx, 'qty')"
                  />
                </td>
                <td class="col-price">
                  <div class="price-input-wrap">
                    <input
                      :ref="el => setPriceRef(el, idx)"
                      :value="formatNumber(item.unit_price)"
                      type="text"
                      class="price-input"
                      @input="updateItemPrice(idx, $event)"
                      @keydown="handleTableKeydown($event, idx, 'price')"
                    />
                    <button 
                      class="price-info-btn" 
                      @click="showPriceInfo(item)"
                      title="Info harga (F4)"
                      tabindex="-1"
                    >
                      <i class="pi pi-info-circle"></i>
                    </button>
                  </div>
                </td>
                <td class="col-total">
                  <span class="total-val">{{ formatRp(item.total) }}</span>
                </td>
                <td class="col-action">
                  <button 
                    class="btn-icon btn-delete" 
                    @click="removeItem(idx)"
                    title="Hapus item (Del)"
                  >
                    <i class="pi pi-trash"></i>
                  </button>
                </td>
              </tr>

              <!-- New Item Row -->
              <tr class="item-row item-row--new" ref="newItemRow">
                <td class="col-no">{{ items.length + 1 }}</td>
                <td class="col-kode" colspan="2">
                  <div class="search-input-wrap">
                    <input
                      ref="inputProduct"
                      v-model="newItem.search"
                      type="text"
                      class="item-input"
                      placeholder="Ketik nama barang & tekan Enter..."
                      @keydown.enter.prevent="openProductModal"
                      @keydown.tab.prevent="focusQty"
                      @keydown="handleNewItemKeydown($event, 'product')"
                    />
                    <i class="pi pi-search input-icon"></i>
                  </div>
                </td>
                <td class="col-qty">
                  <input
                    ref="inputQty"
                    v-model.number="newItem.qty"
                    type="number"
                    class="qty-input"
                    placeholder="0"
                    min="1"
                    @keydown.enter="focusPrice"
                    @keydown="handleNewItemKeydown($event, 'qty')"
                    disabled
                  />
                </td>
                <td class="col-price">
                  <div class="price-input-wrap">
                    <input
                      ref="inputPrice"
                      :value="newItem.unit_price ? formatNumber(newItem.unit_price) : ''"
                      type="text"
                      @keydown="handleNewItemKeydown($event, 'price')"
                      class="price-input"
                      placeholder="0"
                      @input="formatNewItemPrice"
                      @keydown.enter="addItem"
                      disabled
                    />
                    <button
                      class="price-info-btn"
                      @click="showPriceInfoPreview"
                      title="Info harga (F4)"
                      tabindex="-1"
                    >
                      <i class="pi pi-info-circle"></i>
                    </button>
                  </div>
                </td>
                <td class="col-total">
                  <span class="total-val total-preview">
                    {{ newItem.qty && newItem.unit_price ? formatRp(newItem.qty * newItem.unit_price) : '—' }}
                  </span>
                </td>
                <td class="col-action">—</td>
              </tr>

              <!-- Empty State -->
              <tr v-if="items.length === 0" class="empty-row">
                <td colspan="6" class="empty-cell">
                  <i class="pi pi-inbox"></i>
                  <p>Belum ada barang. Mulai ketik nama barang di atas.</p>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Shortcut Hints -->
        <div class="shortcuts-bar">
          <kbd>Esc</kbd>
          <kbd>Y</kbd>
          <kbd>F10</kbd>
          <kbd>↑↓←→</kbd>
          <kbd>Del</kbd>
          <kbd>F4</kbd>
        </div>

        <!-- Subtotal -->
        <div class="table-footer">
          <div class="subtotal-row">
            <span class="subtotal-label">Subtotal:</span>
            <span class="subtotal-value">{{ formatRp(subtotal) }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════
         MODAL PRODUCT SEARCH
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="productModal.show" class="modal-overlay" @click.self="productModal.show = false">
          <div class="modal-box modal-search" role="dialog">
            <div class="modal-header">
              <i class="pi pi-search"></i>
              <h3 class="modal-title">Pilih Barang</h3>
              <button class="modal-close" @click="productModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <div class="search-modal-input-wrap">
                <i class="pi pi-search"></i>
                <input
                  ref="productModalInput"
                  v-model="productModal.query"
                  type="text"
                  class="search-modal-input"
                  placeholder="Ketik untuk filter hasil..."
                  @input="filterProductModal"
                  @keydown="onProductModalKey"
                />
              </div>
              <div class="search-modal-results">
                <div
                  v-for="(item, idx) in productModal.filtered"
                  :key="item.id"
                  class="search-modal-item"
                  :class="{ active: idx === productModal.selectedIndex }"
                  @click="selectProduct(item)"
                  @mouseenter="productModal.selectedIndex = idx"
                >
                  <div class="smi-main">
                    <span class="smi-kode">{{ item.kode }}</span>
                    <span class="smi-nama">{{ item.nama }}</span>
                  </div>
                  <div class="smi-sub">
                    <span>Stok: <strong>{{ item.stok }} {{ item.satuan }}</strong></span>
                  </div>
                </div>
                <div v-if="productModal.filtered.length === 0" class="search-modal-empty">
                  <i class="pi pi-inbox"></i>
                  <p>Tidak ada barang yang cocok</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════
         MODAL PRICE INFO
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="priceInfoModal.show" class="modal-overlay" @click.self="priceInfoModal.show = false">
          <div class="modal-box modal-box--md" role="dialog">
            <div class="modal-header">
              <i class="pi pi-info-circle"></i>
              <h3 class="modal-title">Info Harga: {{ priceInfoModal.product_nama }}</h3>
              <button class="modal-close" @click="priceInfoModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <div class="price-info-grid" v-if="priceInfoModal.loading">
                <div class="skeleton-box"></div>
                <div class="skeleton-box"></div>
                <div class="skeleton-box"></div>
              </div>
              <div class="price-info-grid" v-else>
                <div class="price-info-card">
                  <div class="pic-label">Last Unit Price</div>
                  <div class="pic-value">{{ formatRp(priceInfoModal.data.last_unit_price) }}</div>
                  <div class="pic-hint">Harga jual terakhir (customer ini)</div>
                </div>
                <div class="price-info-card">
                  <div class="pic-label">Last Unit Cost</div>
                  <div class="pic-value">{{ formatRp(priceInfoModal.data.last_unit_cost) }}</div>
                  <div class="pic-hint">Harga beli terakhir</div>
                </div>
                <div class="price-info-card">
                  <div class="pic-label">Last Sale Qty</div>
                  <div class="pic-value">{{ priceInfoModal.data.last_sale_qty || 0 }} pcs</div>
                  <div class="pic-hint">Qty penjualan terakhir</div>
                </div>
                <div class="price-info-card">
                  <div class="pic-label">Last Order Date</div>
                  <div class="pic-value">{{ priceInfoModal.data.last_order_date || '—' }}</div>
                  <div class="pic-hint">Tanggal order terakhir</div>
                </div>
              </div>
            </div>
            <div class="modal-footer">
              <button class="btn-primary" @click="priceInfoModal.show = false">
                Tutup <kbd>Esc</kbd>
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════════
         MODAL SUPPLIER SELECTION
    ═══════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="supplierModal.show" class="modal-overlay" @click.self="supplierModal.show = false" @keydown="onSupplierModalKey">
          <div class="modal-box modal-search" role="dialog">
            <div class="modal-header">
              <i class="pi pi-truck"></i>
              <h3 class="modal-title">Pilih Supplier &mdash; {{ supplierModal.product?.nama }}</h3>
              <button class="modal-close" @click="supplierModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <p class="supplier-select-hint">
                <i class="pi pi-info-circle"></i>
                Barang ini tersedia dari beberapa supplier dengan harga berbeda. Pilih supplier yang akan digunakan.
              </p>
              <div class="search-modal-results">
                <div
                  v-for="(entry, idx) in supplierModal.prices"
                  :key="entry.id"
                  class="search-modal-item"
                  :class="{ active: idx === supplierModal.selectedIndex }"
                  @click="selectSupplierPrice(entry)"
                  @mouseenter="supplierModal.selectedIndex = idx"
                >
                  <div class="smi-main">
                    <span class="smi-nama">{{ entry.supplier_nama }}</span>
                  </div>
                  <div class="smi-sub">
                    <span>Stok: <strong>{{ entry.stok }}</strong></span>
                    <span class="smi-price-sep">&nbsp;&middot;&nbsp;</span>
                    <span>Harga Beli: <strong>{{ formatRp(entry.harga_beli) }}</strong></span>
                  </div>
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
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()

// ───────────────────────────────────────────────────────────
// REFS
// ───────────────────────────────────────────────────────────
const pageEl = ref(null)
const inputProduct = ref(null)
const inputQty = ref(null)
const inputPrice = ref(null)
const productModalInput = ref(null)
const newItemRow = ref(null)

// ───────────────────────────────────────────────────────────
// STATE
// ───────────────────────────────────────────────────────────
const orderData = ref({})
const items = ref([])
const saving = ref(false)
const escPressCount = ref(0)
const escTimer = ref(null)
const qtyRefs = ref({})
const priceRefs = ref({})

const newItem = reactive({
  search: '',
  product_id: null,
  product_kode: '',
  product_nama: '',
  qty: 1,
  unit_price: 0,
  stok_available: 0,
})

const productModal = reactive({
  show: false,
  results: [],
  filtered: [],
  query: '',
  selectedIndex: 0,
})

const priceInfoModal = reactive({
  show: false,
  product_nama: '',
  loading: false,
  data: {
    last_unit_price: 0,
    last_unit_cost: 0,
    last_sale_qty: 0,
    last_order_date: null,
  }
})

const supplierModal = reactive({
  show: false,
  product: null,
  prices: [],        // [{ id, supplier_id, supplier_nama, stok, harga_beli }]
  selectedIndex: 0,
})

// ───────────────────────────────────────────────────────────
// COMPUTED
// ───────────────────────────────────────────────────────────
const subtotal = computed(() => {
  return items.value.reduce((sum, item) => sum + item.total, 0)
})

// ───────────────────────────────────────────────────────────
// LIFECYCLE
// ───────────────────────────────────────────────────────────
onMounted(() => {
  // Load order data from session
  const savedData = sessionStorage.getItem('penjualan_draft')
  if (!savedData) {
    alert('Data order tidak ditemukan. Kembali ke step 1.')
    router.push('/penjualan')
    return
  }

  orderData.value = JSON.parse(savedData)
  
  window.addEventListener('keydown', onGlobalKey)
  pageEl.value?.focus()
  nextTick(() => inputProduct.value?.focus())
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
})

// ───────────────────────────────────────────────────────────
// KEYBOARD SHORTCUTS
// ───────────────────────────────────────────────────────────
function onGlobalKey(e) {
  if (productModal.show || priceInfoModal.show || supplierModal.show) return

  // Esc: Track for double press to exit without save or single for back with draft
  if (e.key === 'Escape') {
    e.preventDefault()
    escPressCount.value++
    
    if (escTimer.value) {
      clearTimeout(escTimer.value)
    }
    
    if (escPressCount.value === 1) {
      // First Esc - go back to step 1 (save as draft)
      escTimer.value = setTimeout(() => {
        backToStep1() // save as draft and go back
        escPressCount.value = 0
      }, 300)
    } else if (escPressCount.value === 2) {
      // Second Esc within 300ms - save as draft and go to dashboard
      clearTimeout(escTimer.value)
      saveAsDraft().then(() => {
        router.push('/dashboard')
      })
      escPressCount.value = 0
    }
    return
  }

  // Reset esc counter on any other key
  escPressCount.value = 0
  if (escTimer.value) {
    clearTimeout(escTimer.value)
  }

  // Y: Quick save and go to list
  if ((e.key === 'y' || e.key === 'Y') && !document.activeElement || document.activeElement.tagName !== 'INPUT') {
    e.preventDefault()
    if (items.value.length > 0) {
      submitSale(false) // false = don't print
    }
    return
  }

  // F10: Print and save
  if (e.key === 'F10') {
    e.preventDefault()
    if (items.value.length > 0) {
      submitSale(true) // true = print after save
    }
    return
  }

  // Ctrl+S: Save
  if (e.ctrlKey && e.key === 's') {
    e.preventDefault()
    if (items.value.length > 0) submitSale(false)
    return
  }
}

// ───────────────────────────────────────────────────────────
// TABLE REFS & NAVIGATION
// ───────────────────────────────────────────────────────────
function setQtyRef(el, idx) {
  if (el) qtyRefs.value[idx] = el
}

function setPriceRef(el, idx) {
  if (el) priceRefs.value[idx] = el
}

function handleNewItemKeydown(e, field) {
  // Backspace - go back to last item when field is empty
  if (e.key === 'Backspace' && !e.target.value) {
    e.preventDefault()
    const lastIdx = items.value.length - 1
    if (lastIdx >= 0) {
      if (field === 'product') {
        // From product search, go to price of last item
        priceRefs.value[lastIdx]?.focus()
      } else if (field === 'qty') {
        // From qty, go to qty of last item
        qtyRefs.value[lastIdx]?.focus()
      } else if (field === 'price') {
        // From price, go to price of last item
        priceRefs.value[lastIdx]?.focus()
      }
    }
    return
  }

  // Arrow Up - go to last item
  if (e.key === 'ArrowUp') {
    e.preventDefault()
    const lastIdx = items.value.length - 1
    if (lastIdx >= 0) {
      if (field === 'product') {
        priceRefs.value[lastIdx]?.focus()
      } else if (field === 'qty') {
        qtyRefs.value[lastIdx]?.focus()
      } else if (field === 'price') {
        priceRefs.value[lastIdx]?.focus()
      }
    }
    return
  }

  // F4 - Show price info (only in price field)
  if (e.key === 'F4' && field === 'price') {
    e.preventDefault()
    showPriceInfoPreview()
    return
  }

  // Arrow Right - move to next field in new item row
  if (e.key === 'ArrowRight') {
    if (field === 'qty' && (e.ctrlKey || e.target.selectionStart === e.target.value.length)) {
      e.preventDefault()
      inputPrice.value?.focus()
      return
    }
  }

  // Arrow Left - move to previous field in new item row
  if (e.key === 'ArrowLeft') {
    if (field === 'price' && (e.ctrlKey || e.target.selectionStart === 0)) {
      e.preventDefault()
      inputQty.value?.focus()
      return
    } else if (field === 'qty' && (e.ctrlKey || e.target.selectionStart === 0)) {
      e.preventDefault()
      inputProduct.value?.focus()
      return
    }
  }
}

function handleTableKeydown(e, rowIdx, field) {
  const totalRows = items.value.length

  // Delete or Backspace - delete row
  if ((e.key === 'Delete' || e.key === 'Backspace') && e.target.value === '') {
    e.preventDefault()
    removeItem(rowIdx)
    return
  }

  // F4 - Show price info (only in price field)
  if (e.key === 'F4' && field === 'price') {
    e.preventDefault()
    showPriceInfo(items.value[rowIdx])
    return
  }

  // Enter - move to next field or row
  if (e.key === 'Enter') {
    e.preventDefault()
    if (field === 'qty') {
      // Move from qty to price in same row
      priceRefs.value[rowIdx]?.focus()
    } else if (field === 'price') {
      // Move from price to new item input
      inputProduct.value?.focus()
    }
    return
  }

  // Arrow Down - move to next row
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    if (rowIdx < totalRows - 1) {
      if (field === 'qty') {
        qtyRefs.value[rowIdx + 1]?.focus()
      } else if (field === 'price') {
        priceRefs.value[rowIdx + 1]?.focus()
      }
    } else {
      // At last row, move to new item
      if (field === 'qty') {
        inputQty.value?.focus()
      } else if (field === 'price') {
        inputPrice.value?.focus()
      }
    }
    return
  }

  // Arrow Up - move to previous row
  if (e.key === 'ArrowUp') {
    e.preventDefault()
    if (rowIdx > 0) {
      if (field === 'qty') {
        qtyRefs.value[rowIdx - 1]?.focus()
      } else if (field === 'price') {
        priceRefs.value[rowIdx - 1]?.focus()
      }
    }
    return
  }

  // Arrow Left - move from price to qty in same row
  if (e.key === 'ArrowLeft' && field === 'price') {
    // With Ctrl: always move
    // Without Ctrl: only move when cursor at start
    if (e.ctrlKey || e.target.selectionStart === 0) {
      e.preventDefault()
      qtyRefs.value[rowIdx]?.focus()
      return
    }
  }

  // Arrow Right - move from qty to price in same row
  if (e.key === 'ArrowRight' && field === 'qty') {
    // With Ctrl: always move
    // Without Ctrl: only move when cursor at end
    if (e.ctrlKey || e.target.selectionStart === e.target.value.length) {
      e.preventDefault()
      priceRefs.value[rowIdx]?.focus()
      return
    }
  }
}

// ───────────────────────────────────────────────────────────
// PRODUCT SEARCH
// ───────────────────────────────────────────────────────────
async function openProductModal() {
  const q = newItem.search.trim()
  if (!q) {
    alert('Ketik nama barang terlebih dahulu')
    return
  }

  try {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .or(`nama.ilike.%${q}%,kode.ilike.%${q}%`)
      .eq('aktif', true)
      .eq('is_archived', false)
      .order('nama')

    if (error) throw error

    productModal.results = data || []
    productModal.filtered = data || []
    productModal.query = ''
    productModal.selectedIndex = 0
    productModal.show = true

    await nextTick()
    productModalInput.value?.focus()
  } catch (err) {
    console.error('[openProductModal]', err)
    alert('Gagal mencari barang: ' + err.message)
  }
}

function filterProductModal() {
  const q = productModal.query.toLowerCase()
  productModal.filtered = q
    ? productModal.results.filter(p =>
        p.nama.toLowerCase().includes(q) || p.kode.toLowerCase().includes(q)
      )
    : productModal.results
  productModal.selectedIndex = 0
}

function onProductModalKey(e) {
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    productModal.selectedIndex = Math.min(productModal.selectedIndex + 1, productModal.filtered.length - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    productModal.selectedIndex = Math.max(productModal.selectedIndex - 1, 0)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (productModal.filtered[productModal.selectedIndex]) {
      selectProduct(productModal.filtered[productModal.selectedIndex])
    }
  } else if (e.key === 'Escape') {
    productModal.show = false
  }
}

async function selectProduct(product) {
  productModal.show = false

  try {
    // Check how many active suppliers this product has
    const { data: prices, error } = await supabase
      .from('product_prices')
      .select('id, stok, harga_beli, supplier:suppliers(id, nama)')
      .eq('product_id', product.id)
      .eq('aktif', true)
      .order('updated_at', { ascending: false })

    if (error) throw error

    const activePrices = (prices || []).filter(p => p.supplier)

    if (activePrices.length > 1) {
      // Multiple suppliers — show selection modal
      supplierModal.product = product
      supplierModal.prices = activePrices.map(p => ({
        id: p.id,
        supplier_id: p.supplier.id,
        supplier_nama: p.supplier.nama,
        stok: p.stok,
        harga_beli: p.harga_beli,
      }))
      supplierModal.selectedIndex = 0
      supplierModal.show = true
      return
    }

    // Single or no supplier — use harga_beli directly if available, else historical
    const fallbackPrice = activePrices.length === 1
      ? activePrices[0].harga_beli
      : await getDefaultPrice(product.id)

    fillNewItem(product, fallbackPrice)
  } catch (err) {
    console.error('[selectProduct]', err)
    const price = await getDefaultPrice(product.id)
    fillNewItem(product, price)
  }
}

function selectSupplierPrice(entry) {
  supplierModal.show = false
  fillNewItem(supplierModal.product, entry.harga_beli)
}

function onSupplierModalKey(e) {
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    supplierModal.selectedIndex = Math.min(supplierModal.selectedIndex + 1, supplierModal.prices.length - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    supplierModal.selectedIndex = Math.max(supplierModal.selectedIndex - 1, 0)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (supplierModal.prices[supplierModal.selectedIndex]) {
      selectSupplierPrice(supplierModal.prices[supplierModal.selectedIndex])
    }
  } else if (e.key === 'Escape') {
    supplierModal.show = false
  }
}

function fillNewItem(product, price) {
  newItem.product_id = product.id
  newItem.product_kode = product.kode
  newItem.product_nama = product.nama
  newItem.unit_price = price
  newItem.stok_available = product.stok
  newItem.search = product.nama

  inputQty.value?.removeAttribute('disabled')
  inputPrice.value?.removeAttribute('disabled')

  nextTick(() => {
    inputQty.value?.focus()
    inputQty.value?.select()
  })
}

async function getDefaultPrice(productId) {
  try {
    const customerId = orderData.value.customer.id

    // Priority 1: Last Unit Price dari customer yang sama
    // First, get the last sale_id for this customer and product
    const { data: customerSales, error: error1 } = await supabase
      .from('sales')
      .select('id')
      .eq('customer_id', customerId)
      .order('order_date', { ascending: false })
      .limit(10)

    if (customerSales && customerSales.length > 0) {
      const saleIds = customerSales.map(s => s.id)
      
      const { data: saleItems } = await supabase
        .from('sale_items')
        .select('unit_price')
        .eq('product_id', productId)
        .in('sale_id', saleIds)
        .order('created_at', { ascending: false })
        .limit(1)

      if (saleItems && saleItems.length > 0) {
        return saleItems[0].unit_price
      }
    }

    // Priority 2: Last Unit Price dari customer lain
    const { data: otherSales } = await supabase
      .from('sale_items')
      .select('unit_price')
      .eq('product_id', productId)
      .order('created_at', { ascending: false })
      .limit(1)

    if (otherSales && otherSales.length > 0) {
      return otherSales[0].unit_price
    }

    // Priority 3: New Unit Cost (dari product_prices)
    const { data: prices } = await supabase
      .from('product_prices')
      .select('harga_beli')
      .eq('product_id', productId)
      .eq('aktif', true)
      .order('updated_at', { ascending: false })
      .limit(1)

    if (prices && prices.length > 0) {
      // Add markup 20% for selling price
      return Math.round(prices[0].harga_beli * 1.2)
    }

    return 0
  } catch (err) {
    console.error('[getDefaultPrice]', err)
    return 0
  }
}

// ───────────────────────────────────────────────────────────
// ITEM MANAGEMENT
// ───────────────────────────────────────────────────────────
function addItem() {
  if (!newItem.product_id) {
    alert('Pilih barang terlebih dahulu')
    return
  }

  if (!newItem.qty || newItem.qty <= 0) {
    alert('Qty harus lebih dari 0')
    inputQty.value?.focus()
    return
  }

  if (!newItem.unit_price || newItem.unit_price < 0) {
    alert('Harga satuan tidak valid')
    inputPrice.value?.focus()
    return
  }

  // Parse price if it's still formatted string
  const unitPrice = typeof newItem.unit_price === 'string' 
    ? parseFormattedNumber(newItem.unit_price) 
    : newItem.unit_price

  // Check stock warning
  if (newItem.qty > newItem.stok_available) {
    const confirm = window.confirm(
      `Stok tidak cukup!\n\n` +
      `Barang: ${newItem.product_nama}\n` +
      `Stok tersedia: ${newItem.stok_available}\n` +
      `Qty yang diminta: ${newItem.qty}\n\n` +
      `Tetap lanjutkan?`
    )
    if (!confirm) {
      inputQty.value?.focus()
      return
    }
  }

  // Add to items
  items.value.push({
    product_id: newItem.product_id,
    product_kode: newItem.product_kode,
    product_nama: newItem.product_nama,
    qty: newItem.qty,
    unit_price: unitPrice,
    total: newItem.qty * unitPrice,
    stok_available: newItem.stok_available,
    stok_warning: newItem.qty > newItem.stok_available,
  })

  // Reset new item
  resetNewItem()
  inputProduct.value?.focus()
}

function resetNewItem() {
  newItem.search = ''
  newItem.product_id = null
  newItem.product_kode = ''
  newItem.product_nama = ''
  newItem.qty = 1
  newItem.unit_price = 0
  newItem.stok_available = 0
  
  inputQty.value?.setAttribute('disabled', 'disabled')
  inputPrice.value?.setAttribute('disabled', 'disabled')
}

function removeItem(index) {
  const item = items.value[index]
  const confirm = window.confirm(`Hapus ${item.product_nama}?`)
  if (confirm) {
    items.value.splice(index, 1)
  }
}

function updateItemTotal(index) {
  const item = items.value[index]
  // Parse formatted price back to number
  const price = typeof item.unit_price === 'string' 
    ? parseFormattedNumber(item.unit_price) 
    : item.unit_price
  item.unit_price = price
  item.total = item.qty * price
  
  // Check stock warning
  item.stok_warning = item.qty > item.stok_available
}

function updateItemPrice(index, event) {
  const item = items.value[index]
  const rawValue = event.target.value.replace(/\./g, '')
  const numValue = parseInt(rawValue) || 0
  
  // Format with thousand separator
  event.target.value = formatNumber(numValue)
  item.unit_price = numValue
  item.total = item.qty * numValue
  
  // Check stock warning
  item.stok_warning = item.qty > item.stok_available
}

function formatNewItemPrice(event) {
  const rawValue = event.target.value.replace(/\./g, '')
  const numValue = parseInt(rawValue) || 0
  event.target.value = formatNumber(numValue)
  newItem.unit_price = numValue
}

// Helper functions for price formatting
function formatNumber(num) {
  if (!num) return '0'
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')
}

function parseFormattedNumber(str) {
  if (typeof str === 'number') return str
  const cleaned = str.replace(/\./g, '')
  return parseInt(cleaned) || 0
}

// ───────────────────────────────────────────────────────────
// PRICE INFO
// ───────────────────────────────────────────────────────────
async function showPriceInfo(item) {
  priceInfoModal.product_nama = item.product_nama
  priceInfoModal.loading = true
  priceInfoModal.show = true

  try {
    const customerId = orderData.value.customer.id
    const productId = item.product_id

    // Get last sale from this customer
    const { data: customerSale } = await supabase
      .from('sale_items')
      .select('unit_price, qty, sale:sales(order_date)')
      .eq('product_id', productId)
      .eq('sale.customer_id', customerId)
      .order('created_at', { ascending: false })
      .limit(1)
      .single()

    // Get last unit cost
    const { data: price } = await supabase
      .from('product_prices')
      .select('harga_beli')
      .eq('product_id', productId)
      .eq('aktif', true)
      .order('updated_at', { ascending: false })
      .limit(1)
      .single()

    priceInfoModal.data = {
      last_unit_price: customerSale?.unit_price || 0,
      last_unit_cost: price?.harga_beli || 0,
      last_sale_qty: customerSale?.qty || 0,
      last_order_date: customerSale?.sale?.order_date || null,
    }
  } catch (err) {
    console.error('[showPriceInfo]', err)
  } finally {
    priceInfoModal.loading = false
  }
}

async function showPriceInfoPreview() {
  if (!newItem.product_id) {
    alert('Pilih barang terlebih dahulu')
    return
  }
  showPriceInfo({
    product_id: newItem.product_id,
    product_nama: newItem.product_nama,
  })
}

// ───────────────────────────────────────────────────────────
// NAVIGATION
// ───────────────────────────────────────────────────────────
function focusQty() {
  inputQty.value?.focus()
}

function focusPrice() {
  inputPrice.value?.focus()
}

function focusNextRow(currentIdx, field) {
  if (field === 'price') {
    // After price, go to next row's item input or add the item
    inputProduct.value?.focus()
  } else if (field === 'item') {
    // After item qty, go to price
    // This shouldn't happen in current flow
  }
}

// ───────────────────────────────────────────────────────────
// FORM SUBMIT
// ───────────────────────────────────────────────────────────
async function submitSale(shouldPrint = false) {
  if (items.value.length === 0) {
    alert('Tambahkan minimal 1 barang')
    return
  }

  // Final credit limit check
  const customer = orderData.value.customer
  const remainingCredit = customer.limit_kredit - customer.saldo_piutang
  
  if (subtotal.value > remainingCredit) {
    const confirm = window.confirm(
      `Total order melebihi sisa limit kredit customer!\n\n` +
      `Customer: ${customer.nama}\n` +
      `Limit Kredit: ${formatRp(customer.limit_kredit)}\n` +
      `Saldo Piutang: ${formatRp(customer.saldo_piutang)}\n` +
      `Sisa Limit: ${formatRp(remainingCredit)}\n` +
      `Total Order: ${formatRp(subtotal.value)}\n\n` +
      `Tetap lanjutkan?`
    )
    if (!confirm) return
  }

  saving.value = true

  try {
    const sale_id = orderData.value.sale_id

    if (!sale_id) {
      throw new Error('Sale ID tidak ditemukan. Silakan kembali ke Step 1.')
    }

    // Update sales header (from draft to completed)
    const { error: updateError } = await supabase
      .from('sales')
      .update({
        subtotal: subtotal.value,
        status: 'completed',
      })
      .eq('id', sale_id)

    if (updateError) throw updateError

    // Insert sale items
    const itemsPayload = items.value.map(item => ({
      sale_id: sale_id,
      product_id: item.product_id,
      product_kode: item.product_kode,
      product_nama: item.product_nama,
      qty: item.qty,
      unit_price: item.unit_price,
      total: item.total,
    }))

    const { error: itemsError } = await supabase
      .from('sale_items')
      .insert(itemsPayload)

    if (itemsError) throw itemsError

    // Deduct stock from warehouse for each item
    for (const item of items.value) {
      const { data: product, error: getError } = await supabase
        .from('products')
        .select('stok')
        .eq('id', item.product_id)
        .single()
      if (getError) throw getError
      const { error: updateError } = await supabase
        .from('products')
        .update({ stok: Math.max(0, (product.stok || 0) - item.qty) })
        .eq('id', item.product_id)
      if (updateError) throw updateError
    }

    // Clear session storage
    sessionStorage.removeItem('penjualan_draft')

    alert(
      `Order berhasil disimpan!\n\n` +
      `No. Order: ${orderData.value.no_order}\n` +
      `Customer: ${customer.nama}\n` +
      `Total: ${formatRp(subtotal.value)}\n` +
      `Items: ${items.value.length} barang`
    )

    // Print if requested (F10)
    if (shouldPrint) {
      printOrder(sale_id)
    }

    router.push('/penjualan')
  } catch (err) {
    console.error('[submitSale]', err)
    alert('Gagal menyimpan order: ' + err.message)
  } finally {
    saving.value = false
  }
}

function printOrder(sale_id) {
  // TODO: Implement print functionality
  // For now, just open print dialog
  window.print()
}

async function saveAsDraft() {
  if (items.value.length === 0) {
    sessionStorage.removeItem('penjualan_draft')
    return
  }

  try {
    const sale_id = orderData.value.sale_id
    if (!sale_id) return

    // Update sales with current items as draft
    const { error: updateError } = await supabase
      .from('sales')
      .update({
        subtotal: subtotal.value,
        status: 'draft',
      })
      .eq('id', sale_id)

    if (updateError) throw updateError

    // Insert/update sale items
    const itemsPayload = items.value.map(item => ({
      sale_id: sale_id,
      product_id: item.product_id,
      product_kode: item.product_kode,
      product_nama: item.product_nama,
      qty: item.qty,
      unit_price: item.unit_price,
      total: item.total,
    }))

    // Restore stock for currently saved items (in case of re-save)
    const { data: existingItems } = await supabase
      .from('sale_items')
      .select('product_id, qty')
      .eq('sale_id', sale_id)
    for (const existingItem of (existingItems || [])) {
      const { data: product } = await supabase
        .from('products')
        .select('stok')
        .eq('id', existingItem.product_id)
        .single()
      if (product) {
        await supabase
          .from('products')
          .update({ stok: (product.stok || 0) + existingItem.qty })
          .eq('id', existingItem.product_id)
      }
    }

    // Delete existing items first
    await supabase
      .from('sale_items')
      .delete()
      .eq('sale_id', sale_id)

    // Insert new items
    const { error: itemsError } = await supabase
      .from('sale_items')
      .insert(itemsPayload)

    if (itemsError) throw itemsError

    // Deduct stock from warehouse for each new item
    for (const item of items.value) {
      const { data: product, error: getError } = await supabase
        .from('products')
        .select('stok')
        .eq('id', item.product_id)
        .single()
      if (getError) throw getError
      const { error: updateError } = await supabase
        .from('products')
        .update({ stok: Math.max(0, (product.stok || 0) - item.qty) })
        .eq('id', item.product_id)
      if (updateError) throw updateError
    }

    console.log('Draft saved successfully')
  } catch (err) {
    console.error('[saveAsDraft]', err)
  }
}

function backToStep1() {
  // Always save as draft (keep the order) and return to menu
  saveAsDraft().then(() => {
    router.push('/penjualan')
  })
}

// ───────────────────────────────────────────────────────────
// HELPERS
// ───────────────────────────────────────────────────────────
function generatePreviewOrderNumber() {
  const year = new Date().getFullYear().toString().slice(-2)
  return `${year}XXXXX (Auto)`
}

function parseDateInput(dateStr) {
  // Parse DD/MM/YY to YYYY-MM-DD
  const parts = dateStr.split('/')
  if (parts.length === 3) {
    const day = parts[0].padStart(2, '0')
    const month = parts[1].padStart(2, '0')
    const year = '20' + parts[2]
    return `${year}-${month}-${day}`
  }
  return dateStr
}

function formatRp(val) {
  if (val == null || isNaN(val)) return 'Rp 0'
  return 'Rp ' + Number(val).toLocaleString('id-ID')
}
</script>

<style scoped>
@import '@/assets/styles.css';
@import '@/assets/components/table.css';
@import '@/assets/components/modal.css';
@import '@/assets/pages/penjualan/penjualan-input-page.css';
</style>
