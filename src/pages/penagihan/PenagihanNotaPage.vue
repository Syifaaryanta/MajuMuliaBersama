<template>
  <div class="penagihan-sub-page penagihan-nota-page" ref="pageEl" tabindex="-1">
    <Toast position="top-right" />

    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Manajemen Nota</h1>
        <p class="g-subtitle">Validasi nota merah, putih, dan kuning agar sesuai status pembayaran customer</p>
      </div>
      <span v-if="isReadOnly" class="read-only-badge">
        <i class="pi pi-lock"></i>
        Mode Read Only
      </span>
    </div>

    <div class="shortcut-strip">
      <kbd>F1 Cari</kbd>
      <kbd>Arrow Pilih Baris</kbd>
      <kbd>Enter Simpan</kbd>
      <kbd>F4 Sinkron 1 Baris</kbd>
      <kbd>Esc Kembali</kbd>
    </div>

    <div v-if="schemaError" class="schema-warning">
      <i class="pi pi-exclamation-triangle"></i>
      <div>
        <strong>Schema Penagihan Belum Siap</strong>
        <p>{{ schemaError }}</p>
        <span>Jalankan migrasi: server/schema/22_penagihan_payments_and_notes.sql</span>
      </div>
    </div>

    <template v-else>
      <div class="toolbar-card">
        <div class="search-field toolbar-search">
          <label class="search-label">
            No. Order / No. Faktur / Customer
            <kbd class="label-kbd">F1</kbd>
          </label>
          <div class="search-input-wrap" :class="{ focused: focusKey === 'search' }">
            <i class="pi pi-search si-icon"></i>
            <input
              ref="searchInput"
              v-model="searchQuery"
              type="text"
              class="search-input"
              placeholder="Ketik untuk filter data..."
              @focus="focusKey = 'search'"
              @blur="focusKey = ''"
            />
            <button v-if="searchQuery" class="clear-btn" @click="searchQuery = ''" tabindex="-1">
              <i class="pi pi-times"></i>
            </button>
          </div>
        </div>

        <div class="toolbar-actions">
          <div class="filter-chip-group">
            <button
              v-for="chip in filterOptions"
              :key="chip.id"
              type="button"
              class="filter-chip"
              :class="{ 'filter-chip--active': activeFilter === chip.id }"
              @click="activeFilter = chip.id"
            >
              {{ chip.label }}
            </button>
          </div>
        </div>
      </div>

      <div class="table-section">
        <div class="result-meta">
          <span class="result-count"><b>{{ rows.length }}</b> transaksi tampil</span>
          <span class="page-info">Perlu sinkron: <b>{{ mismatchCount }}</b></span>
        </div>

        <div class="table-wrap">
          <table class="g-table">
            <thead>
              <tr>
                <th class="col-no">#</th>
                <th class="col-order">No. Order</th>
                <th class="col-customer">Customer</th>
                <th class="col-term">Term</th>
                <th class="col-money">Total</th>
                <th class="col-money">Sisa</th>
                <th class="col-status">Status</th>
                <th class="col-nota">Merah</th>
                <th class="col-nota">Putih</th>
                <th class="col-nota">Kuning</th>
                <th class="col-aksi">Aksi</th>
              </tr>
            </thead>
            <tbody v-if="loading">
              <tr v-for="n in 6" :key="`loading-${n}`">
                <td colspan="11"><div class="skeleton"></div></td>
              </tr>
            </tbody>
            <tbody v-else-if="rows.length === 0">
              <tr>
                <td colspan="11" class="empty-cell">
                  <i class="pi pi-inbox"></i>
                  Tidak ada data nota sesuai filter.
                </td>
              </tr>
            </tbody>
            <tbody v-else>
              <tr
                v-for="(row, idx) in rows"
                :key="row.sale_id"
                :ref="el => setRowRef(el, idx)"
                :class="{ 'g-row--active': selectedRowIndex === idx }"
                @click="selectedRowIndex = idx"
              >
                <td class="col-no">{{ idx + 1 }}</td>
                <td class="col-order">
                  <span class="kode-badge">{{ row.no_order }}</span>
                  <div class="row-sub">Fraktur: {{ row.no_faktur || '-' }}</div>
                </td>
                <td class="col-customer">
                  <div class="customer-cell">
                    <span class="customer-name">{{ row.customer_nama }}</span>
                    <span class="customer-addr">{{ row.customer_alamat || '-' }}</span>
                  </div>
                </td>
                <td class="col-term"><span class="term-badge">{{ row.payment_term_label }}</span></td>
                <td class="col-money"><span class="harga-val">{{ formatRp(row.grand_total) }}</span></td>
                <td class="col-money">
                  <strong :class="{ 'outstanding-val': Number(row.outstanding_amount || 0) > 0 }">
                    {{ formatRp(row.outstanding_amount) }}
                  </strong>
                </td>
                <td class="col-status">
                  <span class="status-pill" :class="statusClass(row.payment_status)">
                    {{ paymentStatusLabel(row.payment_status) }}
                  </span>
                </td>
                <td class="col-nota">
                  <label class="note-check">
                    <input
                      type="checkbox"
                      :checked="getNoteState(row, 'nota_merah')"
                      :disabled="isReadOnly || isRowSaving(row)"
                      @change="onToggleNote(row, 'nota_merah', $event.target.checked)"
                    />
                  </label>
                </td>
                <td class="col-nota">
                  <label class="note-check">
                    <input
                      type="checkbox"
                      :checked="getNoteState(row, 'nota_putih')"
                      :disabled="isReadOnly || isRowSaving(row)"
                      @change="onToggleNote(row, 'nota_putih', $event.target.checked)"
                    />
                  </label>
                </td>
                <td class="col-nota">
                  <label class="note-check">
                    <input
                      type="checkbox"
                      :checked="getNoteState(row, 'nota_kuning')"
                      :disabled="isReadOnly || isRowSaving(row)"
                      @change="onToggleNote(row, 'nota_kuning', $event.target.checked)"
                    />
                  </label>
                </td>
                <td class="col-aksi">
                  <div class="aksi-wrap">
                    <button
                      class="aksi-btn aksi-edit"
                      :disabled="isReadOnly || !hasDraftChanges(row) || isRowSaving(row)"
                      :title="isReadOnly ? 'Mode read only' : 'Simpan perubahan nota'"
                      @click.stop="saveRow(row)"
                    >
                      <i class="pi pi-save"></i>
                    </button>
                    <button
                      class="aksi-btn aksi-view"
                      :disabled="isReadOnly || isRowSaving(row)"
                      :title="isReadOnly ? 'Mode read only' : 'Sinkron otomatis berdasar status pembayaran'"
                      @click.stop="syncRowByRule(row)"
                    >
                      <i class="pi pi-check-square"></i>
                    </button>
                  </div>
                  <p v-if="getRowError(row)" class="row-error">{{ getRowError(row) }}</p>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed, nextTick, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import Toast from 'primevue/toast'
import {
  fetchPenagihanSales,
  filterBySearch,
  paymentStatusLabel,
  statusClass,
  formatRp,
  isSchemaIssue,
  updateSalesNotes,
  buildAutoNotePayload,
  subscribePenagihanAutoSync,
} from '@/lib/penagihanService'

const router = useRouter()
const route = useRoute()
const toast = useToast()

const pageEl = ref(null)
const searchInput = ref(null)
const focusKey = ref('')
const loading = ref(false)
const schemaError = ref('')
const searchQuery = ref('')
const activeFilter = ref('all')
const selectedRowIndex = ref(0)
const rowRefs = ref({})
let stopAutoSync = () => {}

const salesRows = ref([])
const draftNotes = reactive({})

const isReadOnly = computed(() => Boolean(route.meta.readOnly))

const filterOptions = [
  { id: 'all', label: 'Semua' },
  { id: 'debt', label: 'Piutang Aktif' },
  { id: 'paid', label: 'Lunas / Tunai' },
  { id: 'need_sync', label: 'Perlu Sinkron' },
]

function getExpectedNotes(row) {
  return buildAutoNotePayload(row.outstanding_amount)
}

function isNotaMismatch(row) {
  const expected = getExpectedNotes(row)
  return (
    Boolean(row.nota_merah) !== Boolean(expected.nota_merah) ||
    Boolean(row.nota_putih) !== Boolean(expected.nota_putih) ||
    Boolean(row.nota_kuning) !== Boolean(expected.nota_kuning)
  )
}

const rows = computed(() => {
  let data = salesRows.value.slice()

  if (activeFilter.value === 'debt') {
    data = data.filter(row => row.is_credit && Number(row.outstanding_amount || 0) > 0)
  } else if (activeFilter.value === 'paid') {
    data = data.filter(row => Number(row.outstanding_amount || 0) <= 0)
  } else if (activeFilter.value === 'need_sync') {
    data = data.filter(row => isNotaMismatch(row))
  }

  return filterBySearch(data, searchQuery.value, row => {
    return [row.no_order, row.no_faktur, row.customer_nama, row.customer_alamat].join(' ')
  })
})

const mismatchCount = computed(() => salesRows.value.filter(row => isNotaMismatch(row)).length)
const selectedRow = computed(() => rows.value[selectedRowIndex.value] || null)

watch(rows, (data) => {
  rowRefs.value = {}

  if (!data.length) {
    selectedRowIndex.value = 0
    return
  }

  if (selectedRowIndex.value >= data.length) {
    selectedRowIndex.value = data.length - 1
  }

  nextTick(() => ensureSelectedRowVisible())
}, { immediate: true })

watch(selectedRowIndex, () => {
  nextTick(() => ensureSelectedRowVisible())
})

function clearDraftNotes() {
  Object.keys(draftNotes).forEach(key => {
    delete draftNotes[key]
  })
}

function ensureDraft(row) {
  const key = row.sale_id
  if (!draftNotes[key]) {
    draftNotes[key] = {
      nota_merah: Boolean(row.nota_merah),
      nota_putih: Boolean(row.nota_putih),
      nota_kuning: Boolean(row.nota_kuning),
      dirty: false,
      saving: false,
      error: '',
    }
  }
  return draftNotes[key]
}

function refreshDraftDirtyState(row, draft) {
  draft.dirty = (
    Boolean(draft.nota_merah) !== Boolean(row.nota_merah) ||
    Boolean(draft.nota_putih) !== Boolean(row.nota_putih) ||
    Boolean(draft.nota_kuning) !== Boolean(row.nota_kuning)
  )
}

function getNoteState(row, key) {
  const draft = draftNotes[row.sale_id]
  if (!draft) return Boolean(row[key])
  return Boolean(draft[key])
}

function onToggleNote(row, key, checked) {
  if (isReadOnly.value) {
    toast.add({
      severity: 'warn',
      summary: 'Akses Read Only',
      detail: 'Akun ini tidak memiliki izin ubah nota.',
      life: 2500,
    })
    return
  }

  const draft = ensureDraft(row)
  draft.error = ''
  draft[key] = Boolean(checked)

  if (key === 'nota_merah' && checked) {
    draft.nota_putih = false
  }

  if (key === 'nota_putih' && checked) {
    draft.nota_merah = false
  }

  refreshDraftDirtyState(row, draft)
}

function hasDraftChanges(row) {
  return Boolean(draftNotes[row.sale_id]?.dirty)
}

function isRowSaving(row) {
  return Boolean(draftNotes[row.sale_id]?.saving)
}

function getRowError(row) {
  return draftNotes[row.sale_id]?.error || ''
}

function hasDirtyDrafts() {
  return Object.values(draftNotes).some(draft => draft?.dirty || draft?.saving)
}

async function saveRow(row, { silentIfNoChange = false } = {}) {
  if (!row) return false

  if (isReadOnly.value) {
    toast.add({
      severity: 'warn',
      summary: 'Akses Read Only',
      detail: 'Akun ini tidak memiliki izin ubah nota.',
      life: 2500,
    })
    return false
  }

  const draft = ensureDraft(row)
  draft.error = ''
  refreshDraftDirtyState(row, draft)

  if (!draft.dirty) {
    if (!silentIfNoChange) {
      toast.add({
        severity: 'info',
        summary: 'Tidak Ada Perubahan',
        detail: 'Belum ada perubahan nota pada baris ini.',
        life: 2200,
      })
    }
    return true
  }

  if (draft.nota_merah && draft.nota_putih) {
    draft.error = 'Nota merah dan putih tidak bisa aktif bersamaan.'
    return false
  }

  draft.saving = true

  try {
    const payload = {
      nota_merah: Boolean(draft.nota_merah),
      nota_putih: Boolean(draft.nota_putih),
      nota_kuning: Boolean(draft.nota_kuning),
    }

    await updateSalesNotes(row.sale_id, payload)

    row.nota_merah = payload.nota_merah
    row.nota_putih = payload.nota_putih
    row.nota_kuning = payload.nota_kuning

    refreshDraftDirtyState(row, draft)

    toast.add({
      severity: 'success',
      summary: 'Nota Tersimpan',
      detail: `Perubahan nota untuk ${row.no_order} berhasil disimpan.`,
      life: 2200,
    })
    return true
  } catch (err) {
    draft.error = String(err?.message || err || 'Gagal menyimpan nota.')
    return false
  } finally {
    draft.saving = false
  }
}

async function syncRowByRule(row) {
  if (!row) return

  if (isReadOnly.value) {
    toast.add({
      severity: 'warn',
      summary: 'Akses Read Only',
      detail: 'Akun ini tidak memiliki izin sinkron nota.',
      life: 2500,
    })
    return
  }

  const expected = getExpectedNotes(row)
  const draft = ensureDraft(row)
  draft.nota_merah = expected.nota_merah
  draft.nota_putih = expected.nota_putih
  draft.nota_kuning = expected.nota_kuning
  refreshDraftDirtyState(row, draft)

  await saveRow(row, { silentIfNoChange: true })
}

async function loadData() {
  loading.value = true
  schemaError.value = ''

  try {
    salesRows.value = await fetchPenagihanSales()
    clearDraftNotes()
  } catch (err) {
    const message = String(err?.message || err || '')
    console.error('[PenagihanNotaPage.loadData]', err)

    if (isSchemaIssue(message)) {
      schemaError.value = 'Database belum memiliki view/tabel penagihan terbaru.'
      return
    }

    toast.add({
      severity: 'error',
      summary: 'Gagal Memuat Data',
      detail: message,
      life: 3200,
    })
  } finally {
    loading.value = false
  }
}

function setRowRef(el, idx) {
  if (!el) return
  rowRefs.value[idx] = el
}

function ensureSelectedRowVisible() {
  const rowEl = rowRefs.value[selectedRowIndex.value]
  if (!rowEl || typeof rowEl.scrollIntoView !== 'function') return
  rowEl.scrollIntoView({ block: 'nearest' })
}

function moveSelection(delta) {
  if (!rows.value.length) return
  const max = rows.value.length - 1
  selectedRowIndex.value = Math.min(max, Math.max(0, selectedRowIndex.value + delta))
}

function onGlobalKey(e) {
  if (e.key === 'Escape') {
    e.preventDefault()
    router.push('/penagihan')
    return
  }

  if (e.key === 'F1') {
    e.preventDefault()
    focusKey.value = 'search'
    nextTick(() => searchInput.value?.focus())
    return
  }

  const targetTag = e.target?.tagName
  const isTyping = ['INPUT', 'TEXTAREA', 'SELECT'].includes(targetTag)
  if (isTyping) return

  if (e.key === 'ArrowDown') {
    e.preventDefault()
    moveSelection(1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    moveSelection(-1)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (selectedRow.value) saveRow(selectedRow.value)
  } else if (e.key === 'F4') {
    e.preventDefault()
    if (selectedRow.value) syncRowByRule(selectedRow.value)
  }
}

onMounted(async () => {
  pageEl.value?.focus()
  window.addEventListener('keydown', onGlobalKey)
  await loadData()
  stopAutoSync = subscribePenagihanAutoSync({
    key: 'nota',
    onSync: async () => {
      if (hasDirtyDrafts()) return
      await loadData()
    },
  })
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
  stopAutoSync()
})
</script>

<style scoped>
@import '@/assets/pages/penagihan/penagihan-nota-page.css';

.row-error {
  margin-top: 0.3rem;
  font-size: 0.66rem;
  line-height: 1.25;
  color: #b91c1c;
}
</style>
