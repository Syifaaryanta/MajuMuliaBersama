<template>
  <div class="pembelian-order-page" ref="pageEl" tabindex="-1">
    <div class="form-card">
      <div class="form-header">
        <h1 class="form-header-title">Pembuatan Order Pembelian</h1>
        <p class="form-header-subtitle">Tahap 1: Lengkapi informasi header pembelian</p>
      </div>

      <form class="order-form" @submit.prevent="goToInputItem">
        <div class="order-form-grid">
          <div class="form-row form-row--compact">
            <label class="form-label">
              <i class="pi pi-hashtag"></i>
              No. Order Pembelian
            </label>
            <input
              v-model="form.no_order"
              type="text"
              class="form-input"
              readonly
              disabled
              placeholder="Pilih supplier terlebih dahulu"
            />
          </div>

          <div class="form-row form-row--compact">
            <label class="form-label required">
              <i class="pi pi-calendar"></i>
              Tanggal Order
            </label>
            <input
              ref="inputOrderDate"
              v-model="form.order_date"
              type="date"
              class="form-input"
              @focus="focusedField = 'order_date'"
              @keydown.enter.prevent="focusSupplier"
            />
          </div>

          <div
            ref="supplierFieldEl"
            class="form-row form-row--customer"
            :class="{ 'form-row--focused': focusedField === 'supplier' }"
            tabindex="0"
            @click="focusSupplier"
            @focus="focusedField = 'supplier'"
            @keydown.enter="onSupplierFieldEnter"
            @keydown.backspace="onSupplierFieldBackspace"
          >
            <label class="form-label required">
              <i class="pi pi-truck"></i>
              Supplier
            </label>

            <div v-if="!selectedSupplier" class="search-input-wrap">
              <i class="pi pi-search si-icon"></i>
              <input
                ref="inputSupplier"
                v-model="searchSupplier"
                type="text"
                class="form-input si-input"
                placeholder="Ketik nama supplier lalu Enter"
                @focus="focusedField = 'supplier'"
                @keydown.enter.prevent="openSupplierModal"
                @keydown.backspace="onSupplierInputBackspace"
                @input="onSupplierInput"
              />
            </div>

            <div v-else class="customer-info">
              <div class="ci-header">
                <span class="ci-name">{{ selectedSupplier.nama }}</span>
                <span class="ci-kode">{{ selectedSupplier.kode }}</span>
              </div>
              <div class="ci-detail">
                <div class="ci-row">
                  <i class="pi pi-map-marker"></i>
                  <span>{{ selectedSupplier.alamat || '—' }}</span>
                </div>
                <div class="ci-row">
                  <i class="pi pi-phone"></i>
                  <span>{{ selectedSupplier.no_telp || '—' }}</span>
                </div>
              </div>
              <button class="change-customer-btn" type="button" @click="clearSupplier">
                <i class="pi pi-times"></i> Ganti Supplier
              </button>
            </div>
          </div>

          <div
            ref="termsFieldEl"
            class="form-row form-row--option"
            :class="{ 'form-row--focused': focusedField === 'terms' }"
            tabindex="0"
            @click="focusTerms"
            @focus="focusedField = 'terms'"
            @keydown="onTermsFieldKeydown"
          >
            <label class="form-label required">
              <i class="pi pi-clock"></i>
              Terms Pembayaran
            </label>
            <div class="radio-group radio-group-wrap">
              <label class="radio-option" :class="{ active: form.terms === 'tunai' }">
                <input v-model="form.terms" type="radio" value="tunai" />
                <span class="radio-label">Tunai</span>
              </label>
              <label class="radio-option" :class="{ active: form.terms === '1' }">
                <input v-model="form.terms" type="radio" value="1" />
                <span class="radio-label">1 Bulan</span>
              </label>
              <label class="radio-option" :class="{ active: form.terms === '2' }">
                <input v-model="form.terms" type="radio" value="2" />
                <span class="radio-label">2 Bulan</span>
              </label>
              <label class="radio-option" :class="{ active: form.terms === '3' }">
                <input v-model="form.terms" type="radio" value="3" />
                <span class="radio-label">3 Bulan</span>
              </label>
            </div>
          </div>
        </div>

        <div class="form-actions">
          <button type="button" class="btn-secondary" @click="$router.push('/pembelian')">
            <i class="pi pi-times"></i>
            Batal
          </button>
          <button type="submit" class="btn-primary" :disabled="!canProceed">
            <i class="pi pi-arrow-right"></i>
            Lanjut ke Input Item
          </button>
        </div>
      </form>
    </div>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="supplierModal.show" class="modal-overlay" @click.self="supplierModal.show = false">
          <div class="modal-box modal-search" role="dialog">
            <div class="modal-header">
              <i class="pi pi-search"></i>
              <h3 class="modal-title">Pilih Supplier</h3>
              <button class="modal-close" @click="supplierModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <div class="search-modal-input-wrap">
                <i class="pi pi-search"></i>
                <input
                  ref="supplierModalInput"
                  v-model="supplierModal.query"
                  type="text"
                  class="search-modal-input"
                  placeholder="Ketik untuk filter hasil..."
                  @input="filterSupplierModal"
                  @keydown="onSupplierModalKey"
                />
              </div>
              <div class="search-modal-results">
                <div
                  v-for="(item, idx) in supplierModal.filtered"
                  :key="item.id"
                  class="search-modal-item"
                  :class="{ active: idx === supplierModal.selectedIndex }"
                  @click="selectSupplier(item)"
                  @mouseenter="supplierModal.selectedIndex = idx"
                >
                  <div class="smi-main">
                    <span class="smi-kode">{{ item.kode }}</span>
                    <span class="smi-nama">{{ item.nama }}</span>
                  </div>
                  <div class="smi-sub">
                    <span>{{ item.alamat || '—' }}</span>
                  </div>
                </div>
                <div v-if="supplierModal.filtered.length === 0" class="search-modal-empty">
                  <i class="pi pi-inbox"></i>
                  <p>Tidak ada supplier yang cocok</p>
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
import { ref, reactive, computed, nextTick, onMounted, onUnmounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { generatePurchaseOrderNo, upsertPurchaseOrder } from '@/lib/pembelianStore'

const router = useRouter()
const pageEl = ref(null)
const inputOrderDate = ref(null)
const inputSupplier = ref(null)
const supplierFieldEl = ref(null)
const termsFieldEl = ref(null)
const supplierModalInput = ref(null)

const focusedField = ref('')
const searchSupplier = ref('')
const selectedSupplier = ref(null)
const justSelectedSupplier = ref(false)
const ORDER_WORKING_KEY = 'pembelian_order_working_state'

const form = reactive({
  no_order: '',
  order_date: new Date().toISOString().split('T')[0],
  terms: 'tunai',
})

const supplierModal = reactive({
  show: false,
  query: '',
  results: [],
  filtered: [],
  selectedIndex: 0,
})

const termOptions = ['tunai', '1', '2', '3']

const canProceed = computed(() => Boolean(form.order_date && selectedSupplier.value && form.terms && form.no_order))

function handleKeydown(e) {
  if (e.defaultPrevented) {
    return
  }

  if (supplierModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      supplierModal.show = false
    }
    return
  }

  if (e.key === 'Escape') {
    e.preventDefault()
    router.push('/pembelian')
    return
  }

  if (e.key === 'Enter' && document.activeElement?.tagName !== 'INPUT') {
    e.preventDefault()

    if (justSelectedSupplier.value) {
      return
    }

    if (focusedField.value === 'order_date') {
      focusSupplier()
      return
    }

    if (focusedField.value === 'supplier') {
      onSupplierFieldEnter()
      return
    }

    if (focusedField.value === 'terms' && canProceed.value) {
      goToInputItem()
    }
    return
  }

  if (e.key === 'Backspace' && document.activeElement?.tagName !== 'INPUT') {
    if (focusedField.value === 'terms') {
      e.preventDefault()
      focusSupplier()
      return
    }
    if (focusedField.value === 'supplier') {
      e.preventDefault()
      focusOrderDate()
    }
  }

  if (focusedField.value === 'terms') {
    if (e.key === 'ArrowRight') {
      e.preventDefault()
      const idx = termOptions.indexOf(form.terms)
      form.terms = termOptions[(idx + 1) % termOptions.length]
      return
    }
    if (e.key === 'ArrowLeft') {
      e.preventDefault()
      const idx = termOptions.indexOf(form.terms)
      form.terms = termOptions[(idx - 1 + termOptions.length) % termOptions.length]
      return
    }
    if (e.key >= '1' && e.key <= '4') {
      e.preventDefault()
      form.terms = termOptions[parseInt(e.key, 10) - 1]
    }
  }
}

function focusOrderDate() {
  focusedField.value = 'order_date'
  nextTick(() => inputOrderDate.value?.focus())
}

function focusSupplier() {
  focusedField.value = 'supplier'
  nextTick(() => {
    if (selectedSupplier.value) {
      supplierFieldEl.value?.focus()
      return
    }
    inputSupplier.value?.focus()
  })
}

function focusTerms() {
  focusedField.value = 'terms'
  nextTick(() => termsFieldEl.value?.focus())
}

function resolveSupplierTerm(tempoBulan) {
  const tempo = Number(tempoBulan)
  if ([1, 2, 3].includes(tempo)) return String(tempo)
  return 'tunai'
}

function onSupplierInput() {
  if (selectedSupplier.value) {
    selectedSupplier.value = null
    form.terms = 'tunai'
  }
}

function onSupplierInputBackspace(e) {
  if (!searchSupplier.value && e.target.selectionStart === 0) {
    e.preventDefault()
    focusOrderDate()
  }
}

function onSupplierFieldBackspace(e) {
  if (!selectedSupplier.value) return
  e.preventDefault()
  e.stopPropagation()
  clearSupplier()
}

function onSupplierFieldEnter(e) {
  if (!selectedSupplier.value) {
    if (document.activeElement === inputSupplier.value) return
    e?.preventDefault()
    openSupplierModal()
    return
  }
  e?.preventDefault()
  focusTerms()
}

async function openSupplierModal() {
  const q = searchSupplier.value.trim()
  try {
    let query = supabase
      .from('suppliers')
      .select('id, kode, nama, alamat, no_telp, jatuh_tempo_bulan')
      .eq('aktif', true)
      .order('nama')

    if (q) {
      query = query.or(`nama.ilike.%${q}%,kode.ilike.%${q}%`)
    }

    const { data, error } = await query
    if (error) throw error

    supplierModal.results = data || []
    supplierModal.filtered = data || []
    supplierModal.query = ''
    supplierModal.selectedIndex = 0
    supplierModal.show = true

    await nextTick()
    supplierModalInput.value?.focus()
  } catch (err) {
    console.error('[openSupplierModal]', err)
    alert('Gagal memuat supplier: ' + err.message)
  }
}

function filterSupplierModal() {
  const q = supplierModal.query.toLowerCase()
  supplierModal.filtered = q
    ? supplierModal.results.filter(item =>
        item.nama.toLowerCase().includes(q) ||
        item.kode.toLowerCase().includes(q)
      )
    : supplierModal.results
  supplierModal.selectedIndex = 0
}

function onSupplierModalKey(e) {
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    e.stopPropagation()
    supplierModal.selectedIndex = Math.min(supplierModal.selectedIndex + 1, supplierModal.filtered.length - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    e.stopPropagation()
    supplierModal.selectedIndex = Math.max(supplierModal.selectedIndex - 1, 0)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    e.stopPropagation()
    if (supplierModal.filtered[supplierModal.selectedIndex]) {
      selectSupplier(supplierModal.filtered[supplierModal.selectedIndex])
    }
  } else if (e.key === 'Escape') {
    e.preventDefault()
    e.stopPropagation()
    supplierModal.show = false
  }
}

function selectSupplier(item) {
  selectedSupplier.value = item
  searchSupplier.value = item.nama
  form.terms = resolveSupplierTerm(item.jatuh_tempo_bulan)
  justSelectedSupplier.value = true
  supplierModal.show = false
  focusTerms()
  setTimeout(() => {
    justSelectedSupplier.value = false
  }, 0)
}

function clearSupplier() {
  selectedSupplier.value = null
  searchSupplier.value = ''
  form.terms = 'tunai'
  focusSupplier()
}

function onTermsFieldKeydown(e) {
  if (e.key === 'Enter') {
    e.preventDefault()
    e.stopPropagation()
    if (justSelectedSupplier.value) {
      return
    }
    if (canProceed.value) {
      goToInputItem()
    }
    return
  }

  if (e.key === 'Backspace') {
    e.preventDefault()
    e.stopPropagation()
    focusSupplier()
  }
}

async function goToInputItem() {
  if (!canProceed.value) {
    alert('Lengkapi data order pembelian dulu.')
    return
  }

  const payload = {
    no_order: form.no_order,
    order_date: form.order_date,
    terms: form.terms,
    supplier: selectedSupplier.value,
  }

  try {
    await upsertPurchaseOrder({
      ...payload,
      status: 'draft',
      items: [],
      subtotal: 0,
      received_at: null,
    })

    sessionStorage.setItem('pembelian_draft', JSON.stringify(payload))
    router.push({
      path: '/pembelian/input',
      query: { no_order: payload.no_order },
    })
  } catch (err) {
    console.error('[goToInputItem]', err)
    alert('Gagal menyimpan draft order awal ke database: ' + err.message)
  }
}

function persistWorkingState() {
  const snapshot = {
    form: {
      no_order: form.no_order,
      order_date: form.order_date,
      terms: form.terms,
    },
    searchSupplier: searchSupplier.value,
    selectedSupplier: selectedSupplier.value,
  }

  sessionStorage.setItem(ORDER_WORKING_KEY, JSON.stringify(snapshot))
}

function restoreWorkingState() {
  const raw = sessionStorage.getItem(ORDER_WORKING_KEY)
  if (!raw) return false

  try {
    const parsed = JSON.parse(raw)
    if (!parsed || typeof parsed !== 'object') return false

    form.no_order = parsed.form?.no_order || ''
    form.order_date = parsed.form?.order_date || form.order_date
    form.terms = parsed.form?.terms || 'tunai'
    searchSupplier.value = parsed.searchSupplier || ''
    selectedSupplier.value = parsed.selectedSupplier || null
    return true
  } catch (err) {
    console.error('[restoreWorkingState order pembelian]', err)
    return false
  }
}

watch(
  () => [
    form.no_order,
    form.order_date,
    form.terms,
    searchSupplier.value,
    selectedSupplier.value?.id,
  ],
  persistWorkingState,
  { immediate: true }
)

onMounted(async () => {
  restoreWorkingState()
  if (!form.no_order) {
    try {
      form.no_order = await generatePurchaseOrderNo()
    } catch (err) {
      console.error('[generatePurchaseOrderNo]', err)
      const year = new Date().getFullYear().toString().slice(-2)
      form.no_order = `PO${year}001`
    }
  }
  pageEl.value?.focus()
  nextTick(() => focusOrderDate())
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
@import '@/assets/Styles/pembelian/pembelian-order-page.css';
</style>
