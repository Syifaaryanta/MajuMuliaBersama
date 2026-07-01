<template>
  <div class="pembelian-receiving-page" ref="pageEl" tabindex="-1">
    <Toast position="top-right" />

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="filterModal.show" class="modal-overlay" @click.self="closeFilterModalToMenu">
          <form class="modal-box modal-box--filter" role="dialog" aria-modal="true" @submit.prevent="applyFiltersAndCloseModal">
            <div class="modal-header modal-header--blue">
              <div class="modal-header-left">
                <div class="modal-header-icon">
                  <i class="pi pi-filter"></i>
                </div>
                <h3 class="modal-title">Filter Penerimaan Barang</h3>
              </div>
            </div>
            <div class="modal-body">
              <p class="modal-helper"></p>

              <div class="filter-grid">
                <label class="filter-field">
                  <span>Tanggal Awal</span>
                  <input
                    ref="filterStartInput"
                    v-model="filters.startDate"
                    type="date"
                    class="search-input"
                    @keydown.enter.stop.prevent="focusFilterEnd"
                  />
                </label>

                <label class="filter-field">
                  <span>Tanggal Akhir</span>
                  <input
                    ref="filterEndInput"
                    v-model="filters.endDate"
                    type="date"
                    class="search-input"
                    @keydown.enter.stop.prevent="focusFilterSupplier"
                  />
                </label>

                <label class="filter-field filter-field--full">
                  <span>Supplier (Opsional)</span>
                  <input
                    ref="filterSupplierInput"
                    v-model="filters.supplierName"
                    type="text"
                    class="search-input"
                    placeholder="Contoh: Denso"
                    @keydown.enter.stop.prevent="applyFiltersAndCloseModal"
                  />
                </label>
              </div>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn-secondary" @click="closeFilterModalToMenu">Batal</button>
              <button type="submit" class="btn-primary">
                <i class="pi pi-check"></i>
                <span>Enter</span>
              </button>
            </div>
          </form>
        </div>
      </Transition>
    </Teleport>

    <template v-if="!filterModal.show">
      <template v-if="hasAppliedFilter && !poModal.show">
      <div class="search-card">
        <div class="form-header">
          <h1 class="form-header-title">Penerimaan Barang Pembelian</h1>
          <p class="form-header-subtitle">Pilih No. Order pending, lalu validasi item barang.</p>
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
            <button class="search-btn" :disabled="!searchQuery.trim()" @click="loadOrder">Cari</button>
          </div>

          <div class="shortcuts-bar">
            <kbd>F1 No. Order</kbd>
            <kbd>F2 Tabel</kbd>
          </div>
        </div>
      </div>

      <div class="table-card order-list-card">
        <div class="order-summary">
          <strong>Daftar Order Pending</strong> · {{ pendingOrders.length }} order
        </div>

        <div v-if="pendingOrders.length" class="table-wrap">
          <table class="items-table pending-items-table">
            <thead>
              <tr>
                <th>No Order</th>
                <th class="updated-col">Diperbarui</th>
                <th>Supplier</th>
                <th>Item</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(pending, idx) in pendingOrders"
                :key="pending.no_order"
                :class="{ 'row-active': idx === selectedPendingRow }"
                :ref="el => setPendingRowRef(el, idx)"
                :tabindex="idx === selectedPendingRow ? 0 : -1"
                @click="onPendingRowClick(idx)"
                @dblclick="openOrderModal(pending.no_order, idx)"
              >
                <td><strong>{{ pending.no_order }}</strong></td>
                <td class="updated-col">{{ formatDateTime(pending.updated_at || pending.created_at) }}</td>
                <td>{{ pending.supplier?.nama || '-' }}</td>
                <td>{{ pending.items?.length || 0 }}</td>
                <td>
                  <span class="status-chip" :class="pendingStatusClass(pending)">
                    {{ pendingStatusLabel(pending) }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div v-else class="empty-order-list">Tidak ada order pending saat ini.</div>
      </div>
      </template>

      <template v-else-if="hasAppliedFilter">
      <div class="table-card receiving-step-card">
        <div class="order-summary order-summary--blue">
          <strong>Validasi  {{ poModal.order?.no_order || '-' }}</strong>
        </div>

        <div class="supplier-card">
          <div class="supplier-card-title">Supplier</div>
          <div class="supplier-card-name">{{ poModal.order?.supplier?.nama || '-' }}</div>
          <div class="supplier-card-meta">{{ poModal.order?.supplier?.alamat || '-' }}</div>
        </div>

        <div class="step-shortcuts">
          <kbd>Enter Ceklis/Batal</kbd>
          <kbd>Arrow Pindah</kbd>
          <kbd>F10 Konfirmasi</kbd>
          <kbd>Del Hapus</kbd>
        </div>

        <div class="table-wrap">
          <table class="items-table receiving-items-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Kode</th>
                <th>Nama Barang</th>
                <th>Qty</th>
                <th>Valid</th>
                <th>Aksi</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(item, idx) in checks"
                :key="item.receiving_key || `${item.product_id}-${idx}`"
                :class="{ 'row-active': idx === selectedRow, 'row-validated': item.validated }"
                :ref="el => setItemRowRef(el, idx)"
                @click="focusItemRow(idx)"
              >
                <td>{{ idx + 1 }}</td>
                <td>{{ item.product_kode }}</td>
                <td>{{ item.product_nama }}</td>
                <td>{{ item.qty }}</td>
                <td>
                  <input
                    type="checkbox"
                    :checked="item.checked"
                    :disabled="validating"
                    tabindex="-1"
                    @click.stop.prevent="onToggleRowClick(idx)"
                  />
                </td>
                <td>
                  <button
                    type="button"
                    class="btn-icon btn-delete"
                    title="Hapus row (Del)"
                    :disabled="validating"
                    @click.stop="openDeleteConfirm(idx)"
                  >
                    <i class="pi pi-trash"></i>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="modal-footer">
          <div class="validation-status">Tervalidasi {{ validatedCount }}/{{ checks.length }} item</div>
          <div class="step-actions">
            <button class="btn-secondary" @click="closeOrderStep">Kembali Daftar</button>
            <button class="btn-primary" :disabled="validating" @click="openFinalizeConfirm">Konfirmasi (F10)</button>
          </div>
        </div>
      </div>
      </template>
    </template>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="finalizeConfirm.show" class="modal-overlay" @click.self="closeFinalizeConfirm">
          <div class="modal-box modal-box--sm" role="dialog" aria-modal="true">
            <div class="modal-header modal-header--blue modal-header--centered">
              <i class="pi pi-check-circle"></i>
              <h3 class="modal-title">Konfirmasi Validasi</h3>
            </div>
            <div class="modal-body">
              <p>{{ finalizeConfirm.message }}</p>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="closeFinalizeConfirm">Batal</button>
              <button class="btn-primary" :disabled="validating" @click="confirmFinalize">Konfirmasi</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="deleteConfirm.show" class="modal-overlay" @click.self="closeDeleteConfirm">
          <div class="modal-box modal-box--sm" role="dialog" aria-modal="true">
            <div class="modal-header modal-header--danger modal-header--centered">
              <i class="pi pi-exclamation-triangle"></i>
              <h3 class="modal-title">Konfirmasi Hapus</h3>
            </div>
            <div class="modal-body modal-body--centered">
              <p>{{ deleteConfirm.message }}</p>
              <p class="modal-shortcut">Enter: Hapus · Esc: Batal</p>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="closeDeleteConfirm">Batal</button>
              <button class="btn-primary" @click="confirmDeleteRow">Hapus</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, nextTick, onMounted, onUnmounted, onActivated, watch } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useToast } from 'primevue/usetoast'
import Toast from 'primevue/toast'
import {
  getPurchaseOrderByNo,
  listPurchaseOrders,
  upsertPurchaseOrder,
  getPurchaseReceivingItemKey,
  removePurchaseOrder,
} from '@/lib/pembelianStore'

const router = useRouter()
const toast = useToast()
const pageEl = ref(null)
const searchInput = ref(null)
const filterStartInput = ref(null)
const filterEndInput = ref(null)
const filterSupplierInput = ref(null)
const searchQuery = ref('')

const pendingOrders = ref([])
const pendingRowRefs = ref({})
const selectedPendingRow = ref(0)

const filterModal = ref({ show: true })
const filters = ref({
  startDate: '',
  endDate: '',
  supplierName: '',
})
const hasAppliedFilter = ref(false)

const poModal = ref({ show: false, order: null })
const checks = ref([])
const itemRowRefs = ref({})
const selectedRow = ref(0)
const validating = ref(false)
const finalizeConfirm = ref({ show: false, message: '' })

const deleteConfirm = ref({ show: false, mode: '', rowIndex: -1, orderNo: '', message: '' })

const validatedCount = computed(() => checks.value.filter(row => row.validated).length)

function setPendingRowRef(el, idx) {
  if (el) pendingRowRefs.value[idx] = el
}

function setItemRowRef(el, idx) {
  if (el) itemRowRefs.value[idx] = el
}

function focusPendingRow(idx = 0) {
  nextTick(() => {
    pendingRowRefs.value[idx]?.focus?.()
  })
}

function focusItemRow(idx = 0) {
  selectedRow.value = Math.max(0, Math.min(idx, checks.value.length - 1))
  nextTick(() => {
    itemRowRefs.value[selectedRow.value]?.focus?.()
  })
}

async function listPendingOrdersOnly() {
  const orders = await listPurchaseOrders()
  return orders
    .filter(row => row?.no_order && row.status !== 'draft')
    .sort((a, b) => {
      const timeA = new Date(a.updated_at || a.created_at || a.order_date || 0).getTime()
      const timeB = new Date(b.updated_at || b.created_at || b.order_date || 0).getTime()
      const diff = timeB - timeA
      if (diff !== 0) return diff
      return String(b.no_order || '').localeCompare(String(a.no_order || ''))
    })
}

function pad2(value) {
  return String(value).padStart(2, '0')
}

function toDateInputValue(date) {
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`
}

function startOfCurrentMonth() {
  const now = new Date()
  return new Date(now.getFullYear(), now.getMonth(), 1)
}

function toDateKeyFromDateObj(date) {
  if (!(date instanceof Date) || Number.isNaN(date.getTime())) return ''
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`
}

function toDateKey(value) {
  const raw = String(value || '').trim()
  if (!raw) return ''

  const isoDateOnlyMatch = raw.match(/^(\d{4})-(\d{2})-(\d{2})$/)
  if (isoDateOnlyMatch) return `${isoDateOnlyMatch[1]}-${isoDateOnlyMatch[2]}-${isoDateOnlyMatch[3]}`

  const isoWithTimeMatch = raw.match(/^(\d{4})-(\d{2})-(\d{2})T/)
  if (isoWithTimeMatch) {
    const parsedIso = new Date(raw)
    return toDateKeyFromDateObj(parsedIso)
  }

  const idMatch = raw.match(/^(\d{2})\/(\d{2})\/(\d{4})/)
  if (idMatch) return `${idMatch[3]}-${idMatch[2]}-${idMatch[1]}`

  const dashIdMatch = raw.match(/^(\d{2})-(\d{2})-(\d{4})/)
  if (dashIdMatch) return `${dashIdMatch[3]}-${dashIdMatch[2]}-${dashIdMatch[1]}`

  const parsed = new Date(raw)
  return toDateKeyFromDateObj(parsed)
}

function getFilterDateRange() {
  const start = String(filters.value.startDate || '')
  const end = String(filters.value.endDate || '')
  return { start, end }
}

function getOrderDateKey(order) {
  const displaySource = order?.updated_at || order?.created_at || order?.order_date
  return toDateKey(displaySource)
}

function isOrderInDateRange(order, start, end) {
  const dateKey = getOrderDateKey(order)
  if (!dateKey) return false

  if (start && dateKey < start) return false
  if (end && dateKey > end) return false
  return true
}

function applyPendingFilters(orders) {
  const supplierFilter = filters.value.supplierName.trim().toLowerCase()
  const { start, end } = getFilterDateRange()

  return orders.filter(order => {
    if (!isOrderInDateRange(order, start, end)) return false
    if (!supplierFilter) return true
    const supplierName = String(order?.supplier?.nama || order?.supplier_nama || '').toLowerCase()
    return supplierName.includes(supplierFilter)
  })
}

function setDefaultFilters() {
  filters.value = {
    startDate: toDateInputValue(startOfCurrentMonth()),
    endDate: toDateInputValue(new Date()),
    supplierName: '',
  }
}

function getValidatedCount(order) {
  const items = Array.isArray(order?.items) ? order.items : []
  const validations = order?.receiving_validations || {}
  if (!items.length) return 0

  let count = 0
  items.forEach((item, idx) => {
    const key = getPurchaseReceivingItemKey(item, idx)
    if (validations[key]) count += 1
  })
  return count
}

function pendingStatusLabel(order) {
  const total = Array.isArray(order?.items) ? order.items.length : 0
  const validated = getValidatedCount(order)

  if (!total || validated === 0) return 'Belum Validasi'
  if (validated >= total) return 'Sudah Validasi'
  return 'Sebagian Validasi'
}

function pendingStatusClass(order) {
  const label = pendingStatusLabel(order)
  if (label === 'Sudah Validasi') return 'status-chip--done'
  if (label === 'Sebagian Validasi') return 'status-chip--partial'
  return 'status-chip--none'
}

async function refreshPendingOrders() {
  const dbOrders = await listPendingOrdersOnly()
  pendingOrders.value = applyPendingFilters(dbOrders)
  pendingRowRefs.value = {}

  if (!pendingOrders.value.length) {
    selectedPendingRow.value = 0
    return
  }

  if (selectedPendingRow.value > pendingOrders.value.length - 1) {
    selectedPendingRow.value = pendingOrders.value.length - 1
  }

  focusPendingRow(selectedPendingRow.value)
}

function openFilterModal() {
  filterModal.value.show = true
  nextTick(() => {
    filterStartInput.value?.focus?.()
  })
}

function closeFilterModalToMenu() {
  router.push('/pembelian')
}

function focusFilterEnd() {
  nextTick(() => filterEndInput.value?.focus?.())
}

function focusFilterSupplier() {
  nextTick(() => filterSupplierInput.value?.focus?.())
}

async function applyFiltersAndCloseModal() {
  const { start, end } = getFilterDateRange()
  if (start && end && start > end) {
    toast.add({
      severity: 'warn',
      summary: 'Periksa Tanggal',
      detail: 'Tanggal awal tidak boleh lebih besar dari tanggal akhir.',
      life: 2600,
    })
    nextTick(() => filterStartInput.value?.focus?.())
    return
  }

  await refreshPendingOrders()
  hasAppliedFilter.value = true
  filterModal.value.show = false
  nextTick(() => {
    if (poModal.value.show) {
      focusItemRow(selectedRow.value)
      return
    }
    focusPendingRow(selectedPendingRow.value)
  })
}

function buildChecks(order) {
  const validations = order?.receiving_validations || {}
  const receivedAtMap = order?.receiving_validated_at || {}
  return (order?.items || []).map((item, idx) => {
    const receivingKey = getPurchaseReceivingItemKey(item, idx)
    const persistedValidated = Boolean(validations[receivingKey])
    const persistedReceivedAt =
      receivedAtMap[receivingKey] ||
      (persistedValidated ? order?.received_at || null : null)

    return {
      ...item,
      receiving_key: receivingKey,
      received_at: persistedReceivedAt,
      validated: persistedValidated,
      checked: persistedValidated,
    }
  })
}

function onPendingRowClick(idx) {
  selectedPendingRow.value = idx
  focusPendingRow(idx)
}

async function openOrderModal(noOrder, idx = 0) {
  let order = null
  try {
    order = await getPurchaseOrderByNo(noOrder)
  } catch (err) {
    console.error('[openOrderModal receiving]', err)
    alert('Gagal memuat order dari database: ' + err.message)
    return
  }

  if (!order || order.status === 'draft') return

  selectedPendingRow.value = idx
  poModal.value = { show: true, order }
  checks.value = buildChecks(order)
  itemRowRefs.value = {}
  selectedRow.value = 0
  focusItemRow(0)
}

async function loadOrder() {
  const typedNo = searchQuery.value.trim()
  if (!typedNo) return

  const idx = pendingOrders.value.findIndex(row => row.no_order === typedNo)
  if (idx < 0) {
    alert('No order tidak ditemukan atau belum masuk antrian receiving.')
    return
  }

  await openOrderModal(typedNo, idx)
  searchQuery.value = ''
}

function closeOrderStep() {
  poModal.value = { show: false, order: null }
  checks.value = []
  selectedRow.value = 0
  itemRowRefs.value = {}
  closeFinalizeConfirm()
  focusPendingRow(selectedPendingRow.value)
}

function goBackToMenu() {
  router.push('/pembelian')
}

async function persistOrderFromChecks(nextChecks) {
  if (!poModal.value.order) return

  const receivingValidations = {}
  const receivingValidatedAt = {}
  const now = new Date().toISOString()

  nextChecks.forEach((row, idx) => {
    const key = row.receiving_key || getPurchaseReceivingItemKey(row, idx)
    const isValidated = Boolean(row.validated)
    receivingValidations[key] = isValidated
    if (isValidated) {
      receivingValidatedAt[key] = row.received_at || now
    }
  })

  const allValidated = nextChecks.length > 0 && nextChecks.every(row => row.validated)

  await upsertPurchaseOrder({
    ...poModal.value.order,
    status: allValidated ? 'received' : 'ordered',
    received_at: allValidated ? now : null,
    receiving_validations: receivingValidations,
    receiving_validated_at: receivingValidatedAt,
    items: nextChecks.map(({ validated, checked, received_at, ...rest }) => ({ ...rest })),
  })

  const latest = await getPurchaseOrderByNo(poModal.value.order.no_order)
  if (latest) {
    poModal.value.order = latest
  }
}

async function applyReceivingForItem(item) {
  const supplierId = poModal.value.order?.supplier?.id
  const qty = Number(item?.qty || 0)
  if (!supplierId || qty <= 0) return

  const { data: currentProduct, error: productGetError } = await supabase
    .from('products')
    .select('stok')
    .eq('id', item.product_id)
    .single()

  if (productGetError) throw productGetError

  const { data: priceRows, error: priceRowsError } = await supabase
    .from('product_prices')
    .select('id, supplier_id, stok, aktif')
    .eq('product_id', item.product_id)

  if (priceRowsError) throw priceRowsError

  const allPriceRows = Array.isArray(priceRows) ? priceRows : []
  const activeRows = allPriceRows.filter(row => row.aktif !== false)
  const totalActiveStok = activeRows.reduce((sum, row) => sum + Number(row.stok || 0), 0)
  const productStokBefore = Number(currentProduct?.stok || 0)

  // Jika ada selisih stok lama antara products vs product_prices,
  // injeksikan selisih ke supplier baris ini agar trigger tetap menghasilkan stok yang benar.
  const stokGap = Math.max(0, productStokBefore - totalActiveStok)

  const targetRow = allPriceRows.find(row => String(row.supplier_id) === String(supplierId))

  if (targetRow?.id) {
    const nextSupplierStok = Number(targetRow.stok || 0) + qty + stokGap
    const { error: priceUpdateError } = await supabase
      .from('product_prices')
      .update({
        stok: nextSupplierStok,
        harga_beli: Number(item.unit_cost || 0),
        aktif: true,
      })
      .eq('id', targetRow.id)

    if (priceUpdateError) throw priceUpdateError
  } else {
    const { error: priceInsertError } = await supabase
      .from('product_prices')
      .insert({
        product_id: item.product_id,
        supplier_id: supplierId,
        stok: qty + stokGap,
        harga_beli: Number(item.unit_cost || 0),
        aktif: true,
      })

    if (priceInsertError) throw priceInsertError
  }
}

async function rollbackReceivingForItem(item) {
  const supplierId = poModal.value.order?.supplier?.id
  const qty = Number(item?.qty || 0)
  if (!supplierId || qty <= 0) return

  const { data: existingPrice, error: priceGetError } = await supabase
    .from('product_prices')
    .select('id, stok')
    .eq('product_id', item.product_id)
    .eq('supplier_id', supplierId)
    .single()

  if (priceGetError && priceGetError.code !== 'PGRST116') throw priceGetError
  if (!existingPrice?.id) {
    throw new Error('Data stok supplier tidak ditemukan untuk rollback receiving.')
  }

  const nextPriceStok = Math.max(0, Number(existingPrice.stok || 0) - qty)
  const { error: priceUpdateError } = await supabase
    .from('product_prices')
    .update({ stok: nextPriceStok })
    .eq('id', existingPrice.id)

  if (priceUpdateError) throw priceUpdateError
}

function toggleCurrentRowAndAdvance() {
  if (!poModal.value.show) return
  const row = checks.value[selectedRow.value]
  if (!row) return

  const nextChecks = checks.value.map((item, idx) =>
    idx === selectedRow.value ? { ...item, checked: !item.checked } : item
  )

  checks.value = nextChecks
  const nextIdx = Math.min(selectedRow.value + 1, checks.value.length - 1)
  focusItemRow(nextIdx)
}

function onToggleRowClick(idx) {
  focusItemRow(idx)
  toggleCurrentRowAndAdvance()
}

function openFinalizeConfirm() {
  const pendingCount = checks.value.filter(row => !row.checked).length
  if (pendingCount === 0) {
    finalizeConfirm.value = {
      show: true,
      message: 'Semua item sudah dicentang. Lanjutkan validasi dan update stok gudang?',
    }
    return
  }

  finalizeConfirm.value = {
    show: true,
    message: `Masih ada ${pendingCount} item belum dicentang, tapi Anda tetap bisa konfirmasi. Lanjutkan update stok gudang?`,
  }
}

function closeFinalizeConfirm() {
  finalizeConfirm.value = { show: false, message: '' }
}

async function confirmFinalize() {
  if (!poModal.value.show || validating.value) return

  const toValidate = checks.value.filter(row => row.checked && !row.validated)
  const toRollback = checks.value.filter(row => !row.checked && row.validated)
  const validatedNow = new Set(toValidate.map(row => String(row.receiving_key || '')))
  const confirmedAt = new Date().toISOString()

  validating.value = true
  try {
    for (const item of toValidate) {
      await applyReceivingForItem(item)
    }

    for (const item of toRollback) {
      await rollbackReceivingForItem(item)
    }

    const nextChecks = checks.value.map(row => {
      const key = String(row.receiving_key || '')
      if (!row.checked) {
        return {
          ...row,
          validated: false,
          received_at: null,
        }
      }

      const receiveDate = validatedNow.has(key)
        ? confirmedAt
        : (row.received_at || confirmedAt)

      return {
        ...row,
        validated: true,
        received_at: receiveDate,
      }
    })

    checks.value = nextChecks
    await persistOrderFromChecks(nextChecks)

    await refreshPendingOrders()
    closeFinalizeConfirm()
    closeOrderStep()

    let detailMessage = 'Validasi tidak berubah.'
    if (toValidate.length > 0 && toRollback.length > 0) {
      detailMessage = `${toValidate.length} item masuk gudang, ${toRollback.length} item dibatalkan dan stok dikurangi.`
    } else if (toValidate.length > 0) {
      detailMessage = `${toValidate.length} item tervalidasi masuk ke gudang.`
    } else if (toRollback.length > 0) {
      detailMessage = `${toRollback.length} item dibatalkan validasinya dan stok gudang dikurangi.`
    }

    toast.add({
      severity: 'success',
      summary: 'Berhasil',
      detail: detailMessage,
      life: 3200,
    })
  } catch (err) {
    console.error('[confirmFinalize]', err)
    alert('Gagal konfirmasi validasi: ' + err.message)
  } finally {
    validating.value = false
  }
}

function openDeleteConfirm(idx) {
  const row = checks.value[idx]
  if (!row) return

  deleteConfirm.value = {
    show: true,
    mode: 'row',
    rowIndex: idx,
    orderNo: poModal.value.order?.no_order || '',
    message: `Hapus row ${idx + 1} (${row.product_nama || '-'}) dari ${poModal.value.order?.no_order || '-'}?`,
  }
}

function openPendingDeleteConfirm(idx) {
  const target = pendingOrders.value[idx]
  if (!target?.no_order) return

  deleteConfirm.value = {
    show: true,
    mode: 'order',
    rowIndex: idx,
    orderNo: target.no_order,
    message: `Hapus order ${target.no_order}? Item yang sudah tervalidasi akan dikurangi dari stok gudang.`,
  }
}

function closeDeleteConfirm() {
  deleteConfirm.value = { show: false, mode: '', rowIndex: -1, orderNo: '', message: '' }
}

async function rollbackValidatedItemsFromWarehouse(order) {
  const supplierId = order?.supplier?.id
  const items = Array.isArray(order?.items) ? order.items : []
  const validations = order?.receiving_validations || {}

  if (!supplierId) return

  for (let idx = 0; idx < items.length; idx += 1) {
    const item = items[idx]
    const key = getPurchaseReceivingItemKey(item, idx)
    if (!validations[key]) continue

    const qty = Number(item.qty || 0)
    if (qty <= 0) continue

    const { data: existingPrice, error: priceGetError } = await supabase
      .from('product_prices')
      .select('id, stok')
      .eq('product_id', item.product_id)
      .eq('supplier_id', supplierId)
      .single()

    if (priceGetError && priceGetError.code !== 'PGRST116') throw priceGetError
    if (!existingPrice?.id) {
      throw new Error('Data stok supplier tidak ditemukan untuk rollback order receiving.')
    }

    const nextPriceStok = Math.max(0, Number(existingPrice.stok || 0) - qty)
    const { error: priceUpdateError } = await supabase
      .from('product_prices')
      .update({ stok: nextPriceStok })
      .eq('id', existingPrice.id)

    if (priceUpdateError) throw priceUpdateError
  }
}

async function confirmDeleteRow() {
  const idx = deleteConfirm.value.rowIndex
  const mode = deleteConfirm.value.mode
  const orderNo = deleteConfirm.value.orderNo
  closeDeleteConfirm()

  if (mode === 'order') {
    const order = await getPurchaseOrderByNo(orderNo)
    if (!order?.no_order) return

    validating.value = true
    try {
      await rollbackValidatedItemsFromWarehouse(order)
      await removePurchaseOrder(order.no_order)

      if (poModal.value.order?.no_order === order.no_order) {
        closeOrderStep()
      }

      await refreshPendingOrders()
      selectedPendingRow.value = Math.max(0, Math.min(idx, pendingOrders.value.length - 1))
      focusPendingRow(selectedPendingRow.value)
    } catch (err) {
      console.error('[confirmDeleteOrder]', err)
      alert('Gagal hapus order: ' + err.message)
    } finally {
      validating.value = false
    }
    return
  }

  if (idx < 0 || idx >= checks.value.length) return
  const target = checks.value[idx]

  if (target.validated) {
    alert('Row yang sudah tervalidasi tidak bisa dihapus.')
    return
  }

  const nextChecks = checks.value.filter((_, i) => i !== idx)
  if (!nextChecks.length) {
    const currentNoOrder = poModal.value.order.no_order
    await removePurchaseOrder(currentNoOrder)

    poModal.value = { show: false, order: null }
    checks.value = []
    selectedRow.value = 0
    await refreshPendingOrders()
    return
  }

  checks.value = nextChecks
  await persistOrderFromChecks(nextChecks)

  await refreshPendingOrders()
  focusItemRow(Math.min(idx, nextChecks.length - 1))
}

function handleKeydown(e) {
  if (filterModal.value.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      closeFilterModalToMenu()
    }
    return
  }

  if (finalizeConfirm.value.show) {
    if (e.key === 'Enter') {
      e.preventDefault()
      confirmFinalize()
    }
    if (e.key === 'Escape') {
      e.preventDefault()
      closeFinalizeConfirm()
    }
    return
  }

  if (deleteConfirm.value.show) {
    if (e.key === 'Enter') {
      e.preventDefault()
      confirmDeleteRow()
    }
    if (e.key === 'Escape') {
      e.preventDefault()
      closeDeleteConfirm()
    }
    return
  }

  if (poModal.value.show) {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      focusItemRow(Math.min(selectedRow.value + 1, checks.value.length - 1))
      return
    }

    if (e.key === 'ArrowUp') {
      e.preventDefault()
      focusItemRow(Math.max(selectedRow.value - 1, 0))
      return
    }

    if (e.key === 'Enter') {
      e.preventDefault()
      toggleCurrentRowAndAdvance()
      return
    }

    if (e.key === 'F10') {
      e.preventDefault()
      openFinalizeConfirm()
      return
    }

    if (e.key === 'Delete') {
      e.preventDefault()
      openDeleteConfirm(selectedRow.value)
      return
    }

    if (e.key === 'Escape') {
      e.preventDefault()
      openFilterModal()
    }
    return
  }

  if (e.key === 'F1') {
    e.preventDefault()
    nextTick(() => searchInput.value?.focus())
    return
  }

  if (e.key === 'F2') {
    e.preventDefault()
    focusPendingRow(selectedPendingRow.value)
    return
  }

  if (!pendingOrders.value.length) {
    if (e.key === 'Escape') {
      e.preventDefault()
      openFilterModal()
    }
    return
  }

  if (e.key === 'ArrowDown') {
    e.preventDefault()
    selectedPendingRow.value = Math.min(selectedPendingRow.value + 1, pendingOrders.value.length - 1)
    focusPendingRow(selectedPendingRow.value)
    return
  }

  if (e.key === 'ArrowUp') {
    e.preventDefault()
    selectedPendingRow.value = Math.max(selectedPendingRow.value - 1, 0)
    focusPendingRow(selectedPendingRow.value)
    return
  }

  if (e.key === 'Enter') {
    e.preventDefault()
    const target = pendingOrders.value[selectedPendingRow.value]
    if (target?.no_order) {
      void openOrderModal(target.no_order, selectedPendingRow.value)
    }
    return
  }

  if (e.key === 'Delete') {
    e.preventDefault()
    openPendingDeleteConfirm(selectedPendingRow.value)
    return
  }

  if (e.key === 'Escape') {
    e.preventDefault()
    openFilterModal()
  }
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

function resetToInitialFilterMode() {
  setDefaultFilters()
  filterModal.value.show = true
  hasAppliedFilter.value = false
  poModal.value = { show: false, order: null }
  checks.value = []
  selectedRow.value = 0
  selectedPendingRow.value = 0
  pendingOrders.value = []
}

onMounted(() => {
  pageEl.value?.focus()
  resetToInitialFilterMode()

  if (filterModal.value.show) {
    nextTick(() => filterStartInput.value?.focus?.())
  } else if (poModal.value.show) {
    focusItemRow(selectedRow.value)
  } else {
    focusPendingRow(selectedPendingRow.value)
  }

  window.addEventListener('keydown', handleKeydown)
})

onActivated(() => {
  resetToInitialFilterMode()
  nextTick(() => filterStartInput.value?.focus?.())
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})

watch(() => filterModal.value.show, (isOpen) => {
  if (!isOpen && !hasAppliedFilter.value) {
    nextTick(() => {
      filterModal.value.show = true
      filterStartInput.value?.focus?.()
    })
  }
})
</script>

<style scoped>
@import '@/assets/components/modal.css';
@import '@/assets/Styles/pembelian/pembelian-receiving-page.css';
</style>
