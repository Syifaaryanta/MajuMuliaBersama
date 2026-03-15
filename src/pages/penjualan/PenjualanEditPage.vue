<template>
  <div class="penjualan-edit-page" ref="pageEl" tabindex="-1">

    <!-- ── SEARCH CARD ──────────────────────────────────── -->
    <div class="search-card" v-if="formVisible">
      <div class="form-header">
        <h1 class="form-header-title">Pemutakhiran Order Penjualan</h1>
        <p class="form-header-subtitle">Cari dan perbarui order penjualan yang sudah tersimpan</p>
      </div>
      <div class="search-body">
        <div class="search-input-wrap">
          <input
            ref="searchInput"
            v-model="searchQuery"
            type="text"
            class="search-input"
            placeholder="Ketik No. Order lalu tekan Enter..."
            @keydown.enter="searchOrder"
            @keydown.esc="handleSearchEsc"
            autocomplete="off"
          />
          <button 
            v-if="searchQuery" 
            class="clear-btn" 
            @click="clearSearch" 
            title="Clear (Esc)"
          >
            <i class="pi pi-times"></i>
          </button>
          <button 
            class="search-btn" 
            @click="searchOrder"
            :disabled="!searchQuery || loading"
            title="Cari (Enter)"
          >
            <i class="pi pi-search"></i>
            Cari
          </button>
        </div>
      </div>
    </div>

    <!-- ── LOADING STATE ──────────────────────────────────── -->
    <div v-if="loading" class="loading-state">
      <i class="pi pi-spin pi-spinner"></i>
      <p>Mencari order...</p>
    </div>

    <!-- ── NOT FOUND STATE ──────────────────────────────────── -->
    <div v-if="notFound && !loading" class="empty-state">
      <i class="pi pi-inbox"></i>
      <h3>Order tidak ditemukan</h3>
      <p>No. Order <strong>{{ searchQuery }}</strong> tidak ditemukan dalam database.</p>
      <button class="btn-secondary" @click="clearSearch">
        <i class="pi pi-search"></i>
        Cari Lagi
      </button>
    </div>

    <!-- ── EDIT FORM (when order found) ──────────────────────────────────── -->
    <div v-if="order && !loading" class="form-card">
      <div class="form-header">
        <div class="form-header-content">
          <h1 class="form-header-title">Pemutakhiran Informasi Order</h1>
          <p class="form-header-subtitle">Nomor Order: {{ order.no_order }}</p>
        </div>
        <div class="form-header-info">
          <div class="info-item">
            <span class="info-label">Tanggal:</span>
            <span class="info-value">{{ formatDate(order.order_date) }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Status:</span>
            <span class="status-badge" :class="`status-${order.status}`">
              {{ order.status === 'completed' ? 'Selesai' : 'Draft' }}
            </span>
          </div>
        </div>
      </div>

      <div class="order-form">
        
        <!-- Customer Info (Read-only) -->
        <div class="customer-card">
          <div class="customer-header">
            <i class="pi pi-user"></i>
            <span>Customer</span>
          </div>
          <div class="customer-body">
            <div class="customer-name">{{ order.customer.nama }}</div>
            <div class="customer-detail">
              <div class="detail-item">
                <i class="pi pi-map-marker"></i>
                <span>{{ order.customer.alamat || '—' }}</span>
              </div>
              <div class="detail-item">
                <i class="pi pi-phone"></i>
                <span>{{ order.customer.no_telp || '—' }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Items Table -->
        <div class="table-section">
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
                  <th class="col-qty">QTY</th>
                  <th class="col-price">Harga Satuan</th>
                  <th class="col-total">Total</th>
                  <th class="col-action">Aksi</th>
                </tr>
              </thead>
              <tbody>
                <!-- Existing Items -->
                <tr 
                  v-for="(item, idx) in items" 
                  :key="item.id"
                  class="item-row"
                >
                  <td class="col-no">{{ idx + 1 }}</td>
                  <td class="col-kode">
                    <span class="item-kode">{{ item.product_kode }}</span>
                  </td>
                  <td class="col-nama">{{ item.product_nama }}</td>
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
                      tabindex="-1"
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
                  </td>
                  <td class="col-total">
                    <span class="total-val total-preview">
                      {{ newItem.qty && newItem.unit_price ? formatRp(newItem.qty * newItem.unit_price) : '—' }}
                    </span>
                  </td>
                  <td class="col-action">—</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Shortcuts Bar -->
          <div class="shortcuts-bar">
            <kbd>Y</kbd>
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
                Tutup
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════
         MODAL SAVE CONFIRMATION
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="confirmModal.show" class="modal-overlay" @click.self="confirmModal.show = false">
          <div class="modal-box modal-box--sm" role="dialog">
            <div class="modal-header">
              <i class="pi pi-question-circle"></i>
              <h3 class="modal-title">Konfirmasi Simpan</h3>
            </div>
            <div class="modal-body">
              <p style="margin: 0; text-align: center;">Simpan perubahan order ini?</p>
            </div>
            <div class="modal-footer">
              <button 
                class="btn-secondary" 
                @click="confirmModal.show = false"
                ref="btnCancelConfirm"
              >
                Batal
              </button>
              <button 
                class="btn-primary" 
                @click="confirmSave"
                ref="btnConfirmSave"
              >
                Simpan Order
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
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const pageEl = ref(null)
const searchInput = ref(null)
const inputProduct = ref(null)
const inputQty = ref(null)
const inputPrice = ref(null)
const productModalInput = ref(null)
const btnCancelConfirm = ref(null)
const btnConfirmSave = ref(null)

// ───────────────────────────────────────────────────────────
// STATE
// ───────────────────────────────────────────────────────────
const searchQuery = ref('')
const loading = ref(false)
const notFound = ref(false)
const saving = ref(false)
const formVisible = ref(true)

const order = ref(null)
const items = ref([])
const originalItems = ref([]) // Store original items for stock restoration

// Dynamic refs for table navigation
const qtyRefs = ref({})
const priceRefs = ref({})

// New item state
const newItem = reactive({
  search: '',
  product_id: null,
  product_kode: '',
  product_nama: '',
  qty: 1,
  unit_price: 0,
  total: 0,
  stok_available: 0
})

// Product modal
const productModal = reactive({
  show: false,
  query: '',
  results: [],
  filtered: [],
  selectedIndex: 0
})

// Price info modal
const priceInfoModal = reactive({
  show: false,
  product_id: null,
  product_nama: '',
  loading: false,
  data: {
    last_unit_price: 0,
    last_unit_cost: 0,
    last_sale_qty: 0,
    last_order_date: null
  }
})

// Confirmation modal
const confirmModal = reactive({
  show: false
})

// ───────────────────────────────────────────────────────────
// COMPUTED
// ───────────────────────────────────────────────────────────
const subtotal = computed(() => {
  return items.value.reduce((sum, item) => sum + (item.total || 0), 0)
})

// ───────────────────────────────────────────────────────────
// REFS MANAGEMENT
// ───────────────────────────────────────────────────────────
function setQtyRef(el, idx) {
  if (el) qtyRefs.value[idx] = el
}

function setPriceRef(el, idx) {
  if (el) priceRefs.value[idx] = el
}

// ───────────────────────────────────────────────────────────
// KEYBOARD NAVIGATION - TABLE
// ───────────────────────────────────────────────────────────
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
      // Move to next row or new item
      if (rowIdx < totalRows - 1) {
        qtyRefs.value[rowIdx + 1]?.focus()
      } else {
        inputProduct.value?.focus()
      }
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

  // Arrow Left - move from price to qty
  if (e.key === 'ArrowLeft' && field === 'price') {
    if (e.ctrlKey || e.target.selectionStart === 0) {
      e.preventDefault()
      qtyRefs.value[rowIdx]?.focus()
      return
    }
  }

  // Arrow Right - move from qty to price
  if (e.key === 'ArrowRight' && field === 'qty') {
    if (e.ctrlKey || e.target.selectionStart === e.target.value.length) {
      e.preventDefault()
      priceRefs.value[rowIdx]?.focus()
      return
    }
  }
}

// ───────────────────────────────────────────────────────────
// KEYBOARD NAVIGATION - NEW ITEM
// ───────────────────────────────────────────────────────────
function handleNewItemKeydown(e, field) {
  // Backspace - go back to last item when field is empty
  if (e.key === 'Backspace' && !e.target.value) {
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

  // Arrow Right - move to next field
  if (e.key === 'ArrowRight') {
    if (field === 'qty' && (e.ctrlKey || e.target.selectionStart === e.target.value.length)) {
      e.preventDefault()
      inputPrice.value?.focus()
      return
    }
  }

  // Arrow Left - move to previous field
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

// ───────────────────────────────────────────────────────────
// GLOBAL KEY HANDLER
// ───────────────────────────────────────────────────────────
function onGlobalKey(e) {
  // Ignore if modal is open
  if (productModal.show || priceInfoModal.show || confirmModal.show) return
  
  // Ignore if typing in input (let input handler handle it)
  if (e.target.tagName === 'INPUT') {
    // Allow Y to work even in inputs
    if (e.key.toLowerCase() !== 'y') return
  }
  
  // ESC - Show form and hide order info (when editing order)
  if (e.key === 'Escape' && order.value && !formVisible.value) {
    e.preventDefault()
    e.stopPropagation()
    formVisible.value = true
    order.value = null
    items.value = []
    nextTick(() => {
      searchInput.value?.focus()
    })
    return
  }

  // Y - Save order
  if (e.key.toLowerCase() === 'y' && items.value.length > 0) {
    e.preventDefault()
    showConfirmModal()
  }
}

// ───────────────────────────────────────────────────────────
// SEARCH ORDER
// ───────────────────────────────────────────────────────────
async function searchOrder() {
  if (!searchQuery.value.trim()) return
  
  loading.value = true
  notFound.value = false
  order.value = null
  items.value = []
  
  try {
    // Search order
    const { data: orderData, error: orderError } = await supabase
      .from('sales')
      .select(`
        *,
        customer:customers(id, kode, nama, alamat, no_telp)
      `)
      .eq('no_order', searchQuery.value.trim())
      .single()
    
    if (orderError || !orderData) {
      console.error('Order error:', orderError)
      notFound.value = true
      return
    }
    
    order.value = orderData
    
    // Load order items with product info
    const { data: itemsData, error: itemsError } = await supabase
      .from('sale_items')
      .select(`
        *,
        product:products(kode, nama, stok)
      `)
      .eq('sale_id', orderData.id)
    
    console.log('Items query result:', { itemsData, itemsError })
    
    if (itemsError) {
      console.error('Error loading items:', itemsError)
      throw itemsError
    }
    
    if (!itemsData || itemsData.length === 0) {
      alert('Order tidak memiliki item yang dapat diedit')
      notFound.value = true
      return
    }
    
    items.value = itemsData.map(item => ({
      ...item,
      product_id: item.product_id,
      product_kode: item.product_kode,
      product_nama: item.product_nama,
      product_stok: item.product?.stok || 0,
      stok_available: item.product?.stok || 0,
      total: item.qty * item.unit_price
    }))
    
    console.log('Items loaded:', items.value.length, items.value)
    
    // Store original items for stock restoration
    originalItems.value = JSON.parse(JSON.stringify(itemsData.map(item => ({
      product_id: item.product_id,
      qty: item.qty
    }))))

    // Hide search form after order loads
    formVisible.value = false
    
    // Focus first qty input after loading
    await nextTick()
    setTimeout(() => {
      if (items.value.length > 0 && qtyRefs.value[0]) {
        qtyRefs.value[0].focus()
      }
    }, 100)
    
  } catch (error) {
    console.error('Error searching order:', error)
    notFound.value = true
  } finally {
    loading.value = false
  }
}

function clearSearch() {
  // If search is already empty, go back to menu
  if (!searchQuery.value && !order.value) {
    router.push('/penjualan')
    return
  }
  
  // Otherwise, just clear the search
  searchQuery.value = ''
  order.value = null
  items.value = []
  originalItems.value = []
  notFound.value = false
  formVisible.value = true
  nextTick(() => {
    searchInput.value?.focus()
  })
}

function handleSearchEsc(e) {
  e.preventDefault()
  e.stopPropagation()
  
  // If search input is empty, go back to menu
  if (!searchQuery.value.trim()) {
    router.push('/penjualan')
    return
  }
  
  // Otherwise, clear the search
  searchQuery.value = ''
  nextTick(() => {
    searchInput.value?.focus()
  })
}

// ───────────────────────────────────────────────────────────
// ITEM CALCULATIONS
// ───────────────────────────────────────────────────────────
function updateItemTotal(idx) {
  const item = items.value[idx]
  item.total = item.qty * item.unit_price
}

function updateItemPrice(idx, event) {
  const rawValue = event.target.value.replace(/\D/g, '')
  const price = rawValue ? parseInt(rawValue) : 0
  items.value[idx].unit_price = price
  updateItemTotal(idx)
}

function removeItem(idx) {
  items.value.splice(idx, 1)
  nextTick(() => {
    if (items.value.length > 0) {
      const targetIdx = Math.min(idx, items.value.length - 1)
      qtyRefs.value[targetIdx]?.focus()
    } else {
      inputProduct.value?.focus()
    }
  })
}

// ───────────────────────────────────────────────────────────
// PRODUCT SEARCH
// ───────────────────────────────────────────────────────────
async function openProductModal() {
  if (!newItem.search.trim()) return
  
  const { data } = await supabase
    .from('products')
    .select('*')
    .or(`kode.ilike.%${newItem.search}%,nama.ilike.%${newItem.search}%`)
    .eq('is_archived', false)
    .limit(20)
  
  productModal.results = data || []
  productModal.filtered = productModal.results
  productModal.query = ''
  productModal.selectedIndex = 0
  productModal.show = true
  
  nextTick(() => {
    productModalInput.value?.focus()
  })
}

function filterProductModal() {
  if (!productModal.query) {
    productModal.filtered = productModal.results
  } else {
    const q = productModal.query.toLowerCase()
    productModal.filtered = productModal.results.filter(p => 
      p.kode.toLowerCase().includes(q) || p.nama.toLowerCase().includes(q)
    )
  }
  productModal.selectedIndex = 0
}

function onProductModalKey(e) {
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    productModal.selectedIndex = Math.min(
      productModal.selectedIndex + 1,
      productModal.filtered.length - 1
    )
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    productModal.selectedIndex = Math.max(productModal.selectedIndex - 1, 0)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (productModal.filtered[productModal.selectedIndex]) {
      selectProduct(productModal.filtered[productModal.selectedIndex])
    }
  } else if (e.key === 'Escape') {
    e.preventDefault()
    productModal.show = false
    nextTick(() => inputProduct.value?.focus())
  }
}

function selectProduct(product) {
  newItem.product_id = product.id
  newItem.product_kode = product.kode
  newItem.product_nama = product.nama
  newItem.search = `${product.kode} - ${product.nama}`
  newItem.unit_price = product.harga_jual || 0
  newItem.stok_available = product.stok || 0
  
  productModal.show = false
  
  nextTick(() => {
    inputQty.value?.removeAttribute('disabled')
    inputQty.value?.focus()
  })
}

function focusPrice() {
  inputPrice.value?.removeAttribute('disabled')
  nextTick(() => {
    inputPrice.value?.focus()
  })
}

function formatNewItemPrice(e) {
  const rawValue = e.target.value.replace(/\D/g, '')
  newItem.unit_price = rawValue ? parseInt(rawValue) : 0
}

function addItem() {
  if (!newItem.product_id || !newItem.qty || !newItem.unit_price) return
  
  items.value.push({
    id: Date.now(), // temporary id for new items
    product_id: newItem.product_id,
    product_kode: newItem.product_kode,
    product_nama: newItem.product_nama,
    qty: newItem.qty,
    unit_price: newItem.unit_price,
    total: newItem.qty * newItem.unit_price,
    stok_available: newItem.stok_available,
    is_new: true // flag for new items
  })
  
  // Reset new item
  newItem.search = ''
  newItem.product_id = null
  newItem.product_kode = ''
  newItem.product_nama = ''
  newItem.qty = 1
  newItem.unit_price = 0
  newItem.total = 0
  newItem.stok_available = 0
  
  nextTick(() => {
    const lastIdx = items.value.length - 1
    qtyRefs.value[lastIdx]?.focus()
  })
}

// ───────────────────────────────────────────────────────────
// PRICE INFO
// ───────────────────────────────────────────────────────────
async function showPriceInfo(item) {
  if (!item.product_id || !order.value?.customer_id) return
  
  priceInfoModal.show = true
  priceInfoModal.product_id = item.product_id
  priceInfoModal.product_nama = item.product_nama
  priceInfoModal.loading = true
  
  try {
    // Get last sale to this customer
    const { data: lastSale } = await supabase
      .from('sale_items')
      .select('unit_price, qty, sale:sales(order_date)')
      .eq('product_id', item.product_id)
      .eq('sales.customer_id', order.value.customer_id)
      .order('created_at', { ascending: false })
      .limit(1)
      .single()
    
    // Get last purchase price
    const { data: lastPurchase } = await supabase
      .from('purchase_items')
      .select('unit_cost')
      .eq('product_id', item.product_id)
      .order('created_at', { ascending: false })
      .limit(1)
      .single()
    
    priceInfoModal.data = {
      last_unit_price: lastSale?.unit_price || 0,
      last_unit_cost: lastPurchase?.unit_cost || 0,
      last_sale_qty: lastSale?.qty || 0,
      last_order_date: lastSale?.sale?.order_date || null
    }
  } catch (error) {
    console.error('Error loading price info:', error)
  } finally {
    priceInfoModal.loading = false
  }
}

// ───────────────────────────────────────────────────────────
// SAVE ORDER
// ───────────────────────────────────────────────────────────
function showConfirmModal() {
  confirmModal.show = true
  nextTick(() => {
    btnConfirmSave.value?.focus()
  })
}

async function confirmSave() {
  console.log('confirmSave called - items.value:', items.value)
  console.log('items.value.length:', items.value.length)
  
  if (items.value.length === 0) {
    alert('Order harus memiliki minimal 1 item')
    return
  }
  
  confirmModal.show = false
  saving.value = true
  
  try {
    const oldStatus = order.value.status
    
    // STOCK MANAGEMENT LOGIC
    // If order was 'completed' or 'draft' (draft also deducts stock), restore old stock first
    if ((oldStatus === 'completed' || oldStatus === 'draft') && originalItems.value.length > 0) {
      for (const oldItem of originalItems.value) {
        // Restore stock (add back the old qty) - manual update
        const { data: product, error: getError } = await supabase
          .from('products')
          .select('stok')
          .eq('id', oldItem.product_id)
          .single()
        
        if (getError) throw getError
        
        const { error: updateError } = await supabase
          .from('products')
          .update({ stok: (product.stok || 0) + oldItem.qty })
          .eq('id', oldItem.product_id)
        
        if (updateError) throw updateError
      }
    }
    
    // Now deduct stock for NEW items (always, because status becomes 'completed')
    for (const item of items.value) {
      // Deduct stock - manual update
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
    
    // Update order header - set status to 'completed' after edit
    const { error: orderError } = await supabase
      .from('sales')
      .update({
        subtotal: subtotal.value,
        status: 'completed' // Always set to completed after editing
      })
      .eq('id', order.value.id)
    
    if (orderError) throw orderError
    
    // Delete all existing items
    await supabase
      .from('sale_items')
      .delete()
      .eq('sale_id', order.value.id)
    
    // Insert all items (existing + new)
    const itemsToInsert = items.value.map(item => ({
      sale_id: order.value.id,
      product_id: item.product_id,
      product_kode: item.product_kode,
      product_nama: item.product_nama,
      qty: item.qty,
      unit_price: item.unit_price,
      total: item.total
    }))
    
    const { error: itemsError } = await supabase
      .from('sale_items')
      .insert(itemsToInsert)
    
    if (itemsError) throw itemsError
    
    // Show search form again after save
    formVisible.value = true
    order.value = null
    items.value = []
    searchQuery.value = ''
    
    // Focus search input
    nextTick(() => {
      searchInput.value?.focus()
    })
    
  } catch (error) {
    console.error('Error saving order:', error)
    console.error('Error details:', error.message, error.code, error)
    alert(`Gagal menyimpan perubahan: ${error.message || error}`)
  } finally {
    saving.value = false
  }
}

// ───────────────────────────────────────────────────────────
// FORMATTING
// ───────────────────────────────────────────────────────────
function formatRp(value) {
  if (!value) return 'Rp 0'
  return `Rp ${value.toLocaleString('id-ID')}`
}

function formatNumber(value) {
  if (!value) return ''
  return value.toLocaleString('id-ID')
}

function formatDate(dateString) {
  if (!dateString) return '—'
  const date = new Date(dateString)
  const day = String(date.getDate()).padStart(2, '0')
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const year = String(date.getFullYear()).slice(-2)
  return `${day}/${month}/${year}`
}

// ───────────────────────────────────────────────────────────
// LIFECYCLE
// ───────────────────────────────────────────────────────────
onMounted(() => {
  document.addEventListener('keydown', onGlobalKey)
  nextTick(() => {
    searchInput.value?.focus()
  })
})

onUnmounted(() => {
  document.removeEventListener('keydown', onGlobalKey)
})

// Watch for confirmation modal keyboard events
watch(() => confirmModal.show, (show) => {
  if (show) {
    const handleConfirmKey = (e) => {
      if (e.key === 'Enter') {
        e.preventDefault()
        confirmSave()
      } else if (e.key === 'Escape') {
        e.preventDefault()
        confirmModal.show = false
      }
    }
    document.addEventListener('keydown', handleConfirmKey)
    return () => document.removeEventListener('keydown', handleConfirmKey)
  }
})
</script>

<style src="@/assets/pages/penjualan/penjualan-edit-page.css"></style>
<style src="@/assets/components/modal.css"></style>
