<template>
  <div class="penjualan-page" ref="pageEl" tabindex="-1">

    <!-- ── PAGE HEADER ──────────────────────────────────── -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Buat Order Penjualan</h1>
        <p class="g-subtitle">Step 1: Informasi Order & Customer</p>
      </div>
      <button class="btn-secondary" @click="$router.push('/penjualan/list')" title="Lihat Daftar Order">
        <i class="pi pi-list"></i>
        <span>Daftar Order</span>
      </button>
    </div>

    <!-- ── FORM CARD ─────────────────────────────────────── -->
    <div class="form-card">
      <form @submit.prevent="submitOrder" class="order-form">
        
        <!-- No Order (Read-only, auto generate) -->
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
          <span class="field-hint">Nomor order akan dibuat otomatis</span>
        </div>

        <!-- Order Date -->
        <div class="form-row">
          <label class="form-label required">
            <i class="pi pi-calendar"></i>
            Tanggal Order
            <kbd class="label-kbd">Auto focus</kbd>
          </label>
          <input
            ref="inputOrderDate"
            v-model="form.order_date"
            type="text"
            class="form-input"
            placeholder="DD/MM/YY (default: hari ini)"
            @keydown.enter.prevent="nextField('customer')"
            @blur="validateDate"
          />
          <span class="field-hint">Format: DD/MM/YY (contoh: 03/03/26) atau tekan Enter untuk hari ini</span>
        </div>

        <!-- Customer Search -->
        <div class="form-row">
          <label class="form-label required">
            <i class="pi pi-user"></i>
            Customer
            <kbd class="label-kbd">Enter</kbd>
            <kbd class="label-kbd">F2 = Baru</kbd>
          </label>
          <div class="search-input-wrap" :class="{ filled: selectedCustomer }">
            <i class="pi pi-search si-icon"></i>
            <input
              ref="inputCustomer"
              v-model="searchCustomer"
              type="text"
              class="form-input si-input"
              placeholder="Ketik nama customer & tekan Enter..."
              @focus="focusedField = 'customer'"
              @blur="onCustomerBlur"
              @input="onCustomerInput"
              @keydown="onCustomerKey"
              :disabled="selectedCustomer !== null"
            />
            <button
              v-if="selectedCustomer"
              class="change-btn"
              @click="clearCustomer"
              type="button"
              title="Ganti customer"
            >
              <i class="pi pi-times"></i>
            </button>
          </div>
          
          <!-- Customer Info (if selected) -->
          <div v-if="selectedCustomer" class="customer-info">
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
          </div>
        </div>

        <!-- Diantar / Diambil -->
        <div class="form-row" :class="{ 'form-row--focused': focusedField === 'pengiriman' }">
          <label class="form-label">
            <i class="pi pi-truck"></i>
            Pengiriman
            <kbd class="label-kbd">↑↓ 0/1</kbd>
            <kbd class="label-kbd">F4 = Info</kbd>
          </label>
          <div class="radio-group">
            <label class="radio-option" :class="{ active: form.diantar === true }">
              <input type="radio" :value="true" v-model="form.diantar" />
              <span class="radio-label">
                <i class="pi pi-truck"></i>
                Diantar
                <kbd>1</kbd>
              </span>
            </label>
            <label class="radio-option" :class="{ active: form.diantar === false }">
              <input type="radio" :value="false" v-model="form.diantar" />
              <span class="radio-label">
                <i class="pi pi-shopping-bag"></i>
                Diambil
                <kbd>0</kbd>
              </span>
            </label>
          </div>
        </div>

        <!-- Limit Bulan -->
        <div class="form-row" :class="{ 'form-row--focused': focusedField === 'tempo' }">
          <label class="form-label">
            <i class="pi pi-clock"></i>
            Jatuh Tempo
            <kbd class="label-kbd">↑↓ 0/1/2</kbd>
            <kbd class="label-kbd">F4 = Info</kbd>
          </label>
          <div class="radio-group">
            <label class="radio-option" :class="{ active: form.limit_bulan === 0 }">
              <input type="radio" :value="0" v-model="form.limit_bulan" />
              <span class="radio-label">1 Bulan <kbd>0</kbd></span>
            </label>
            <label class="radio-option" :class="{ active: form.limit_bulan === 1 }">
              <input type="radio" :value="1" v-model="form.limit_bulan" />
              <span class="radio-label">2 Bulan <kbd>1</kbd></span>
            </label>
            <label class="radio-option" :class="{ active: form.limit_bulan === 2 }">
              <input type="radio" :value="2" v-model="form.limit_bulan" />
              <span class="radio-label">3 Bulan <kbd>2</kbd></span>
            </label>
          </div>
        </div>

        <!-- Salesman -->
        <div class="form-row" :class="{ 'form-row--focused': focusedField === 'salesman' }">
          <label class="form-label">
            <i class="pi pi-users"></i>
            Salesman
            <kbd class="label-kbd">↑↓ 0-4</kbd>
            <kbd class="label-kbd">F4 = Info</kbd>
          </label>
          <div class="radio-group">
            <label 
              v-for="(sales, idx) in salesOptions" 
              :key="sales"
              class="radio-option" 
              :class="{ active: form.salesman === sales }"
            >
              <input type="radio" :value="sales" v-model="form.salesman" />
              <span class="radio-label">Sales {{ sales }} <kbd>{{ idx }}</kbd></span>
            </label>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="form-actions">
          <button type="button" class="btn-secondary" @click="$router.push('/dashboard')">
            <i class="pi pi-times"></i>
            Batal <kbd>Esc</kbd>
          </button>
          <button type="submit" class="btn-primary" :disabled="!canProceed">
            <i class="pi pi-arrow-right"></i>
            Lanjut ke Input Barang <kbd>Y</kbd>
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

    <!-- ═══════════════════════════════════════════════════
         MODAL TAMBAH CUSTOMER CEPAT
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="addCustomerModal.show" class="modal-overlay" @click.self="closeAddCustomer">
          <div class="modal-box" role="dialog">
            <div class="modal-header">
              <i class="pi pi-user-plus"></i>
              <h3 class="modal-title">Tambah Customer Baru</h3>
              <button class="modal-close" @click="closeAddCustomer" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <form @submit.prevent="submitAddCustomer" class="modal-body">
              <div class="mfield-grid">
                <div class="mfield mfield-full">
                  <label class="mfield-label">Nama Customer <span class="required">*</span></label>
                  <input
                    ref="addCustomerNameInput"
                    v-model="addCustomerForm.nama"
                    type="text"
                    class="mfield-input"
                    placeholder="Nama customer"
                    required
                  />
                </div>
                <div class="mfield mfield-full">
                  <label class="mfield-label">Alamat <span class="optional">(opsional)</span></label>
                  <textarea
                    v-model="addCustomerForm.alamat"
                    class="mfield-textarea"
                    placeholder="Alamat lengkap customer"
                    rows="2"
                  ></textarea>
                </div>
                <div class="mfield">
                  <label class="mfield-label">No. Telp <span class="optional">(opsional)</span></label>
                  <input
                    v-model="addCustomerForm.no_telp"
                    type="text"
                    class="mfield-input"
                    placeholder="08xxxxxxxxxx"
                  />
                </div>
                <div class="mfield">
                  <label class="mfield-label">Limit Kredit <span class="optional">(opsional)</span></label>
                  <input
                    v-model="addCustomerForm.limit_kredit"
                    type="number"
                    class="mfield-input"
                    placeholder="10000000"
                    min="0"
                    step="1000"
                  />
                </div>
              </div>
              <div class="modal-footer">
                <button type="button" class="btn-secondary" @click="closeAddCustomer">
                  Batal <kbd>Esc</kbd>
                </button>
                <button type="submit" class="btn-primary" :disabled="addCustomerModal.saving">
                  <i class="pi pi-check"></i>
                  <span>{{ addCustomerModal.saving ? 'Menyimpan...' : 'Simpan & Gunakan' }}</span>
                  <kbd>Enter</kbd>
                </button>
              </div>
            </form>
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

  // Esc: Back to dashboard
  if (e.key === 'Escape') {
    e.preventDefault()
    router.push('/dashboard')
    return
  }

  // Number keys for radio selections
  if (!customerModal.show && !addCustomerModal.show && document.activeElement?.tagName !== 'INPUT') {
    if (e.key === '0') {
      e.preventDefault()
      if (focusedField.value === 'tempo') {
        form.limit_bulan = 0
      } else if (focusedField.value === 'salesman') {
        form.salesman = 'A'
      } else {
        form.diantar = false
        focusedField.value = 'pengiriman'
      }
    } else if (e.key === '1') {
      e.preventDefault()
      if (focusedField.value === 'tempo') {
        form.limit_bulan = 1
      } else if (focusedField.value === 'salesman') {
        form.salesman = 'B'
      } else {
        form.diantar = true
        focusedField.value = 'pengiriman'
      }
    } else if (e.key === '2') {
      e.preventDefault()
      if (focusedField.value === 'tempo') {
        form.limit_bulan = 2
      } else if (focusedField.value === 'salesman') {
        form.salesman = 'C'
      }
    } else if (e.key === '3' && focusedField.value === 'salesman') {
      e.preventDefault()
      form.salesman = 'D'
    } else if (e.key === '4' && focusedField.value === 'salesman') {
      e.preventDefault()
      form.salesman = 'E'
    }
  }

  // Arrow keys for radio navigation
  if (!customerModal.show && !addCustomerModal.show && document.activeElement?.tagName !== 'INPUT') {
    if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
      e.preventDefault()
      if (focusedField.value === 'pengiriman') {
        focusedField.value = 'tempo'
      } else if (focusedField.value === 'tempo') {
        focusedField.value = 'salesman'
      } else if (!focusedField.value && selectedCustomer.value) {
        focusedField.value = 'pengiriman'
      }
    } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
      e.preventDefault()
      if (focusedField.value === 'salesman') {
        focusedField.value = 'tempo'
      } else if (focusedField.value === 'tempo') {
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
  if (!q) {
    alert('Ketik nama customer terlebih dahulu')
    return
  }

  try {
    const { data, error } = await supabase
      .from('customers')
      .select('*')
      .ilike('nama', `%${q}%`)
      .eq('aktif', true)
      .order('nama')

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
}

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

  // Save to session storage and navigate to input page
  const orderData = {
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
}

// ───────────────────────────────────────────────────────────
// HELPERS
// ───────────────────────────────────────────────────────────
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
@import '@/assets/pages/penjualan/penjualan-page.css';
</style>
