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
      <kbd>F2 Tanggal</kbd>
      <kbd>F3 Filter Status</kbd>
      <kbd>Arrow Pilih Baris</kbd>
      <kbd>Enter Nota</kbd>
      <kbd>Arrow Kanan Kolom</kbd>
      <kbd>Esc Baris</kbd>
      <kbd>F4 Sinkron 1 Baris</kbd>
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
          <div class="date-filter-wrap">
            <label class="search-label">
              Tanggal Order
              <kbd class="label-kbd">F2</kbd>
            </label>
            <div class="date-filter-row">
              <input
                ref="dateStartInput"
                v-model="dateFilter.start"
                type="date"
                class="mfield-input date-filter-input"
                @keydown.enter.prevent="onDateStartEnter"
              />
              <span class="date-separator">s/d</span>
              <input
                ref="dateEndInput"
                v-model="dateFilter.end"
                type="date"
                class="mfield-input date-filter-input"
              />
            </div>
          </div>

          <button
            type="button"
            class="btn-filter-popup"
            @click="openStatusFilterModal"
          >
            <i class="pi pi-sliders-h"></i>
            <span>Filter: {{ activeFilterLabel }}</span>
            <kbd>F3</kbd>
          </button>
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
              </tr>
            </thead>
            <tbody v-if="loading">
              <tr v-for="n in 6" :key="`loading-${n}`">
                <td colspan="10"><div class="skeleton"></div></td>
              </tr>
            </tbody>
            <tbody v-else-if="rows.length === 0">
              <tr>
                <td colspan="10" class="empty-cell">
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
                @click="() => onRowClick(idx)"
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
                  <p v-if="getRowError(row)" class="row-error">{{ getRowError(row) }}</p>
                </td>
                <td class="col-nota">
                  <label class="note-check">
                    <input
                      type="checkbox"
                      :checked="getNoteState(row, 'nota_merah')"
                      :disabled="isReadOnly || isRowSaving(row)"
                      :ref="el => setNoteRef(el, idx, 'nota_merah')"
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
                      :ref="el => setNoteRef(el, idx, 'nota_putih')"
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
                      :ref="el => setNoteRef(el, idx, 'nota_kuning')"
                      @change="onToggleNote(row, 'nota_kuning', $event.target.checked)"
                    />
                  </label>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </template>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="statusFilterModal.show" class="modal-overlay" @click.self="closeStatusFilterModal">
          <div class="modal-box modal-box--status-filter" role="dialog" aria-label="Filter status nota">
            <div class="modal-header modal-header--blue">
              <h3 class="modal-title">Filter Status Nota</h3>
              <button class="modal-close" @click="closeStatusFilterModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body status-filter-body">
              <button
                v-for="opt in statusFilterLayout"
                :key="opt.id"
                type="button"
                class="status-filter-option"
                :class="{ 'status-filter-option--active': statusFilterModal.selectedId === opt.id }"
                @mouseenter="statusFilterModal.selectedId = opt.id"
                @click="applyStatusFilterById(opt.id)"
              >
                <span class="status-filter-label">
                  <i :class="statusFilterIcon(opt.id)"></i>
                  {{ opt.label }}
                </span>
                <i v-if="activeFilter === opt.id" class="pi pi-check"></i>
              </button>
              <p class="status-filter-hint">Arrow: pilih · Enter: terapkan · Esc: batal</p>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
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
  toIsoDate,
  isSchemaIssue,
  updateSalesNotes,
  subscribePenagihanAutoSync,
} from '@/lib/penagihanService'

const router = useRouter()
const route = useRoute()
const toast = useToast()

const pageEl = ref(null)
const searchInput = ref(null)
const dateStartInput = ref(null)
const dateEndInput = ref(null)
const focusKey = ref('')
const loading = ref(false)
const schemaError = ref('')
const searchQuery = ref('')
const activeFilter = ref('all')
const dateFilter = reactive({
  start: '',
  end: toIsoDate(new Date()),
})
const selectedRowIndex = ref(0)
const rowRefs = ref({})
const noteRefs = ref({})
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

const statusFilterModal = reactive({
  show: false,
  selectedId: 'all',
})

const noteNav = reactive({
  mode: 'row',
  col: 'nota_merah',
})

const statusFilterLayout = computed(() => {
  return [
    filterOptions[0],
    filterOptions[1],
    filterOptions[2],
    filterOptions[3],
  ].filter(Boolean)
})

const activeFilterLabel = computed(() => {
  const found = filterOptions.find(opt => opt.id === activeFilter.value)
  return found?.label || 'Semua'
})

function getExpectedNotes(row) {
  const isPaid = Number(row.outstanding_amount || 0) <= 0
  return {
    nota_merah: isPaid,
    nota_putih: !isPaid,
    nota_kuning: true,
  }
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

  const start = String(dateFilter.start || '').trim()
  const end = String(dateFilter.end || '').trim()
  if (start) {
    data = data.filter(row => String(row.order_date || '') >= start)
  }
  if (end) {
    data = data.filter(row => String(row.order_date || '') <= end)
  }

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

function toggleNoteByKey(row, key) {
  if (!row) return
  if (isReadOnly.value || isRowSaving(row)) return
  const nextChecked = !getNoteState(row, key)
  onToggleNote(row, key, nextChecked)
  saveRow(row, { silent: true, silentIfNoChange: true })
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

async function saveRow(row, { silentIfNoChange = false, silent = false } = {}) {
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
    if (!silentIfNoChange && !silent) {
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

    if (!silent) {
      toast.add({
        severity: 'success',
        summary: 'Nota Tersimpan',
        detail: `Perubahan nota untuk ${row.no_order} berhasil disimpan.`,
        life: 2200,
      })
    }
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

    salesRows.value.forEach((row) => {
      const expected = getExpectedNotes(row)
      const mismatch = (
        Boolean(row.nota_merah) !== Boolean(expected.nota_merah) ||
        Boolean(row.nota_putih) !== Boolean(expected.nota_putih) ||
        Boolean(row.nota_kuning) !== Boolean(expected.nota_kuning)
      )

      if (mismatch) {
        draftNotes[row.sale_id] = {
          nota_merah: Boolean(expected.nota_merah),
          nota_putih: Boolean(expected.nota_putih),
          nota_kuning: Boolean(expected.nota_kuning),
          dirty: true,
          saving: false,
          error: '',
        }
      }
    })
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

function setNoteRef(el, idx, key) {
  if (!el) return
  if (!noteRefs.value[idx]) noteRefs.value[idx] = {}
  noteRefs.value[idx][key] = el
}

function focusNoteCell(rowIndex, key) {
  const rowNotes = noteRefs.value[rowIndex]
  const el = rowNotes?.[key]
  if (el && typeof el.focus === 'function') {
    el.focus()
  }
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

function onRowClick(idx) {
  selectedRowIndex.value = idx
  noteNav.mode = 'row'
  noteNav.col = 'nota_merah'
}

function enterNoteMode(col = 'nota_merah') {
  if (!rows.value.length) return
  noteNav.mode = 'note'
  noteNav.col = col
  nextTick(() => focusNoteCell(selectedRowIndex.value, col))
}

function exitNoteMode() {
  noteNav.mode = 'row'
  noteNav.col = 'nota_merah'
  pageEl.value?.focus()
}

function moveNoteColumn(direction) {
  const order = ['nota_merah', 'nota_putih', 'nota_kuning']
  const currentIndex = order.indexOf(noteNav.col)
  if (currentIndex === -1) return
  const nextIndex = direction === 'right'
    ? Math.min(order.length - 1, currentIndex + 1)
    : Math.max(0, currentIndex - 1)
  noteNav.col = order[nextIndex]
  nextTick(() => focusNoteCell(selectedRowIndex.value, noteNav.col))
}

function moveNoteRow(delta) {
  if (!rows.value.length) return
  moveSelection(delta)
  nextTick(() => focusNoteCell(selectedRowIndex.value, noteNav.col))
}

function onDateStartEnter() {
  if (!dateFilter.end) {
    dateFilter.end = toIsoDate(new Date())
  }
  nextTick(() => dateEndInput.value?.focus())
}

function openStatusFilterModal() {
  statusFilterModal.selectedId = 'all'
  statusFilterModal.show = true
}

function closeStatusFilterModal() {
  statusFilterModal.show = false
}

function applyStatusFilterById(filterId) {
  const opt = filterOptions.find(item => item.id === filterId)
  if (!opt) return
  activeFilter.value = opt.id
  closeStatusFilterModal()
}

function moveStatusFilterSelection(direction) {
  const current = statusFilterModal.selectedId || 'all'
  const nextMap = {
    all: { down: 'debt', right: 'paid', left: 'all', up: 'all' },
    debt: { up: 'all', right: 'paid', down: 'need_sync', left: 'debt' },
    paid: { up: 'all', left: 'debt', down: 'need_sync', right: 'paid' },
    need_sync: { up: 'debt', left: 'debt', right: 'paid', down: 'need_sync' },
  }

  const nextId = nextMap[current]?.[direction] || current
  statusFilterModal.selectedId = nextId
}

function statusFilterIcon(filterId) {
  switch (filterId) {
    case 'debt':
      return 'pi pi-exclamation-circle'
    case 'paid':
      return 'pi pi-check-circle'
    case 'need_sync':
      return 'pi pi-sync'
    default:
      return 'pi pi-list'
  }
}

function onGlobalKey(e) {
  if (statusFilterModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      closeStatusFilterModal()
      return
    }
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      moveStatusFilterSelection('down')
      return
    }
    if (e.key === 'ArrowUp') {
      e.preventDefault()
      moveStatusFilterSelection('up')
      return
    }
    if (e.key === 'ArrowLeft') {
      e.preventDefault()
      moveStatusFilterSelection('left')
      return
    }
    if (e.key === 'ArrowRight') {
      e.preventDefault()
      moveStatusFilterSelection('right')
      return
    }
    if (e.key === 'Enter') {
      e.preventDefault()
      applyStatusFilterById(statusFilterModal.selectedId)
      return
    }
  }

  if (noteNav.mode === 'note') {
    if (e.key === 'Escape') {
      e.preventDefault()
      exitNoteMode()
      return
    }
    if (e.key === 'Enter') {
      e.preventDefault()
      if (selectedRow.value) toggleNoteByKey(selectedRow.value, noteNav.col)
      return
    }
    if (e.key === 'ArrowRight') {
      e.preventDefault()
      moveNoteColumn('right')
      return
    }
    if (e.key === 'ArrowLeft') {
      e.preventDefault()
      moveNoteColumn('left')
      return
    }
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      moveNoteRow(1)
      return
    }
    if (e.key === 'ArrowUp') {
      e.preventDefault()
      moveNoteRow(-1)
      return
    }
  }

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

  if (e.key === 'F2') {
    e.preventDefault()
    focusKey.value = 'date-start'
    nextTick(() => dateStartInput.value?.focus())
    return
  }

  if (e.key === 'F3') {
    e.preventDefault()
    openStatusFilterModal()
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
    enterNoteMode('nota_merah')
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
@import '@/assets/Styles/penagihan/penagihan-nota-page.css';

.row-error {
  margin-top: 0.3rem;
  font-size: 0.66rem;
  line-height: 1.25;
  color: #b91c1c;
}
</style>
