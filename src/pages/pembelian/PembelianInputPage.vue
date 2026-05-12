<template>
  <div class="pembelian-input-page" ref="pageEl" tabindex="-1">
    <div class="form-card">
      <div class="form-header">
        <h1 class="form-header-title">Input Item Pembelian</h1>
        <p class="form-header-subtitle">Tahap 2: Tambahkan item, kuantitas, dan harga beli</p>
      </div>

      <div class="order-info-section">
        <div class="order-info-card">
          <div class="info-row">
            <div class="info-col">
              <label>No. Order:</label>
              <strong>{{ orderData.no_order }}</strong>
            </div>
            <div class="info-col">
              <label>Tanggal:</label>
              <strong>{{ orderData.order_date }}</strong>
            </div>
            <div class="info-col">
              <label>Terms:</label>
              <strong>{{ termLabel }}</strong>
            </div>
          </div>
          <div class="info-row info-customer">
            <div class="info-col-full">
              <label>Supplier:</label>
              <strong>{{ orderData.supplier?.nama }}</strong>
              <span class="customer-details">
                {{ orderData.supplier?.alamat || 'Alamat tidak tersedia' }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="shortcuts-bar">
      <kbd>F2 Input Item</kbd>
      <kbd>F4 Info Harga</kbd>
      <kbd>F10 Simpan</kbd>
    </div>

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
                <th class="col-price">Harga per Pcs</th>
                <th class="col-total">Total</th>
                <th class="col-action">Aksi</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, idx) in items" :key="idx" class="item-row">
                <td>{{ idx + 1 }}</td>
                <td><span class="item-kode">{{ item.product_kode }}</span></td>
                <td>{{ item.product_nama }}</td>
                <td>
                  <input
                    :ref="el => setQtyRef(el, idx)"
                    v-model.number="item.qty"
                    class="qty-input"
                    type="number"
                    min="0.01"
                    step="any"
                    @input="updateItemTotal(idx)"
                    @keydown="handleTableKeydown($event, idx, 'qty')"
                  />
                </td>
                <td>
                  <input
                    :ref="el => setPriceRef(el, idx)"
                    :value="formatNumber(item.unit_cost)"
                    class="price-input"
                    type="text"
                    @input="updateItemPrice(idx, $event)"
                    @keydown="handleTableKeydown($event, idx, 'price')"
                  />
                </td>
                <td><span class="total-val">{{ formatRp(item.total) }}</span></td>
                <td>
                  <button
                    type="button"
                    class="btn-icon btn-delete"
                    title="Hapus baris ini"
                    @click="removeItem(idx)"
                  >
                    <i class="pi pi-trash"></i>
                  </button>
                </td>
              </tr>

              <tr class="item-row item-row--new">
                <td>{{ items.length + 1 }}</td>
                <td colspan="2">
                  <div class="search-input-wrap">
                    <input
                      ref="inputProduct"
                      v-model="newItem.search"
                      type="text"
                      class="item-input"
                      placeholder="Cari nama barang atau kode lalu Enter"
                      @keydown.enter.prevent="onProductEnter"
                      @keydown="handleNewItemKeydown($event, 'product')"
                    />
                    <i class="pi pi-search input-icon"></i>
                  </div>
                </td>
                <td>
                  <input
                    ref="inputQty"
                    v-model.number="newItem.qty"
                    class="qty-input"
                    type="number"
                    min="0.01"
                    step="any"
                    @keydown.enter.prevent="focusPrice"
                    @keydown="handleNewItemKeydown($event, 'qty')"
                    disabled
                  />
                </td>
                <td>
                  <input
                    ref="inputPrice"
                    :value="newItem.unit_cost ? formatNumber(newItem.unit_cost) : ''"
                    class="price-input"
                    type="text"
                    @input="formatNewItemPrice"
                    @keydown.enter.prevent="addItem"
                    @keydown="handleNewItemKeydown($event, 'price')"
                    disabled
                  />
                </td>
                <td>
                  <span class="total-val total-preview">
                    {{ newItem.qty && newItem.unit_cost ? formatRp(newItem.qty * newItem.unit_cost) : '—' }}
                  </span>
                </td>
                <td>—</td>
              </tr>

              <tr v-if="items.length === 0" class="empty-row">
                <td colspan="7" class="empty-cell">
                  <i class="pi pi-inbox"></i>
                  <p>Belum ada item, ketik barang di baris input.</p>
                </td>
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
      </div>
    </div>

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
          <div class="modal-box modal-box--price-history" role="dialog" aria-modal="true">
            <div class="modal-header modal-header--blue">
              <i class="pi pi-tags"></i>
              <h3 class="modal-title">Riwayat Harga Pembelian</h3>
              <button class="modal-close" @click="closePriceHistoryModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <div class="price-history-product-name">
                {{ priceHistoryModal.productName || '-' }}
              </div>

              <div class="price-summary-box">
                <div class="price-summary-row">
                  <span>Supplier Aktif</span>
                  <strong>{{ priceHistoryModal.currentSupplierName || '-' }}</strong>
                </div>
                <div class="price-summary-row">
                  <span>Harga Sebelumnya</span>
                  <strong>{{ formatRp(priceHistoryModal.previousPrice) }}</strong>
                </div>
                <div class="price-summary-row">
                  <span>Last Order Date</span>
                  <strong>{{ formatDateDisplay(priceHistoryModal.lastOrderDate) }}</strong>
                </div>
              </div>

              <div v-if="priceHistoryModal.loading" class="price-history-empty">Memuat riwayat harga...</div>

              <div v-else-if="priceHistoryTableRows.length" class="price-history-table-wrap">
                <table class="price-history-table">
                  <thead>
                    <tr>
                      <th>Supplier</th>
                      <th>Harga Terakhir</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr
                      v-for="(row, idx) in priceHistoryTableRows"
                      :key="`${row.supplier_id || row.supplier_nama}-${idx}`"
                      :class="{ 'price-row-current': row.is_current }"
                    >
                      <td>
                        <div class="price-supplier-cell">
                          <strong>{{ row.supplier_nama || '-' }}</strong>
                        </div>
                      </td>
                      <td><strong>{{ formatRp(row.harga_beli) }}</strong></td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <div v-else class="price-history-empty">
                Tidak ada data supplier lain untuk perbandingan harga.
              </div>

            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="closePriceHistoryModal">Esc: Tutup</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="submitConfirmModal.show" class="modal-overlay" @click.self="closeSubmitConfirmModal">
          <div class="modal-box modal-box--sm" role="dialog" aria-modal="true">
            <div class="modal-header modal-header--blue">
              <i class="pi pi-check-circle"></i>
              <h3 class="modal-title">Simpan Ke Receiving?</h3>
              <button class="modal-close" @click="closeSubmitConfirmModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <p>Data akan disimpan dan masuk ke halaman Receiving.</p>
              <p class="modal-shortcut"></p>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="closeSubmitConfirmModal">Batal (Esc)</button>
              <button class="btn-primary" @click="confirmSubmitToReceiving">Konfirmasi (Enter/Y)</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="exitConfirmModal.show" class="modal-overlay" @click.self="closeExitConfirmModal">
          <div class="modal-box modal-box--sm" role="dialog" aria-modal="true">
            <div class="modal-header modal-header--danger">
              <i class="pi pi-exclamation-triangle"></i>
              <h3 class="modal-title">Keluar Dari Input?</h3>
              <button class="modal-close" @click="closeExitConfirmModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <p>Data yang sudah diinput akan disimpan sebagai draft. Lanjut keluar?</p>
              <p class="modal-shortcut"></p>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="closeExitConfirmModal">Batal (Esc)</button>
              <button class="btn-primary" @click="confirmExitAndSaveDraft">Ya, Simpan Draft (Y)</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, reactive, computed, nextTick, onMounted, onUnmounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { upsertPurchaseOrder, getTermLabel, getPurchaseOrderByNo } from '@/lib/pembelianStore'
import { buildPurchaseOrderFingerprint } from '@/lib/orderDedupe'

const router = useRouter()
const route = useRoute()
const pageEl = ref(null)
const isSubmitting = ref(false)
const inputProduct = ref(null)
const inputQty = ref(null)
const inputPrice = ref(null)
const productModalInput = ref(null)
const qtyRefs = ref({})
const priceRefs = ref({})
const priceHistoryReturnFocusEl = ref(null)

const PEMBELIAN_FLASH_KEY = 'pembelian_flash_notice'
const PEMBELIAN_INPUT_WORKING_KEY = 'pembelian_input_working_state'

const orderData = ref({})
const items = ref([])

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
})

const submitConfirmModal = reactive({
  show: false,
})

const exitConfirmModal = reactive({
  show: false,
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

const subtotal = computed(() => items.value.reduce((sum, row) => sum + row.total, 0))
const termLabel = computed(() => getTermLabel(orderData.value.terms || '1'))
const priceHistoryTableRows = computed(() =>
  (priceHistoryModal.comparisons || []).filter(row => !row.is_current)
)

function setQtyRef(el, idx) {
  if (el) qtyRefs.value[idx] = el
}

function setPriceRef(el, idx) {
  if (el) priceRefs.value[idx] = el
}

function onGlobalKey(e) {
  if (priceHistoryModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      closePriceHistoryModal()
    }
    return
  }

  if (submitConfirmModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      closeSubmitConfirmModal()
      return
    }
    if (e.key === 'Enter' || e.key === 'y' || e.key === 'Y') {
      e.preventDefault()
      confirmSubmitToReceiving()
    }
    return
  }

  if (exitConfirmModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      closeExitConfirmModal()
      return
    }
    if (e.key === 'Enter' || e.key === 'y' || e.key === 'Y') {
      e.preventDefault()
      confirmExitAndSaveDraft()
    }
    return
  }

  if (productModal.show) return

  if (e.key === 'Escape') {
    e.preventDefault()
    openExitConfirmModal()
    return
  }

  if (e.key === 'F10') {
    e.preventDefault()
    openSubmitConfirmModal()
    return
  }

  if (e.key === 'F2') {
    e.preventDefault()
    focusProductInput()
  }
}

function focusProductInput() {
  nextTick(() => {
    inputProduct.value?.focus()
    inputProduct.value?.select?.()
  })
}

function handleNewItemKeydown(e, field) {
  if (e.key === 'F4' && field === 'price') {
    e.preventDefault()
    if (!newItem.product_id) {
      alert('Pilih barang dulu sebelum melihat riwayat harga.')
      return
    }
    openPriceHistoryModal(
      {
        product_id: newItem.product_id,
        product_nama: newItem.product_nama,
        product_kode: newItem.product_kode,
      },
      inputPrice.value
    )
    return
  }

  if (e.key === 'ArrowUp') {
    e.preventDefault()
    const last = items.value.length - 1
    if (last < 0) return

    if (field === 'product') {
      priceRefs.value[last]?.focus()
      return
    }

    if (field === 'qty') {
      qtyRefs.value[last]?.focus()
      return
    }

    if (field === 'price') {
      priceRefs.value[last]?.focus()
    }
    return
  }

  if (e.key === 'ArrowRight') {
    if (field === 'product') {
      if (!newItem.product_id) return
      e.preventDefault()
      inputQty.value?.focus()
      return
    }

    if (field === 'qty') {
      e.preventDefault()
      inputPrice.value?.focus()
    }
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

function handleTableKeydown(e, idx, field) {
  if (e.key === 'Delete') {
    e.preventDefault()
    removeItem(idx)

    nextTick(() => {
      const nextIdx = Math.min(idx, items.value.length - 1)
      if (nextIdx >= 0) {
        if (field === 'price') {
          priceRefs.value[nextIdx]?.focus()
        } else {
          qtyRefs.value[nextIdx]?.focus()
        }
      } else {
        inputProduct.value?.focus()
      }
    })
    return
  }

  if (e.key === 'F4' && field === 'price') {
    e.preventDefault()
    const row = items.value[idx]
    if (!row?.product_id) return
    openPriceHistoryModal(row, priceRefs.value[idx])
    return
  }

  if (e.key === 'ArrowRight') {
    if (field === 'qty') {
      e.preventDefault()
      priceRefs.value[idx]?.focus()
    }
    return
  }

  if (e.key === 'ArrowLeft') {
    if (field === 'price') {
      e.preventDefault()
      qtyRefs.value[idx]?.focus()
      return
    }

    if (field === 'qty') {
      e.preventDefault()
      inputProduct.value?.focus()
    }
    return
  }

  if (e.key === 'ArrowDown') {
    e.preventDefault()
    if (idx < items.value.length - 1) {
      if (field === 'qty') qtyRefs.value[idx + 1]?.focus()
      if (field === 'price') priceRefs.value[idx + 1]?.focus()
      return
    }

    if (field === 'qty') {
      inputQty.value?.focus()
      return
    }

    inputPrice.value?.focus()
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

  if (e.key === 'Enter') {
    e.preventDefault()
    if (field === 'qty') {
      priceRefs.value[idx]?.focus()
      return
    }

    if (idx < items.value.length - 1) {
      qtyRefs.value[idx + 1]?.focus()
      return
    }

    inputProduct.value?.focus()
  }
}

async function onProductEnter() {
  if (!newItem.search.trim()) return
  await openProductModal()
}

async function openProductModal() {
  try {
    const q = newItem.search.trim()
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
    productModal.show = true

    await nextTick()
    productModalInput.value?.focus()
  } catch (err) {
    console.error('[openProductModal]', err)
    alert('Gagal mencari produk: ' + err.message)
  }
}

function filterProductModal() {
  const q = productModal.query.toLowerCase()
  productModal.filtered = q
    ? productModal.results.filter(row => row.nama.toLowerCase().includes(q) || row.kode.toLowerCase().includes(q))
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
    e.preventDefault()
    productModal.show = false
  }
}

async function selectProduct(product) {
  productModal.show = false
  newItem.product_id = product.id
  newItem.product_kode = product.kode
  newItem.product_nama = product.nama
  newItem.search = product.nama

  newItem.unit_cost = await resolveDefaultPurchasePrice(product.id)

  inputQty.value?.removeAttribute('disabled')
  inputPrice.value?.removeAttribute('disabled')

  await nextTick()
  inputQty.value?.focus()
  inputQty.value?.select()
}

async function resolveDefaultPurchasePrice(productId) {
  const supplierId = orderData.value?.supplier?.id
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
    console.error('[collectLatestSupplierPrices]', historyError)
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
    alert('Pilih barang dulu sebelum membuka riwayat harga.')
    return
  }

  priceHistoryReturnFocusEl.value = focusEl
  priceHistoryModal.show = true
  priceHistoryModal.loading = true
  priceHistoryModal.productName = row.product_nama || row.product_kode || '-'
  priceHistoryModal.currentSupplierName = orderData.value?.supplier?.nama || '-'
  priceHistoryModal.previousPrice = 0
  priceHistoryModal.lastOrderDate = null
  priceHistoryModal.comparisons = []

  const supplierId = orderData.value?.supplier?.id
  const historyRows = await collectLatestSupplierPrices(row.product_id)

  let comparisons = historyRows.map(item => ({
    ...item,
    is_current: String(item.supplier_id) === String(supplierId),
  }))

  const currentSupplierRow = comparisons.find(item => item.is_current)

  if (!currentSupplierRow) {
    try {
      const { data: currentPrice, error } = await supabase
        .from('product_prices')
        .select('harga_beli')
        .eq('product_id', row.product_id)
        .eq('supplier_id', supplierId)
        .eq('aktif', true)
        .single()

      if (error && error.code !== 'PGRST116') throw error

      if (currentPrice?.harga_beli) {
        comparisons.unshift({
          supplier_key: supplierId != null ? `id:${supplierId}` : `nama:${priceHistoryModal.currentSupplierName}`,
          supplier_id: supplierId ?? null,
          supplier_nama: priceHistoryModal.currentSupplierName,
          harga_beli: Number(currentPrice.harga_beli || 0),
          last_order_date: null,
          is_current: true,
        })
      }
    } catch (err) {
      console.error('[openPriceHistoryModal fallback price]', err)
    }
  }

  comparisons.sort((a, b) => {
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

function focusPrice() {
  inputPrice.value?.focus()
}

function formatNewItemPrice(e) {
  const num = parseFormattedNumber(e.target.value)
  newItem.unit_cost = num
  e.target.value = formatNumber(num)
}

function updateItemPrice(idx, e) {
  const num = parseFormattedNumber(e.target.value)
  items.value[idx].unit_cost = num
  items.value[idx].total = num * Number(items.value[idx].qty || 0)
  e.target.value = formatNumber(num)
}

function updateItemTotal(idx) {
  const row = items.value[idx]
  row.total = Number(row.qty || 0) * Number(row.unit_cost || 0)
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
  inputProduct.value?.focus()
}

function removeItem(idx) {
  items.value.splice(idx, 1)
}

function resetNewItem() {
  newItem.search = ''
  newItem.product_id = null
  newItem.product_kode = ''
  newItem.product_nama = ''
  newItem.qty = 1
  newItem.unit_cost = 0
  inputQty.value?.setAttribute('disabled', 'disabled')
  inputPrice.value?.setAttribute('disabled', 'disabled')
}

function openSubmitConfirmModal() {
  if (isSubmitting.value) return
  if (!items.value.length) {
    alert('Tambahkan minimal 1 barang sebelum simpan ke Receiving.')
    return
  }
  submitConfirmModal.show = true
}

function closeSubmitConfirmModal() {
  submitConfirmModal.show = false
}

function openExitConfirmModal() {
  if (isSubmitting.value) return
  exitConfirmModal.show = true
}

function closeExitConfirmModal() {
  exitConfirmModal.show = false
}

function buildPayload(status = 'ordered') {
  const normalizedItems = items.value.map(item => ({
    product_id: item.product_id,
    product_kode: item.product_kode,
    product_nama: item.product_nama,
    qty: Number(item.qty || 0),
    unit_cost: Number(item.unit_cost || 0),
    total: Number(item.total || Number(item.qty || 0) * Number(item.unit_cost || 0)),
  }))

  const payload = {
    no_order: orderData.value.no_order,
    order_date: orderData.value.order_date,
    supplier: orderData.value.supplier,
    terms: orderData.value.terms,
    items: normalizedItems,
    subtotal: normalizedItems.reduce((sum, row) => sum + Number(row.total || 0), 0),
    status,
    received_at: null,
  }

  payload.request_fingerprint = buildPurchaseOrderFingerprint(payload)
  return payload
}

async function saveOrderWithStatus(status = 'ordered') {
  const payload = buildPayload(status)
  await upsertPurchaseOrder(payload)
  sessionStorage.removeItem('pembelian_draft')
  clearWorkingState()
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

async function confirmSubmitToReceiving() {
  if (isSubmitting.value) return
  if (!items.value.length) {
    closeSubmitConfirmModal()
    alert('Tambahkan minimal 1 barang sebelum simpan ke Receiving.')
    return
  }

  isSubmitting.value = true

  try {
    await saveOrderWithStatus('ordered')
    setFlashToast(
      'Masuk Receiving',
      `No. Order ${orderData.value.no_order || '-'} masuk ke halaman Receiving.`
    )
    closeSubmitConfirmModal()
    router.push('/pembelian')
  } finally {
    isSubmitting.value = false
  }
}

async function confirmExitAndSaveDraft() {
  if (isSubmitting.value) return
  isSubmitting.value = true

  try {
    await saveOrderWithStatus('draft')
    setFlashToast(
      'Draft Tersimpan',
      `No. Order ${orderData.value.no_order || '-'} masuk ke halaman Order Pembelian Tertunda.`
    )
    closeExitConfirmModal()
    router.push('/pembelian')
  } finally {
    isSubmitting.value = false
  }
}

function formatRp(val) {
  if (!val || Number.isNaN(val)) return 'Rp 0'
  return 'Rp ' + Number(val).toLocaleString('id-ID')
}

function formatNumber(num) {
  if (!num) return ''
  return Number(num).toLocaleString('id-ID')
}

function parseFormattedNumber(val) {
  return parseInt(String(val).replace(/\./g, '').replace(/\D/g, ''), 10) || 0
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

function persistWorkingState() {
  if (!orderData.value?.no_order) return

  const snapshot = {
    no_order: orderData.value.no_order,
    items: items.value.map(item => ({
      product_id: item.product_id,
      product_kode: item.product_kode,
      product_nama: item.product_nama,
      qty: Number(item.qty || 0),
      unit_cost: Number(item.unit_cost || 0),
      total: Number(item.total || Number(item.qty || 0) * Number(item.unit_cost || 0)),
    })),
    newItem: {
      search: newItem.search,
      product_id: newItem.product_id,
      product_kode: newItem.product_kode,
      product_nama: newItem.product_nama,
      qty: Number(newItem.qty || 1),
      unit_cost: Number(newItem.unit_cost || 0),
    },
  }

  sessionStorage.setItem(PEMBELIAN_INPUT_WORKING_KEY, JSON.stringify(snapshot))
}

function restoreWorkingState() {
  const raw = sessionStorage.getItem(PEMBELIAN_INPUT_WORKING_KEY)
  if (!raw) return

  try {
    const parsed = JSON.parse(raw)
    if (!parsed || parsed.no_order !== orderData.value?.no_order) return

    items.value = Array.isArray(parsed.items)
      ? parsed.items.map(item => ({
          product_id: item.product_id,
          product_kode: item.product_kode,
          product_nama: item.product_nama,
          qty: Number(item.qty || 0),
          unit_cost: Number(item.unit_cost || 0),
          total: Number(item.total || Number(item.qty || 0) * Number(item.unit_cost || 0)),
        }))
      : []

    newItem.search = String(parsed.newItem?.search || '')
    newItem.product_id = parsed.newItem?.product_id || null
    newItem.product_kode = String(parsed.newItem?.product_kode || '')
    newItem.product_nama = String(parsed.newItem?.product_nama || '')
    newItem.qty = Number(parsed.newItem?.qty || 1)
    newItem.unit_cost = Number(parsed.newItem?.unit_cost || 0)
  } catch (err) {
    console.error('[restoreWorkingState input pembelian]', err)
  }

  nextTick(() => {
    if (newItem.product_id) {
      inputQty.value?.removeAttribute('disabled')
      inputPrice.value?.removeAttribute('disabled')
      return
    }

    inputQty.value?.setAttribute('disabled', 'disabled')
    inputPrice.value?.setAttribute('disabled', 'disabled')
  })
}

function clearWorkingState() {
  sessionStorage.removeItem(PEMBELIAN_INPUT_WORKING_KEY)
}

function handleBeforeUnload() {
  persistWorkingState()
}

watch(
  () => ({
    no_order: orderData.value?.no_order,
    items: items.value,
    newItem: {
      search: newItem.search,
      product_id: newItem.product_id,
      product_kode: newItem.product_kode,
      product_nama: newItem.product_nama,
      qty: newItem.qty,
      unit_cost: newItem.unit_cost,
    },
  }),
  () => {
    persistWorkingState()
  },
  { deep: true }
)

onMounted(async () => {
  const raw = sessionStorage.getItem('pembelian_draft')

  if (raw) {
    try {
      orderData.value = JSON.parse(raw)
    } catch (err) {
      console.error('[parse pembelian_draft input]', err)
    }
  }

  if (!orderData.value?.no_order) {
    const noOrderQuery = String(route.query.no_order || '').trim()
    if (noOrderQuery) {
      try {
        const existingOrder = await getPurchaseOrderByNo(noOrderQuery)
        if (existingOrder?.no_order) {
          orderData.value = {
            no_order: existingOrder.no_order,
            order_date: existingOrder.order_date,
            terms: String(existingOrder.terms || 'tunai'),
            supplier: existingOrder.supplier || {
              id: existingOrder.supplier_id || null,
              nama: existingOrder.supplier_nama || '',
              alamat: existingOrder.supplier_alamat || '',
            },
          }

          items.value = Array.isArray(existingOrder.items)
            ? existingOrder.items.map(item => ({
                product_id: item.product_id,
                product_kode: item.product_kode,
                product_nama: item.product_nama,
                qty: Number(item.qty || 0),
                unit_cost: Number(item.unit_cost || 0),
                total: Number(item.total || Number(item.qty || 0) * Number(item.unit_cost || 0)),
              }))
            : []
        }
      } catch (err) {
        console.error('[getPurchaseOrderByNo input pembelian]', err)
      }
    }
  }

  if (!orderData.value?.no_order) {
    alert('Data header tidak ditemukan. Kembali ke Order Pembelian.')
    router.push('/pembelian/order')
    return
  }

  restoreWorkingState()
  pageEl.value?.focus()
  window.addEventListener('keydown', onGlobalKey)
  window.addEventListener('beforeunload', handleBeforeUnload)
  nextTick(() => inputProduct.value?.focus())
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
  window.removeEventListener('beforeunload', handleBeforeUnload)
})
</script>

<style scoped>
@import '@/assets/styles.css';
@import '@/assets/components/form.css';
@import '@/assets/components/modal.css';
@import '@/assets/Styles/pembelian/pembelian-input-page.css';
</style>
