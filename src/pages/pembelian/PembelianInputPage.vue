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
                    min="1"
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
                    <span class="del-label">Del</span>
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
                    min="1"
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

        <p class="row-delete-hint">Klik Del di row untuk menghapus 1 row.</p>

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
  </div>
</template>

<script setup>
import { ref, reactive, computed, nextTick, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { upsertPurchaseOrder, getTermLabel } from '@/lib/pembelianStore'
import { buildPurchaseOrderFingerprint } from '@/lib/orderDedupe'

const router = useRouter()
const pageEl = ref(null)
const isSubmitting = ref(false)
const inputProduct = ref(null)
const inputQty = ref(null)
const inputPrice = ref(null)
const productModalInput = ref(null)
const qtyRefs = ref({})
const priceRefs = ref({})

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

const subtotal = computed(() => items.value.reduce((sum, row) => sum + row.total, 0))
const termLabel = computed(() => getTermLabel(orderData.value.terms || '1'))

function setQtyRef(el, idx) {
  if (el) qtyRefs.value[idx] = el
}

function setPriceRef(el, idx) {
  if (el) priceRefs.value[idx] = el
}

function onGlobalKey(e) {
  if (productModal.show) return

  if (e.key === 'Escape') {
    e.preventDefault()
    router.push('/pembelian/order')
    return
  }

  if ((e.key === 'y' || e.key === 'Y') && items.value.length > 0) {
    e.preventDefault()
    submitPurchase()
  }
}

function handleNewItemKeydown(e, field) {
  if (field === 'product' && e.key === 'Enter' && !newItem.search.trim() && items.value.length > 0) {
    e.preventDefault()
    submitPurchase()
    return
  }

  if (e.key === 'ArrowUp') {
    e.preventDefault()
    const last = items.value.length - 1
    if (last >= 0) {
      if (field === 'product') priceRefs.value[last]?.focus()
      if (field === 'qty') qtyRefs.value[last]?.focus()
      if (field === 'price') priceRefs.value[last]?.focus()
    }
  }

  if (e.key === 'ArrowRight' && field === 'qty') {
    e.preventDefault()
    inputPrice.value?.focus()
  }

  if (e.key === 'ArrowLeft' && field === 'price') {
    e.preventDefault()
    inputQty.value?.focus()
  }
}

function handleTableKeydown(e, idx, field) {
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    if (idx < items.value.length - 1) {
      if (field === 'qty') qtyRefs.value[idx + 1]?.focus()
      if (field === 'price') priceRefs.value[idx + 1]?.focus()
    } else {
      inputProduct.value?.focus()
    }
    return
  }

  if (e.key === 'ArrowUp') {
    e.preventDefault()
    if (idx > 0) {
      if (field === 'qty') qtyRefs.value[idx - 1]?.focus()
      if (field === 'price') priceRefs.value[idx - 1]?.focus()
    }
    return
  }

  if (e.key === 'Enter') {
    e.preventDefault()
    if (field === 'qty') {
      priceRefs.value[idx]?.focus()
    } else {
      inputProduct.value?.focus()
    }
  }
}

async function onProductEnter() {
  if (!newItem.search.trim()) {
    if (items.value.length > 0) submitPurchase()
    return
  }
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

  try {
    const { data: price } = await supabase
      .from('product_prices')
      .select('harga_beli')
      .eq('product_id', product.id)
      .eq('supplier_id', orderData.value.supplier.id)
      .eq('aktif', true)
      .single()

    newItem.unit_cost = Number(price?.harga_beli || 0)
  } catch {
    newItem.unit_cost = 0
  }

  inputQty.value?.removeAttribute('disabled')
  inputPrice.value?.removeAttribute('disabled')

  await nextTick()
  inputQty.value?.focus()
  inputQty.value?.select()
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
  items.value[idx].total = num * items.value[idx].qty
  e.target.value = formatNumber(num)
}

function updateItemTotal(idx) {
  const row = items.value[idx]
  row.total = row.qty * row.unit_cost
}

function addItem() {
  if (!newItem.product_id) {
    alert('Pilih barang dulu.')
    return
  }
  if (!newItem.qty || newItem.qty < 1) {
    alert('Qty minimal 1.')
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

function submitPurchase() {
  if (isSubmitting.value) return

  if (!items.value.length) {
    alert('Tambahkan minimal 1 barang.')
    return
  }

  isSubmitting.value = true

  const payload = {
    no_order: orderData.value.no_order,
    order_date: orderData.value.order_date,
    supplier: orderData.value.supplier,
    terms: orderData.value.terms,
    items: items.value,
    subtotal: subtotal.value,
    status: 'ordered',
    received_at: null,
    request_fingerprint: buildPurchaseOrderFingerprint({
      order_date: orderData.value.order_date,
      supplier: orderData.value.supplier,
      terms: orderData.value.terms,
      items: items.value,
      subtotal: subtotal.value,
      status: 'ordered',
    }),
  }

  try {
    upsertPurchaseOrder(payload)
    sessionStorage.removeItem('pembelian_draft')
    alert('Order pembelian tersimpan. Data masuk ke Edit, Receiving, dan History.')
    router.push('/pembelian/edit-order')
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

onMounted(() => {
  const raw = sessionStorage.getItem('pembelian_draft')
  if (!raw) {
    alert('Data header tidak ditemukan. Kembali ke Order Pembelian.')
    router.push('/pembelian/order')
    return
  }

  orderData.value = JSON.parse(raw)
  pageEl.value?.focus()
  window.addEventListener('keydown', onGlobalKey)
  nextTick(() => inputProduct.value?.focus())
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
})
</script>

<style scoped>
@import '@/assets/styles.css';
@import '@/assets/components/form.css';
@import '@/assets/components/modal.css';
@import '@/assets/pages/pembelian/pembelian-input-page.css';
</style>
