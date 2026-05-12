<template>
  <div class="penjualan-edit-page" :class="{ 'penjualan-edit-page--search-only': formVisible }" ref="pageEl" tabindex="-1">

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="formVisible" class="modal-overlay modal-overlay--transparent" @click.self="clearSearch">
          <form class="modal-box modal-box--filter" @submit.prevent="submitSearchModal">
            <div class="modal-header modal-header--blue">
              <div class="modal-header-left">
                <div class="modal-header-icon">
                  <i class="pi pi-filter"></i>
                </div>
                <h3 class="modal-title">Filter Edit Order Penjualan</h3>
              </div>
            </div>

            <div class="modal-body">
              <p class="modal-helper">Isi No. Order lalu tekan Enter.</p>

              <div class="filter-modal-grid">
                <div class="search-field">
                  <label class="search-label">
                    <i class="pi pi-hashtag"></i>
                    No. Order
                  </label>
                  <input
                    ref="searchInput"
                    v-model="searchQuery"
                    type="text"
                    class="search-input"
                    placeholder="Ketik No. Order lalu tekan Enter..."
                    autocomplete="off"
                    @keydown.enter.prevent="submitSearchModal"
                    @keydown.esc="handleSearchEsc"
                  />
                </div>
              </div>

              <p v-if="searchModalError" class="modal-error-inline">{{ searchModalError }}</p>
            </div>

            <div class="modal-footer">
              <button type="button" class="btn-secondary" @click="clearSearch">Batal</button>
              <button type="submit" class="btn-primary" :disabled="loading || !searchQuery.trim()">
                <i class="pi pi-check"></i>
                <span>Enter</span>
              </button>
            </div>
          </form>
        </div>
      </Transition>
    </Teleport>

    <!-- ── LOADING STATE ──────────────────────────────────── -->
    <div v-if="loading" class="loading-state">
      <i class="pi pi-spin pi-spinner"></i>
      <p>Mencari order...</p>
    </div>

    <!-- ── NOT FOUND STATE ──────────────────────────────────── -->
    <div v-if="notFound && !loading && !formVisible" class="empty-state">
      <i class="pi pi-inbox"></i>
      <h3>Order tidak ditemukan</h3>
      <p>No. Order <strong>{{ searchQuery }}</strong> tidak ditemukan dalam database.</p>
      <button class="btn-secondary" @click="clearSearch">
        <i class="pi pi-search"></i>
        Cari Lagi
      </button>
    </div>

    <!-- ── EDIT FORM (when order found) ──────────────────────────────────── -->
    <div v-if="order && !loading" class="form-card">
      <div class="form-header">
        <div class="form-header-content">
          <h1 class="form-header-title">Edit Order Penjualan</h1>
          <p class="form-header-subtitle">No. Order: {{ order.no_order }} · No. Fraktur: {{ order.no_faktur || '-' }}</p>
        </div>
        <div class="form-header-info">
          <div class="info-item">
            <span class="info-label">Tanggal:</span>
            <span class="info-value">{{ formatDate(order.order_date) }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Status:</span>
            <span class="status-badge" :class="`status-${order.status}`">
              {{ order.status === 'completed' ? 'Selesai' : 'Draft' }}
            </span>
          </div>
        </div>
      </div>

      <div class="order-form">
        
        <!-- Customer Info (Read-only) -->
        <div class="customer-card">
          <div class="customer-header">
            <i class="pi pi-user"></i>
            <span>Customer</span>
          </div>
          <div class="customer-body">
            <div class="customer-name">{{ order.customer.nama }}</div>
            <div class="customer-detail">
              <div class="detail-item">
                <i class="pi pi-map-marker"></i>
                <span>{{ order.customer.alamat || '—' }}</span>
              </div>
              <div class="detail-item">
                <i class="pi pi-phone"></i>
                <span>{{ order.customer.no_telp || '—' }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Shortcuts Bar -->
        <div class="shortcuts-bar">
          <kbd>F1 Lain-Lain</kbd>
          <kbd>F2 Barang</kbd>
          <kbd>F10 Keterangan</kbd>
          <kbd>F4 Info</kbd>
        </div>

        <!-- Items Table -->
        <div class="table-section">
          <div class="table-header">
            <h3 class="table-title">
              <i class="pi pi-list"></i>
              Daftar Barang ({{ items.length }} item)
            </h3>
          </div>

          <div class="table-wrap">
            <table class="items-table">
              <thead>
                <tr>
                  <th class="col-no">#</th>
                  <th class="col-kode">Kode</th>
                  <th class="col-nama">Nama Barang</th>
                  <th class="col-stock">Stok</th>
                  <th class="col-qty">QTY</th>
                  <th class="col-price">Harga Satuan</th>
                  <th class="col-total">Total</th>
                  <th class="col-action">Aksi</th>
                </tr>
              </thead>
              <tbody>
                <!-- Existing Items -->
                <tr 
                  v-for="(item, idx) in items" 
                  :key="item.id"
                  class="item-row"
                >
                  <td class="col-no">{{ idx + 1 }}</td>
                  <td class="col-kode">
                    <span class="item-kode">{{ item.product_kode }}</span>
                  </td>
                  <td class="col-nama">{{ item.product_nama }}</td>
                  <td class="col-stock">{{ item.stok_available }}</td>
                  <td class="col-qty">
                    <input
                      :ref="el => setQtyRef(el, idx)"
                      v-model.number="item.qty"
                      type="number"
                      class="qty-input"
                      min="0.01"
                      step="any"
                      @input="updateItemTotal(idx)"
                      @keydown="handleTableKeydown($event, idx, 'qty')"
                    />
                  </td>
                  <td class="col-price">
                    <div class="price-input-wrap">
                      <input
                        :ref="el => setPriceRef(el, idx)"
                        :value="formatNumber(item.unit_price)"
                        type="text"
                        class="price-input"
                        inputmode="numeric"
                        autocomplete="off"
                        spellcheck="false"
                        @input="updateItemPrice(idx, $event)"
                        @keydown="handleTableKeydown($event, idx, 'price')"
                      />
                    </div>
                  </td>
                  <td class="col-total">
                    <span class="total-val">{{ formatRp(item.total) }}</span>
                  </td>
                  <td class="col-action">
                    <button 
                      class="btn-icon btn-delete" 
                      @click="requestRemoveItem(idx)"
                      title="Hapus item (Del)"
                      tabindex="-1"
                    >
                      <i class="pi pi-trash"></i>
                    </button>
                  </td>
                </tr>

                <tr v-for="(adj, adjIdx) in adjustmentRows" :key="adj.id" class="item-row item-row--extra-charge">
                  <td class="col-no">{{ items.length + adjIdx + 1 }}</td>
                  <td class="col-kode">—</td>
                  <td class="col-nama">
                    <div class="item-info">
                      <span class="item-nama">{{ adj.description }}</span>
                    </div>
                  </td>
                  <td class="col-stock">—</td>
                  <td class="col-qty">—</td>
                  <td class="col-price">
                    <div class="price-input-wrap">
                      <input
                        type="text"
                        class="price-input"
                        :value="formatSignedNumber(adj.amount)"
                        readonly
                        @keydown="handleAdjustmentRowKeydown($event, adjIdx)"
                      />
                    </div>
                  </td>
                  <td class="col-total">
                    <span class="total-val">{{ formatRp(adj.amount) }}</span>
                  </td>
                  <td class="col-action">
                    <div class="adjustment-actions">
                      <button class="btn-icon" @click="moveAdjustmentUp(adjIdx)" title="Pindah ke atas" :disabled="adjIdx === 0">
                        <i class="pi pi-arrow-up"></i>
                      </button>
                      <button class="btn-icon" @click="moveAdjustmentDown(adjIdx)" title="Pindah ke bawah" :disabled="adjIdx === adjustmentRows.length - 1">
                        <i class="pi pi-arrow-down"></i>
                      </button>
                      <button class="btn-icon btn-delete" @click="requestRemoveAdjustment(adjIdx)" title="Hapus penyesuaian">
                        <i class="pi pi-times"></i>
                      </button>
                    </div>
                  </td>
                </tr>

                <!-- New Item Row -->
                <tr class="item-row item-row--new" ref="newItemRow">
                  <td class="col-no">{{ items.length + adjustmentRows.length + 1 }}</td>
                  <td class="col-kode" colspan="2">
                    <div class="search-input-wrap">
                      <input
                        ref="inputProduct"
                        v-model="newItem.search"
                        type="text"
                        class="item-input"
                        :class="{ 'item-input--search-mode': productSearchArmed }"
                        :placeholder="productInputPlaceholder"
                        @keydown.enter.prevent="onNewItemSearchEnter"
                        @keydown.tab.prevent="onNewItemSearchTab"
                        @keydown="handleNewItemKeydown($event, 'product')"
                      />
                      <i class="pi pi-search input-icon"></i>
                    </div>
                  </td>
                  <td class="col-stock">
                    <span v-if="newItem.product_id">{{ newItem.stok_available }}</span>
                    <span v-else>—</span>
                  </td>
                  <td class="col-qty">
                    <span v-if="isInlineAdjustmentDraft" class="qty-na">—</span>
                    <input
                      v-else
                      ref="inputQty"
                      v-model.number="newItem.qty"
                      type="number"
                      class="qty-input"
                      placeholder="0"
                      min="0.01"
                      step="any"
                      @keydown.enter="focusPrice"
                      @keydown="handleNewItemKeydown($event, 'qty')"
                      :disabled="!newItem.product_id"
                    />
                  </td>
                  <td class="col-price">
                    <div class="price-input-wrap">
                      <input
                        ref="inputPrice"
                        :value="newItem.unit_price ? formatSignedNumber(newItem.unit_price) : ''"
                        type="text"
                        @keydown="handleNewItemKeydown($event, 'price')"
                        class="price-input"
                        inputmode="numeric"
                        autocomplete="off"
                        spellcheck="false"
                        :placeholder="isInlineAdjustmentDraft ? 'Nominal +/- (contoh: -70.000)' : 'Harga satuan barang'"
                        @input="formatNewItemPrice"
                        @keydown.enter="onNewRowPriceEnter"
                        :disabled="!canInputPrice"
                      />
                    </div>
                  </td>
                  <td class="col-total">
                    <span class="total-val total-preview">
                      {{ newItem.unit_price ? formatRp(isInlineAdjustmentDraft ? newItem.unit_price : (newItem.qty * newItem.unit_price)) : '—' }}
                    </span>
                  </td>
                  <td class="col-action">
                    <button v-if="isInlineAdjustmentDraft" class="btn-icon" @click="confirmAdjustmentFromNewRow" title="Konfirmasi penyesuaian">
                      <i class="pi pi-check"></i>
                    </button>
                    <span v-else>—</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="table-note-inline">
            <span class="table-note-inline-label">Keterangan:</span>
            <input
              ref="senderInlineInput"
              v-model="extraForm.senderName"
              type="text"
              class="table-note-inline-input"
              @keydown.enter.prevent.stop="submitFromInlineNote"
            />
          </div>

          <!-- Subtotal -->
          <div class="table-footer">
            <div class="subtotal-row">
              <span class="subtotal-label">Subtotal:</span>
              <span class="subtotal-value">{{ formatRp(subtotal) }}</span>
            </div>
          </div>

          <div class="table-enter-row">
            <button class="btn-primary table-enter-btn" @click="submitFromInlineNote" :disabled="saving">
              Enter
            </button>
          </div>

        </div>

      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════
         MODAL PRODUCT SEARCH
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="productModal.show" class="modal-overlay" @click.self="closeProductModal">
          <div class="modal-box modal-search" role="dialog" tabindex="0" @keydown="onProductModalKey">
            <div class="modal-header">
              <i class="pi pi-search"></i>
              <h3 class="modal-title">Pilih Barang</h3>
              <button class="modal-close" @click="closeProductModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <div class="search-modal-input-wrap">
                <i class="pi pi-search"></i>
                <input
                  ref="productModalInput"
                  v-model="productModal.query"
                  type="text"
                  class="search-modal-input"
                  placeholder="Ketik untuk filter hasil..."
                  @input="filterProductModal"
                  @keydown="onProductModalKey"
                />
              </div>
              <div class="search-modal-results" ref="productModalResultsEl">
                <div
                  v-for="(item, idx) in productModal.filtered"
                  :key="item.id"
                  class="search-modal-item"
                  :class="{ active: idx === productModal.selectedIndex }"
                  @click="selectProduct(item)"
                  @mouseenter="productModal.selectedIndex = idx"
                >
                  <div class="smi-main">
                    <span class="smi-kode">{{ item.kode }}</span>
                    <span class="smi-nama">{{ item.nama }}</span>
                  </div>
                  <div class="smi-sub">
                    <span>Stok: <strong>{{ item.stok }} {{ item.satuan }}</strong></span>
                  </div>
                </div>
                <div v-if="productModal.filtered.length === 0" class="search-modal-empty">
                  <i class="pi pi-inbox"></i>
                  <p>Tidak ada barang yang cocok</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════
         MODAL PRICE INFO
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="priceInfoModal.show" class="modal-overlay" @click.self="closePriceInfoModal">
          <div class="modal-box modal-box--md" role="dialog">
            <div class="modal-header">
              <i class="pi pi-info-circle"></i>
              <h3 class="modal-title">Info Harga: {{ priceInfoModal.product_nama }}</h3>
              <button class="modal-close" @click="closePriceInfoModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <div class="price-info-grid" v-if="priceInfoModal.loading">
                <div class="skeleton-box"></div>
                <div class="skeleton-box"></div>
                <div class="skeleton-box"></div>
              </div>
              <div class="price-info-grid" v-else>
                <div class="price-info-card">
                  <div class="pic-label">Last Unit Price</div>
                  <div class="pic-value">{{ formatRp(priceInfoModal.data.last_unit_price) }}</div>
                  <div class="pic-hint">Harga jual terakhir (customer ini)</div>
                </div>
                <div class="price-info-card">
                  <div class="pic-label">Last Unit Cost</div>
                  <div class="pic-value">{{ formatRp(priceInfoModal.data.last_unit_cost) }}</div>
                  <div class="pic-hint">Harga beli terakhir</div>
                </div>
                <div class="price-info-card">
                  <div class="pic-label">Last Sale Qty</div>
                  <div class="pic-value">{{ priceInfoModal.data.last_sale_qty || 0 }} pcs</div>
                  <div class="pic-hint">Qty penjualan terakhir</div>
                </div>
                <div class="price-info-card">
                  <div class="pic-label">Last Order Date</div>
                  <div class="pic-value">{{ priceInfoModal.data.last_order_date || '—' }}</div>
                  <div class="pic-hint">Tanggal order terakhir</div>
                </div>
              </div>
            </div>
            <div class="modal-footer">
              <button class="btn-primary" @click="closePriceInfoModal">
                Tutup
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════════
         MODAL SUPPLIER SELECTION
    ═══════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="supplierModal.show" class="modal-overlay" @click.self="supplierModal.show = false" @keydown="onSupplierModalKey">
          <div ref="supplierModalBox" class="modal-box modal-search" role="dialog" tabindex="0">
            <div class="modal-header modal-header--blue">
              <i class="pi pi-truck"></i>
              <h3 class="modal-title">Pilih Supplier</h3>
              <button class="modal-close" @click="supplierModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <p class="supplier-product-name"> <strong>{{ supplierModal.product?.nama }}</strong></p>
              <p class="supplier-select-hint">
                <i class="pi pi-info-circle"></i>
                Barang ini tersedia dari beberapa supplier dengan harga berbeda. Pilih supplier yang akan digunakan.
              </p>
              <div class="search-modal-results" ref="supplierModalResultsEl">
                <div
                  v-for="(entry, idx) in supplierModal.prices"
                  :key="entry.id"
                  class="search-modal-item"
                  :class="{ active: idx === supplierModal.selectedIndex }"
                  @click="selectSupplierPrice(entry)"
                  @mouseenter="supplierModal.selectedIndex = idx"
                >
                  <div class="smi-main">
                    <span class="smi-nama">{{ entry.supplier_nama }}</span>
                  </div>
                  <div class="smi-sub">
                    <span>Modal: <strong>{{ formatRp(entry.harga_beli) }}</strong></span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════
         MODAL STOK KOSONG
    ════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="stockEmptyModal.show" class="modal-overlay modal-overlay--stock-empty" @click.self="closeStockEmptyModal">
          <div ref="stockEmptyModalBox" class="modal-box modal-box--sm modal-box--stock-empty" role="dialog" tabindex="0" aria-modal="true" aria-label="Peringatan stok kosong" @keydown="onStockEmptyModalKey">
            <div class="modal-header modal-header--danger">
              <i class="pi pi-ban"></i>
              <h3 class="modal-title">Stok Gudang Kosong</h3>
              <button class="modal-close" @click="closeStockEmptyModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <p class="confirm-text">Item ini tidak bisa diinput karena stok gudang kosong.</p>
              <p class="confirm-subtext">Item: <strong>{{ stockEmptyModal.productName }}</strong></p>
              <p class="confirm-subtext">Tekan <strong>Enter</strong> untuk batalkan dan cari item lain.</p>
            </div>
            <div class="modal-footer">
              <button class="btn-primary" @click="closeStockEmptyModal">Batal & Cari Lagi <kbd>Enter</kbd></button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════════
         MODAL KONFIRMASI PRINT
    ═══════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="printConfirmModal.show" class="modal-overlay" @click.self="closePrintConfirmModal">
          <div
            ref="printConfirmModalBox"
            class="modal-box modal-box--print-confirm"
            role="dialog"
            tabindex="0"
            @keydown="handlePrintConfirmKeydown"
          >
            <div class="modal-header">
              <i class="pi pi-print"></i>
              <h3 class="modal-title">Konfirmasi Cetak Nota</h3>
              <button class="modal-close" @click="closePrintConfirmModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <p class="print-confirm-help">
                Pilih urutan item.
              </p>

              <div class="print-sort-options">
                <button
                  v-for="(opt, idx) in printSortOptions"
                  :key="opt.value"
                  type="button"
                  class="print-sort-btn"
                  :class="{ active: idx === printConfirmModal.sortIndex }"
                  @click="setPrintSortIndex(idx)"
                >
                  {{ opt.label }}
                </button>
              </div>

              <div class="print-preview-table-wrap">
                <table class="print-preview-table">
                  <thead>
                    <tr>
                      <th>Nama Barang</th>
                      <th class="text-right">Qty</th>
                      <th class="text-right">Harga</th>
                      <th class="text-right">Jumlah</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="item in sortedPrintItems" :key="`${item.product_id}-${item.product_kode}-${item.unit_price}`">
                      <td>{{ item.product_nama }}</td>
                      <td class="text-right">{{ item.qty }}</td>
                      <td class="text-right">{{ formatRp(item.unit_price) }}</td>
                      <td class="text-right">{{ formatRp(item.total) }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="closePrintConfirmModal">Batal (Esc)</button>
              <button class="btn-secondary" @click="confirmSaveFromPrintModal">Simpan (Enter)</button>
              <button class="btn-primary" @click="printFromConfirmModal">Print (P)</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════════
         MODAL KONFIRMASI HAPUS
    ═══════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="deleteConfirmModal.show" class="modal-overlay" @click.self="closeDeleteConfirmModal">
          <div class="modal-box modal-box--sm" role="dialog">
            <div class="modal-header">
              <i class="pi pi-trash"></i>
              <h3 class="modal-title">Konfirmasi Hapus</h3>
              <button class="modal-close" @click="closeDeleteConfirmModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <p>Hapus item ini?</p>
              <strong>{{ deleteConfirmModal.label || 'Baris terpilih' }}</strong>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="closeDeleteConfirmModal">Batal (Esc)</button>
              <button class="btn-danger" @click="confirmDeleteRow">Hapus (Enter)</button>
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
const pageEl = ref(null)
const searchInput = ref(null)
const inputProduct = ref(null)
const inputQty = ref(null)
const inputPrice = ref(null)
const productModalInput = ref(null)
const productModalResultsEl = ref(null)
const supplierModalResultsEl = ref(null)
const supplierModalBox = ref(null)
const senderInlineInput = ref(null)
const priceInfoReturnFocusEl = ref(null)
const printConfirmModalBox = ref(null)
const stockEmptyModalBox = ref(null)
const suppressNextProductModalEnter = ref(false)

// ───────────────────────────────────────────────────────────
// STATE
// ───────────────────────────────────────────────────────────
const searchQuery = ref('')
const searchModalError = ref('')
const loading = ref(false)
const notFound = ref(false)
const saving = ref(false)
const formVisible = ref(true)

const order = ref(null)
const items = ref([])
const originalItems = ref([]) // Store original items for stock restoration

// Dynamic refs for table navigation
const qtyRefs = ref({})
const priceRefs = ref({})

// New item state
const newItem = reactive({
  search: '',
  product_id: null,
  product_kode: '',
  product_nama: '',
  qty: 1,
  unit_price: 0,
  total: 0,
  stok_available: 0
})

// Product modal
const productModal = reactive({
  show: false,
  query: '',
  results: [],
  filtered: [],
  selectedIndex: 0
})

// Price info modal
const priceInfoModal = reactive({
  show: false,
  product_id: null,
  product_nama: '',
  loading: false,
  data: {
    last_unit_price: 0,
    last_unit_cost: 0,
    last_sale_qty: 0,
    last_order_date: null
  }
})

const supplierModal = reactive({
  show: false,
  product: null,
  prices: [],
  selectedIndex: 0,
  defaultUnitPrice: 0,
})

const printConfirmModal = reactive({
  show: false,
  sortIndex: 0,
  saleId: null,
  payload: null,
})

const deleteConfirmModal = reactive({
  show: false,
  type: 'item',
  index: -1,
  label: '',
})

const stockEmptyModal = reactive({
  show: false,
  productName: '',
})

const printSortOptions = [
  { value: 'original', label: 'Urutan Asli' },
  { value: 'alpha', label: 'Abjad (A-Z)' },
  { value: 'qty', label: 'Qty Terbanyak' },
  { value: 'price', label: 'Harga Tertinggi' },
]

const EDIT_LAST_ORDER_KEY = 'penjualan_edit_last_order'
const EDIT_RESTORE_ON_REFRESH_KEY = 'penjualan_edit_restore_on_refresh'
const SALES_HISTORY_DETAIL_KEY = 'penjualan_list_open_no_order'
const PENJUALAN_FLASH_KEY = 'penjualan_flash_notice'

function normalizeAdjustmentDescription(text) {
  return String(text || '')
    .split(' | ')
    .map(part => part.replace(/^(\d+\.\s*)+/, '').trim())
    .filter(Boolean)
    .join(' | ')
}

const productSearchArmed = ref(true)
const adjustmentRows = ref([])
const senderNoteAutofilled = ref(false)

const extraForm = reactive({
  senderName: '',
})

// ───────────────────────────────────────────────────────────
// COMPUTED
// ───────────────────────────────────────────────────────────
const subtotal = computed(() => {
  return items.value.reduce((sum, item) => sum + (item.total || 0), 0) + adjustmentTotal.value
})

const adjustmentTotal = computed(() => {
  return adjustmentRows.value.reduce((sum, row) => sum + Number(row.amount || 0), 0)
})

const isInlineAdjustmentDraft = computed(() => {
  return !productSearchArmed.value && !newItem.product_id && !!newItem.search.trim()
})

const canInputPrice = computed(() => {
  return !!newItem.product_id || isInlineAdjustmentDraft.value
})

const productInputPlaceholder = computed(() => {
  if (productSearchArmed.value) {
    return 'Ketik nama barang lalu Enter'
  }
  return 'Ketik keterangan lalu Enter, atau tekan F2 untuk cari barang'
})

const sortedPrintItems = computed(() => {
  const rows = (printConfirmModal.payload?.items || []).slice()
  const sortKey = printSortOptions[printConfirmModal.sortIndex]?.value || 'original'

  if (sortKey === 'original') {
    return rows
  }

  if (sortKey === 'qty') {
    return rows.sort((a, b) => {
      const qDiff = Number(b.qty || 0) - Number(a.qty || 0)
      if (qDiff !== 0) return qDiff
      return String(a.product_nama || '').localeCompare(String(b.product_nama || ''), 'id')
    })
  }

  if (sortKey === 'price') {
    return rows.sort((a, b) => {
      const pDiff = Number(b.unit_price || 0) - Number(a.unit_price || 0)
      if (pDiff !== 0) return pDiff
      return String(a.product_nama || '').localeCompare(String(b.product_nama || ''), 'id')
    })
  }

  return rows.sort((a, b) => String(a.product_nama || '').localeCompare(String(b.product_nama || ''), 'id'))
})

// ───────────────────────────────────────────────────────────
// REFS MANAGEMENT
// ───────────────────────────────────────────────────────────
function setQtyRef(el, idx) {
  if (el) qtyRefs.value[idx] = el
}

function setPriceRef(el, idx) {
  if (el) priceRefs.value[idx] = el
}

// ───────────────────────────────────────────────────────────
// KEYBOARD NAVIGATION - TABLE
// ───────────────────────────────────────────────────────────
function handleTableKeydown(e, rowIdx, field) {
  const totalRows = items.value.length

  // Delete - delete focused row directly
  if (e.key === 'Delete') {
    e.preventDefault()
    requestRemoveItem(rowIdx)
    return
  }

  // Backspace - delete row only when cell is empty
  if (e.key === 'Backspace' && e.target.value === '') {
    e.preventDefault()
    requestRemoveItem(rowIdx)
    return
  }

  // F4 - Show price info (only in price field)
  if (e.key === 'F4' && field === 'price') {
    e.preventDefault()
    showPriceInfo(items.value[rowIdx], e.target)
    return
  }

  // Enter - move to next field or row
  if (e.key === 'Enter') {
    e.preventDefault()
    if (field === 'qty') {
      // Move from qty to price in same row
      priceRefs.value[rowIdx]?.focus()
    } else if (field === 'price') {
      // Move to next row or new item
      if (rowIdx < totalRows - 1) {
        qtyRefs.value[rowIdx + 1]?.focus()
      } else {
        inputProduct.value?.focus()
      }
    }
    return
  }

  // Arrow Down - move to next row
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    if (rowIdx < totalRows - 1) {
      if (field === 'qty') {
        qtyRefs.value[rowIdx + 1]?.focus()
      } else if (field === 'price') {
        priceRefs.value[rowIdx + 1]?.focus()
      }
    } else {
      // At last row, move to new item
      if (field === 'qty') {
        inputQty.value?.focus()
      } else if (field === 'price') {
        inputPrice.value?.focus()
      }
    }
    return
  }

  // Arrow Up - move to previous row
  if (e.key === 'ArrowUp') {
    e.preventDefault()
    if (rowIdx > 0) {
      if (field === 'qty') {
        qtyRefs.value[rowIdx - 1]?.focus()
      } else if (field === 'price') {
        priceRefs.value[rowIdx - 1]?.focus()
      }
    }
    return
  }

  // Arrow Left - move from price to qty
  if (e.key === 'ArrowLeft' && field === 'price') {
    if (e.ctrlKey || e.target.selectionStart === 0) {
      e.preventDefault()
      qtyRefs.value[rowIdx]?.focus()
      return
    }
  }

  // Arrow Right - move from qty to price
  if (e.key === 'ArrowRight' && field === 'qty') {
    if (e.ctrlKey || e.target.selectionStart === e.target.value.length) {
      e.preventDefault()
      priceRefs.value[rowIdx]?.focus()
      return
    }
  }
}

function handleAdjustmentRowKeydown(e, rowIdx) {
  if (e.key === 'Delete' || e.key === 'Backspace') {
    e.preventDefault()
    requestRemoveAdjustment(rowIdx)
  }
}

// ───────────────────────────────────────────────────────────
// KEYBOARD NAVIGATION - NEW ITEM
// ───────────────────────────────────────────────────────────
function handleNewItemKeydown(e, field) {
  // Backspace - go back to last item when field is empty
  if (e.key === 'Backspace' && !e.target.value) {
    e.preventDefault()
    const lastIdx = items.value.length - 1
    if (lastIdx >= 0) {
      if (field === 'product') {
        priceRefs.value[lastIdx]?.focus()
      } else if (field === 'qty') {
        qtyRefs.value[lastIdx]?.focus()
      } else if (field === 'price') {
        priceRefs.value[lastIdx]?.focus()
      }
    }
    return
  }

  if (e.key === 'F4' && field === 'price') {
    e.preventDefault()
    showPriceInfoPreview(e.target)
    return
  }

  // Arrow Up - go to last item
  if (e.key === 'ArrowUp') {
    e.preventDefault()
    const lastIdx = items.value.length - 1
    if (lastIdx >= 0) {
      if (field === 'product') {
        priceRefs.value[lastIdx]?.focus()
      } else if (field === 'qty') {
        qtyRefs.value[lastIdx]?.focus()
      } else if (field === 'price') {
        priceRefs.value[lastIdx]?.focus()
      }
    }
    return
  }

  // Arrow Right - move to next field
  if (e.key === 'ArrowRight') {
    if (field === 'qty' && (e.ctrlKey || e.target.selectionStart === e.target.value.length)) {
      e.preventDefault()
      inputPrice.value?.focus()
      return
    }
  }

  // Arrow Left - move to previous field
  if (e.key === 'ArrowLeft') {
    if (field === 'price' && (e.ctrlKey || e.target.selectionStart === 0)) {
      e.preventDefault()
      inputQty.value?.focus()
      return
    } else if (field === 'qty' && (e.ctrlKey || e.target.selectionStart === 0)) {
      e.preventDefault()
      inputProduct.value?.focus()
      return
    }
  }
}

// ───────────────────────────────────────────────────────────
// GLOBAL KEY HANDLER
// ───────────────────────────────────────────────────────────
function onGlobalKey(e) {
  if (e.defaultPrevented) return

  if (stockEmptyModal.show) {
    if (e.key === 'Escape' || e.key === 'Enter') {
      e.preventDefault()
      closeStockEmptyModal()
      return
    }
    return
  }

  if (deleteConfirmModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      closeDeleteConfirmModal()
      return
    }

    if (e.key === 'Enter') {
      e.preventDefault()
      confirmDeleteRow()
      return
    }

    return
  }

  if (printConfirmModal.show) {
    const targetEl = e.target instanceof HTMLElement ? e.target : null
    if (targetEl && printConfirmModalBox.value?.contains(targetEl)) {
      return
    }

    handlePrintConfirmKeydown(e)
    return
  }

  if (priceInfoModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      closePriceInfoModal()
    }
    return
  }

  if (productModal.show) {
    onProductModalKey(e)
    return
  }

  if (supplierModal.show) {
    onSupplierModalKey(e)
    return
  }

  if (formVisible.value) {
    if (e.key === 'Escape') {
      e.preventDefault()
      clearSearch()
    }
    return
  }

  if (!order.value) return

  const isActionShortcut =
    e.key === 'F1' ||
    e.key === 'F2' ||
    e.key === 'F10' ||
    e.key === 'Escape' ||
    (e.ctrlKey && e.key.toLowerCase() === 's')

  // Allow typing naturally, but keep action shortcuts active even inside input fields
  if (e.target.tagName === 'INPUT' && !isActionShortcut) {
    return
  }

  if (e.key === 'Enter' && document.activeElement === senderInlineInput.value) {
    e.preventDefault()
    submitFromInlineNote()
    return
  }
  
  // ESC - Show form and hide order info (when editing order)
  if (e.key === 'Escape' && order.value && !formVisible.value) {
    e.preventDefault()
    e.stopPropagation()
    formVisible.value = true
    order.value = null
    items.value = []
    adjustmentRows.value = []
    productSearchArmed.value = false
    extraForm.senderName = ''
    senderNoteAutofilled.value = false
    searchModalError.value = ''
    nextTick(() => {
      searchInput.value?.focus()
    })
    return
  }

  if (e.key === 'F10') {
    e.preventDefault()
    focusInlineNoteInput()
    return
  }

  if (e.key === 'F1') {
    e.preventDefault()
    productSearchArmed.value = false
    focusProductInput()
    return
  }

  if (e.key === 'F2') {
    e.preventDefault()
    activateProductSearchMode()
    return
  }

  if (e.ctrlKey && e.key.toLowerCase() === 's' && items.value.length > 0) {
    e.preventDefault()
    submitFromInlineNote()
  }
}

function onStockEmptyCaptureKey(e) {
  if (!stockEmptyModal.show) return

  const isEnter = e.key === 'Enter' || e.code === 'NumpadEnter'
  if (isEnter || e.key === 'Escape') {
    e.preventDefault()
    e.stopPropagation()
    closeStockEmptyModal(isEnter ? 'enter' : 'escape')
  }
}

// ───────────────────────────────────────────────────────────
// SEARCH ORDER
// ───────────────────────────────────────────────────────────
async function searchOrder() {
  if (!searchQuery.value.trim()) return

  searchModalError.value = ''
  
  loading.value = true
  notFound.value = false
  order.value = null
  items.value = []
  adjustmentRows.value = []
  
  try {
    // Cari berdasarkan no_order dulu, lalu validasi tanggal di sisi aplikasi
    const { data: orderData, error: orderError } = await supabase
      .from('sales')
      .select(`
        *,
        customer:customers(id, kode, nama, alamat, no_telp)
      `)
      .eq('no_order', searchQuery.value.trim())
      .maybeSingle()
    
    if (orderError) {
      console.error('Order error:', orderError)
      notFound.value = true
      searchModalError.value = `Gagal mencari order: ${orderError.message || orderError}`
      return
    }

    if (!orderData) {
      notFound.value = true
      searchModalError.value = 'Order tidak ditemukan. Pastikan No. Order benar.'
      return
    }

    order.value = orderData
    sessionStorage.setItem(EDIT_LAST_ORDER_KEY, String(orderData.no_order || searchQuery.value.trim() || ''))
    extraForm.senderName = orderData.sender_note || ''
    senderNoteAutofilled.value = false

    const existingExtraDesc = normalizeAdjustmentDescription(orderData.extra_charge_desc)
    const existingExtraAmount = Number(orderData.extra_charge_amount || 0)
    if (existingExtraDesc || existingExtraAmount) {
      adjustmentRows.value = [{
        id: `adj-${Date.now()}`,
        description: existingExtraDesc || 'Penyesuaian',
        amount: existingExtraAmount,
      }]
    }
    
    // Load order items with product info
    const { data: itemsData, error: itemsError } = await supabase
      .from('sale_items')
      .select(`
        *,
        product:products(kode, nama, stok)
      `)
      .eq('sale_id', orderData.id)
    
    console.log('Items query result:', { itemsData, itemsError })
    
    if (itemsError) {
      console.error('Error loading items:', itemsError)
      throw itemsError
    }
    
    items.value = (itemsData || []).map(item => ({
      ...item,
      product_id: item.product_id,
      product_kode: item.product_kode,
      product_nama: item.product_nama,
      product_stok: item.product?.stok || 0,
      stok_available: item.product?.stok || 0,
      total: item.qty * item.unit_price
    }))
    
    console.log('Items loaded:', items.value.length, items.value)
    
    // Store original items for stock restoration
    originalItems.value = JSON.parse(JSON.stringify((itemsData || []).map(item => ({
      product_id: item.product_id,
      qty: item.qty
    }))))

    // Hide search form after order loads
    formVisible.value = false
    searchModalError.value = ''
    
    // Samakan dengan halaman input item: fokus ke row input barang baru.
    await nextTick()
    setTimeout(() => {
      inputProduct.value?.focus()
      inputProduct.value?.select?.()
    }, 100)
    
  } catch (error) {
    console.error('Error searching order:', error)
    notFound.value = true
    searchModalError.value = `Gagal mencari order: ${error.message || error}`
  } finally {
    loading.value = false
  }
}

async function submitSearchModal() {
  if (!searchQuery.value.trim()) {
    searchModalError.value = 'No. Order wajib diisi.'
    nextTick(() => {
      searchInput.value?.focus()
    })
    return
  }

  await searchOrder()
}

function clearSearch() {
  // If search is already empty, go back to menu
  if (!searchQuery.value && !order.value) {
    sessionStorage.removeItem(EDIT_LAST_ORDER_KEY)
    router.push('/penjualan')
    return
  }
  
  // Otherwise, just clear the search
  searchQuery.value = ''
  searchModalError.value = ''
  order.value = null
  items.value = []
  originalItems.value = []
  notFound.value = false
  formVisible.value = true
  adjustmentRows.value = []
  extraForm.senderName = ''
  senderNoteAutofilled.value = false
  nextTick(() => {
    searchInput.value?.focus()
  })
}

function handleSearchEsc(e) {
  e.preventDefault()
  e.stopPropagation()
  
  // If search input is empty, go back to menu
  if (!searchQuery.value.trim()) {
    router.push('/penjualan')
    return
  }
  
  // Otherwise, clear the search
  searchQuery.value = ''
  nextTick(() => {
    searchInput.value?.focus()
  })
}

function focusProductInput() {
  nextTick(() => inputProduct.value?.focus())
}

function focusInlineNoteInput() {
  const isPickup = order.value?.diantar === false
  const isSenderNoteEmpty = !String(extraForm.senderName || '').trim()
  if (isPickup && isSenderNoteEmpty && !senderNoteAutofilled.value) {
    extraForm.senderName = 'Diambil'
    senderNoteAutofilled.value = true
  }

  nextTick(() => {
    senderInlineInput.value?.focus()
    senderInlineInput.value?.setSelectionRange?.(
      String(extraForm.senderName || '').length,
      String(extraForm.senderName || '').length,
    )
  })
}

async function submitFromInlineNote() {
  if (saving.value) return
  if (!items.value.length) {
    alert('Tambahkan minimal 1 barang')
    return
  }

  openPrintConfirmModal(buildPrintPayload())
}

function activateProductSearchMode() {
  productSearchArmed.value = true
  nextTick(() => {
    inputProduct.value?.focus()
    inputProduct.value?.select?.()
  })
}

function onNewItemSearchTab() {
  if (productSearchArmed.value) {
    openProductModal()
    return
  }

  if (newItem.product_id) {
    inputQty.value?.focus()
    return
  }

  if (isInlineAdjustmentDraft.value) {
    focusPrice()
    return
  }

}

function onNewItemSearchEnter() {
  if (productSearchArmed.value) {
    openProductModal()
    return
  }

  if (isInlineAdjustmentDraft.value && Number(newItem.unit_price || 0) !== 0) {
    confirmAdjustmentFromNewRow()
    return
  }

  if (isInlineAdjustmentDraft.value) {
    focusPrice()
  }
}

function confirmAdjustmentFromNewRow() {
  const description = normalizeAdjustmentDescription(newItem.search)
  const amount = Number(newItem.unit_price || 0)
  if (!description) {
    alert('Isi keterangan penyesuaian, contoh: Pengiriman atau Potongan')
    return
  }

  if (!amount) {
    alert('Isi nominal penyesuaian (boleh negatif untuk potongan)')
    inputPrice.value?.focus()
    return
  }

  adjustmentRows.value.push({
    id: `adj-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
    description,
    amount,
  })

  resetNewItem()
  focusProductInput()
}

function requestRemoveAdjustment(index) {
  const row = adjustmentRows.value[index]
  deleteConfirmModal.show = true
  deleteConfirmModal.type = 'adjustment'
  deleteConfirmModal.index = index
  deleteConfirmModal.label = row?.description || 'Penyesuaian'
}

function removeAdjustment(index) {
  adjustmentRows.value.splice(index, 1)
}

function moveAdjustmentUp(index) {
  if (index <= 0) return
  const rows = adjustmentRows.value
  ;[rows[index - 1], rows[index]] = [rows[index], rows[index - 1]]
}

function moveAdjustmentDown(index) {
  const rows = adjustmentRows.value
  if (index < 0 || index >= rows.length - 1) return
  ;[rows[index], rows[index + 1]] = [rows[index + 1], rows[index]]
}

function onNewRowPriceEnter() {
  if (isInlineAdjustmentDraft.value) {
    confirmAdjustmentFromNewRow()
    return
  }

  addItem()
}

// ───────────────────────────────────────────────────────────
// ITEM CALCULATIONS
// ───────────────────────────────────────────────────────────
function updateItemTotal(idx) {
  const item = items.value[idx]
  item.total = item.qty * item.unit_price
}

function updateItemPrice(idx, event) {
  const rawValue = event.target.value.replace(/\D/g, '')
  const price = rawValue ? parseInt(rawValue) : 0
  items.value[idx].unit_price = price
  updateItemTotal(idx)
}

function removeItem(idx) {
  items.value.splice(idx, 1)
  nextTick(() => {
    if (items.value.length > 0) {
      const targetIdx = Math.min(idx, items.value.length - 1)
      qtyRefs.value[targetIdx]?.focus()
    } else {
      inputProduct.value?.focus()
    }
  })
}

function requestRemoveItem(idx) {
  const row = items.value[idx]
  deleteConfirmModal.show = true
  deleteConfirmModal.type = 'item'
  deleteConfirmModal.index = idx
  deleteConfirmModal.label = row?.product_nama || row?.product_kode || 'Item barang'
}

function closeDeleteConfirmModal() {
  deleteConfirmModal.show = false
  deleteConfirmModal.type = 'item'
  deleteConfirmModal.index = -1
  deleteConfirmModal.label = ''
}

function confirmDeleteRow() {
  const idx = Number(deleteConfirmModal.index)
  if (idx < 0) {
    closeDeleteConfirmModal()
    return
  }

  if (deleteConfirmModal.type === 'adjustment') {
    removeAdjustment(idx)
  } else {
    removeItem(idx)
  }

  closeDeleteConfirmModal()
}

// ───────────────────────────────────────────────────────────
// PRODUCT SEARCH
// ───────────────────────────────────────────────────────────
async function openProductModal() {
  if (!productSearchArmed.value) return
  if (!newItem.search.trim()) return
  
  const { data } = await supabase
    .from('products')
    .select('*')
    .or(`kode.ilike.%${newItem.search}%,nama.ilike.%${newItem.search}%`)
    .eq('is_archived', false)
    .limit(20)
  
  productModal.results = data || []
  productModal.filtered = productModal.results
  productModal.query = ''
  productModal.selectedIndex = 0
  productModal.show = true
  
  nextTick(() => {
    productModalInput.value?.focus()
  })
}

function filterProductModal() {
  if (!productModal.query) {
    productModal.filtered = productModal.results
  } else {
    const q = productModal.query.toLowerCase()
    productModal.filtered = productModal.results.filter(p => 
      p.kode.toLowerCase().includes(q) || p.nama.toLowerCase().includes(q)
    )
  }
  productModal.selectedIndex = 0
  nextTick(() => ensureProductModalSelectionVisible())
}

function onProductModalKey(e) {
  if (e.defaultPrevented) return

  const isEnter = e.key === 'Enter' || e.code === 'NumpadEnter'

  if (suppressNextProductModalEnter.value && isEnter) {
    e.preventDefault()
    e.stopPropagation()
    suppressNextProductModalEnter.value = false
    return
  }

  if (stockEmptyModal.show) {
    if (isEnter || e.key === 'Escape') {
      e.preventDefault()
      e.stopPropagation()
      closeStockEmptyModal(isEnter ? 'enter' : 'escape')
    }
    return
  }

  if (e.key === 'ArrowDown') {
    e.preventDefault()
    productModal.selectedIndex = Math.min(
      productModal.selectedIndex + 1,
      productModal.filtered.length - 1
    )
    ensureProductModalSelectionVisible()
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    productModal.selectedIndex = Math.max(productModal.selectedIndex - 1, 0)
    ensureProductModalSelectionVisible()
  } else if (e.key === 'PageDown') {
    e.preventDefault()
    productModal.selectedIndex = Math.min(productModal.selectedIndex + 8, productModal.filtered.length - 1)
    ensureProductModalSelectionVisible()
  } else if (e.key === 'PageUp') {
    e.preventDefault()
    productModal.selectedIndex = Math.max(productModal.selectedIndex - 8, 0)
    ensureProductModalSelectionVisible()
  } else if (isEnter) {
    e.preventDefault()
    if (productModal.filtered[productModal.selectedIndex]) {
      selectProduct(productModal.filtered[productModal.selectedIndex])
    }
  } else if (e.key === 'Escape') {
    closeProductModal()
  }
}

function closeProductModal() {
  productModal.show = false
  productSearchArmed.value = true
  focusProductInput()
}

function ensureProductModalSelectionVisible() {
  const container = productModalResultsEl.value
  if (!container) return

  const selected = container.children?.[productModal.selectedIndex]
  if (selected && typeof selected.scrollIntoView === 'function') {
    selected.scrollIntoView({ block: 'nearest' })
  }
}

async function selectProduct(product) {
  if (Number(product?.stok || 0) <= 0) {
    openStockEmptyModal(product?.nama)
    productSearchArmed.value = true
    return
  }

  productModal.show = false
  productSearchArmed.value = false

  try {
    const defaultUnitPrice = await getDefaultPrice(product.id)

    const { data: prices, error } = await supabase
      .from('product_prices')
      .select('id, stok, harga_beli, supplier:suppliers(id, nama)')
      .eq('product_id', product.id)
      .eq('aktif', true)
      .order('updated_at', { ascending: false })

    if (error) throw error

    const activePrices = (prices || []).filter(p => p.supplier)

    if (activePrices.length > 1) {
      supplierModal.product = product
      supplierModal.prices = activePrices.map(p => ({
        id: p.id,
        supplier_id: p.supplier.id,
        supplier_nama: p.supplier.nama,
        stok: p.stok,
        harga_beli: p.harga_beli,
      }))
      supplierModal.defaultUnitPrice = defaultUnitPrice
      supplierModal.selectedIndex = 0
      supplierModal.show = true
      nextTick(() => {
        supplierModalBox.value?.focus?.()
        ensureSupplierModalSelectionVisible()
      })
      return
    }

    fillNewItem(product, defaultUnitPrice)
  } catch (error) {
    console.error('[selectProduct edit]', error)
    const fallbackPrice = await getDefaultPrice(product.id)
    fillNewItem(product, fallbackPrice)
  }
}

function selectSupplierPrice(entry) {
  supplierModal.show = false
  fillNewItem(supplierModal.product, supplierModal.defaultUnitPrice)
}

function onSupplierModalKey(e) {
  if (e.defaultPrevented) return

  if (e.key === 'ArrowDown') {
    e.preventDefault()
    supplierModal.selectedIndex = Math.min(supplierModal.selectedIndex + 1, supplierModal.prices.length - 1)
    ensureSupplierModalSelectionVisible()
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    supplierModal.selectedIndex = Math.max(supplierModal.selectedIndex - 1, 0)
    ensureSupplierModalSelectionVisible()
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (supplierModal.prices[supplierModal.selectedIndex]) {
      selectSupplierPrice(supplierModal.prices[supplierModal.selectedIndex])
    }
  } else if (e.key === 'Escape') {
    supplierModal.show = false
    nextTick(() => {
      productModalInput.value?.focus()
      productModalInput.value?.select?.()
    })
  }
}

function ensureSupplierModalSelectionVisible() {
  const container = supplierModalResultsEl.value
  if (!container) return

  const selectedEl = container.children?.[supplierModal.selectedIndex]
  if (selectedEl && typeof selectedEl.scrollIntoView === 'function') {
    selectedEl.scrollIntoView({ block: 'nearest' })
  }
}

function fillNewItem(product, price) {
  if (!product) return

  newItem.product_id = product.id
  newItem.product_kode = product.kode
  newItem.product_nama = product.nama
  newItem.search = `${product.kode} - ${product.nama}`
  newItem.unit_price = Number(price || 0)
  newItem.stok_available = Number(product.stok || 0)

  nextTick(() => {
    inputQty.value?.focus()
    inputQty.value?.select?.()
  })
}

async function getDefaultPrice(productId) {
  try {
    const customerId = order.value?.customer_id || order.value?.customer?.id
    if (!customerId) return 0

    const { data: customerSales, error: salesError } = await supabase
      .from('sales')
      .select('id')
      .eq('customer_id', customerId)
      .eq('status', 'completed')
      .order('order_date', { ascending: false })
      .limit(200)

    if (salesError) throw salesError

    if (customerSales && customerSales.length > 0) {
      const saleIds = customerSales.map(s => s.id)

      const { data: saleItems, error: saleItemsError } = await supabase
        .from('sale_items')
        .select('unit_price')
        .eq('product_id', productId)
        .in('sale_id', saleIds)
        .order('created_at', { ascending: false })
        .limit(1)

      if (saleItemsError) throw saleItemsError

      if (saleItems && saleItems.length > 0) {
        return Number(saleItems[0].unit_price || 0)
      }
    }

    return 0
  } catch (error) {
    console.error('[getDefaultPrice edit]', error)
    return 0
  }
}

function focusPrice() {
  if (canInputPrice.value) {
    nextTick(() => {
      inputPrice.value?.focus()
    })
  }
}

function formatNewItemPrice(e) {
  const parsed = parseSignedAmountInput(e.target.value)
  e.target.value = parsed.display
  newItem.unit_price = parsed.amount
}

function resetNewItem() {
  newItem.search = ''
  newItem.product_id = null
  newItem.product_kode = ''
  newItem.product_nama = ''
  newItem.qty = 1
  newItem.unit_price = 0
  newItem.total = 0
  newItem.stok_available = 0
  productSearchArmed.value = true
}

function addItem() {
  if (Number(newItem.stok_available || 0) <= 0) {
    openStockEmptyModal(newItem.product_nama)
    return
  }

  if (!newItem.product_id || !newItem.qty || !newItem.unit_price) return
  
  items.value.push({
    id: Date.now(), // temporary id for new items
    product_id: newItem.product_id,
    product_kode: newItem.product_kode,
    product_nama: newItem.product_nama,
    qty: newItem.qty,
    unit_price: newItem.unit_price,
    total: newItem.qty * newItem.unit_price,
    stok_available: newItem.stok_available,
    is_new: true // flag for new items
  })
  
  resetNewItem()
  
  nextTick(() => {
    const lastIdx = items.value.length - 1
    qtyRefs.value[lastIdx]?.focus()
  })
}

// ───────────────────────────────────────────────────────────
// PRICE INFO
// ───────────────────────────────────────────────────────────
async function showPriceInfo(item, returnFocusEl = null) {
  const customerId = order.value?.customer_id || order.value?.customer?.id
  if (!item.product_id || !customerId) return
  
  priceInfoReturnFocusEl.value = returnFocusEl || document.activeElement
  priceInfoModal.show = true
  priceInfoModal.product_id = item.product_id
  priceInfoModal.product_nama = item.product_nama
  priceInfoModal.loading = true
  
  try {
    const { data: customerSales, error: customerSalesError } = await supabase
      .from('sales')
      .select('id, order_date')
      .eq('customer_id', customerId)
      .eq('status', 'completed')
      .order('order_date', { ascending: false })
      .limit(200)

    if (customerSalesError) throw customerSalesError

    const customerSaleIds = (customerSales || []).map(row => row.id)
    const salesDateById = new Map((customerSales || []).map(row => [row.id, row.order_date]))

    let customerSaleItem = null
    if (customerSaleIds.length > 0) {
      const { data: saleItems, error: saleItemsError } = await supabase
        .from('sale_items')
        .select('sale_id, unit_price, qty, created_at')
        .eq('product_id', item.product_id)
        .in('sale_id', customerSaleIds)
        .order('created_at', { ascending: false })
        .limit(1)

      if (saleItemsError) throw saleItemsError
      customerSaleItem = saleItems?.[0] || null
    }

    const { data: latestPrice, error: latestPriceError } = await supabase
      .from('product_prices')
      .select('harga_beli')
      .eq('product_id', item.product_id)
      .eq('aktif', true)
      .order('updated_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (latestPriceError) throw latestPriceError

    let fallbackUnitCost = 0
    if (!latestPrice?.harga_beli) {
      const { data: lastPurchase } = await supabase
        .from('purchase_items')
        .select('unit_cost')
        .eq('product_id', item.product_id)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle()
      fallbackUnitCost = Number(lastPurchase?.unit_cost || 0)
    }
    
    priceInfoModal.data = {
      last_unit_price: Number(customerSaleItem?.unit_price || 0),
      last_unit_cost: Number(latestPrice?.harga_beli || fallbackUnitCost || 0),
      last_sale_qty: Number(customerSaleItem?.qty || 0),
      last_order_date: customerSaleItem?.sale_id ? (salesDateById.get(customerSaleItem.sale_id) || null) : null,
    }
  } catch (error) {
    console.error('Error loading price info:', error)
  } finally {
    priceInfoModal.loading = false
  }
}

function showPriceInfoPreview(returnFocusEl = null) {
  if (!newItem.product_id) {
    alert('Pilih barang terlebih dahulu')
    return
  }

  showPriceInfo({
    product_id: newItem.product_id,
    product_nama: newItem.product_nama,
  }, returnFocusEl)
}

function closePriceInfoModal() {
  priceInfoModal.show = false
  nextTick(() => {
    priceInfoReturnFocusEl.value?.focus?.()
  })
}

function openStockEmptyModal(productName) {
  stockEmptyModal.productName = String(productName || '-').trim() || '-'
  stockEmptyModal.show = true
  nextTick(() => {
    stockEmptyModalBox.value?.focus?.()
  })
}

function closeStockEmptyModal(source = 'manual') {
  if (source === 'enter') {
    suppressNextProductModalEnter.value = true
    setTimeout(() => {
      suppressNextProductModalEnter.value = false
    }, 0)
  }

  stockEmptyModal.show = false
  nextTick(() => {
    if (productModal.show) {
      productModalInput.value?.focus()
      productModalInput.value?.select?.()
      ensureProductModalSelectionVisible()
    } else {
      inputProduct.value?.focus()
      inputProduct.value?.select?.()
    }
  })
}

function onStockEmptyModalKey(e) {
  const isEnter = e.key === 'Enter' || e.code === 'NumpadEnter'
  if (isEnter || e.key === 'Escape') {
    e.preventDefault()
    e.stopPropagation()
    closeStockEmptyModal(isEnter ? 'enter' : 'escape')
  }
}

// ───────────────────────────────────────────────────────────
// SAVE ORDER
// ───────────────────────────────────────────────────────────
async function submitSaleUpdate({ navigateAfterSave = true } = {}) {
  if (saving.value) return false

  console.log('confirmSave called - items.value:', items.value)
  console.log('items.value.length:', items.value.length)
  
  if (items.value.length === 0) {
    alert('Order harus memiliki minimal 1 item')
    return false
  }
  
  saving.value = true
  
  try {
    const oldStatus = order.value.status
    
    // STOCK MANAGEMENT LOGIC
    // If order was 'completed' or 'draft' (draft also deducts stock), restore old stock first
    if ((oldStatus === 'completed' || oldStatus === 'draft') && originalItems.value.length > 0) {
      for (const oldItem of originalItems.value) {
        // Restore stock (add back the old qty) - manual update
        const { data: product, error: getError } = await supabase
          .from('products')
          .select('stok')
          .eq('id', oldItem.product_id)
          .single()
        
        if (getError) throw getError
        
        const { error: updateError } = await supabase
          .from('products')
          .update({ stok: (product.stok || 0) + oldItem.qty })
          .eq('id', oldItem.product_id)
        
        if (updateError) throw updateError
      }
    }
    
    // Now deduct stock for NEW items (always, because status becomes 'completed')
    for (const item of items.value) {
      // Deduct stock - manual update
      const { data: product, error: getError } = await supabase
        .from('products')
        .select('stok')
        .eq('id', item.product_id)
        .single()
      
      if (getError) throw getError
      
      const { error: updateError } = await supabase
        .from('products')
        .update({ stok: Math.max(0, (product.stok || 0) - item.qty) })
        .eq('id', item.product_id)
      
      if (updateError) throw updateError
    }
    
    const extraChargeSnapshot = buildExtraChargeSnapshot()

    // Update order header - set status to 'completed' after edit
    const { error: orderError } = await supabase
      .from('sales')
      .update({
        subtotal: subtotal.value,
        status: 'completed', // Always set to completed after editing
        extra_charge_desc: extraChargeSnapshot.description,
        extra_charge_amount: extraChargeSnapshot.amount,
        sender_note: extraForm.senderName.trim() || null,
      })
      .eq('id', order.value.id)
    
    if (orderError) throw orderError
    
    // Delete all existing items
    await supabase
      .from('sale_items')
      .delete()
      .eq('sale_id', order.value.id)
    
    // Insert all items (existing + new)
    const itemsToInsert = items.value.map(item => ({
      sale_id: order.value.id,
      product_id: item.product_id,
      product_kode: item.product_kode,
      product_nama: item.product_nama,
      qty: item.qty,
      unit_price: item.unit_price,
      total: item.total
    }))
    
    const { error: itemsError } = await supabase
      .from('sale_items')
      .insert(itemsToInsert)
    
    if (itemsError) throw itemsError
    
    if (navigateAfterSave) {
      goToSalesHistoryDetail(order.value?.no_order)
    }

    return true
    
  } catch (error) {
    console.error('Error saving order:', error)
    console.error('Error details:', error.message, error.code, error)
    alert(`Gagal menyimpan perubahan: ${error.message || error}`)
    return false
  } finally {
    saving.value = false
  }
}

function setPrintSortIndex(index) {
  printConfirmModal.sortIndex = index
}

function handlePrintConfirmKeydown(e) {
  if (!printConfirmModal.show) return

  if (e.key === 'Escape') {
    e.preventDefault()
    closePrintConfirmModal()
    return
  }

  if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
    e.preventDefault()
    printConfirmModal.sortIndex = (printConfirmModal.sortIndex + 1) % printSortOptions.length
    return
  }

  if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
    e.preventDefault()
    printConfirmModal.sortIndex = (printConfirmModal.sortIndex - 1 + printSortOptions.length) % printSortOptions.length
    return
  }

  if (e.key === 'Enter') {
    e.preventDefault()
    confirmSaveFromPrintModal()
    return
  }

  if (e.key === 'p' || e.key === 'P') {
    e.preventDefault()
    printFromConfirmModal()
  }
}

function openPrintConfirmModal(payload) {
  printConfirmModal.payload = payload
  printConfirmModal.sortIndex = 0
  printConfirmModal.saleId = payload?.saleId || null
  printConfirmModal.show = true
  nextTick(() => {
    printConfirmModalBox.value?.focus?.()
  })
}

function closePrintConfirmModal() {
  printConfirmModal.show = false
  printConfirmModal.payload = null
  printConfirmModal.saleId = null
  nextTick(() => {
    focusInlineNoteInput()
  })
}

async function goToSalesHistoryDetail(noOrder) {
  const targetNoOrder = String(noOrder || '').trim()
  if (!targetNoOrder) {
    await router.push('/penjualan/list')
    return
  }

  sessionStorage.setItem(
    SALES_HISTORY_DETAIL_KEY,
    JSON.stringify({ noOrder: targetNoOrder, openDetail: true })
  )

  await router.push({
    path: '/penjualan/list',
    query: { no_order: targetNoOrder, open_detail: '1' },
  })
}

function handleBeforeUnload() {
  const currentNoOrder = String(order.value?.no_order || searchQuery.value || '').trim()
  if (!currentNoOrder) return

  sessionStorage.setItem(EDIT_LAST_ORDER_KEY, currentNoOrder)
  sessionStorage.setItem(EDIT_RESTORE_ON_REFRESH_KEY, '1')
}

function buildPrintPayload() {
  return {
    saleId: order.value?.id,
    header: {
      no_order: order.value?.no_order,
      no_faktur: order.value?.no_faktur,
      order_date: order.value?.order_date,
      limit_bulan: Number(order.value?.limit_bulan || 0),
    },
    customer: {
      nama: order.value?.customer?.nama,
      kode: order.value?.customer?.kode,
      alamat: order.value?.customer?.alamat,
    },
    senderNote: extraForm.senderName || '',
    items: normalizeItemsForPrint(items.value),
    adjustmentRows: adjustmentRows.value.slice(),
    subtotal: subtotal.value,
  }
}

async function confirmSaveFromPrintModal() {
  if (saving.value) return
  const payload = printConfirmModal.payload
  const targetNoOrder = payload?.header?.no_order || order.value?.no_order || searchQuery.value
  closePrintConfirmModal()
  const isSaved = await submitSaleUpdate({ navigateAfterSave: false })
  if (!isSaved) return
  await goToSalesHistoryDetail(targetNoOrder)
}

async function printFromConfirmModal() {
  if (saving.value) return
  const payload = printConfirmModal.payload
  if (!payload) {
    closePrintConfirmModal()
    return
  }

  const sortedItems = sortedPrintItems.value
  const printPayload = {
    ...payload,
    items: sortedItems,
  }

  closePrintConfirmModal()
  const isSaved = await submitSaleUpdate({ navigateAfterSave: false })
  if (!isSaved) return

  const html = buildNotaPrintHtml(printPayload, sortedItems)
  const win = window.open('', '_blank', 'width=1200,height=760')
  if (!win) {
    alert('Popup print diblokir browser. Izinkan popup lalu coba lagi.')
    return
  }

  win.document.open()
  win.document.write(html)
  win.document.close()

  win.onload = async () => {
    win.focus()
    win.print()

    sessionStorage.setItem(
      PENJUALAN_FLASH_KEY,
      JSON.stringify({
        severity: 'success',
        summary: 'Tersimpan ke Riwayat',
        detail: `No. Order ${printPayload?.header?.no_order || order.value?.no_order || searchQuery.value || '-'} tersimpan di Riwayat Transaksi.`,
        life: 3200,
      })
    )

    await router.push('/penjualan')
  }
}

function normalizeItemsForPrint(rows) {
  return (rows || []).map(item => ({
    product_id: item.product_id,
    product_kode: item.product_kode,
    product_nama: item.product_nama,
    qty: Number(item.qty || 0),
    unit_price: Number(item.unit_price || 0),
    total: Number(item.total || 0),
  }))
}

function buildExtraChargeSnapshot() {
  const validRows = adjustmentRows.value
    .map(row => ({
      description: normalizeAdjustmentDescription(row.description),
      amount: Number(row.amount || 0),
    }))
    .filter(row => row.description && row.amount !== 0)

  if (!validRows.length) {
    return {
      description: null,
      amount: 0,
    }
  }

  return {
    description: validRows.map(row => row.description).join(' | '),
    amount: validRows.reduce((sum, row) => sum + row.amount, 0),
  }
}

function paymentTermLabel(limitBulan) {
  if (Number(limitBulan) === -1) return 'TUNAI'
  const bulan = Number(limitBulan || 0) + 1
  return `${bulan} BULAN`
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;')
}

function chunkItems(itemsList, size = 15) {
  const chunks = []
  for (let i = 0; i < itemsList.length; i += size) {
    chunks.push(itemsList.slice(i, i + size))
  }
  return chunks.length ? chunks : [[]]
}

function buildNotaPrintHtml(payload, sortedItems) {
  const adjustmentLines = (payload.adjustmentRows || []).map(row => ({
    product_kode: '-',
    product_nama: row.description,
    qty: '-',
    unit_price: row.amount,
    total: row.amount,
  }))

  const allRows = sortedItems.concat(adjustmentLines)
  const pages = chunkItems(allRows, 15)

  const pageHtml = pages.map((pageRows, idx) => {
    const rows = pageRows.map(row => `
      <tr>
        <td>${escapeHtml(row.product_kode || '-')}</td>
        <td>${escapeHtml(row.product_nama || '-')}</td>
        <td class="text-right">${escapeHtml(row.qty)}</td>
        <td class="text-right">${escapeHtml(formatRp(Number(row.unit_price || 0)).replace('Rp ', ''))}</td>
        <td class="text-right">${escapeHtml(formatRp(Number(row.total || 0)).replace('Rp ', ''))}</td>
      </tr>
    `).join('')

    return `
      <section class="nota-page">
        <div class="nota-head">
          <div class="title-left">
            <div class="nama-toko">MAJU MULIA BERSAMA</div>
            <div class="kota">SEMARANG</div>
          </div>
          <div class="title-center">FAKTUR</div>
          <div class="title-right">
            <div>No. Faktur: ${escapeHtml(payload.header.no_faktur || '-')}</div>
            <div>Tanggal: ${escapeHtml(payload.header.order_date || '-')}</div>
            <div>No. Order: ${escapeHtml(payload.header.no_order || '-')}</div>
            <div>Salesmen: -</div>
            <div>Halaman: ${idx + 1}</div>
          </div>
        </div>

        <div class="meta-left">
          <div>Kepada: ${escapeHtml(payload.customer.nama || '-')} (${escapeHtml(payload.customer.kode || '-')})</div>
          <div>${escapeHtml(payload.customer.alamat || '-')}</div>
          <div>Pembayaran: ${escapeHtml(paymentTermLabel(payload.header.limit_bulan))}</div>
        </div>

        <table class="nota-table">
          <thead>
            <tr>
              <th class="col-kode">Kode Barang</th>
              <th class="col-nama">Nama Barang</th>
              <th class="col-qty">Qty</th>
              <th class="col-harga">Harga</th>
              <th class="col-jumlah">Jumlah</th>
            </tr>
          </thead>
          <tbody>
            ${rows}
          </tbody>
        </table>

        <div class="nota-bottom">
          <div class="bottom-left">
            <div>Keterangan: ${escapeHtml(payload.senderNote || '')}</div>
          </div>
          <div class="bottom-sign">
            <div>Dikirim Oleh</div>
            <div class="sign-line"></div>
          </div>
          <div class="bottom-sign">
            <div>Diterima Oleh</div>
            <div class="sign-line"></div>
          </div>
          <div class="subtotal-box">
            <div class="subtotal-label">Subtotal</div>
            <div class="subtotal-val">${escapeHtml(formatRp(payload.subtotal || 0).replace('Rp ', ''))}</div>
          </div>
        </div>
      </section>
    `
  }).join('')

  return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8" />
        <title>Print Nota ${escapeHtml(payload.header.no_order || '')}</title>
        <style>
          @page { size: 23.5cm 14cm; margin: 0; }
          body {
            margin: 0;
            font-family: 'Courier New', Courier, monospace;
            font-size: 12pt;
            font-weight: bold;
            color: black;
          }
          .nota-page {
            width: 23.5cm;
            height: 14cm;
            box-sizing: border-box;
            padding: 0.8cm 0.8cm 0.55cm;
            page-break-after: always;
          }
          .nota-page:last-child { page-break-after: auto; }
          .nota-head {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            align-items: start;
            margin-bottom: 0.35cm;
          }
          .title-center { text-align: center; letter-spacing: 0.22em; }
          .title-right { justify-self: end; text-align: left; font-size: 9.5pt; }
          .nama-toko { letter-spacing: 0.08em; }
          .kota { letter-spacing: 0.32em; font-size: 10pt; }
          .meta-left { margin-bottom: 0.24cm; font-size: 10pt; line-height: 1.25; }
          .nota-table { width: 100%; border-collapse: collapse; font-size: 9.5pt; }
          .nota-table th, .nota-table td { border: 1px solid #000; padding: 0.08cm 0.1cm; }
          .nota-table td { height: 0.42cm; }
          .col-kode { width: 18%; }
          .col-nama { width: 45%; }
          .col-qty { width: 9%; }
          .col-harga { width: 14%; }
          .col-jumlah { width: 14%; }
          .text-right { text-align: right; }
          .nota-bottom {
            margin-top: 0.18cm;
            display: grid;
            grid-template-columns: 1.25fr 0.8fr 0.8fr 0.55fr;
            align-items: end;
            gap: 0.2cm;
          }
          .bottom-left { font-size: 10pt; min-height: 1.1cm; }
          .bottom-sign { text-align: center; font-size: 10pt; }
          .sign-line { border-bottom: 1px solid #000; margin-top: 0.65cm; }
          .subtotal-box {
            border: 1px solid #000;
            min-height: 1.1cm;
            display: flex;
            flex-direction: column;
            justify-content: center;
            text-align: right;
            padding: 0.05cm 0.08cm;
            font-size: 10pt;
          }
          .subtotal-label { font-size: 8.5pt; }
        </style>
      </head>
      <body>${pageHtml}</body>
    </html>
  `
}

// ───────────────────────────────────────────────────────────
// FORMATTING
// ───────────────────────────────────────────────────────────
function formatRp(value) {
  if (!value) return 'Rp 0'
  return `Rp ${value.toLocaleString('id-ID')}`
}

function formatNumber(value) {
  if (!value) return ''
  return value.toLocaleString('id-ID')
}

function formatSignedNumber(value) {
  const n = Number(value || 0)
  if (!n) return ''
  const absVal = Math.abs(n).toLocaleString('id-ID')
  return n < 0 ? `-${absVal}` : absVal
}

function parseSignedAmountInput(raw) {
  const text = String(raw || '').trim()
  const isNegative = text.startsWith('-')
  const digits = text.replace(/\D/g, '')

  if (!digits) {
    return {
      amount: 0,
      display: isNegative ? '-' : '',
    }
  }

  const number = Number(digits)
  const amount = isNegative ? -number : number

  return {
    amount,
    display: formatSignedNumber(amount),
  }
}

function formatDate(dateString) {
  if (!dateString) return '—'
  const date = new Date(dateString)
  const day = String(date.getDate()).padStart(2, '0')
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const year = String(date.getFullYear()).slice(-2)
  return `${day}/${month}/${year}`
}

// ───────────────────────────────────────────────────────────
// LIFECYCLE
// ───────────────────────────────────────────────────────────
onMounted(() => {
  window.addEventListener('keydown', onStockEmptyCaptureKey, true)
  window.addEventListener('keydown', onGlobalKey)
  window.addEventListener('beforeunload', handleBeforeUnload)

  const shouldRestore = sessionStorage.getItem(EDIT_RESTORE_ON_REFRESH_KEY) === '1'
  const persistedOrderNo = String(sessionStorage.getItem(EDIT_LAST_ORDER_KEY) || '').trim()

  // Consume restore marker once so normal menu navigation won't auto-search.
  sessionStorage.removeItem(EDIT_RESTORE_ON_REFRESH_KEY)

  if (shouldRestore && persistedOrderNo) {
    searchQuery.value = persistedOrderNo
    searchOrder()
    return
  }

  // Fresh entry from menu should start empty.
  sessionStorage.removeItem(EDIT_LAST_ORDER_KEY)

  nextTick(() => {
    searchInput.value?.focus()
  })
})

onUnmounted(() => {
  window.removeEventListener('keydown', onStockEmptyCaptureKey, true)
  window.removeEventListener('keydown', onGlobalKey)
  window.removeEventListener('beforeunload', handleBeforeUnload)
})
</script>

<style src="@/assets/components/modal.css"></style>
<style src="@/assets/Styles/penjualan/penjualan-edit-page.css"></style>
