<template>
  <div class="pembelian-receiving-page" ref="pageEl" tabindex="-1">
    <div class="search-card">
      <div class="form-header">
        <h1 class="form-header-title">Penerimaan Barang Pembelian</h1>
        <p class="form-header-subtitle">Cari nomor order, validasi barang masuk, lalu konfirmasi</p>
      </div>
      <div class="search-body">
        <div class="search-input-wrap">
          <input
            ref="searchInput"
            v-model="searchQuery"
            type="text"
            class="search-input"
            placeholder="Input No. Order Pembelian lalu Enter"
            @keydown.enter.prevent="loadOrder"
          />
          <button class="search-btn" :disabled="!searchQuery" @click="loadOrder">Cari</button>
        </div>
      </div>
    </div>

    <div class="table-card order-list-card">
      <div class="order-summary">
        <strong>Daftar Order Pending</strong> · {{ visiblePendingOrders.length }} order
      </div>

      <div v-if="visiblePendingOrders.length" class="table-wrap">
        <table class="items-table">
          <thead>
            <tr>
              <th>No Order</th>
              <th>Supplier</th>
              <th>Item</th>
              <th>Diperbarui</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="(pending, idx) in visiblePendingOrders"
              :key="pending.no_order"
              :class="{ 'row-active': isPendingRowActive(pending.no_order, idx) }"
              @click="onPendingRowClick(pending.no_order, idx)"
            >
              <td><strong>{{ pending.no_order }}</strong></td>
              <td>{{ pending.supplier?.nama || '-' }}</td>
              <td>{{ pending.items?.length || 0 }}</td>
              <td>{{ formatDateTime(pending.updated_at || pending.created_at) }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div v-else class="empty-order-list">Tidak ada order pending untuk kata kunci ini.</div>
    </div>

    <div v-if="order" class="table-card">
      <div class="order-summary">
        <strong>{{ order.no_order }}</strong> · {{ order.supplier?.nama }} · {{ order.items.length }} item
      </div>
      <div class="table-wrap">
        <table class="items-table">
          <thead>
            <tr>
              <th>#</th>
              <th>Kode</th>
              <th>Nama Barang</th>
              <th>Qty</th>
              <th>Valid</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="(item, idx) in checks"
              :key="item.product_id"
              :class="{ 'row-active': idx === selectedRow, 'row-checked': item.checked }"
              @click="selectedRow = idx"
            >
              <td>{{ idx + 1 }}</td>
              <td>{{ item.product_kode }}</td>
              <td>{{ item.product_nama }}</td>
              <td>{{ item.qty }}</td>
              <td>
                <input type="checkbox" v-model="item.checked" tabindex="-1" @click.stop />
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="table-footer">
        <div class="validation-status">Tervalidasi {{ checkedCount }}/{{ checks.length }} item</div>
        <button
          type="button"
          class="btn-primary"
          :disabled="!canConfirm"
          title="Shortcut: Y"
          @click="openConfirmModal"
        >
          Konfirmasi Validasi
        </button>
      </div>
    </div>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="confirmVisible" class="modal-overlay" @click.self="confirmVisible = false">
          <div class="modal-box modal-box--sm" role="dialog" aria-modal="true">
            <div class="modal-header">
              <i class="pi pi-check-circle"></i>
              <h3 class="modal-title">Konfirmasi Receiving</h3>
            </div>
            <div class="modal-body">
              <p v-if="canConfirm">Lanjutkan receiving untuk item yang sudah Anda validasi?</p>
              <p v-else>Validasi minimal 1 item terlebih dulu, lalu tekan Y lagi untuk konfirmasi.</p>
              <p class="modal-shortcut">Enter: Konfirmasi · Esc: Batal</p>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="confirmVisible = false">Batal</button>
              <button class="btn-primary" :disabled="!canConfirm" @click="confirmReceiving">Konfirmasi</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, nextTick, onMounted, onUnmounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { getPurchaseOrderByNo, listPurchaseOrders, markPurchaseOrderReceived } from '@/lib/pembelianStore'

const router = useRouter()
const pageEl = ref(null)
const searchInput = ref(null)
const searchQuery = ref('')
const pendingOrders = ref([])
const selectedPendingRow = ref(0)
const order = ref(null)
const checks = ref([])
const selectedRow = ref(0)
const confirmVisible = ref(false)

const checkedCount = computed(() => checks.value.filter(row => row.checked).length)
const canConfirm = computed(() => checkedCount.value > 0)
const filteredPendingOrders = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return pendingOrders.value

  return pendingOrders.value.filter(row => {
    const noOrder = String(row.no_order || '').toLowerCase()
    const supplier = String(row.supplier?.nama || '').toLowerCase()
    return noOrder.includes(q) || supplier.includes(q)
  })
})
const visiblePendingOrders = computed(() => {
  if (order.value?.no_order) {
    return filteredPendingOrders.value.filter(row => row.no_order === order.value.no_order)
  }
  return filteredPendingOrders.value
})

watch(searchQuery, () => {
  selectedPendingRow.value = 0
  order.value = null
  checks.value = []
  selectedRow.value = 0
  confirmVisible.value = false
})

function handleKeydown(e) {
  if (confirmVisible.value) {
    if (e.key === 'Enter') {
      e.preventDefault()
      confirmReceiving()
    }
    if (e.key === 'Escape') {
      e.preventDefault()
      confirmVisible.value = false
    }
    return
  }

  if (e.key === 'F1') {
    e.preventDefault()
    nextTick(() => searchInput.value?.focus())
    return
  }

  if (e.key === 'Escape') {
    e.preventDefault()
    if (order.value) {
      resetForm()
      return
    }
    if (searchQuery.value.trim()) {
      searchQuery.value = ''
      return
    }
    router.push('/pembelian')
    return
  }

  const targetTag = String(e.target?.tagName || '').toLowerCase()
  const isTypingTarget = targetTag === 'input' || targetTag === 'textarea'
  if (isTypingTarget) {
    return
  }

  if (!order.value && visiblePendingOrders.value.length) {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      selectedPendingRow.value = Math.min(
        selectedPendingRow.value + 1,
        visiblePendingOrders.value.length - 1
      )
      return
    }

    if (e.key === 'ArrowUp') {
      e.preventDefault()
      selectedPendingRow.value = Math.max(selectedPendingRow.value - 1, 0)
      return
    }

    if (e.key === 'Enter') {
      e.preventDefault()
      const target = visiblePendingOrders.value[selectedPendingRow.value]
      if (target?.no_order) {
        selectOrder(target.no_order, { silentNotFound: true })
      }
      return
    }
  }

  if (order.value) {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      selectedRow.value = Math.min(selectedRow.value + 1, checks.value.length - 1)
      return
    }

    if (e.key === 'ArrowUp') {
      e.preventDefault()
      selectedRow.value = Math.max(selectedRow.value - 1, 0)
      return
    }

    if (e.key === 'Enter') {
      e.preventDefault()
      const row = checks.value[selectedRow.value]
      if (row) {
        row.checked = !row.checked
      }
      return
    }

    if (e.key === 'y' || e.key === 'Y') {
      e.preventDefault()
      openConfirmModal()
      return
    }
  }

}

function openConfirmModal() {
  confirmVisible.value = true
}

function listPendingOrders() {
  return listPurchaseOrders()
    .filter(row => row?.no_order && row.status !== 'received')
    .sort((a, b) => {
      const timeA = new Date(a.updated_at || a.created_at || 0).getTime()
      const timeB = new Date(b.updated_at || b.created_at || 0).getTime()
      return timeB - timeA
    })
}

function refreshPendingOrders() {
  pendingOrders.value = listPendingOrders()
  if (!pendingOrders.value.length) {
    selectedPendingRow.value = 0
    return
  }

  if (selectedPendingRow.value > pendingOrders.value.length - 1) {
    selectedPendingRow.value = pendingOrders.value.length - 1
  }
}

function applyOrder(row) {
  if (!row) return

  order.value = row
  checks.value = (row.items || []).map(item => ({ ...item, checked: false }))
  selectedRow.value = 0
  confirmVisible.value = false
  nextTick(() => pageEl.value?.focus())
}

function selectOrder(noOrder, { silentNotFound = false } = {}) {
  const row = pendingOrders.value.find(item => item.no_order === noOrder) || getPurchaseOrderByNo(noOrder)
  if (!row || row.status === 'received') {
    if (!silentNotFound) {
      alert('No order tidak ditemukan atau sudah received.')
    }
    return
  }

  applyOrder(row)
}

function loadOrder({ silentNotFound = false } = {}) {
  const typedNo = searchQuery.value.trim()

  if (!typedNo) {
    const target = visiblePendingOrders.value[selectedPendingRow.value] || visiblePendingOrders.value[0]
    if (target?.no_order) {
      selectOrder(target.no_order, { silentNotFound: true })
      return
    }
    return
  }

  const row = pendingOrders.value.find(item => item.no_order === typedNo) || getPurchaseOrderByNo(typedNo)
  if (!row || row.status === 'received') {
    if (!silentNotFound) {
      alert('No order tidak ditemukan atau sudah received.')
    }
    return
  }

  applyOrder(row)
  searchQuery.value = ''
}

function isPendingRowActive(noOrder, idx) {
  if (order.value?.no_order) {
    return order.value.no_order === noOrder
  }
  return idx === selectedPendingRow.value
}

function onPendingRowClick(noOrder, idx) {
  if (order.value?.no_order) {
    selectOrder(noOrder, { silentNotFound: true })
    return
  }
  selectedPendingRow.value = idx
}

async function confirmReceiving() {
  if (!order.value) return
  const validatedItems = checks.value.filter(item => item.checked)
  if (!validatedItems.length) return

  try {
    for (const item of validatedItems) {
      const { data: currentProduct, error: productGetError } = await supabase
        .from('products')
        .select('stok')
        .eq('id', item.product_id)
        .single()

      if (productGetError) throw productGetError

      const { error: productUpdateError } = await supabase
        .from('products')
        .update({ stok: Number(currentProduct?.stok || 0) + Number(item.qty) })
        .eq('id', item.product_id)

      if (productUpdateError) throw productUpdateError

      const { data: existingPrice, error: priceGetError } = await supabase
        .from('product_prices')
        .select('id, stok')
        .eq('product_id', item.product_id)
        .eq('supplier_id', order.value.supplier.id)
        .single()

      if (priceGetError && priceGetError.code !== 'PGRST116') throw priceGetError

      if (existingPrice?.id) {
        const { error: priceUpdateError } = await supabase
          .from('product_prices')
          .update({
            stok: Number(existingPrice.stok || 0) + Number(item.qty),
            harga_beli: Number(item.unit_cost || 0),
            aktif: true,
          })
          .eq('id', existingPrice.id)

        if (priceUpdateError) throw priceUpdateError
      } else {
        const { error: priceInsertError } = await supabase
          .from('product_prices')
          .insert({
            product_id: item.product_id,
            supplier_id: order.value.supplier.id,
            stok: Number(item.qty),
            harga_beli: Number(item.unit_cost || 0),
            aktif: true,
          })

        if (priceInsertError) throw priceInsertError
      }
    }

    markPurchaseOrderReceived(order.value.no_order)
    refreshPendingOrders()
    alert('Receiving berhasil. Stok gudang bertambah sesuai validasi.')
    resetForm({ autoLoadLatest: true })
  } catch (err) {
    console.error('[confirmReceiving]', err)
    alert('Gagal proses receiving: ' + err.message)
  }
}

function resetForm({ autoLoadLatest = false } = {}) {
  order.value = null
  checks.value = []
  selectedRow.value = 0
  confirmVisible.value = false
  searchQuery.value = ''
  refreshPendingOrders()
  nextTick(() => {
    searchInput.value?.focus()
    if (autoLoadLatest && pendingOrders.value.length) {
      selectedPendingRow.value = 0
    }
  })
}

function formatDateTime(value) {
  if (!value) return '-'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '-'
  return date.toLocaleString('id-ID', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

onMounted(() => {
  pageEl.value?.focus()
  refreshPendingOrders()
  selectedPendingRow.value = 0
  nextTick(() => searchInput.value?.focus())
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<style scoped>
@import '@/assets/components/modal.css';
@import '@/assets/pages/pembelian/pembelian-receiving-page.css';
</style>
