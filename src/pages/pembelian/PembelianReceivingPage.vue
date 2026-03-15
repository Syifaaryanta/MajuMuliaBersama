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
              <p>Semua item sudah tervalidasi. Lanjutkan proses barang masuk gudang?</p>
              <p class="modal-shortcut">Enter: Konfirmasi · Esc: Batal</p>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="confirmVisible = false">Batal</button>
              <button class="btn-primary" @click="confirmReceiving">Konfirmasi</button>
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
import { supabase } from '@/lib/supabase'
import { getPurchaseOrderByNo, markPurchaseOrderReceived } from '@/lib/pembelianStore'

const router = useRouter()
const pageEl = ref(null)
const searchInput = ref(null)
const searchQuery = ref('')
const order = ref(null)
const checks = ref([])
const selectedRow = ref(0)
const confirmVisible = ref(false)

const checkedCount = computed(() => checks.value.filter(row => row.checked).length)
const canConfirm = computed(() => checks.value.length > 0 && checks.value.every(row => row.checked))

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
      openConfirmModal()
      return
    }

    if (e.key === 'y' || e.key === 'Y') {
      e.preventDefault()
      const row = checks.value[selectedRow.value]
      if (row) row.checked = true
      return
    }

    if (e.key === 'n' || e.key === 'N') {
      e.preventDefault()
      const row = checks.value[selectedRow.value]
      if (row) row.checked = false
      return
    }
  }

  if (e.key === 'Escape') {
    e.preventDefault()
    if (order.value) {
      resetForm()
    } else {
      router.push('/pembelian')
    }
  }
}

function openConfirmModal() {
  if (!canConfirm.value) {
    alert('Centang semua item dulu sebelum validasi receiving.')
    return
  }
  confirmVisible.value = true
}

function loadOrder() {
  const row = getPurchaseOrderByNo(searchQuery.value.trim())
  if (!row) {
    alert('No order tidak ditemukan.')
    return
  }
  if (row.status === 'received') {
    alert('Order ini sudah diterima sebelumnya.')
    return
  }

  order.value = row
  checks.value = row.items.map(item => ({ ...item, checked: false }))
  selectedRow.value = 0
  confirmVisible.value = false
}

async function confirmReceiving() {
  if (!order.value) return

  try {
    for (const item of checks.value) {
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
    alert('Receiving berhasil. Stok gudang bertambah sesuai validasi.')
    resetForm()
  } catch (err) {
    console.error('[confirmReceiving]', err)
    alert('Gagal proses receiving: ' + err.message)
  }
}

function resetForm() {
  order.value = null
  checks.value = []
  selectedRow.value = 0
  confirmVisible.value = false
  searchQuery.value = ''
  nextTick(() => searchInput.value?.focus())
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
@import '@/assets/components/modal.css';
@import '@/assets/pages/pembelian/pembelian-receiving-page.css';
</style>
