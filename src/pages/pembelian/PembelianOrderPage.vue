<template>
  <div class="pembelian-order-page" ref="pageEl" tabindex="-1">
    <div class="form-card">
      <div class="form-header">
        <h1 class="form-header-title">Order Pembelian</h1>
        <p class="form-header-subtitle">Step 1: Informasi Header Pembelian</p>
      </div>

      <form class="order-form" @submit.prevent="goToInputItem">
        <div class="form-row">
          <label class="form-label">
            <i class="pi pi-hashtag"></i>
            No. Order Pembelian
          </label>
          <input v-model="form.no_order" type="text" class="form-input" readonly disabled />
        </div>

        <div class="form-row">
          <label class="form-label required">
            <i class="pi pi-calendar"></i>
            Tanggal Order
          </label>
          <input
            ref="inputOrderDate"
            v-model="form.order_date"
            type="date"
            class="form-input"
            @keydown.enter.prevent="focusSupplier"
          />
        </div>

        <div class="form-row">
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
              @keydown.enter.prevent="openSupplierModal"
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

        <div class="form-row" :class="{ 'form-row--focused': focusedField === 'terms' }" @click="focusedField = 'terms'">
          <label class="form-label required">
            <i class="pi pi-clock"></i>
            Terms Pembayaran
          </label>
          <div class="radio-group radio-group-wrap">
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
            <label class="radio-option" :class="{ active: form.terms === 'lunas' }">
              <input v-model="form.terms" type="radio" value="lunas" />
              <span class="radio-label">Lunas</span>
            </label>
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
import { ref, reactive, computed, nextTick, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { generatePurchaseOrderNo } from '@/lib/pembelianStore'

const router = useRouter()
const pageEl = ref(null)
const inputOrderDate = ref(null)
const inputSupplier = ref(null)
const supplierModalInput = ref(null)

const focusedField = ref('')
const searchSupplier = ref('')
const selectedSupplier = ref(null)
const suppressEnterOnce = ref(false)

const form = reactive({
  no_order: '',
  order_date: new Date().toISOString().split('T')[0],
  terms: '1',
})

const supplierModal = reactive({
  show: false,
  query: '',
  results: [],
  filtered: [],
  selectedIndex: 0,
})

const termOptions = ['1', '2', '3', 'lunas']

const canProceed = computed(() => Boolean(form.order_date && selectedSupplier.value && form.terms))

function handleKeydown(e) {
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

    if (suppressEnterOnce.value) {
      suppressEnterOnce.value = false
      return
    }

    if (!selectedSupplier.value) {
      focusSupplier()
      return
    }
    if (!focusedField.value) {
      focusedField.value = 'terms'
      return
    }
    if (focusedField.value === 'terms' && canProceed.value) {
      goToInputItem()
    }
    return
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

function focusSupplier() {
  nextTick(() => inputSupplier.value?.focus())
}

function onSupplierInput() {
  if (selectedSupplier.value) {
    selectedSupplier.value = null
  }
}

async function openSupplierModal() {
  const q = searchSupplier.value.trim()
  try {
    let query = supabase
      .from('suppliers')
      .select('id, kode, nama, alamat, no_telp')
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
    supplierModal.selectedIndex = Math.min(supplierModal.selectedIndex + 1, supplierModal.filtered.length - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    supplierModal.selectedIndex = Math.max(supplierModal.selectedIndex - 1, 0)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (supplierModal.filtered[supplierModal.selectedIndex]) {
      selectSupplier(supplierModal.filtered[supplierModal.selectedIndex])
    }
  } else if (e.key === 'Escape') {
    e.preventDefault()
    supplierModal.show = false
  }
}

function selectSupplier(item) {
  selectedSupplier.value = item
  searchSupplier.value = item.nama
  supplierModal.show = false
  focusedField.value = 'terms'
  suppressEnterOnce.value = true
  nextTick(() => pageEl.value?.focus())
}

function clearSupplier() {
  selectedSupplier.value = null
  searchSupplier.value = ''
  focusSupplier()
}

function goToInputItem() {
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

  sessionStorage.setItem('pembelian_draft', JSON.stringify(payload))
  router.push('/pembelian/input')
}

onMounted(() => {
  form.no_order = generatePurchaseOrderNo()
  pageEl.value?.focus()
  nextTick(() => inputOrderDate.value?.focus())
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
@import '@/assets/pages/pembelian/pembelian-order-page.css';
</style>
