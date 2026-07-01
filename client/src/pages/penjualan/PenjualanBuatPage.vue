<template>
  <div class="penjualan-page" ref="pageEl" tabindex="-1">

    <!-- ── FORM CARD WITH HEADER ─────────────────────────────────────── -->
    <div class="form-card">
      <div class="form-header">
        <h1 class="form-header-title">Pembuatan Order Penjualan</h1>
        <p class="form-header-subtitle">Tahap 1: Lengkapi informasi order dan pelanggan</p>
      </div>
      <form @submit.prevent="attemptSubmitOrder" class="order-form">
        <div class="order-form-grid">
          <!-- No Order -->
          <div class="form-row form-row--compact">
            <label class="form-label">
              <i class="pi pi-hashtag"></i>
              No. Order
            </label>
            <input
              v-model="form.no_order"
              type="text"
              class="form-input"
              placeholder="Auto generate"
              readonly
              disabled
            />
          </div>

          <!-- No Fraktur -->
          <div class="form-row form-row--compact">
            <label class="form-label">
              <i class="pi pi-receipt"></i>
              No. Fraktur
            </label>
            <input
              type="text"
              class="form-input"
              :value="form.no_faktur"
              placeholder="Auto saat order disimpan final"
              readonly
              disabled
            />
          </div>

          <!-- Order Date -->
          <div class="form-row form-row--compact">
            <label class="form-label required">
              <i class="pi pi-calendar"></i>
              Tanggal Order
            </label>
            <input
              ref="inputOrderDate"
              v-model="form.order_date"
              type="text"
              class="form-input"
              placeholder="DD/MM/YY"
              @keydown.enter.prevent="nextField('customer')"
              @blur="validateDate"
            />
          </div>

          <!-- Customer Search -->
          <div class="form-row form-row--customer" :class="{ 'form-row--adding': addCustomerModal.show, 'form-row--focused': focusedField === 'customer' && !addCustomerModal.show }">
            <label class="form-label required">
              <i class="pi pi-user"></i>
              Customer
            </label>
            
            <!-- Search Input (when not adding customer) -->
            <div v-if="!addCustomerModal.show && !selectedCustomer" class="customer-search-input-wrap">
              <i class="pi pi-search customer-search-icon"></i>
              <input
                ref="inputCustomer"
                v-model="searchCustomer"
                type="text"
                class="form-input customer-search-input"
                placeholder="Tekan Enter untuk pilih customer..."
                @focus="focusedField = 'customer'"
                @blur="onCustomerBlur"
                @input="onCustomerInput"
                @keydown.enter.prevent="openCustomerModal"
                @keydown.f2.prevent="quickAddCustomer"
                @keydown.backspace="onCustomerBackspace"
              />
            </div>
            
            <!-- Customer Info (if selected) -->
            <div v-if="selectedCustomer && !addCustomerModal.show" class="customer-info">
              <div class="ci-header">
                <span class="ci-name">{{ selectedCustomer.nama }}</span>
                <span class="ci-kode">{{ selectedCustomer.kode }}</span>
              </div>
              <div class="ci-detail">
                <div class="ci-row">
                  <i class="pi pi-map-marker"></i>
                  <span>{{ selectedCustomer.alamat || '—' }}</span>
                </div>
                <div class="ci-row">
                  <i class="pi pi-phone"></i>
                  <span>{{ selectedCustomer.no_telp || '—' }}</span>
                </div>
                <div class="ci-row ci-credit">
                  <i class="pi pi-wallet"></i>
                  <span>Limit: {{ formatRp(selectedCustomer.limit_kredit) }}</span>
                  <span class="ci-separator">|</span>
                  <span>Piutang: {{ formatRp(selectedCustomer.saldo_piutang) }}</span>
                  <span class="ci-separator">|</span>
                  <span :class="remainingCreditClass">
                    Sisa: {{ remainingCreditLabel }}
                  </span>
                </div>
              </div>
              <button class="change-customer-btn" @click="clearCustomer" type="button">
                <i class="pi pi-times"></i> Ganti Customer
              </button>
            </div>

            <!-- Inline Add Customer Form -->
            <div v-if="addCustomerModal.show" class="inline-add-customer">
              <div class="iac-header">
                <i class="pi pi-user-plus"></i>
                <span>Tambah Customer Baru</span>
                <button class="iac-close" @click="closeAddCustomer" type="button">
                  <i class="pi pi-times"></i>
                </button>
              </div>
              <div class="iac-grid">
                <div class="iac-field iac-full">
                  <label class="iac-label">Nama Customer <span class="required">*</span></label>
                  <input
                    ref="addCustomerNameInput"
                    v-model="addCustomerForm.nama"
                    type="text"
                    class="iac-input"
                    placeholder="Nama customer"
                    required
                    @keydown.enter.prevent="submitAddCustomer"
                  />
                </div>
                <div class="iac-field">
                  <label class="iac-label">Alamat <span class="optional">(opsional)</span></label>
                  <input
                    v-model="addCustomerForm.alamat"
                    type="text"
                    class="iac-input"
                    placeholder="Alamat lengkap customer"
                    @keydown.enter.prevent="submitAddCustomer"
                  />
                </div>
                <div class="iac-field">
                  <label class="iac-label">No. Telp <span class="optional">(opsional)</span></label>
                  <input
                    v-model="addCustomerForm.no_telp"
                    type="text"
                    class="iac-input"
                    placeholder="08xxxxxxxxxx"
                    @keydown.enter.prevent="submitAddCustomer"
                  />
                </div>
                <div class="iac-field">
                  <label class="iac-label">Limit Kredit <span class="optional">(opsional)</span></label>
                  <input
                    v-model="addCustomerForm.limit_kredit"
                    type="number"
                    class="iac-input"
                    placeholder="10000000"
                    min="0"
                    step="1000"
                    @keydown.enter.prevent="submitAddCustomer"
                  />
                </div>
                <div class="iac-actions">
                  <button type="button" class="btn-secondary" @click="closeAddCustomer">
                    Batal
                  </button>
                  <button type="button" class="btn-primary" @click="submitAddCustomer" :disabled="addCustomerModal.saving">
                    <i class="pi pi-check"></i>
                    <span>{{ addCustomerModal.saving ? 'Menyimpan...' : 'Simpan' }}</span>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Pengiriman -->
          <div class="form-row form-row--option" :class="{ 'form-row--focused': focusedField === 'pengiriman' }" @click="focusedField = 'pengiriman'">
            <label class="form-label">
              <i class="pi pi-truck"></i>
              Pengiriman
            </label>
            <div class="radio-group">
              <label class="radio-option" :class="{ active: form.diantar === true }">
                <input type="radio" :value="true" v-model="form.diantar" @change="onPengirimanChange" />
                <span class="radio-label">
                  <i class="pi pi-truck"></i>
                  Diantar
                </span>
              </label>
              <label class="radio-option" :class="{ active: form.diantar === false }">
                <input type="radio" :value="false" v-model="form.diantar" @change="onPengirimanChange" />
                <span class="radio-label">
                  <i class="pi pi-shopping-bag"></i>
                  Diambil
                </span>
              </label>
            </div>
          </div>

          <!-- Jatuh Tempo -->
          <div class="form-row form-row--option" :class="{ 'form-row--focused': focusedField === 'tempo' }" @click="focusedField = 'tempo'">
            <label class="form-label">
              <i class="pi pi-clock"></i>
              Jatuh Tempo
            </label>
            <div class="radio-group radio-group--tempo">
              <label class="radio-option" :class="{ active: form.limit_bulan === -1 }">
                <input type="radio" :value="-1" v-model="form.limit_bulan" @change="onTempoChange" />
                <span class="radio-label">Tunai</span>
              </label>
              <label class="radio-option" :class="{ active: form.limit_bulan === 0 }">
                <input type="radio" :value="0" v-model="form.limit_bulan" @change="onTempoChange" />
                <span class="radio-label">1 Bulan</span>
              </label>
              <label class="radio-option" :class="{ active: form.limit_bulan === 1 }">
                <input type="radio" :value="1" v-model="form.limit_bulan" @change="onTempoChange" />
                <span class="radio-label">2 Bulan</span>
              </label>
              <label class="radio-option" :class="{ active: form.limit_bulan === 2 }">
                <input type="radio" :value="2" v-model="form.limit_bulan" @change="onTempoChange" />
                <span class="radio-label">3 Bulan</span>
              </label>
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="form-actions">
          <button type="button" class="btn-secondary" @click="$router.push('/penjualan')">
            <i class="pi pi-times"></i>
            Batal
          </button>
          <button type="submit" class="btn-primary" :disabled="!canProceed || submitInProgress">
            <i class="pi pi-arrow-right"></i>
            {{ submitInProgress ? 'Menyimpan Draft...' : 'Lanjut ke Input Barang' }}
          </button>
        </div>

      </form>
    </div>

    <!-- ═══════════════════════════════════════════════════
         MODAL CUSTOMER SEARCH
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="customerModal.show" class="modal-overlay" @click.self="customerModal.show = false">
          <div class="modal-box modal-search" role="dialog">
            <div class="modal-header">
              <i class="pi pi-search"></i>
              <h3 class="modal-title">Pilih Customer</h3>
              <button class="modal-close" @click="customerModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <div class="search-modal-input-wrap">
                <i class="pi pi-search"></i>
                <input
                  ref="customerModalInput"
                  v-model="customerModal.query"
                  type="text"
                  class="search-modal-input"
                  placeholder="Ketik untuk filter hasil..."
                  @input="filterCustomerModal"
                  @keydown="onCustomerModalKey"
                />
              </div>
              <div class="search-modal-results" ref="customerModalResultsEl">
                <div
                  v-for="(item, idx) in customerModal.filtered"
                  :key="item.id"
                  class="search-modal-item"
                  :class="{ active: idx === customerModal.selectedIndex }"
                  @click="selectCustomer(item)"
                  @mouseenter="customerModal.selectedIndex = idx"
                >
                  <div class="smi-main">
                    <span class="smi-kode">{{ item.kode }}</span>
                    <span class="smi-nama">{{ item.nama }}</span>
                  </div>
                  <div class="smi-sub">
                    <span v-if="item.alamat">{{ item.alamat }}</span>
                    <span v-if="item.no_telp" class="smi-telp">{{ item.no_telp }}</span>
                  </div>
                </div>
                <div v-if="customerModal.filtered.length === 0" class="search-modal-empty">
                  <i class="pi pi-inbox"></i>
                  <p>Tidak ada customer yang cocok</p>
                  <button class="btn-link" @click="quickAddCustomer">
                    <i class="pi pi-plus"></i>
                    Tambah Customer Baru (F2)
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════
         MODAL INFO (F4)
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="infoModal.show" class="modal-overlay" @click.self="infoModal.show = false">
          <div class="modal-box modal-box--sm" role="dialog">
            <div class="modal-header">
              <i class="pi pi-info-circle"></i>
              <h3 class="modal-title">{{ infoModal.title }}</h3>
              <button class="modal-close" @click="infoModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <div class="info-content" v-html="infoModal.content"></div>
            </div>
            <div class="modal-footer">
              <button class="btn-primary" @click="infoModal.show = false">
                Mengerti <kbd>Esc</kbd>
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="overLimitConfirm.show" class="modal-overlay" @click.self="cancelOverLimitConfirm">
          <div class="modal-box modal-box--sm" role="dialog" aria-modal="true" aria-label="Konfirmasi limit kredit customer">
            <div class="modal-header modal-header--danger">
              <i class="pi pi-exclamation-triangle"></i>
              <h3 class="modal-title">Peringatan Limit Kredit</h3>
              <button class="modal-close" @click="cancelOverLimitConfirm" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <p class="confirm-text">Customer <strong>{{ selectedCustomer?.nama }}</strong> sudah melewati limit kredit.</p>
              <div class="credit-summary-grid">
                <div class="credit-summary-item">
                  <span class="credit-summary-label">Limit Kredit</span>
                  <strong class="credit-summary-value">{{ formatRp(selectedCustomer?.limit_kredit) }}</strong>
                </div>
                <div class="credit-summary-item">
                  <span class="credit-summary-label">Saldo Piutang</span>
                  <strong class="credit-summary-value">{{ formatRp(selectedCustomer?.saldo_piutang) }}</strong>
                </div>
                <div class="credit-summary-item" :class="{ 'credit-summary-item--danger': remainingCredit < 0 }">
                  <span class="credit-summary-label">Sisa Limit</span>
                  <strong class="credit-summary-value">{{ formatRp(remainingCredit) }}</strong>
                </div>
              </div>
              <p class="confirm-subtext">Tekan <strong>Y</strong> untuk tetap lanjut, atau <strong>N</strong> untuk batal.</p>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn-secondary" @click="cancelOverLimitConfirm">
                Batal <kbd>N</kbd>
              </button>
              <button type="button" class="btn-primary" @click="confirmOverLimitAndSubmit" :disabled="submitInProgress">
                Tetap Lanjutkan <kbd>Y</kbd>
              </button>
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
import { buildSalesDraftFingerprint } from '@/lib/orderDedupe'

const router = useRouter()

// ───────────────────────────────────────────────────────────
// REFS
// ───────────────────────────────────────────────────────────
const pageEl = ref(null)
const inputOrderDate = ref(null)
const inputCustomer = ref(null)
const customerModalInput = ref(null)
const customerModalResultsEl = ref(null)
const addCustomerNameInput = ref(null)

// ───────────────────────────────────────────────────────────
// STATE
// ───────────────────────────────────────────────────────────
const focusedField = ref('')
const searchCustomer = ref('')
const selectedCustomer = ref(null)
const justSelectedCustomer = ref(false)

const form = reactive({
  no_order: '',
  no_faktur: '',
  order_date: formatDateInput(new Date()),
  customer_id: null,
  diantar: true,
  limit_bulan: 0,
})

const customerModal = reactive({
  show: false,
  results: [],
  filtered: [],
  query: '',
  selectedIndex: 0,
})

const infoModal = reactive({
  show: false,
  title: '',
  content: '',
})

const addCustomerModal = reactive({
  show: false,
  saving: false,
})

const overLimitConfirm = reactive({
  show: false,
})

const submitInProgress = ref(false)

const addCustomerForm = reactive({
  nama: '',
  alamat: '',
  no_telp: '',
  limit_kredit: 10000000,
})

// ───────────────────────────────────────────────────────────
// COMPUTED
// ───────────────────────────────────────────────────────────
const canProceed = computed(() => {
  return selectedCustomer.value !== null && form.order_date
})

const remainingCredit = computed(() => {
  if (!selectedCustomer.value) return 0
  return selectedCustomer.value.limit_kredit - selectedCustomer.value.saldo_piutang
})

const remainingCreditLabel = computed(() => {
  if (!selectedCustomer.value) return 'Rp 0'
  if (remainingCredit.value < 0) {
    return 'Overlimit'
  }
  if (remainingCredit.value === 0) {
    return 'Limit Habis'
  }
  return formatRp(remainingCredit.value)
})

const remainingCreditClass = computed(() => {
  return remainingCredit.value <= 0 ? 'text-danger' : 'text-success'
})

// ───────────────────────────────────────────────────────────
// LIFECYCLE
// ───────────────────────────────────────────────────────────
onMounted(() => {
  window.addEventListener('keydown', onGlobalKey)
  pageEl.value?.focus()
  nextTick(() => inputOrderDate.value?.focus())
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
})

// ───────────────────────────────────────────────────────────
// KEYBOARD SHORTCUTS
// ───────────────────────────────────────────────────────────
function onGlobalKey(e) {
  if (overLimitConfirm.show) {
    if (e.key === 'Escape' || e.key === 'n' || e.key === 'N') {
      e.preventDefault()
      cancelOverLimitConfirm()
    } else if (e.key === 'Enter' || e.key === 'y' || e.key === 'Y') {
      e.preventDefault()
      confirmOverLimitAndSubmit()
    }
    return
  }

  if (customerModal.show || infoModal.show || addCustomerModal.show) {
    // Esc in modals
    if (e.key === 'Escape') {
      e.preventDefault()
      if (customerModal.show) customerModal.show = false
      if (infoModal.show) infoModal.show = false
      if (addCustomerModal.show) closeAddCustomer()
    }
    return
  }

  // F2: Quick add customer
  if (e.key === 'F2') {
    e.preventDefault()
    quickAddCustomer()
    return
  }

  // F4: Show info for focused field
  if (e.key === 'F4') {
    e.preventDefault()
    showInfo(focusedField.value || 'pengiriman')
    return
  }

  // Y: Submit form
  if (e.key === 'y' || e.key === 'Y') {
    if (canProceed.value && !customerModal.show) {
      e.preventDefault()
      attemptSubmitOrder()
    }
    return
  }

  // Esc: Back to menu
  if (e.key === 'Escape') {
    e.preventDefault()
    router.push('/penjualan')
    return
  }

  // Number keys for radio selections (1-based)
  if (!customerModal.show && !addCustomerModal.show && document.activeElement?.tagName !== 'INPUT') {
    if (e.key === '1') {
      e.preventDefault()
      if (focusedField.value === 'tempo') {
        form.limit_bulan = 0
      } else {
        form.diantar = true
        focusedField.value = 'pengiriman'
      }
    } else if (e.key === '2') {
      e.preventDefault()
      if (focusedField.value === 'tempo') {
        form.limit_bulan = 1
      } else {
        form.diantar = false
        focusedField.value = 'pengiriman'
      }
    } else if (e.key === '3') {
      e.preventDefault()
      if (focusedField.value === 'tempo') {
        form.limit_bulan = 2
      }
    } else if (e.key === '0') {
      e.preventDefault()
      if (focusedField.value === 'tempo') {
        form.limit_bulan = -1
      }
    }
  }

  // Arrow keys for radio navigation
  if (!customerModal.show && !addCustomerModal.show && document.activeElement?.tagName !== 'INPUT') {
    // ArrowDown/ArrowUp: Navigate between fields
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      if (focusedField.value === 'pengiriman') {
        focusedField.value = 'tempo'
      } else if (!focusedField.value && selectedCustomer.value) {
        focusedField.value = 'pengiriman'
      }
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      if (focusedField.value === 'tempo') {
        focusedField.value = 'pengiriman'
      }
    }
    // ArrowLeft/ArrowRight: Toggle options within field
    else if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
      e.preventDefault()
      if (focusedField.value === 'pengiriman') {
        form.diantar = !form.diantar
      } else if (focusedField.value === 'tempo') {
        if (e.key === 'ArrowRight') {
          form.limit_bulan = Math.min(form.limit_bulan + 1, 2)
        } else {
          form.limit_bulan = Math.max(form.limit_bulan - 1, -1)
        }
      }
    }
  }

  if (!customerModal.show && !addCustomerModal.show && document.activeElement?.tagName !== 'INPUT') {
    if (e.key === 'Backspace') {
      e.preventDefault()
      if (focusedField.value === 'tempo') {
        focusedField.value = 'pengiriman'
      } else if (focusedField.value === 'pengiriman') {
        focusedField.value = 'customer'
      } else if (focusedField.value === 'customer') {
        if (selectedCustomer.value) {
          clearCustomer()
        } else {
          focusedField.value = ''
          nextTick(() => inputOrderDate.value?.focus())
        }
      }
    }
  }

  // Enter: Move to next field
  if (!customerModal.show && !addCustomerModal.show && document.activeElement?.tagName !== 'INPUT') {
    if (e.key === 'Enter') {
      e.preventDefault()
      
      // Prevent immediate navigation after customer selection
      if (justSelectedCustomer.value) {
        justSelectedCustomer.value = false
        return
      }
      
      if (focusedField.value === 'pengiriman') {
        focusedField.value = 'tempo'
      } else if (focusedField.value === 'tempo') {
        // Move to submit if all fields completed
        if (canProceed.value) {
          attemptSubmitOrder()
        }
      } else if (!focusedField.value && selectedCustomer.value) {
        focusedField.value = 'pengiriman'
      }
    }
  }
}

// ───────────────────────────────────────────────────────────
// CUSTOMER SEARCH
// ───────────────────────────────────────────────────────────
function onCustomerInput() {
  // Reset selection when typing
  if (selectedCustomer.value) {
    selectedCustomer.value = null
    form.customer_id = null
  }
}

function onCustomerBlur() {
  if (!selectedCustomer.value) {
    focusedField.value = ''
  }
}

function onCustomerKey(e) {
  if (e.key === 'Enter') {
    e.preventDefault()
    openCustomerModal()
  } else if (e.key === 'F2') {
    e.preventDefault()
    quickAddCustomer()
  }
}

function onCustomerBackspace(e) {
  if (!searchCustomer.value?.trim() && !selectedCustomer.value) {
    e.preventDefault()
    focusedField.value = ''
    nextTick(() => inputOrderDate.value?.focus())
  }
}

async function refreshSelectedCustomerFinancials() {
  if (!selectedCustomer.value?.id) return

  const { data, error } = await supabase
    .from('customers')
    .select('limit_kredit, saldo_piutang, jatuh_tempo_bulan')
    .eq('id', selectedCustomer.value.id)
    .single()

  if (error) {
    console.error('[refreshSelectedCustomerFinancials]', error)
    return
  }

  selectedCustomer.value = {
    ...selectedCustomer.value,
    limit_kredit: Number(data?.limit_kredit || 0),
    saldo_piutang: Number(data?.saldo_piutang || 0),
    jatuh_tempo_bulan: data?.jatuh_tempo_bulan,
  }
}

async function openCustomerModal() {
  const q = searchCustomer.value.trim()
  
  try {
    let query = supabase
      .from('customers')
      .select('*')
      .eq('aktif', true)
      .order('nama')

    // Filter by name if search query exists
    if (q) {
      query = query.ilike('nama', `%${q}%`)
    }

    const { data, error } = await query

    if (error) throw error

    customerModal.results = data || []
    customerModal.filtered = data || []
    customerModal.query = ''
    customerModal.selectedIndex = 0
    customerModal.show = true

    await nextTick()
    customerModalInput.value?.focus()
  } catch (err) {
    console.error('[openCustomerModal]', err)
    alert('Gagal mencari customer: ' + err.message)
  }
}

function filterCustomerModal() {
  const q = customerModal.query.toLowerCase()
  customerModal.filtered = q
    ? customerModal.results.filter(c =>
        c.nama.toLowerCase().includes(q) ||
        c.kode.toLowerCase().includes(q) ||
        (c.alamat && c.alamat.toLowerCase().includes(q))
      )
    : customerModal.results
  customerModal.selectedIndex = 0
  nextTick(() => ensureCustomerModalSelectionVisible())
}

function onCustomerModalKey(e) {
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    customerModal.selectedIndex = Math.min(customerModal.selectedIndex + 1, customerModal.filtered.length - 1)
    ensureCustomerModalSelectionVisible()
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    customerModal.selectedIndex = Math.max(customerModal.selectedIndex - 1, 0)
    ensureCustomerModalSelectionVisible()
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (customerModal.filtered[customerModal.selectedIndex]) {
      selectCustomer(customerModal.filtered[customerModal.selectedIndex])
    }
  } else if (e.key === 'Escape') {
    customerModal.show = false
  } else if (e.key === 'F2') {
    e.preventDefault()
    customerModal.show = false
    quickAddCustomer()
  }
}

function ensureCustomerModalSelectionVisible() {
  const container = customerModalResultsEl.value
  if (!container) return

  const selectedEl = container.children?.[customerModal.selectedIndex]
  if (selectedEl && typeof selectedEl.scrollIntoView === 'function') {
    selectedEl.scrollIntoView({ block: 'nearest' })
  }
}

function mapCustomerTempoToLimitBulan(jatuhTempoBulan) {
  const tempo = Number(jatuhTempoBulan)
  if (tempo === 2) return 1
  if (tempo === 3) return 2
  return 0
}
  

async function selectCustomer(customer) {
  selectedCustomer.value = customer
  searchCustomer.value = customer.nama
  form.customer_id = customer.id
  form.limit_bulan = mapCustomerTempoToLimitBulan(customer?.jatuh_tempo_bulan)
  await refreshSelectedCustomerFinancials()
  customerModal.show = false
  justSelectedCustomer.value = true
  
  // Auto focus to page element so keyboard shortcuts work
  nextTick(() => {
    pageEl.value?.focus()
    focusedField.value = 'pengiriman'
  })
}

function clearCustomer() {
  selectedCustomer.value = null
  searchCustomer.value = ''
  form.customer_id = null
  justSelectedCustomer.value = false
  focusedField.value = 'customer'
  nextTick(() => inputCustomer.value?.focus())
}

function quickAddCustomer() {
  const nama = searchCustomer.value.trim()
  
  // Pre-fill nama if available
  addCustomerForm.nama = nama
  addCustomerForm.alamat = ''
  addCustomerForm.no_telp = ''
  addCustomerForm.limit_kredit = 10000000
  
  addCustomerModal.show = true
  nextTick(() => addCustomerNameInput.value?.focus())
}

function closeAddCustomer() {
  addCustomerModal.show = false
  addCustomerModal.saving = false
  nextTick(() => inputCustomer.value?.focus())
}

async function submitAddCustomer() {
  const nama = addCustomerForm.nama.trim()
  if (!nama) {
    alert('Nama customer wajib diisi')
    return
  }

  addCustomerModal.saving = true

  try {
    // Generate kode customer
    const { data: existingCustomers, error: countError } = await supabase
      .from('customers')
      .select('kode')
      .order('kode', { ascending: false })
      .limit(1)

    if (countError) throw countError

    let newKode = 'CUST001'
    if (existingCustomers && existingCustomers.length > 0) {
      const lastKode = existingCustomers[0].kode
      const num = parseInt(lastKode.replace('CUST', '')) + 1
      newKode = 'CUST' + String(num).padStart(3, '0')
    }

    // Insert customer
    const { data: newCustomer, error: insertError } = await supabase
      .from('customers')
      .insert({
        kode: newKode,
        nama: nama,
        alamat: addCustomerForm.alamat || null,
        no_telp: addCustomerForm.no_telp || null,
        limit_kredit: addCustomerForm.limit_kredit || 10000000,
        saldo_piutang: 0,
        aktif: true,
      })
      .select()
      .single()

    if (insertError) throw insertError

    // Use the new customer
    selectCustomer(newCustomer)
    closeAddCustomer()

    alert(`Customer "${nama}" berhasil ditambahkan dengan kode ${newKode}`)
  } catch (err) {
    console.error('[submitAddCustomer]', err)
    alert('Gagal menambahkan customer: ' + err.message)
  } finally {
    addCustomerModal.saving = false
  }
}

// ───────────────────────────────────────────────────────────
// FORM HELPERS
// ───────────────────────────────────────────────────────────
async function nextField(fieldName) {
  focusedField.value = fieldName
  await nextTick()
  
  if (fieldName === 'customer') {
    inputCustomer.value?.focus()
  } else if (fieldName === 'pengiriman') {
    // Focus on pengiriman section
  } else if (fieldName === 'tempo') {
    // Focus on tempo section
  }
}

function validateDate() {
  if (!form.order_date) {
    form.order_date = formatDateInput(new Date())
  }
  // Could add more validation for DD/MM/YY format
}

function onPengirimanChange() {
  focusedField.value = 'pengiriman'
  pageEl.value?.focus()
}

function onTempoChange() {
  focusedField.value = 'tempo'
  pageEl.value?.focus()
}

function showInfo(field) {
  const infos = {
    pengiriman: {
      title: 'Info: Pengiriman',
      content: `
        <p><strong>Diantar (1)</strong>: Barang akan dikirim ke alamat customer</p>
        <p><strong>Diambil (0)</strong>: Customer mengambil barang sendiri</p>
      `
    },
    tempo: {
      title: 'Info: Jatuh Tempo',
      content: `
        <p><strong>Tunai (0)</strong>: Pembayaran langsung saat transaksi</p>
        <p><strong>1 Bulan (1)</strong>: Jatuh tempo 30 hari dari tanggal order</p>
        <p><strong>2 Bulan (2)</strong>: Jatuh tempo 60 hari dari tanggal order</p>
        <p><strong>3 Bulan (3)</strong>: Jatuh tempo 90 hari dari tanggal order</p>
      `
    }
  }
  
  const info = infos[field] || infos.pengiriman
  infoModal.title = info.title
  infoModal.content = info.content
  infoModal.show = true
}

// ───────────────────────────────────────────────────────────
// FORM SUBMIT
// ───────────────────────────────────────────────────────────
async function attemptSubmitOrder() {
  if (submitInProgress.value) return

  if (!canProceed.value) {
    alert('Mohon lengkapi data customer terlebih dahulu')
    return
  }

  await refreshSelectedCustomerFinancials()

  // Validate credit limit
  if (remainingCredit.value < 0) {
    overLimitConfirm.show = true
    return
  }

  await submitOrderCore()
}

function cancelOverLimitConfirm() {
  overLimitConfirm.show = false
  nextTick(() => pageEl.value?.focus())
}

async function confirmOverLimitAndSubmit() {
  if (submitInProgress.value) return
  overLimitConfirm.show = false
  await submitOrderCore()
}

async function submitOrderCore() {
  if (submitInProgress.value) return

  const draftPayload = {
    order_date: parseDateInput(form.order_date),
    customer_id: selectedCustomer.value.id,
    customer_nama: selectedCustomer.value.nama,
    customer_alamat: selectedCustomer.value.alamat,
    customer_telp: selectedCustomer.value.no_telp,
    diantar: form.diantar,
    limit_bulan: form.limit_bulan,
    subtotal: 0,
    status: 'draft',
  }

  const requestFingerprint = buildSalesDraftFingerprint({
    orderDate: draftPayload.order_date,
    customerId: draftPayload.customer_id,
    diantar: draftPayload.diantar,
    limitBulan: draftPayload.limit_bulan,
  })

  submitInProgress.value = true

  try {
    let sale = null
    let supportsRequestFingerprint = true

    const { data: existingDraft, error: existingDraftError } = await supabase
      .from('sales')
      .select('id, no_order, no_faktur, order_date, customer_id, customer_nama, customer_alamat, customer_telp, diantar, limit_bulan')
      .eq('request_fingerprint', requestFingerprint)
      .eq('status', 'draft')
      .order('id', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (existingDraftError) {
      if (String(existingDraftError.message || '').toLowerCase().includes('request_fingerprint')) {
        supportsRequestFingerprint = false
      } else {
        throw existingDraftError
      }
    }

    if (supportsRequestFingerprint && existingDraft) {
      sale = existingDraft
    } else {
      const insertPayload = supportsRequestFingerprint
        ? { ...draftPayload, request_fingerprint: requestFingerprint }
        : draftPayload

      const { data: newSale, error: saleError } = await supabase
        .from('sales')
        .insert([insertPayload])
        .select('id, no_order, no_faktur, order_date, customer_id, customer_nama, customer_alamat, customer_telp, diantar, limit_bulan')
        .single()

      if (saleError) {
        if (
          supportsRequestFingerprint &&
          (saleError.code === '23505' || String(saleError.message || '').toLowerCase().includes('duplicate'))
        ) {
          const { data: duplicateDraft, error: duplicateError } = await supabase
            .from('sales')
            .select('id, no_order, no_faktur, order_date, customer_id, customer_nama, customer_alamat, customer_telp, diantar, limit_bulan')
            .eq('request_fingerprint', requestFingerprint)
            .eq('status', 'draft')
            .order('id', { ascending: false })
            .limit(1)
            .maybeSingle()

          if (duplicateError) throw duplicateError
          if (!duplicateDraft) throw saleError
          sale = duplicateDraft
        } else {
          throw saleError
        }
      } else {
        sale = newSale
      }
    }

    // Save to session storage with sale_id
    const orderData = {
      sale_id: sale.id,
      no_order: sale.no_order,
      no_faktur: sale.no_faktur,
      order_date: form.order_date,
      customer: {
        id: selectedCustomer.value.id,
        kode: selectedCustomer.value.kode,
        nama: selectedCustomer.value.nama,
        alamat: selectedCustomer.value.alamat,
        no_telp: selectedCustomer.value.no_telp,
        limit_kredit: selectedCustomer.value.limit_kredit,
        saldo_piutang: selectedCustomer.value.saldo_piutang,
      },
      diantar: form.diantar,
      limit_bulan: form.limit_bulan,
    }

    sessionStorage.setItem('penjualan_draft', JSON.stringify(orderData))
    router.push('/penjualan/input')
  } catch (err) {
    console.error('[submitOrderCore]', err)
    alert('Gagal membuat draft order: ' + err.message)
  } finally {
    submitInProgress.value = false
  }
}

// ───────────────────────────────────────────────────────────
// HELPERS
// ───────────────────────────────────────────────────────────
function parseDateInput(dateStr) {
  // Parse DD/MM/YY to YYYY-MM-DD
  const parts = dateStr.split('/')
  if (parts.length === 3) {
    const day = parts[0].padStart(2, '0')
    const month = parts[1].padStart(2, '0')
    let year = parts[2]
    if (year.length === 2) {
      year = '20' + year
    }
    return `${year}-${month}-${day}`
  }
  // Return current date if invalid
  return new Date().toISOString().split('T')[0]
}

function formatDateInput(date) {
  const d = new Date(date)
  const day = String(d.getDate()).padStart(2, '0')
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const year = String(d.getFullYear()).slice(-2)
  return `${day}/${month}/${year}`
}

function formatRp(val) {
  if (val == null || isNaN(val)) return 'Rp 0'
  return 'Rp ' + Number(val).toLocaleString('id-ID')
}
</script>

<style scoped>
@import '@/assets/styles.css';
@import '@/assets/components/form.css';
@import '@/assets/components/modal.css';
@import '@/assets/Styles/penjualan/penjualan-buat-page.css';
</style>
