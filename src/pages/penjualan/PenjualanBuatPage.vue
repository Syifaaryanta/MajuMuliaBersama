<template>
  <div class="penjualan-page" ref="pageEl" tabindex="-1">

    <!-- ── FORM CARD WITH HEADER ─────────────────────────────────────── -->
    <div class="form-card">
      <div class="form-header">
        <h1 class="form-header-title">Buat Order Penjualan</h1>
        <p class="form-header-subtitle">Step 1: Informasi Order & Customer</p>
      </div>
      <form @submit.prevent="submitOrder" class="order-form">
        
        <!-- LEFT COLUMN -->
        <div class="form-col-left">
          <!-- No Order -->
          <div class="form-row">
            <label class="form-label">
              <i class="pi pi-hashtag"></i>
              No. Order
            </label>
            <input
              v-model="form.no_order"
              type="text"
              class="form-input"
              placeholder="Auto generate saat save"
              readonly
              disabled
            />
          </div>

          <!-- Order Date -->
          <div class="form-row">
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
          <div class="form-row" :class="{ 'form-row--adding': addCustomerModal.show }">
            <label class="form-label required">
              <i class="pi pi-user"></i>
              Customer
            </label>
            
            <!-- Search Input (when not adding customer) -->
            <div v-if="!addCustomerModal.show && !selectedCustomer" style="position: relative; width: 100%;">
              <i class="pi pi-search" style="position: absolute; left: 1rem; top: 50%; transform: translateY(-50%); color: #9ca3af; pointer-events: none; font-size: 0.9rem; z-index: 1;"></i>
              <input
                ref="inputCustomer"
                v-model="searchCustomer"
                type="text"
                class="form-input"
                style="padding-left: 2.75rem; width: 100%;"
                placeholder="Tekan Enter untuk pilih customer..."
                @focus="focusedField = 'customer'"
                @blur="onCustomerBlur"
                @input="onCustomerInput"
                @keydown.enter.prevent="openCustomerModal"
                @keydown.f2.prevent="quickAddCustomer"
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
                  <span :class="{'text-danger': remainingCredit <= 0, 'text-success': remainingCredit > 0}">
                    Sisa: {{ formatRp(remainingCredit) }}
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
        </div>

        <!-- RIGHT COLUMN -->
        <div class="form-col-right">
          <!-- Pengiriman -->
          <div class="form-row" :class="{ 'form-row--focused': focusedField === 'pengiriman' }" @click="focusedField = 'pengiriman'">
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
          <div class="form-row" :class="{ 'form-row--focused': focusedField === 'tempo' }" @click="focusedField = 'tempo'">
            <label class="form-label">
              <i class="pi pi-clock"></i>
              Jatuh Tempo
            </label>
            <div class="radio-group">
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

          <!-- Salesman -->
          <div class="form-row" :class="{ 'form-row--focused': focusedField === 'salesman' }" @click="focusedField = 'salesman'">
            <label class="form-label">
              <i class="pi pi-users"></i>
              Salesman
            </label>
            <div class="radio-group radio-group-wrap">
              <label 
                v-for="(sales, idx) in salesOptions" 
                :key="sales"
                class="radio-option" 
                :class="{ active: form.salesman === sales }"
              >
                <input type="radio" :value="sales" v-model="form.salesman" @change="onSalesmanChange" />
                <span class="radio-label">Sales {{ sales }}</span>
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
          <button type="submit" class="btn-primary" :disabled="!canProceed">
            <i class="pi pi-arrow-right"></i>
            Lanjut ke Input Barang
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
              <div class="search-modal-results">
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

  </div>
</template>

<script setup>
import { ref, reactive, computed, nextTick, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()

// ───────────────────────────────────────────────────────────
// REFS
// ───────────────────────────────────────────────────────────
const pageEl = ref(null)
const inputOrderDate = ref(null)
const inputCustomer = ref(null)
const customerModalInput = ref(null)
const addCustomerNameInput = ref(null)

// ───────────────────────────────────────────────────────────
// STATE
// ───────────────────────────────────────────────────────────
const focusedField = ref('')
const searchCustomer = ref('')
const selectedCustomer = ref(null)
const justSelectedCustomer = ref(false)

const salesOptions = ['A', 'B', 'C', 'D', 'E']

const form = reactive({
  no_order: '',
  order_date: formatDateInput(new Date()),
  customer_id: null,
  diantar: true,
  limit_bulan: 0,
  salesman: 'A',
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
      submitOrder()
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
      } else if (focusedField.value === 'salesman') {
        form.salesman = 'A'
      } else {
        form.diantar = true
        focusedField.value = 'pengiriman'
      }
    } else if (e.key === '2') {
      e.preventDefault()
      if (focusedField.value === 'tempo') {
        form.limit_bulan = 1
      } else if (focusedField.value === 'salesman') {
        form.salesman = 'B'
      } else {
        form.diantar = false
        focusedField.value = 'pengiriman'
      }
    } else if (e.key === '3') {
      e.preventDefault()
      if (focusedField.value === 'tempo') {
        form.limit_bulan = 2
      } else if (focusedField.value === 'salesman') {
        form.salesman = 'C'
      }
    } else if (e.key === '4' && focusedField.value === 'salesman') {
      e.preventDefault()
      form.salesman = 'D'
    } else if (e.key === '5' && focusedField.value === 'salesman') {
      e.preventDefault()
      form.salesman = 'E'
    }
  }

  // Arrow keys for radio navigation
  if (!customerModal.show && !addCustomerModal.show && document.activeElement?.tagName !== 'INPUT') {
    // ArrowDown/ArrowUp: Navigate between fields
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      if (focusedField.value === 'pengiriman') {
        focusedField.value = 'tempo'
      } else if (focusedField.value === 'tempo') {
        focusedField.value = 'salesman'
      } else if (!focusedField.value && selectedCustomer.value) {
        focusedField.value = 'pengiriman'
      }
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      if (focusedField.value === 'salesman') {
        focusedField.value = 'tempo'
      } else if (focusedField.value === 'tempo') {
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
          form.limit_bulan = Math.max(form.limit_bulan - 1, 0)
        }
      } else if (focusedField.value === 'salesman') {
        const salesIndex = salesOptions.indexOf(form.salesman)
        if (e.key === 'ArrowRight') {
          const nextIndex = (salesIndex + 1) % salesOptions.length
          form.salesman = salesOptions[nextIndex]
        } else {
          const prevIndex = (salesIndex - 1 + salesOptions.length) % salesOptions.length
          form.salesman = salesOptions[prevIndex]
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
        focusedField.value = 'salesman'
      } else if (focusedField.value === 'salesman') {
        // Move to submit if all fields completed
        if (canProceed.value) {
          submitOrder()
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
  focusedField.value = ''
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
}

function onCustomerModalKey(e) {
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    customerModal.selectedIndex = Math.min(customerModal.selectedIndex + 1, customerModal.filtered.length - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    customerModal.selectedIndex = Math.max(customerModal.selectedIndex - 1, 0)
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
}justSelectedCustomer.value = true
  

function selectCustomer(customer) {
  selectedCustomer.value = customer
  searchCustomer.value = customer.nama
  form.customer_id = customer.id
  customerModal.show = false
  
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

function onSalesmanChange() {
  focusedField.value = 'salesman'
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
        <p><strong>1 Bulan (0)</strong>: Jatuh tempo 30 hari dari tanggal order</p>
        <p><strong>2 Bulan (1)</strong>: Jatuh tempo 60 hari dari tanggal order</p>
        <p><strong>3 Bulan (2)</strong>: Jatuh tempo 90 hari dari tanggal order</p>
      `
    },
    salesman: {
      title: 'Info: Salesman',
      content: `
        <p>Pilih salesman yang bertanggung jawab untuk order ini:</p>
        <ul>
          <li><strong>Sales A (0)</strong></li>
          <li><strong>Sales B (1)</strong></li>
          <li><strong>Sales C (2)</strong></li>
          <li><strong>Sales D (3)</strong></li>
          <li><strong>Sales E (4)</strong></li>
        </ul>
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
async function submitOrder() {
  if (!canProceed.value) {
    alert('Mohon lengkapi data customer terlebih dahulu')
    return
  }

  // Validate credit limit
  if (remainingCredit.value < 0) {
    const confirm = window.confirm(
      `Customer ${selectedCustomer.value.nama} telah melebihi limit kredit!\n\n` +
      `Limit: ${formatRp(selectedCustomer.value.limit_kredit)}\n` +
      `Piutang: ${formatRp(selectedCustomer.value.saldo_piutang)}\n\n` +
      `Tetap lanjutkan?`
    )
    if (!confirm) return
  }

  try {
    // Create draft order in database
    const { data: sale, error: saleError } = await supabase
      .from('sales')
      .insert([{
        order_date: parseDateInput(form.order_date),
        customer_id: selectedCustomer.value.id,
        customer_nama: selectedCustomer.value.nama,
        customer_alamat: selectedCustomer.value.alamat,
        customer_telp: selectedCustomer.value.no_telp,
        diantar: form.diantar,
        limit_bulan: form.limit_bulan,
        salesman: form.salesman,
        subtotal: 0,
        status: 'draft',
      }])
      .select()
      .single()

    if (saleError) throw saleError

    // Save to session storage with sale_id
    const orderData = {
      sale_id: sale.id,
      no_order: sale.no_order,
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
      salesman: form.salesman,
    }

    sessionStorage.setItem('penjualan_draft', JSON.stringify(orderData))
    router.push('/penjualan/input')
  } catch (err) {
    console.error('[submitOrder]', err)
    alert('Gagal membuat draft order: ' + err.message)
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
@import '@/assets/pages/penjualan/penjualan-buat-page.css';
</style>
