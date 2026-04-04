<template>
  <div class="penjualan-edit-page" :class="{ 'penjualan-edit-page--search-only': formVisible }" ref="pageEl" tabindex="-1">
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="formVisible" class="modal-overlay modal-overlay--transparent" @click.self="clearSearch">
          <form class="modal-box modal-box--filter" @submit.prevent="submitSearchModal">
            <div class="modal-header modal-header--blue">
              <div class="modal-header-left">
                <div class="modal-header-icon">
                  <i class="pi pi-filter"></i>
                </div>
                <h3 class="modal-title">Filter Edit Order Pembelian</h3>
              </div>
            </div>

            <div class="modal-body">
              <p class="modal-helper">Isi No. Order lalu tekan Enter.</p>

              <div class="filter-modal-grid">
                <div class="search-field">
                  <label class="search-label">
                    <i class="pi pi-hashtag"></i>
                    No. Order
                  </label>
                  <input
                    ref="searchInput"
                    v-model="searchQuery"
                    type="text"
                    class="search-input"
                    placeholder="Ketik No. Order lalu tekan Enter..."
                    autocomplete="off"
                    @keydown.enter.prevent="submitSearchModal"
                    @keydown.esc="handleSearchEsc"
                  />
                </div>
              </div>

              <p v-if="searchModalError" class="modal-error-inline">{{ searchModalError }}</p>
            </div>

            <div class="modal-footer">
              <button type="button" class="btn-secondary" @click="clearSearch">Batal</button>
              <button type="submit" class="btn-primary" :disabled="loading || !searchQuery.trim()">
                <i class="pi pi-check"></i>
                <span>Enter</span>
              </button>
            </div>
          </form>
        </div>
      </Transition>
    </Teleport>

    <div v-if="loading" class="loading-state">
      <i class="pi pi-spin pi-spinner"></i>
      <p>Mencari order...</p>
    </div>

    <div v-if="notFound && !loading && !formVisible" class="empty-state">
      <i class="pi pi-inbox"></i>
      <h3>Order tidak ditemukan</h3>
      <p>No. Order <strong>{{ searchQuery }}</strong> tidak ditemukan.</p>
      <button class="btn-secondary" @click="clearSearch">
        <i class="pi pi-search"></i>
        Cari Lagi
      </button>
    </div>

    <div v-if="order && !loading" class="form-card">
      <div class="form-header">
        <div class="form-header-content">
          <h1 class="form-header-title">Edit Order Pembelian</h1>
          <p class="form-header-subtitle">No. Order: {{ order.no_order }}</p>
        </div>
        <div class="form-header-info">
          <div class="info-item">
            <span class="info-label">Tanggal:</span>
            <span class="info-value">{{ formatDate(order.order_date) }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Status:</span>
            <span class="status-badge" :class="statusClass(order.status)">
              {{ statusLabel(order.status) }}
            </span>
          </div>
        </div>
      </div>

      <div class="order-form">
        <div class="customer-card">
          <div class="customer-header">
            <i class="pi pi-truck"></i>
            <span>Supplier</span>
          </div>
          <div class="customer-body">
            <div class="customer-name">{{ order.supplier?.nama || '-' }}</div>
            <div class="customer-detail">
              <div class="detail-item">
                <i class="pi pi-map-marker"></i>
                <span>{{ order.supplier?.alamat || '—' }}</span>
              </div>
              <div class="detail-item">
                <i class="pi pi-phone"></i>
                <span>{{ order.supplier?.no_telp || '—' }}</span>
              </div>
            </div>
          </div>
        </div>

        <div class="shortcuts-bar">
          <kbd>F2 Barang</kbd>
          <kbd>F4 Info</kbd>
          <kbd>F10 Simpan</kbd>
          <kbd>Del Hapus</kbd>
        </div>

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
                <tr v-for="(item, idx) in items" :key="`${item.product_id}-${idx}`" class="item-row">
                  <td class="col-no">{{ idx + 1 }}</td>
                  <td class="col-kode">
                    <span class="item-kode">{{ item.product_kode }}</span>
                  </td>
                  <td class="col-nama">
                    <input
                      :ref="el => setNameRef(el, idx)"
                      :value="item.product_nama"
                      type="text"
                      class="item-input item-input--inline"
                      readonly
                      title="Enter untuk ganti barang"
                      @keydown="handleNameKeydown($event, idx)"
                      @dblclick="openEditProductModal(idx)"
                    />
                  </td>
                  <td class="col-qty">
                    <input
                      :ref="el => setQtyRef(el, idx)"
                      v-model.number="item.qty"
                      type="number"
                      class="qty-input"
                      min="0.01"
                      step="any"
                      @input="updateItemTotal(idx)"
                      @keydown="handleTableKeydown($event, idx, 'qty')"
                    />
                  </td>
                  <td class="col-price">
                    <input
                      :ref="el => setPriceRef(el, idx)"
                      :value="formatNumber(item.unit_cost)"
                      type="text"
                      class="price-input"
                      @input="updateItemPrice(idx, $event)"
                      @keydown="handleTableKeydown($event, idx, 'price')"
                    />
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

                <tr class="item-row item-row--new">
                  <td class="col-no">{{ items.length + 1 }}</td>
                  <td class="col-kode" colspan="2">
                    <div class="search-input-wrap">
                      <input
                        ref="inputProduct"
                        v-model="newItem.search"
                        type="text"
                        class="item-input"
                        placeholder="Ketik nama barang lalu Enter"
                        @keydown.enter.prevent="onProductEnter"
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
                      min="0.01"
                      step="any"
                      placeholder="0"
                      @keydown.enter.prevent="focusPrice"
                      @keydown="handleNewItemKeydown($event, 'qty')"
                      :disabled="!newItem.product_id"
                    />
                  </td>
                  <td class="col-price">
                    <input
                      ref="inputPrice"
                      :value="newItem.unit_cost ? formatNumber(newItem.unit_cost) : ''"
                      type="text"
                      class="price-input"
                      placeholder="Harga satuan"
                      @input="formatNewItemPrice"
                      @keydown.enter.prevent="addItem"
                      @keydown="handleNewItemKeydown($event, 'price')"
                      :disabled="!newItem.product_id"
                    />
                  </td>
                  <td class="col-total">
                    <span class="total-val total-preview">
                      {{ newItem.unit_cost ? formatRp(newItem.qty * newItem.unit_cost) : '—' }}
                    </span>
                  </td>
                  <td class="col-action">—</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="table-footer">
            <div class="subtotal-row">
              <span class="subtotal-label">Subtotal:</span>
              <span class="subtotal-value">{{ formatRp(subtotal) }}</span>
            </div>
          </div>

          <div class="table-enter-row">
            <button class="btn-primary table-enter-btn" @click="saveOrder" :disabled="saving">
              Simpan
            </button>
          </div>
        </div>
      </div>
    </div>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="productModal.show" class="modal-overlay" @click.self="closeProductModal">
          <div class="modal-box modal-search" role="dialog" tabindex="0">
            <div class="modal-header modal-header--blue">
              <i class="pi pi-search"></i>
              <h3 class="modal-title">Pilih Barang</h3>
              <button class="modal-close" @click="closeProductModal" tabindex="-1">
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
                    <span>Stok saat ini: <strong>{{ item.stok }}</strong></span>
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

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="priceHistoryModal.show" class="modal-overlay" @click.self="closePriceHistoryModal">
          <div class="modal-box modal-box--md" role="dialog">
            <div class="modal-header modal-header--blue">
              <i class="pi pi-tags"></i>
              <h3 class="modal-title">Info Harga: {{ priceHistoryModal.productName || '-' }}</h3>
              <button class="modal-close" @click="closePriceHistoryModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <div class="price-info-grid">
                <div class="price-info-card">
                  <div class="pic-label">Supplier Aktif</div>
                  <div class="pic-value">{{ priceHistoryModal.currentSupplierName || '-' }}</div>
                </div>
                <div class="price-info-card">
                  <div class="pic-label">Harga Sebelumnya</div>
                  <div class="pic-value">{{ formatRp(priceHistoryModal.previousPrice) }}</div>
                </div>
                <div class="price-info-card">
                  <div class="pic-label">Last Order Date</div>
                  <div class="pic-value">{{ formatDateDisplay(priceHistoryModal.lastOrderDate) }}</div>
                </div>
              </div>

              <div class="price-history-table-wrap" v-if="priceHistoryTableRows.length">
                <table class="price-history-table">
                  <thead>
                    <tr>
                      <th>Supplier</th>
                      <th>Harga Terakhir</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(row, idx) in priceHistoryTableRows" :key="`${row.supplier_id || row.supplier_nama}-${idx}`">
                      <td>{{ row.supplier_nama || '-' }}</td>
                      <td>{{ formatRp(row.harga_beli) }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div v-else class="price-history-empty">Tidak ada data supplier lain untuk perbandingan harga.</div>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="closePriceHistoryModal">Tutup</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="confirmModal" class="modal-overlay" @click.self="confirmModal = false">
          <div class="modal-box modal-box--sm" role="dialog">
            <div class="modal-header modal-header--blue">
              <i class="pi pi-check-circle"></i>
              <h3 class="modal-title">Simpan Perubahan?</h3>
              <button class="modal-close" @click="confirmModal = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <p class="confirm-text" >Perubahan item pembelian akan disimpan dan order akan masuk ke receiving.</p>
              <p class="confirm-subtext"></p>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="confirmModal = false">Batal (Esc)</button>
              <button class="btn-primary" @click="confirmSave">Simpan (Enter)</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="draftConfirmModal.show" class="modal-overlay" @click.self="closeDraftConfirmModal">
          <div class="modal-box modal-box--sm" role="dialog">
            <div class="modal-header modal-header--danger">
              <i class="pi pi-exclamation-triangle"></i>
              <h3 class="modal-title">Keluar Dari Edit?</h3>
              <button class="modal-close" @click="closeDraftConfirmModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <p class="confirm-text">Perubahan akan disimpan sebagai draft.</p>
              <p class="confirm-subtext"></p>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="closeDraftConfirmModal">Batal (Esc)</button>
              <button class="btn-primary" @click="saveAsDraftAndBack">Simpan Draft (Enter/Y)</button>
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
import { getPurchaseOrderByNo, upsertPurchaseOrder } from '@/lib/pembelianStore'

const PEMBELIAN_FLASH_KEY = 'pembelian_flash_notice'
const EDIT_WORKING_STATE_KEY = 'pembelian_edit_working_state'
const router = useRouter()
const pageEl = ref(null)
const searchInput = ref(null)
const inputProduct = ref(null)
const inputQty = ref(null)
const inputPrice = ref(null)
const productModalInput = ref(null)
const nameRefs = ref({})
const qtyRefs = ref({})
const priceRefs = ref({})
const priceHistoryReturnFocusEl = ref(null)
const productModalReturnFocusEl = ref(null)

const searchQuery = ref('')
const searchModalError = ref('')
const loading = ref(false)
const notFound = ref(false)
const saving = ref(false)
const formVisible = ref(true)

const order = ref(null)
const items = ref([])
const confirmModal = ref(false)

const newItem = reactive({
  search: '',
  product_id: null,
  product_kode: '',
  product_nama: '',
  qty: 1,
  unit_cost: 0,
})

const productModal = reactive({
  show: false,
  results: [],
  filtered: [],
  query: '',
  selectedIndex: 0,
  mode: 'new',
  editIndex: null,
})

const priceHistoryModal = reactive({
  show: false,
  loading: false,
  productName: '',
  currentSupplierName: '',
  previousPrice: 0,
  lastOrderDate: null,
  comparisons: [],
})

const draftConfirmModal = reactive({
  show: false,
})

const subtotal = computed(() => items.value.reduce((sum, item) => sum + Number(item.total || 0), 0))
const priceHistoryTableRows = computed(() =>
  (priceHistoryModal.comparisons || []).filter(row => !row.is_current)
)

function statusClass(status) {
  return status === 'received' ? 'status-completed' : 'status-draft'
}

function statusLabel(status) {
  if (status === 'received') return 'Received'
  if (status === 'ordered') return 'Ordered'
  return 'Draft'
}

function setQtyRef(el, idx) {
  if (el) qtyRefs.value[idx] = el
}

function setPriceRef(el, idx) {
  if (el) priceRefs.value[idx] = el
}

function setNameRef(el, idx) {
  if (el) nameRefs.value[idx] = el
}

function focusFirstItemNameOrNewInput() {
  nextTick(() => {
    const focusTarget = () => {
      if (items.value.length > 0) {
        nameRefs.value[0]?.focus()
        nameRefs.value[0]?.select?.()
        return
      }
      focusProductInput()
    }

    focusTarget()
    setTimeout(focusTarget, 80)
  })
}

function focusProductInput() {
  nextTick(() => {
    inputProduct.value?.focus()
    inputProduct.value?.select?.()
  })
}

function focusNameInputByActiveRow() {
  const activeEl = document.activeElement
  if (!activeEl) return false

  for (let idx = 0; idx < items.value.length; idx += 1) {
    if (
      nameRefs.value[idx] === activeEl ||
      qtyRefs.value[idx] === activeEl ||
      priceRefs.value[idx] === activeEl
    ) {
      nextTick(() => {
        nameRefs.value[idx]?.focus()
        nameRefs.value[idx]?.select?.()
      })
      return true
    }
  }

  return false
}

function focusPrice() {
  inputPrice.value?.focus()
}

function handleTableKeydown(e, idx, field) {
  if (e.key === 'Delete') {
    e.preventDefault()
    removeItem(idx)
    return
  }

  if (e.key === 'F4' && field === 'price') {
    e.preventDefault()
    const row = items.value[idx]
    if (!row?.product_id) return
    openPriceHistoryModal(row, priceRefs.value[idx])
    return
  }

  if (e.key === 'ArrowDown') {
    e.preventDefault()
    if (idx < items.value.length - 1) {
      if (field === 'qty') qtyRefs.value[idx + 1]?.focus()
      if (field === 'price') priceRefs.value[idx + 1]?.focus()
      return
    }

    if (field === 'qty') inputQty.value?.focus()
    if (field === 'price') inputPrice.value?.focus()
    return
  }

  if (e.key === 'ArrowUp') {
    e.preventDefault()
    if (idx > 0) {
      if (field === 'qty') qtyRefs.value[idx - 1]?.focus()
      if (field === 'price') priceRefs.value[idx - 1]?.focus()
      return
    }

    inputProduct.value?.focus()
    return
  }

  if (e.key === 'ArrowRight' && field === 'qty') {
    e.preventDefault()
    priceRefs.value[idx]?.focus()
    return
  }

  if (e.key === 'ArrowLeft' && field === 'price') {
    e.preventDefault()
    qtyRefs.value[idx]?.focus()
    return
  }

  if (e.key === 'Enter') {
    e.preventDefault()
    if (field === 'qty') {
      priceRefs.value[idx]?.focus()
    } else if (idx < items.value.length - 1) {
      qtyRefs.value[idx + 1]?.focus()
    } else {
      inputProduct.value?.focus()
    }
  }
}

function handleNameKeydown(e, idx) {
  if (e.key === 'Enter') {
    e.preventDefault()
    openEditProductModal(idx)
    return
  }

  if (e.key === 'Delete') {
    e.preventDefault()
    removeItem(idx)
    return
  }

  if (e.key === 'F4') {
    e.preventDefault()
    const row = items.value[idx]
    if (!row?.product_id) return
    openPriceHistoryModal(row, nameRefs.value[idx])
    return
  }

  if (e.key === 'ArrowRight') {
    e.preventDefault()
    qtyRefs.value[idx]?.focus()
    return
  }

  if (e.key === 'ArrowDown') {
    e.preventDefault()
    if (idx < items.value.length - 1) {
      nameRefs.value[idx + 1]?.focus()
    } else {
      inputProduct.value?.focus()
    }
    return
  }

  if (e.key === 'ArrowUp') {
    e.preventDefault()
    if (idx > 0) {
      nameRefs.value[idx - 1]?.focus()
    }
  }
}

function handleNewItemKeydown(e, field) {
  if (e.key === 'F4' && field === 'price') {
    e.preventDefault()
    if (!newItem.product_id) {
      alert('Pilih barang dulu sebelum melihat info harga.')
      return
    }
    openPriceHistoryModal(newItem, inputPrice.value)
    return
  }

  if (e.key === 'ArrowUp') {
    e.preventDefault()
    const lastIdx = items.value.length - 1
    if (lastIdx < 0) return

    if (field === 'product' || field === 'price') {
      priceRefs.value[lastIdx]?.focus()
      return
    }

    qtyRefs.value[lastIdx]?.focus()
    return
  }

  if (e.key === 'ArrowRight' && field === 'qty') {
    e.preventDefault()
    inputPrice.value?.focus()
    return
  }

  if (e.key === 'ArrowLeft') {
    if (field === 'price') {
      e.preventDefault()
      inputQty.value?.focus()
      return
    }
    if (field === 'qty') {
      e.preventDefault()
      inputProduct.value?.focus()
    }
  }
}

function onGlobalKey(e) {
  if (e.defaultPrevented) return

  if (confirmModal.value) {
    if (e.key === 'Enter') {
      e.preventDefault()
      confirmSave()
      return
    }
    if (e.key === 'Escape') {
      e.preventDefault()
      confirmModal.value = false
      return
    }
    return
  }

  if (draftConfirmModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      closeDraftConfirmModal()
      return
    }
    if (e.key === 'Enter' || e.key === 'y' || e.key === 'Y') {
      e.preventDefault()
      saveAsDraftAndBack()
      return
    }
    return
  }

  if (priceHistoryModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      closePriceHistoryModal()
    }
    return
  }

  if (productModal.show) {
    return
  }

  if (formVisible.value) {
    if (e.key === 'Escape') {
      e.preventDefault()
      clearSearch()
    }
    return
  }

  if (!order.value) return

  const isActionShortcut =
    e.key === 'F2' ||
    e.key === 'F10' ||
    e.key === 'Escape' ||
    (e.ctrlKey && e.key.toLowerCase() === 's')

  if (e.target?.tagName === 'INPUT' && !isActionShortcut) {
    return
  }

  if (e.key === 'Escape') {
    e.preventDefault()
    openDraftConfirmModal()
    return
  }

  if (e.key === 'F2') {
    e.preventDefault()
    if (!focusNameInputByActiveRow()) {
      focusProductInput()
    }
    return
  }

  if (e.key === 'F10') {
    e.preventDefault()
    saveOrder()
    return
  }

  if (e.ctrlKey && e.key.toLowerCase() === 's') {
    e.preventDefault()
    saveOrder()
  }
}

async function searchOrder() {
  if (!searchQuery.value.trim()) return

  searchModalError.value = ''
  loading.value = true
  notFound.value = false
  order.value = null
  items.value = []

  try {
    const row = await getPurchaseOrderByNo(searchQuery.value.trim())
    if (!row) {
      notFound.value = true
      formVisible.value = false
      searchModalError.value = 'Order tidak ditemukan. Pastikan No. Order benar.'
      return
    }

    order.value = row
    items.value = JSON.parse(JSON.stringify(row.items || [])).map(item => ({
      ...item,
      qty: Number(item.qty || 0),
      unit_cost: Number(item.unit_cost || 0),
      total: Number(item.total || Number(item.qty || 0) * Number(item.unit_cost || 0)),
    }))

    formVisible.value = false
    await nextTick()
    focusFirstItemNameOrNewInput()
  } catch (err) {
    console.error('[searchOrder edit pembelian]', err)
    notFound.value = true
    formVisible.value = false
    searchModalError.value = 'Gagal memuat order dari database.'
  } finally {
    loading.value = false
  }
}

async function submitSearchModal() {
  if (!searchQuery.value.trim()) {
    searchModalError.value = 'No. Order wajib diisi.'
    nextTick(() => searchInput.value?.focus())
    return
  }

  await searchOrder()
}

function clearSearch() {
  if (!searchQuery.value && !order.value) {
    clearWorkingState()
    router.push('/pembelian')
    return
  }

  searchQuery.value = ''
  searchModalError.value = ''
  order.value = null
  items.value = []
  notFound.value = false
  formVisible.value = true
  resetNewItem()
  clearWorkingState()
  nextTick(() => searchInput.value?.focus())
}

function handleSearchEsc(e) {
  e.preventDefault()
  e.stopPropagation()

  if (!searchQuery.value.trim()) {
    router.push('/pembelian')
    return
  }

  searchQuery.value = ''
  nextTick(() => searchInput.value?.focus())
}

function updateItemTotal(idx) {
  const row = items.value[idx]
  row.total = Number(row.qty || 0) * Number(row.unit_cost || 0)
}

function updateItemPrice(idx, e) {
  const cost = parseFormattedNumber(e.target.value)
  items.value[idx].unit_cost = cost
  items.value[idx].total = Number(items.value[idx].qty || 0) * cost
  e.target.value = formatNumber(cost)
}

function removeItem(idx) {
  items.value.splice(idx, 1)
  nextTick(() => {
    if (items.value.length > 0) {
      const targetIdx = Math.min(idx, items.value.length - 1)
      nameRefs.value[targetIdx]?.focus()
    } else {
      focusProductInput()
    }
  })
}

function formatNewItemPrice(e) {
  const num = parseFormattedNumber(e.target.value)
  newItem.unit_cost = num
  e.target.value = formatNumber(num)
}

function addItem() {
  if (!newItem.product_id) {
    alert('Pilih barang dulu.')
    return
  }

  if (!newItem.qty || Number(newItem.qty) <= 0) {
    alert('Qty harus lebih dari 0.')
    return
  }

  items.value.push({
    product_id: newItem.product_id,
    product_kode: newItem.product_kode,
    product_nama: newItem.product_nama,
    qty: Number(newItem.qty),
    unit_cost: Number(newItem.unit_cost || 0),
    total: Number(newItem.qty) * Number(newItem.unit_cost || 0),
  })

  resetNewItem()
  focusProductInput()
}

function resetNewItem() {
  newItem.search = ''
  newItem.product_id = null
  newItem.product_kode = ''
  newItem.product_nama = ''
  newItem.qty = 1
  newItem.unit_cost = 0
}

function clearWorkingState() {
  sessionStorage.removeItem(EDIT_WORKING_STATE_KEY)
}

function saveWorkingState() {
  const hasOrder = Boolean(order.value?.no_order)
  const hasSearch = Boolean(searchQuery.value.trim())

  if (!hasOrder && !hasSearch) {
    clearWorkingState()
    return
  }

  const payload = {
    searchQuery: searchQuery.value,
    formVisible: formVisible.value,
    orderNo: order.value?.no_order || null,
    items: items.value,
    newItem: { ...newItem },
  }

  sessionStorage.setItem(EDIT_WORKING_STATE_KEY, JSON.stringify(payload))
}

async function restoreWorkingState() {
  const raw = sessionStorage.getItem(EDIT_WORKING_STATE_KEY)
  if (!raw) return false

  try {
    const state = JSON.parse(raw)
    searchQuery.value = String(state?.searchQuery || '')

    if (state?.newItem && typeof state.newItem === 'object') {
      newItem.search = String(state.newItem.search || '')
      newItem.product_id = state.newItem.product_id ?? null
      newItem.product_kode = String(state.newItem.product_kode || '')
      newItem.product_nama = String(state.newItem.product_nama || '')
      newItem.qty = Number(state.newItem.qty || 1)
      newItem.unit_cost = Number(state.newItem.unit_cost || 0)
    }

    if (!state?.orderNo) {
      formVisible.value = true
      return true
    }

    const row = await getPurchaseOrderByNo(state.orderNo)
    if (!row) {
      clearWorkingState()
      return false
    }

    order.value = row
    items.value = Array.isArray(state.items)
      ? JSON.parse(JSON.stringify(state.items)).map(item => ({
          ...item,
          qty: Number(item.qty || 0),
          unit_cost: Number(item.unit_cost || 0),
          total: Number(item.total || Number(item.qty || 0) * Number(item.unit_cost || 0)),
        }))
      : JSON.parse(JSON.stringify(row.items || [])).map(item => ({
          ...item,
          qty: Number(item.qty || 0),
          unit_cost: Number(item.unit_cost || 0),
          total: Number(item.total || Number(item.qty || 0) * Number(item.unit_cost || 0)),
        }))

    formVisible.value = false
    notFound.value = false
    searchModalError.value = ''
    return true
  } catch {
    clearWorkingState()
    return false
  }
}

function saveOrder() {
  if (!order.value) return
  if (!items.value.length) {
    alert('Order minimal punya 1 item')
    return
  }
  confirmModal.value = true
}

async function persistOrder(status) {
  if (!order.value) return

  const payload = {
    ...order.value,
    status,
    items: items.value.map(item => ({
      ...item,
      qty: Number(item.qty || 0),
      unit_cost: Number(item.unit_cost || 0),
      total: Number(item.total || Number(item.qty || 0) * Number(item.unit_cost || 0)),
    })),
    subtotal: subtotal.value,
  }

  await upsertPurchaseOrder(payload)
}

function setFlashToast(summary, detail, severity = 'success', life = 3200) {
  sessionStorage.setItem(
    PEMBELIAN_FLASH_KEY,
    JSON.stringify({
      severity,
      summary,
      detail,
      life,
    })
  )
}

async function confirmSave() {
  if (!order.value || saving.value) return

  saving.value = true

  try {
    await persistOrder('ordered')
    confirmModal.value = false
    setFlashToast(
      'Masuk Receiving',
      `No. Order ${order.value.no_order || '-'} masuk ke halaman Receiving.`
    )
    clearWorkingState()
    router.push('/pembelian')
  } finally {
    saving.value = false
  }
}

function openDraftConfirmModal() {
  if (!order.value) return
  draftConfirmModal.show = true
}

function closeDraftConfirmModal() {
  draftConfirmModal.show = false
}

async function saveAsDraftAndBack() {
  if (!order.value) return
  await persistOrder('draft')
  draftConfirmModal.show = false
  setFlashToast(
    'Draft Tersimpan',
    `No. Order ${order.value.no_order || '-'} masuk ke halaman Order Pembelian Tertunda.`
  )
  clearWorkingState()
  router.push('/pembelian')
}

async function onProductEnter() {
  if (!newItem.search.trim()) return
  await openProductModal({
    query: newItem.search.trim(),
    mode: 'new',
    returnFocusEl: inputProduct.value,
  })
}

async function openProductModal({ query = '', mode = 'new', editIndex = null, returnFocusEl = null } = {}) {
  try {
    const q = String(query || '').trim()
    const { data, error } = await supabase
      .from('products')
      .select('id, kode, nama, stok')
      .or(`nama.ilike.%${q}%,kode.ilike.%${q}%`)
      .eq('aktif', true)
      .eq('is_archived', false)
      .order('nama')

    if (error) throw error

    productModal.results = data || []
    productModal.filtered = data || []
    productModal.query = ''
    productModal.selectedIndex = 0
    productModal.mode = mode
    productModal.editIndex = editIndex
    productModalReturnFocusEl.value = returnFocusEl
    productModal.show = true

    await nextTick()
    productModalInput.value?.focus()
  } catch (err) {
    console.error('[openProductModal edit pembelian]', err)
    alert('Gagal mencari produk: ' + err.message)
  }
}

function closeProductModal() {
  productModal.show = false
  productModal.mode = 'new'
  productModal.editIndex = null
  nextTick(() => {
    productModalReturnFocusEl.value?.focus?.()
  })
}

async function openEditProductModal(idx) {
  const row = items.value[idx]
  if (!row) return

  await openProductModal({
    query: row.product_nama || row.product_kode || '',
    mode: 'edit',
    editIndex: idx,
    returnFocusEl: nameRefs.value[idx],
  })
}

function filterProductModal() {
  const q = productModal.query.toLowerCase()
  productModal.filtered = q
    ? productModal.results.filter(row => row.nama.toLowerCase().includes(q) || row.kode.toLowerCase().includes(q))
    : productModal.results
  productModal.selectedIndex = 0
}

function onProductModalKey(e) {
  if (!productModal.show) return

  if ((e.key === 'ArrowDown' || e.key === 'ArrowUp') && productModal.filtered.length === 0) {
    e.preventDefault()
    return
  }

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
    e.preventDefault()
    closeProductModal()
  }
}

async function selectProduct(product) {
  const mode = productModal.mode
  const editIndex = productModal.editIndex
  productModal.show = false
  productModal.mode = 'new'
  productModal.editIndex = null

  const unitCost = await resolveDefaultPurchasePrice(product.id)

  if (mode === 'edit' && Number.isInteger(editIndex) && items.value[editIndex]) {
    const row = items.value[editIndex]
    row.product_id = product.id
    row.product_kode = product.kode
    row.product_nama = product.nama
    row.unit_cost = Number(unitCost || 0)
    row.total = Number(row.qty || 0) * Number(row.unit_cost || 0)

    await nextTick()
    qtyRefs.value[editIndex]?.focus()
    qtyRefs.value[editIndex]?.select?.()
    return
  }

  newItem.product_id = product.id
  newItem.product_kode = product.kode
  newItem.product_nama = product.nama
  newItem.search = product.nama
  newItem.unit_cost = unitCost

  await nextTick()
  inputQty.value?.focus()
  inputQty.value?.select()
}

async function resolveDefaultPurchasePrice(productId) {
  const supplierId = order.value?.supplier?.id
  const historyRows = await collectLatestSupplierPrices(productId)
  const currentHistory = historyRows.find(row => String(row.supplier_id) === String(supplierId))

  if (currentHistory?.harga_beli) {
    return Number(currentHistory.harga_beli)
  }

  try {
    const { data, error } = await supabase
      .from('product_prices')
      .select('harga_beli')
      .eq('product_id', productId)
      .eq('supplier_id', supplierId)
      .eq('aktif', true)
      .single()

    if (error && error.code !== 'PGRST116') throw error
    return Number(data?.harga_beli || 0)
  } catch {
    return 0
  }
}

async function collectLatestSupplierPrices(productId) {
  if (!productId) return []

  const { data: historyData, error: historyError } = await supabase
    .from('purchase_items')
    .select('unit_cost, purchases(status, supplier_id, supplier_nama, order_date, updated_at, created_at)')
    .eq('product_id', productId)

  if (historyError) {
    console.error('[collectLatestSupplierPrices edit pembelian]', historyError)
    return []
  }

  const entries = []

  for (const row of historyData || []) {
    const purchase = Array.isArray(row.purchases) ? row.purchases[0] : row.purchases
    if (!purchase || purchase.status === 'draft') continue

    const supplierName = purchase.supplier_nama || '-'
    const supplierId = purchase.supplier_id ?? null
    const supplierKey = supplierId != null ? `id:${supplierId}` : `nama:${supplierName}`
    const orderDate = purchase.order_date || purchase.updated_at || purchase.created_at || null
    const time = orderDate ? new Date(orderDate).getTime() : 0

    entries.push({
      supplier_key: supplierKey,
      supplier_id: supplierId,
      supplier_nama: supplierName,
      harga_beli: Number(row.unit_cost || 0),
      last_order_date: orderDate,
      time: Number.isFinite(time) ? time : 0,
    })
  }

  entries.sort((a, b) => b.time - a.time)

  const latestMap = new Map()
  for (const row of entries) {
    if (!latestMap.has(row.supplier_key)) {
      latestMap.set(row.supplier_key, row)
    }
  }

  return Array.from(latestMap.values())
}

async function openPriceHistoryModal(row, focusEl = null) {
  if (!row?.product_id) {
    alert('Pilih barang dulu sebelum membuka info harga.')
    return
  }

  priceHistoryReturnFocusEl.value = focusEl
  priceHistoryModal.show = true
  priceHistoryModal.loading = true
  priceHistoryModal.productName = row.product_nama || row.product_kode || '-'
  priceHistoryModal.currentSupplierName = order.value?.supplier?.nama || '-'
  priceHistoryModal.previousPrice = 0
  priceHistoryModal.lastOrderDate = null
  priceHistoryModal.comparisons = []

  const supplierId = order.value?.supplier?.id
  const historyRows = await collectLatestSupplierPrices(row.product_id)

  const comparisons = historyRows
    .map(item => ({
      ...item,
      is_current: String(item.supplier_id) === String(supplierId),
    }))
    .sort((a, b) => {
      if (a.is_current && !b.is_current) return -1
      if (!a.is_current && b.is_current) return 1
      return new Date(b.last_order_date || 0).getTime() - new Date(a.last_order_date || 0).getTime()
    })

  const latestCurrent = comparisons.find(item => item.is_current)
  priceHistoryModal.previousPrice = Number(latestCurrent?.harga_beli || 0)
  priceHistoryModal.lastOrderDate = latestCurrent?.last_order_date || null
  priceHistoryModal.comparisons = comparisons
  priceHistoryModal.loading = false
}

function closePriceHistoryModal() {
  priceHistoryModal.show = false
  nextTick(() => {
    priceHistoryReturnFocusEl.value?.focus?.()
  })
}

function formatRp(val) {
  return 'Rp ' + Number(val || 0).toLocaleString('id-ID')
}

function formatNumber(num) {
  if (!num) return ''
  return Number(num).toLocaleString('id-ID')
}

function parseFormattedNumber(value) {
  return parseInt(String(value).replace(/\./g, '').replace(/\D/g, ''), 10) || 0
}

function formatDate(value) {
  if (!value) return '-'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '-'
  const dd = String(date.getDate()).padStart(2, '0')
  const mm = String(date.getMonth() + 1).padStart(2, '0')
  const yy = String(date.getFullYear()).slice(-2)
  return `${dd}/${mm}/${yy}`
}

function formatDateDisplay(value) {
  if (!value) return '-'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '-'
  const dd = String(date.getDate()).padStart(2, '0')
  const mm = String(date.getMonth() + 1).padStart(2, '0')
  const yyyy = String(date.getFullYear())
  return `${dd}-${mm}-${yyyy}`
}

onMounted(async () => {
  pageEl.value?.focus()

  const restored = await restoreWorkingState()
  if (restored && order.value) {
    nextTick(() => focusFirstItemNameOrNewInput())
  }

  const pendingSearchNo = sessionStorage.getItem('pembelian_edit_search_no_order')
  if (!restored && pendingSearchNo) {
    searchQuery.value = pendingSearchNo
    sessionStorage.removeItem('pembelian_edit_search_no_order')
    nextTick(async () => {
      await submitSearchModal()
    })
  } else if (!restored) {
    nextTick(() => searchInput.value?.focus())
  }

  window.addEventListener('keydown', onGlobalKey)
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
})

watch(
  [searchQuery, formVisible, order, items],
  () => {
    saveWorkingState()
  },
  { deep: true }
)

watch(
  newItem,
  () => {
    saveWorkingState()
  },
  { deep: true }
)
</script>

<style scoped>
@import '@/assets/styles.css';
@import '@/assets/components/form.css';
@import '@/assets/components/modal.css';
@import '@/assets/pages/pembelian/pembelian-edit-page.css';

.item-input--inline {
  width: 100%;
  min-height: 38px;
  cursor: pointer;
  background: #ffffff;
  border: 1px solid #d8e0ec;
  border-radius: 10px;
  padding: 8px 12px;
}

.item-input--inline:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15);
}
</style>
