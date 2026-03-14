<template>
  <div class="pembelian-edit-page" ref="pageEl" tabindex="-1">
    <div class="search-card" v-if="formVisible">
      <div class="form-header">
        <h1 class="form-header-title">Edit Order Pembelian</h1>
        <p class="form-header-subtitle">Cari no order lalu Enter untuk edit barang</p>
      </div>
      <div class="search-body">
        <div class="search-input-wrap">
          <input
            ref="searchInput"
            v-model="searchQuery"
            type="text"
            class="search-input"
            placeholder="Ketik No. Order Pembelian"
            @keydown.enter.prevent="searchOrder"
            @keydown.esc.prevent="handleEscOnSearch"
          />
          <button class="search-btn" :disabled="!searchQuery" @click="searchOrder">Cari</button>
        </div>
      </div>
    </div>

    <div v-if="notFound" class="empty-state">
      <i class="pi pi-inbox"></i>
      <h3>Order tidak ditemukan</h3>
      <p>No Order {{ searchQuery }} belum ada.</p>
    </div>

    <div v-if="order && !formVisible" class="form-card">
      <div class="form-header">
        <h1 class="form-header-title">Edit {{ order.no_order }}</h1>
        
      </div>

      <div class="table-wrap">
        <table class="items-table">
          <thead>
            <tr>
              <th>#</th>
              <th>Kode</th>
              <th>Nama Barang</th>
              <th>Qty</th>
              <th>Harga/Pcs</th>
              <th>Total</th>
              <th>Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(item, idx) in items" :key="idx" class="item-row">
              <td>{{ idx + 1 }}</td>
              <td>{{ item.product_kode }}</td>
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
              <td>{{ formatRp(item.total) }}</td>
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
          </tbody>
        </table>
      </div>

      <div class="table-footer">
        <div class="subtotal-row">
          <span class="subtotal-label">Subtotal:</span>
          <span class="subtotal-value">{{ formatRp(subtotal) }}</span>
        </div>
      </div>

      <div class="modal-footer">
        <button class="btn-secondary" @click="backToSearch">Kembali</button>
        <button class="btn-primary" @click="saveOrder">Simpan</button>
      </div>
    </div>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="confirmModal" class="modal-overlay" @click.self="confirmModal = false">
          <div class="modal-box modal-box--sm" role="dialog">
            <div class="modal-header">
              <i class="pi pi-check-circle"></i>
              <h3 class="modal-title">Simpan Perubahan?</h3>
            </div>
            <div class="modal-body">
              <p>Tekan Enter untuk konfirmasi simpan.</p>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="confirmModal = false">Batal</button>
              <button class="btn-primary" @click="confirmSave">Simpan</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, nextTick, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { getPurchaseOrderByNo, upsertPurchaseOrder } from '@/lib/pembelianStore'

const router = useRouter()
const pageEl = ref(null)
const searchInput = ref(null)
const searchQuery = ref('')
const formVisible = ref(true)
const notFound = ref(false)
const order = ref(null)
const items = ref([])
const confirmModal = ref(false)
const qtyRefs = ref({})
const priceRefs = ref({})

const subtotal = computed(() => items.value.reduce((sum, item) => sum + item.total, 0))

function handleKeydown(e) {
  if (confirmModal.value) {
    if (e.key === 'Enter') {
      e.preventDefault()
      confirmSave()
    }
    if (e.key === 'Escape') {
      e.preventDefault()
      confirmModal.value = false
    }
    return
  }

  if ((e.key === 'y' || e.key === 'Y') && order.value && !formVisible.value) {
    e.preventDefault()
    saveOrder()
    return
  }

  if (e.key === 'Escape') {
    e.preventDefault()
    if (!formVisible.value) {
      backToSearch()
    } else {
      router.push('/pembelian')
    }
  }
}

function setQtyRef(el, idx) {
  if (el) qtyRefs.value[idx] = el
}

function setPriceRef(el, idx) {
  if (el) priceRefs.value[idx] = el
}

function handleTableKeydown(e, idx, field) {
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    if (idx < items.value.length - 1) {
      if (field === 'qty') qtyRefs.value[idx + 1]?.focus()
      if (field === 'price') priceRefs.value[idx + 1]?.focus()
    }
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    if (idx > 0) {
      if (field === 'qty') qtyRefs.value[idx - 1]?.focus()
      if (field === 'price') priceRefs.value[idx - 1]?.focus()
    }
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (field === 'qty') {
      priceRefs.value[idx]?.focus()
    } else if (idx < items.value.length - 1) {
      qtyRefs.value[idx + 1]?.focus()
    }
  }
}

function updateItemTotal(idx) {
  const row = items.value[idx]
  row.total = Number(row.qty) * Number(row.unit_cost)
}

function updateItemPrice(idx, e) {
  const cost = parseFormattedNumber(e.target.value)
  items.value[idx].unit_cost = cost
  items.value[idx].total = Number(items.value[idx].qty) * cost
  e.target.value = formatNumber(cost)
}

function removeItem(idx) {
  items.value.splice(idx, 1)
}

function searchOrder() {
  const row = getPurchaseOrderByNo(searchQuery.value.trim())
  if (!row) {
    notFound.value = true
    order.value = null
    items.value = []
    return
  }

  notFound.value = false
  order.value = row
  items.value = JSON.parse(JSON.stringify(row.items || []))
  formVisible.value = false

  nextTick(() => qtyRefs.value[0]?.focus())
}

function backToSearch() {
  formVisible.value = true
  order.value = null
  items.value = []
  notFound.value = false
  nextTick(() => searchInput.value?.focus())
}

function handleEscOnSearch() {
  if (!searchQuery.value.trim()) {
    router.push('/pembelian')
    return
  }
  searchQuery.value = ''
}

function saveOrder() {
  if (!order.value) return
  if (!items.value.length) {
    alert('Order minimal punya 1 item')
    return
  }
  confirmModal.value = true
}

function confirmSave() {
  const payload = {
    ...order.value,
    items: items.value,
    subtotal: subtotal.value,
  }
  upsertPurchaseOrder(payload)
  confirmModal.value = false
  alert('Perubahan order pembelian berhasil disimpan.')
  backToSearch()
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

onMounted(() => {
  pageEl.value?.focus()
  nextTick(() => searchInput.value?.focus())
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<style scoped>
@import '@/assets/styles.css';
@import '@/assets/components/form.css';
@import '@/assets/components/modal.css';
@import '@/assets/pages/pembelian/pembelian-edit-page.css';
</style>
