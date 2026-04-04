<template>
  <div class="penjualan-input-page" ref="pageEl" tabindex="-1">

    <!-- ── FORM CARD WITH HEADER ─────────────────────────────────────── -->
    <div class="form-card">
      <div class="form-header">
        <h1 class="form-header-title">Input Item Penjualan</h1>
        <p class="form-header-subtitle">Tahap 2: Tambahkan item yang akan dijual</p>
      </div>

      <!-- Order Info Card -->
      <div class="order-info-section">
        <div v-if="orderData.customer" class="order-info-card">
          <div class="info-row">
            <div class="info-col">
              <label>No. Order:</label>
              <strong class="order-number-preview">
                {{ orderData.no_order || generatePreviewOrderNumber() }}
              </strong>
            </div>
            <div class="info-col">
              <label>No. Fraktur:</label>
              <strong>{{ orderData.no_faktur || 'Auto saat simpan final' }}</strong>
            </div>
            <div class="info-col">
              <label>Tanggal:</label>
              <strong>{{ orderData.order_date }}</strong>
            </div>
            <div class="info-col">
              <label>Pengiriman:</label>
              <strong>{{ orderData.diantar ? 'Diantar' : 'Diambil' }}</strong>
            </div>
            <div class="info-col">
              <label>Tempo:</label>
              <strong>{{ paymentTermLabel(orderData.limit_bulan) }}</strong>
            </div>
          </div>
          <div class="info-row info-customer">
            <div class="info-col-full">
              <label>Customer:</label>
              <strong>{{ orderData.customer.nama }}</strong>
              <span class="customer-details">
                {{ orderData.customer.alamat || 'Alamat tidak tersedia' }}
                <span v-if="orderData.customer.no_telp"> · {{ orderData.customer.no_telp }}</span>
              </span>
            </div>
          </div>
        </div>
        <div v-else class="order-info-card">
          <div class="loading-state">
            <i class="pi pi-spin pi-spinner"></i>
            <p>Memuat data order...</p>
          </div>
        </div>
      </div>
    </div>

    <!-- ── ITEMS TABLE ──────────────────────────────────── -->
    <div class="items-section">
      <!-- Shortcut Hints -->
      <div class="shortcuts-bar">
        <kbd>F1 Lain-Lain</kbd>
        <kbd>F2 Barang</kbd>
        <kbd>F10 Keterangan</kbd>
        <kbd>F4 Info</kbd>
      </div>

      <div class="table-card">
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
                <th class="col-qty">Qty</th>
                <th class="col-price">Harga Satuan</th>
                <th class="col-total">Total</th>
                <th class="col-action">Aksi</th>
              </tr>
            </thead>
            <tbody>
              <!-- Existing Items -->
              <tr 
                v-for="(item, idx) in items" 
                :key="idx"
                class="item-row"
                :class="{ 'item-row--warning': item.stok_warning }"
              >
                <td class="col-no">{{ idx + 1 }}</td>
                <td class="col-kode">
                  <span class="item-kode">{{ item.product_kode }}</span>
                </td>
                <td class="col-nama">
                  <div class="item-info">
                    <span class="item-nama">{{ item.product_nama }}</span>
                    <span v-if="item.stok_warning" class="stock-warning">
                      <i class="pi pi-exclamation-triangle"></i>
                      Stok: {{ item.stok_available }}
                    </span>
                  </div>
                </td>
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
                    @click="removeItem(idx)"
                    title="Hapus item (Del)"
                  >
                    <i class="pi pi-trash"></i>
                  </button>
                </td>
              </tr>

              <!-- Adjustment Rows (Diskon/Biaya/Pengiriman) -->
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
                    />
                  </div>
                </td>
                <td class="col-total">
                  <span class="total-val">{{ formatRp(adj.amount) }}</span>
                </td>
                <td class="col-action">
                  <div class="adjustment-actions">
                    <button
                      class="btn-icon"
                      @click="moveAdjustmentUp(adjIdx)"
                      title="Pindah ke atas"
                      :disabled="adjIdx === 0"
                    >
                      <i class="pi pi-arrow-up"></i>
                    </button>
                    <button
                      class="btn-icon"
                      @click="moveAdjustmentDown(adjIdx)"
                      title="Pindah ke bawah"
                      :disabled="adjIdx === adjustmentRows.length - 1"
                    >
                      <i class="pi pi-arrow-down"></i>
                    </button>
                    <button class="btn-icon btn-delete" @click="removeAdjustment(adjIdx)" title="Hapus penyesuaian">
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

              <!-- Empty State -->
              <tr v-if="items.length === 0 && adjustmentRows.length === 0 && !newItem.product_id && !newItem.search.trim()" class="empty-row">
                <td colspan="8" class="empty-cell">
                  <i class="pi pi-inbox"></i>
                  <p>Belum ada barang. Mulai ketik nama barang di atas.</p>
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
            @keydown.enter.prevent="submitFromInlineNote"
          />
        </div>

        <!-- Subtotal -->
        <div class="table-footer">
          <div class="subtotal-row">
            <span class="subtotal-label">Subtotal:</span>
            <span class="subtotal-value">{{ formatRp(subtotal) }}</span>
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
            <div class="modal-header modal-header--blue">
              <i class="pi pi-info-circle"></i>
              <h3 class="modal-title">Info Harga</h3>
              <button class="modal-close" @click="closePriceInfoModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <p class="price-info-product-name"><strong>{{ priceInfoModal.product_nama }}</strong></p>
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
                Tutup <kbd>Esc</kbd>
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
                Pilih urutan item, lalu pilih aksi: Simpan sebagai Draft (Enter) atau Print (P).
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
              <button class="btn-secondary" @click="confirmSaveFromPrintModal">Simpan Draft (Enter)</button>
              <button class="btn-primary" @click="printFromConfirmModal">Print (P)</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════════
         MODAL KONFIRMASI LIMIT KREDIT
    ═══════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="creditLimitConfirmModal.show" class="modal-overlay" @click.self="closeCreditLimitConfirmModal">
          <div class="modal-box modal-box--sm" role="dialog" aria-modal="true" aria-label="Konfirmasi limit kredit">
            <div class="modal-header modal-header--danger">
              <i class="pi pi-exclamation-triangle"></i>
              <h3 class="modal-title">Peringatan Limit Kredit</h3>
              <button class="modal-close" @click="closeCreditLimitConfirmModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <p class="confirm-text">Total order melebihi sisa limit kredit customer.</p>
              <p class="confirm-subtext">Customer: <strong>{{ creditLimitConfirmModal.customerName }}</strong></p>
              <div class="credit-summary-grid">
                <div class="credit-summary-item">
                  <span class="credit-summary-label">Limit Kredit</span>
                  <strong class="credit-summary-value">{{ formatRp(creditLimitConfirmModal.limitKredit) }}</strong>
                </div>
                <div class="credit-summary-item">
                  <span class="credit-summary-label">Saldo Piutang</span>
                  <strong class="credit-summary-value">{{ formatRp(creditLimitConfirmModal.saldoPiutang) }}</strong>
                </div>
                <div class="credit-summary-item" :class="{ 'credit-summary-item--danger': creditLimitConfirmModal.remainingCredit < 0 }">
                  <span class="credit-summary-label">Sisa Limit</span>
                  <strong class="credit-summary-value">{{ formatRp(creditLimitConfirmModal.remainingCredit) }}</strong>
                </div>
                <div class="credit-summary-item">
                  <span class="credit-summary-label">Total Order</span>
                  <strong class="credit-summary-value">{{ formatRp(creditLimitConfirmModal.totalOrder) }}</strong>
                </div>
              </div>
              <p class="confirm-subtext confirm-subtext--danger">
                Total Limit: {{ formatRp(creditLimitConfirmModal.totalLimit) }}
              </p>
              <p class="confirm-subtext">Tekan <strong>Y</strong> untuk tetap lanjut, atau <strong>N</strong> untuk batal.</p>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="closeCreditLimitConfirmModal">
                Batal <kbd>N</kbd>
              </button>
              <button class="btn-primary" @click="confirmCreditLimitAndSubmit" :disabled="saving">
                Tetap Lanjutkan <kbd>Y</kbd>
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════════
         MODAL STOK KOSONG
    ═══════════════════════════════════════════════════════ -->
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
              <button class="btn-primary" @click="closeStockEmptyModal">Batal &amp; Cari Lagi <kbd>Enter</kbd></button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ═══════════════════════════════════════════════════════
         MODAL KONFIRMASI KELUAR
    ═══════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="exitConfirmModal.show" class="modal-overlay" @click.self="closeExitConfirmModal">
          <div class="modal-box modal-box--sm" role="dialog">
            <div class="modal-header">
              <i class="pi pi-exclamation-triangle"></i>
              <h3 class="modal-title">Keluar Dari Input?</h3>
              <button class="modal-close" @click="closeExitConfirmModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <p>Data yang sudah diinput akan disimpan sebagai draft. Lanjut keluar?</p>
            </div>
            <div class="modal-footer">
              <button class="btn-secondary" @click="closeExitConfirmModal">Batal (Esc)</button>
              <button class="btn-primary" @click="confirmExitAndSaveDraft">Ya, Simpan Draft (Y)</button>
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

const router = useRouter()

// ───────────────────────────────────────────────────────────
// REFS
// ───────────────────────────────────────────────────────────
const pageEl = ref(null)
const inputProduct = ref(null)
const inputQty = ref(null)
const inputPrice = ref(null)
const productModalInput = ref(null)
const productModalResultsEl = ref(null)
const supplierModalResultsEl = ref(null)
const supplierModalBox = ref(null)
const newItemRow = ref(null)
const senderInlineInput = ref(null)
const priceInfoReturnFocusEl = ref(null)
const printConfirmModalBox = ref(null)
const stockEmptyModalBox = ref(null)
const suppressNextProductModalEnter = ref(false)

// ───────────────────────────────────────────────────────────
// STATE
// ───────────────────────────────────────────────────────────
const orderData = ref({})
const items = ref([])
const saving = ref(false)
const escPressCount = ref(0)
const escTimer = ref(null)
const qtyRefs = ref({})
const priceRefs = ref({})

const newItem = reactive({
  search: '',
  product_id: null,
  product_kode: '',
  product_nama: '',
  qty: 1,
  unit_price: 0,
  stok_available: 0,
})

const productModal = reactive({
  show: false,
  results: [],
  filtered: [],
  query: '',
  selectedIndex: 0,
})

const priceInfoModal = reactive({
  show: false,
  product_nama: '',
  loading: false,
  data: {
    last_unit_price: 0,
    last_unit_cost: 0,
    last_sale_qty: 0,
    last_order_date: null,
  }
})

const supplierModal = reactive({
  show: false,
  product: null,
  prices: [],        // [{ id, supplier_id, supplier_nama, stok, harga_beli }]
  selectedIndex: 0,
  defaultUnitPrice: 0,
})

const printConfirmModal = reactive({
  show: false,
  sortIndex: 0,
  saleId: null,
  payload: null,
})

const exitConfirmModal = reactive({
  show: false,
})

const creditLimitConfirmModal = reactive({
  show: false,
  shouldPrint: false,
  customerName: '',
  limitKredit: 0,
  saldoPiutang: 0,
  remainingCredit: 0,
  totalOrder: 0,
  totalLimit: 0,
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

const SALES_HISTORY_DETAIL_KEY = 'penjualan_list_open_no_order'
const PENJUALAN_FLASH_KEY = 'penjualan_flash_notice'

const productSearchArmed = ref(true)
const adjustmentRows = ref([])
const WORKING_STATE_KEY = 'penjualan_input_working_state'
const senderNoteAutofilled = ref(false)

const extraForm = reactive({
  senderName: '',
})

// ───────────────────────────────────────────────────────────
// COMPUTED
// ───────────────────────────────────────────────────────────
const subtotal = computed(() => {
  return items.value.reduce((sum, item) => sum + item.total, 0) + adjustmentTotal.value
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
// LIFECYCLE
// ───────────────────────────────────────────────────────────
onMounted(() => {
  // Load order data from session
  const savedData = sessionStorage.getItem('penjualan_draft')
  if (!savedData) {
    alert('Data order tidak ditemukan. Kembali ke step 1.')
    router.push('/penjualan')
    return
  }

  orderData.value = JSON.parse(savedData)

  const existingExtraDesc = String(orderData.value.extra_charge_desc || '').trim()
  const existingExtraAmount = Number(orderData.value.extra_charge_amount || 0)
  if (existingExtraDesc || existingExtraAmount) {
    adjustmentRows.value = [{
      id: `adj-${Date.now()}`,
      description: existingExtraDesc || 'Penyesuaian',
      amount: existingExtraAmount,
    }]
  }

  extraForm.senderName = orderData.value.sender_note || ''

  restoreWorkingState()
  
  window.addEventListener('keydown', onStockEmptyCaptureKey, true)
  window.addEventListener('keydown', onGlobalKey)
  window.addEventListener('beforeunload', handleBeforeUnload)
  pageEl.value?.focus()
  nextTick(() => inputProduct.value?.focus())
})

onUnmounted(() => {
  window.removeEventListener('keydown', onStockEmptyCaptureKey, true)
  window.removeEventListener('keydown', onGlobalKey)
  window.removeEventListener('beforeunload', handleBeforeUnload)
})

watch(
  () => ({
    items: items.value,
    adjustmentRows: adjustmentRows.value,
    senderName: extraForm.senderName,
    productSearchArmed: productSearchArmed.value,
    newItem: {
      search: newItem.search,
      product_id: newItem.product_id,
      product_kode: newItem.product_kode,
      product_nama: newItem.product_nama,
      qty: newItem.qty,
      unit_price: newItem.unit_price,
      stok_available: newItem.stok_available,
    },
  }),
  () => {
    persistWorkingState()
  },
  { deep: true }
)

// ───────────────────────────────────────────────────────────
// KEYBOARD SHORTCUTS
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

  if (creditLimitConfirmModal.show) {
    if (e.key === 'Escape' || e.key === 'n' || e.key === 'N') {
      e.preventDefault()
      closeCreditLimitConfirmModal()
      return
    }

    if (e.key === 'Enter' || e.key === 'y' || e.key === 'Y') {
      e.preventDefault()
      confirmCreditLimitAndSubmit()
      return
    }

    return
  }

  if (exitConfirmModal.show) {
    if (e.key === 'Escape') {
      e.preventDefault()
      closeExitConfirmModal()
      return
    }

    if (e.key === 'y' || e.key === 'Y') {
      e.preventDefault()
      confirmExitAndSaveDraft()
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

  if (supplierModal.show) return

  // Esc: show confirm modal for save draft and exit
  if (e.key === 'Escape') {
    e.preventDefault()
    openExitConfirmModal()
    return
  }

  // Reset esc counter on any other key
  escPressCount.value = 0
  if (escTimer.value) {
    clearTimeout(escTimer.value)
  }

  // F10: focus inline note field
  if (e.key === 'F10') {
    e.preventDefault()
    focusInlineNoteInput()
    return
  }

  // F1: switch to adjustment mode
  if (e.key === 'F1') {
    e.preventDefault()
    productSearchArmed.value = false
    focusProductInput()
    return
  }

  // F2: active product search mode
  if (e.key === 'F2') {
    e.preventDefault()
    activateProductSearchMode()
    return
  }

  // Ctrl+S: Save
  if (e.ctrlKey && e.key === 's') {
    e.preventDefault()
    if ((items.value.length > 0 || adjustmentRows.value.length > 0) && !saving.value) {
      submitSale(true)
    }
    return
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

function focusProductInput() {
  nextTick(() => inputProduct.value?.focus())
}

function focusInlineNoteInput() {
  const isPickup = orderData.value?.diantar === false
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
  await submitSale(true)
}

function setPrintSortIndex(index) {
  printConfirmModal.sortIndex = index
}

function handlePrintConfirmKeydown(e) {
  if (!printConfirmModal.show) return

  if (e.key === 'Escape') {
    e.preventDefault()
    e.stopPropagation()
    closePrintConfirmModal()
    return
  }

  if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
    e.preventDefault()
    e.stopPropagation()
    const next = (printConfirmModal.sortIndex + 1) % printSortOptions.length
    printConfirmModal.sortIndex = next
    return
  }

  if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
    e.preventDefault()
    e.stopPropagation()
    const prev = (printConfirmModal.sortIndex - 1 + printSortOptions.length) % printSortOptions.length
    printConfirmModal.sortIndex = prev
    return
  }

  if (e.key === 'Enter') {
    e.preventDefault()
    e.stopPropagation()
    confirmSaveFromPrintModal()
    return
  }

  if (e.key === 'p' || e.key === 'P') {
    e.preventDefault()
    e.stopPropagation()
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

function goToSalesHistoryDetail(noOrder) {
  const targetNoOrder = String(noOrder || '').trim()
  if (!targetNoOrder) {
    router.push('/penjualan/list')
    return
  }

  sessionStorage.setItem(
    SALES_HISTORY_DETAIL_KEY,
    JSON.stringify({ noOrder: targetNoOrder, openDetail: true })
  )

  router.push({
    path: '/penjualan/list',
    query: { no_order: targetNoOrder, open_detail: '1' },
  })
}

function openExitConfirmModal() {
  exitConfirmModal.show = true
}

function closeExitConfirmModal() {
  exitConfirmModal.show = false
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

function openCreditLimitConfirmModal({ customer, remainingCredit, totalOrder, shouldPrint }) {
  const saldoPiutang = Number(customer.saldo_piutang || 0)
  const totalOrderNumber = Number(totalOrder || 0)
  creditLimitConfirmModal.customerName = customer.nama || '-'
  creditLimitConfirmModal.limitKredit = Number(customer.limit_kredit || 0)
  creditLimitConfirmModal.saldoPiutang = saldoPiutang
  creditLimitConfirmModal.remainingCredit = Number(remainingCredit || 0)
  creditLimitConfirmModal.totalOrder = totalOrderNumber
  creditLimitConfirmModal.totalLimit = saldoPiutang + totalOrderNumber
  creditLimitConfirmModal.shouldPrint = Boolean(shouldPrint)
  creditLimitConfirmModal.show = true
}

function closeCreditLimitConfirmModal() {
  creditLimitConfirmModal.show = false
}

async function confirmCreditLimitAndSubmit() {
  if (saving.value) return
  const shouldPrint = Boolean(creditLimitConfirmModal.shouldPrint)
  closeCreditLimitConfirmModal()
  await submitSale(shouldPrint, true)
}

async function confirmExitAndSaveDraft() {
  if (saving.value) return

  const isSaved = await saveAsDraft()
  if (!isSaved) {
    alert('Gagal menyimpan draft. Coba lagi.')
    return
  }

  sessionStorage.setItem(
    PENJUALAN_FLASH_KEY,
    JSON.stringify({
      severity: 'success',
      summary: 'Draft Tersimpan',
      detail: `No. Order ${orderData.value?.no_order || '-'} disimpan sebagai draft.`,
      life: 3200,
    })
  )

  clearWorkingState()
  exitConfirmModal.show = false
  router.push('/penjualan')
}

function handleBeforeUnload() {
  persistWorkingState()
}

function persistWorkingState() {
  if (!orderData.value?.sale_id) return

  const snapshot = {
    sale_id: orderData.value.sale_id,
    items: items.value,
    adjustmentRows: adjustmentRows.value,
    senderName: extraForm.senderName,
    productSearchArmed: productSearchArmed.value,
    newItem: {
      search: newItem.search,
      product_id: newItem.product_id,
      product_kode: newItem.product_kode,
      product_nama: newItem.product_nama,
      qty: newItem.qty,
      unit_price: newItem.unit_price,
      stok_available: newItem.stok_available,
    },
  }

  sessionStorage.setItem(WORKING_STATE_KEY, JSON.stringify(snapshot))
}

function restoreWorkingState() {
  const raw = sessionStorage.getItem(WORKING_STATE_KEY)
  if (!raw) return

  try {
    const parsed = JSON.parse(raw)
    if (!parsed || parsed.sale_id !== orderData.value.sale_id) return

    items.value = Array.isArray(parsed.items) ? parsed.items : []
    adjustmentRows.value = Array.isArray(parsed.adjustmentRows) ? parsed.adjustmentRows : []
    extraForm.senderName = parsed.senderName || ''
    productSearchArmed.value = Boolean(parsed.productSearchArmed)

    if (parsed.newItem) {
      newItem.search = parsed.newItem.search || ''
      newItem.product_id = parsed.newItem.product_id || null
      newItem.product_kode = parsed.newItem.product_kode || ''
      newItem.product_nama = parsed.newItem.product_nama || ''
      newItem.qty = Number(parsed.newItem.qty || 1)
      newItem.unit_price = Number(parsed.newItem.unit_price || 0)
      newItem.stok_available = Number(parsed.newItem.stok_available || 0)
    }
  } catch (err) {
    console.error('[restoreWorkingState]', err)
  }
}

function clearWorkingState() {
  sessionStorage.removeItem(WORKING_STATE_KEY)
}

async function confirmSaveFromPrintModal() {
  if (saving.value) return
  const payload = printConfirmModal.payload
  closePrintConfirmModal()

  const isSaved = await saveAsDraft()
  if (!isSaved) {
    alert('Gagal menyimpan draft. Coba lagi.')
    return
  }

  clearWorkingState()
  sessionStorage.removeItem('penjualan_draft')
  sessionStorage.setItem(
    PENJUALAN_FLASH_KEY,
    JSON.stringify({
      severity: 'success',
      summary: 'Draft Tersimpan',
      detail: `No. Order ${payload?.header?.no_order || orderData.value?.no_order || '-'} disimpan sebagai draft.`,
      life: 3200,
    })
  )

  router.push('/penjualan')
}

function printFromConfirmModal() {
  const payload = printConfirmModal.payload
  if (!payload) {
    closePrintConfirmModal()
    return
  }

  const sortedItems = sortedPrintItems.value
  const html = buildNotaPrintHtml(payload, sortedItems)
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
        detail: `No. Order ${payload?.header?.no_order || orderData.value?.no_order || '-'} tersimpan di Riwayat Transaksi.`,
        life: 3200,
      })
    )

    await router.push('/penjualan')
  }

  closePrintConfirmModal()
}

function activateProductSearchMode() {
  productSearchArmed.value = true
  nextTick(() => {
    inputProduct.value?.focus()
    inputProduct.value?.select?.()
  })
}

function closeProductModal() {
  productModal.show = false
  productSearchArmed.value = true
  focusProductInput()
}

function confirmAdjustmentFromNewRow() {
  const description = newItem.search.trim()
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

// ───────────────────────────────────────────────────────────
// TABLE REFS & NAVIGATION
// ───────────────────────────────────────────────────────────
function setQtyRef(el, idx) {
  if (el) qtyRefs.value[idx] = el
}

function setPriceRef(el, idx) {
  if (el) priceRefs.value[idx] = el
}

function handleNewItemKeydown(e, field) {
  // Backspace - go back to last item when field is empty
  if (e.key === 'Backspace' && !e.target.value) {
    e.preventDefault()
    const lastIdx = items.value.length - 1
    if (lastIdx >= 0) {
      if (field === 'product') {
        // From product search, go to price of last item
        priceRefs.value[lastIdx]?.focus()
      } else if (field === 'qty') {
        // From qty, go to qty of last item
        qtyRefs.value[lastIdx]?.focus()
      } else if (field === 'price') {
        // From price, go to price of last item
        priceRefs.value[lastIdx]?.focus()
      }
    }
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

  // F4 - Show price info (only in price field)
  if (e.key === 'F4' && field === 'price') {
    e.preventDefault()
    showPriceInfoPreview(e.target)
    return
  }

  // Arrow Right - move to next field in new item row
  if (e.key === 'ArrowRight') {
    if (field === 'product') {
      e.preventDefault()
      if (newItem.product_id) {
        inputQty.value?.focus()
      } else if (isInlineAdjustmentDraft.value) {
        inputPrice.value?.focus()
      }
      return
    }

    if (field === 'qty' && (e.ctrlKey || e.target.selectionStart === e.target.value.length)) {
      e.preventDefault()
      inputPrice.value?.focus()
      return
    }
  }

  // Arrow Left - move to previous field in new item row
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

  // Arrow Down - move to next form in new row
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    if (field === 'product') {
      if (newItem.product_id) {
        inputQty.value?.focus()
      } else if (isInlineAdjustmentDraft.value) {
        inputPrice.value?.focus()
      }
    } else if (field === 'qty') {
      inputPrice.value?.focus()
    }
    return
  }
}

function handleTableKeydown(e, rowIdx, field) {
  const totalRows = items.value.length

  // Delete or Backspace - delete row
  if ((e.key === 'Delete' || e.key === 'Backspace') && e.target.value === '') {
    e.preventDefault()
    removeItem(rowIdx)
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
      // Move from price to new item input
      inputProduct.value?.focus()
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

  // Arrow Left - move from price to qty in same row
  if (e.key === 'ArrowLeft' && field === 'price') {
    // With Ctrl: always move
    // Without Ctrl: only move when cursor at start
    if (e.ctrlKey || e.target.selectionStart === 0) {
      e.preventDefault()
      qtyRefs.value[rowIdx]?.focus()
      return
    }
  }

  // Arrow Right - move from qty to price in same row
  if (e.key === 'ArrowRight' && field === 'qty') {
    // With Ctrl: always move
    // Without Ctrl: only move when cursor at end
    if (e.ctrlKey || e.target.selectionStart === e.target.value.length) {
      e.preventDefault()
      priceRefs.value[rowIdx]?.focus()
      return
    }
  }
}

// ───────────────────────────────────────────────────────────
// PRODUCT SEARCH
// ───────────────────────────────────────────────────────────
async function openProductModal() {
  if (!productSearchArmed.value) return

  const q = newItem.search.trim()
  if (!q) {
    alert('Ketik nama barang terlebih dahulu')
    return
  }

  try {
    const qLoose = normalizeLooseSearch(q)
    const tokens = qLoose.split(' ').filter(Boolean)
    const tokenConditions = (tokens.length ? tokens : [normalizeSearch(q)])
      .filter(Boolean)
      .flatMap(t => [`nama.ilike.%${t}%`, `kode.ilike.%${t}%`])

    let query = supabase
      .from('products')
      .select('*')
      .eq('is_archived', false)
      .order('nama')
      .limit(500)

    if (tokenConditions.length) {
      query = query.or(tokenConditions.join(','))
    }

    const { data, error } = await query

    if (error) throw error

    const ranked = rankProductsByQuery(data || [], q)
    productModal.results = ranked
    productModal.filtered = ranked
    productModal.query = ''
    productModal.selectedIndex = 0
    productModal.show = true

    await nextTick()
    productModalInput.value?.focus()
  } catch (err) {
    console.error('[openProductModal]', err)
    alert('Gagal mencari barang: ' + err.message)
  }
}

function filterProductModal() {
  const q = productModal.query
  productModal.filtered = q ? rankProductsByQuery(productModal.results, q) : productModal.results
  productModal.selectedIndex = 0
  nextTick(() => ensureProductModalSelectionVisible())
}

function rankProductsByQuery(rows, query) {
  const q = normalizeSearch(query)
  if (!q) return rows

  const qLoose = normalizeLooseSearch(q)
  const qTokens = qLoose.split(' ').filter(Boolean)
  const matches = []

  rows.forEach((row, idx) => {
    const namaRaw = normalizeSearch(row.nama)
    const namaLoose = normalizeLooseSearch(row.nama)
    const allRaw = normalizeSearch(`${row.kode || ''} ${row.nama || ''}`)
    const allLoose = normalizeLooseSearch(`${row.kode || ''} ${row.nama || ''}`)

    const namaStartsWith = namaRaw.startsWith(q) || namaLoose.startsWith(qLoose)
    const allStartsWith = allRaw.startsWith(q) || allLoose.startsWith(qLoose)
    const namaContains = namaRaw.includes(q) || namaLoose.includes(qLoose)
    const allContains = allRaw.includes(q) || allLoose.includes(qLoose)
    const namaTokenMatch = qTokens.length > 0 && qTokens.every(t => namaLoose.includes(t))
    const allTokenMatch = qTokens.length > 0 && qTokens.every(t => allLoose.includes(t))

    let rank = -1
    if (namaStartsWith) rank = 0
    else if (allStartsWith) rank = 1
    else if (namaContains) rank = 2
    else if (allContains) rank = 3
    else if (namaTokenMatch) rank = 4
    else if (allTokenMatch) rank = 5

    if (rank === -1) return

    const namaPos = qLoose ? namaLoose.indexOf(qLoose) : -1
    const allPos = qLoose ? allLoose.indexOf(qLoose) : -1
    const phrasePos = namaPos >= 0 ? namaPos : (allPos >= 0 ? allPos : Number.MAX_SAFE_INTEGER)

    matches.push({ row, rank, phrasePos, idx, namaLoose })
  })

  matches.sort((a, b) => {
    if (a.rank !== b.rank) return a.rank - b.rank
    if (a.phrasePos !== b.phrasePos) return a.phrasePos - b.phrasePos
    const namaCompare = a.namaLoose.localeCompare(b.namaLoose)
    if (namaCompare !== 0) return namaCompare
    return a.idx - b.idx
  })

  return matches.map(m => m.row)
}

function normalizeSearch(value) {
  return String(value ?? '')
    .toLowerCase()
    .normalize('NFKC')
    .trim()
}

function normalizeLooseSearch(value) {
  return normalizeSearch(value)
    .replace(/[^a-z0-9]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
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
    productModal.selectedIndex = Math.min(productModal.selectedIndex + 1, productModal.filtered.length - 1)
    ensureProductModalSelectionVisible()
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    productModal.selectedIndex = Math.max(productModal.selectedIndex - 1, 0)
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

function ensureProductModalSelectionVisible() {
  const container = productModalResultsEl.value
  if (!container) return

  const selectedEl = container.children?.[productModal.selectedIndex]
  if (selectedEl && typeof selectedEl.scrollIntoView === 'function') {
    selectedEl.scrollIntoView({ block: 'nearest' })
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

    // Check how many active suppliers this product has
    const { data: prices, error } = await supabase
      .from('product_prices')
      .select('id, stok, harga_beli, supplier:suppliers(id, nama)')
      .eq('product_id', product.id)
      .eq('aktif', true)
      .order('updated_at', { ascending: false })

    if (error) throw error

    const activePrices = (prices || []).filter(p => p.supplier)

    if (activePrices.length > 1) {
      // Multiple suppliers — show selection modal
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

    // Single/no supplier tetap default ke histori harga customer (jika tidak ada maka 0).
    fillNewItem(product, defaultUnitPrice)
  } catch (err) {
    console.error('[selectProduct]', err)
    const price = await getDefaultPrice(product.id)
    fillNewItem(product, price)
  }
}

function selectSupplierPrice(entry) {
  supplierModal.show = false
  fillNewItem(supplierModal.product, supplierModal.defaultUnitPrice)
}

function onSupplierModalKey(e) {
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
  newItem.product_id = product.id
  newItem.product_kode = product.kode
  newItem.product_nama = product.nama
  newItem.unit_price = price
  newItem.stok_available = product.stok
  newItem.search = product.nama

  nextTick(() => {
    inputQty.value?.focus()
    inputQty.value?.select()
  })
}

async function getDefaultPrice(productId) {
  try {
    const customerId = orderData.value.customer.id

    // Default harga satuan: last unit price customer ini untuk item yang sama.
    const { data: customerSales, error: error1 } = await supabase
      .from('sales')
      .select('id')
      .eq('customer_id', customerId)
      .eq('status', 'completed')
      .order('order_date', { ascending: false })
      .limit(200)

    if (error1) throw error1

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
        return saleItems[0].unit_price
      }
    }
    // Jika customer belum pernah beli item ini, default 0.
    return 0
  } catch (err) {
    console.error('[getDefaultPrice]', err)
    return 0
  }
}

// ───────────────────────────────────────────────────────────
// ITEM MANAGEMENT
// ───────────────────────────────────────────────────────────
function addItem() {
  if (!newItem.product_id) {
    alert('Pilih barang terlebih dahulu')
    return
  }

  if (Number(newItem.stok_available || 0) <= 0) {
    openStockEmptyModal(newItem.product_nama)
    return
  }

  if (!newItem.qty || newItem.qty <= 0) {
    alert('Qty harus lebih dari 0')
    inputQty.value?.focus()
    return
  }

  if (!newItem.unit_price || newItem.unit_price < 0) {
    alert('Harga satuan tidak valid')
    inputPrice.value?.focus()
    return
  }

  // Parse price if it's still formatted string
  const unitPrice = typeof newItem.unit_price === 'string' 
    ? parseFormattedNumber(newItem.unit_price) 
    : newItem.unit_price

  // Check stock warning
  if (newItem.qty > newItem.stok_available) {
    const confirm = window.confirm(
      `Stok tidak cukup!\n\n` +
      `Barang: ${newItem.product_nama}\n` +
      `Stok tersedia: ${newItem.stok_available}\n` +
      `Qty yang diminta: ${newItem.qty}\n\n` +
      `Tetap lanjutkan?`
    )
    if (!confirm) {
      inputQty.value?.focus()
      return
    }
  }

  // Add to items
  items.value.push({
    product_id: newItem.product_id,
    product_kode: newItem.product_kode,
    product_nama: newItem.product_nama,
    qty: newItem.qty,
    unit_price: unitPrice,
    total: newItem.qty * unitPrice,
    stok_available: newItem.stok_available,
    stok_warning: newItem.qty > newItem.stok_available,
  })

  // Reset new item
  resetNewItem()
  inputProduct.value?.focus()
}

function resetNewItem() {
  newItem.search = ''
  newItem.product_id = null
  newItem.product_kode = ''
  newItem.product_nama = ''
  newItem.qty = 1
  newItem.unit_price = 0
  newItem.stok_available = 0
  productSearchArmed.value = true
}

function removeItem(index) {
  const item = items.value[index]
  const confirm = window.confirm(`Hapus ${item.product_nama}?`)
  if (confirm) {
    items.value.splice(index, 1)
  }
}

function updateItemTotal(index) {
  const item = items.value[index]
  // Parse formatted price back to number
  const price = typeof item.unit_price === 'string' 
    ? parseFormattedNumber(item.unit_price) 
    : item.unit_price
  item.unit_price = price
  item.total = item.qty * price
  
  // Check stock warning
  item.stok_warning = item.qty > item.stok_available
}

function updateItemPrice(index, event) {
  const item = items.value[index]
  const rawValue = event.target.value.replace(/\./g, '')
  const numValue = parseInt(rawValue) || 0
  
  // Format with thousand separator
  event.target.value = formatNumber(numValue)
  item.unit_price = numValue
  item.total = item.qty * numValue
  
  // Check stock warning
  item.stok_warning = item.qty > item.stok_available
}

function formatNewItemPrice(event) {
  const parsed = parseSignedAmountInput(event.target.value)
  event.target.value = parsed.display
  newItem.unit_price = parsed.amount
}

// Helper functions for price formatting
function formatNumber(num) {
  if (!num) return '0'
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')
}

function formatSignedNumber(num) {
  const n = Number(num || 0)
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

function parseFormattedNumber(str) {
  if (typeof str === 'number') return str
  const cleaned = str.replace(/\./g, '')
  return parseInt(cleaned) || 0
}

// ───────────────────────────────────────────────────────────
// PRICE INFO
// ───────────────────────────────────────────────────────────
async function showPriceInfo(item, returnFocusEl = null) {
  priceInfoReturnFocusEl.value = returnFocusEl || document.activeElement
  priceInfoModal.product_nama = item.product_nama
  priceInfoModal.loading = true
  priceInfoModal.show = true

  try {
    const customerId = orderData.value.customer.id
    const productId = item.product_id

    // Ambil histori order customer untuk item ini secara global (lintas supplier).
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
        .eq('product_id', productId)
        .in('sale_id', customerSaleIds)
        .order('created_at', { ascending: false })
        .limit(1)

      if (saleItemsError) throw saleItemsError
      customerSaleItem = saleItems?.[0] || null
    }

    // Get last unit cost
    const { data: price } = await supabase
      .from('product_prices')
      .select('harga_beli')
      .eq('product_id', productId)
      .eq('aktif', true)
      .order('updated_at', { ascending: false })
      .limit(1)
      .single()

    priceInfoModal.data = {
      last_unit_price: customerSaleItem?.unit_price || 0,
      last_unit_cost: price?.harga_beli || 0,
      last_sale_qty: customerSaleItem?.qty || 0,
      last_order_date: customerSaleItem?.sale_id ? (salesDateById.get(customerSaleItem.sale_id) || null) : null,
    }
  } catch (err) {
    console.error('[showPriceInfo]', err)
  } finally {
    priceInfoModal.loading = false
  }
}

async function refreshOrderCustomerFinancials() {
  const customerId = orderData.value?.customer?.id
  if (!customerId) return

  const { data, error } = await supabase
    .from('customers')
    .select('limit_kredit, saldo_piutang')
    .eq('id', customerId)
    .single()

  if (error) {
    console.error('[refreshOrderCustomerFinancials]', error)
    return
  }

  orderData.value.customer = {
    ...orderData.value.customer,
    limit_kredit: Number(data?.limit_kredit || 0),
    saldo_piutang: Number(data?.saldo_piutang || 0),
  }
}

function calculateCreditExposure(limitBulan, subtotal) {
  if (Number(limitBulan) === -1) return 0
  return Math.max(0, Number(subtotal || 0))
}

async function showPriceInfoPreview(returnFocusEl = null) {
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

// ───────────────────────────────────────────────────────────
// NAVIGATION
// ───────────────────────────────────────────────────────────
function focusQty() {
  if (newItem.product_id) {
    inputQty.value?.focus()
    return
  }

  if (isInlineAdjustmentDraft.value) {
    focusPrice()
  }
}

function focusPrice() {
  if (canInputPrice.value) {
    inputPrice.value?.focus()
  }
}

function onNewItemSearchTab() {
  if (productSearchArmed.value) {
    openProductModal()
    return
  }

  if (newItem.product_id) {
    focusQty()
    return
  }

  if (isInlineAdjustmentDraft.value) {
    focusPrice()
    return
  }

  if (isInlineAdjustmentDraft.value) {
    focusPrice()
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

function onNewRowPriceEnter() {
  if (isInlineAdjustmentDraft.value) {
    confirmAdjustmentFromNewRow()
    return
  }

  addItem()
}

function focusNextRow(currentIdx, field) {
  if (field === 'price') {
    // After price, go to next row's item input or add the item
    inputProduct.value?.focus()
  } else if (field === 'item') {
    // After item qty, go to price
    // This shouldn't happen in current flow
  }
}

// ───────────────────────────────────────────────────────────
// FORM SUBMIT
// ───────────────────────────────────────────────────────────
async function submitSale(shouldPrint = false, bypassLimitConfirm = false) {
  if (saving.value) return

  if (items.value.length === 0) {
    alert('Tambahkan minimal 1 barang')
    return
  }

  await refreshOrderCustomerFinancials()

  // Final credit limit check
  const customer = orderData.value.customer
  const remainingCredit = Number(customer.limit_kredit || 0) - Number(customer.saldo_piutang || 0)
  
  if (!bypassLimitConfirm && subtotal.value > remainingCredit) {
    openCreditLimitConfirmModal({
      customer,
      remainingCredit,
      totalOrder: subtotal.value,
      shouldPrint,
    })
    return
  }

  saving.value = true

  try {
    const sale_id = orderData.value.sale_id
    const normalizedItems = normalizeItemsForSave(items.value)
    const normalizedSubtotal = normalizedItems.reduce((sum, item) => sum + item.total, 0) + adjustmentTotal.value
    const extraChargeSnapshot = buildExtraChargeSnapshot()

    if (!sale_id) {
      throw new Error('Sale ID tidak ditemukan. Silakan kembali ke Step 1.')
    }

    if (!normalizedItems.length) {
      throw new Error('Tidak ada item valid untuk disimpan.')
    }

    const { data: existingSale, error: existingSaleError } = await supabase
      .from('sales')
      .select('customer_id, subtotal, status, limit_bulan')
      .eq('id', sale_id)
      .single()

    if (existingSaleError) throw existingSaleError

    const oldExposure = calculateCreditExposure(existingSale?.limit_bulan, existingSale?.subtotal)
    const newExposure = calculateCreditExposure(orderData.value?.limit_bulan, normalizedSubtotal)
    const exposureDelta = newExposure - oldExposure

    // Restore stock for previously saved rows (draft or previous retries)
    const { data: existingItems, error: existingItemsError } = await supabase
      .from('sale_items')
      .select('product_id, qty')
      .eq('sale_id', sale_id)

    if (existingItemsError) throw existingItemsError

    for (const existingItem of (existingItems || [])) {
      const { data: product, error: getError } = await supabase
        .from('products')
        .select('stok')
        .eq('id', existingItem.product_id)
        .single()
      if (getError) throw getError

      const { error: updateError } = await supabase
        .from('products')
        .update({ stok: (product.stok || 0) + existingItem.qty })
        .eq('id', existingItem.product_id)
      if (updateError) throw updateError
    }

    // Always replace items to avoid duplicates
    const { error: deleteError } = await supabase
      .from('sale_items')
      .delete()
      .eq('sale_id', sale_id)

    if (deleteError) throw deleteError

    // Insert normalized sale items
    const itemsPayload = normalizedItems.map(item => ({
      sale_id: sale_id,
      product_id: item.product_id,
      product_kode: item.product_kode,
      product_nama: item.product_nama,
      qty: item.qty,
      unit_price: item.unit_price,
      total: item.total,
    }))

    const { error: itemsError } = await supabase
      .from('sale_items')
      .insert(itemsPayload)

    if (itemsError) throw itemsError

    // Deduct stock from warehouse using normalized rows
    for (const item of normalizedItems) {
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

    // Update sales header (from draft to completed)
    const { data: updatedSale, error: updateError } = await supabase
      .from('sales')
      .update({
        subtotal: normalizedSubtotal,
        status: 'completed',
        extra_charge_desc: extraChargeSnapshot.description,
        extra_charge_amount: extraChargeSnapshot.amount,
        sender_note: extraForm.senderName.trim() || null,
      })
      .eq('id', sale_id)
      .select('no_order, no_faktur, extra_charge_desc, extra_charge_amount, sender_note')
      .single()

    if (updateError) throw updateError

    if (updatedSale) {
      orderData.value.no_order = updatedSale.no_order || orderData.value.no_order
      orderData.value.no_faktur = updatedSale.no_faktur || orderData.value.no_faktur
      orderData.value.extra_charge_desc = updatedSale.extra_charge_desc || null
      orderData.value.extra_charge_amount = Number(updatedSale.extra_charge_amount || 0)
      orderData.value.sender_note = updatedSale.sender_note || null
    }

    await refreshOrderCustomerFinancials()

    // Clear session storage
    sessionStorage.removeItem('penjualan_draft')
    clearWorkingState()

    if (shouldPrint) {
      openPrintConfirmModal({
        saleId: sale_id,
        header: {
          no_order: orderData.value.no_order,
          no_faktur: orderData.value.no_faktur,
          order_date: orderData.value.order_date,
          limit_bulan: Number(orderData.value.limit_bulan || 0),
        },
        customer: {
          nama: customer.nama,
          kode: customer.kode,
          alamat: customer.alamat,
        },
        senderNote: extraForm.senderName || '',
        items: normalizedItems,
        adjustmentRows: adjustmentRows.value.slice(),
        subtotal: normalizedSubtotal,
      })
    } else {
      alert(
        `Order berhasil disimpan!\n\n` +
        `No. Order: ${orderData.value.no_order}\n` +
        `No. Fraktur: ${orderData.value.no_faktur || '-'}\n` +
        `Customer: ${customer.nama}\n` +
        `Total: ${formatRp(normalizedSubtotal)}\n` +
        `Items: ${normalizedItems.length} barang`
      )
      router.push('/penjualan')
    }
  } catch (err) {
    console.error('[submitSale]', err)
    alert('Gagal menyimpan order: ' + err.message)
  } finally {
    saving.value = false
  }
}

function printOrder(sale_id) {
  console.log('[printOrder] gunakan alur print modal', sale_id)
}

async function saveAsDraft() {
  try {
    const sale_id = orderData.value.sale_id
    const normalizedItems = normalizeItemsForSave(items.value)
    const normalizedSubtotal = normalizedItems.reduce((sum, item) => sum + item.total, 0) + adjustmentTotal.value
    const extraChargeSnapshot = buildExtraChargeSnapshot()

    if (!sale_id) {
      return true
    }

    const { data: existingSale, error: existingSaleError } = await supabase
      .from('sales')
      .select('customer_id, subtotal, status, limit_bulan')
      .eq('id', sale_id)
      .single()

    if (existingSaleError) throw existingSaleError

    // Update sales with current items as draft
    const { error: updateError } = await supabase
      .from('sales')
      .update({
        subtotal: normalizedSubtotal,
        status: 'draft',
        extra_charge_desc: extraChargeSnapshot.description,
        extra_charge_amount: extraChargeSnapshot.amount,
        sender_note: extraForm.senderName.trim() || null,
      })
      .eq('id', sale_id)

    if (updateError) throw updateError

    // Insert/update sale items
    const itemsPayload = normalizedItems.map(item => ({
      sale_id: sale_id,
      product_id: item.product_id,
      product_kode: item.product_kode,
      product_nama: item.product_nama,
      qty: item.qty,
      unit_price: item.unit_price,
      total: item.total,
    }))

    // Restore stock for currently saved items (in case of re-save)
    const { data: existingItems } = await supabase
      .from('sale_items')
      .select('product_id, qty')
      .eq('sale_id', sale_id)
    for (const existingItem of (existingItems || [])) {
      const { data: product } = await supabase
        .from('products')
        .select('stok')
        .eq('id', existingItem.product_id)
        .single()
      if (product) {
        await supabase
          .from('products')
          .update({ stok: (product.stok || 0) + existingItem.qty })
          .eq('id', existingItem.product_id)
      }
    }

    // Delete existing items first
    await supabase
      .from('sale_items')
      .delete()
      .eq('sale_id', sale_id)

    // Insert new items
    if (itemsPayload.length > 0) {
      const { error: itemsError } = await supabase
        .from('sale_items')
        .insert(itemsPayload)

      if (itemsError) throw itemsError
    }

    // Deduct stock from warehouse for each new item
    for (const item of normalizedItems) {
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

    await refreshOrderCustomerFinancials()

    console.log('Draft saved successfully')
    return true
  } catch (err) {
    console.error('[saveAsDraft]', err)
    return false
  }
}

function backToStep1() {
  // Always save as draft (keep the order) and return to menu
  saveAsDraft().then(() => {
    router.push('/penjualan')
  })
}

function normalizeItemsForSave(rawItems) {
  const grouped = new Map()

  for (const item of rawItems || []) {
    const qty = Number(item.qty || 0)
    const unitPrice = Number(item.unit_price || 0)
    if (!item.product_id || qty <= 0) continue

    const key = `${item.product_id}::${unitPrice}`
    if (!grouped.has(key)) {
      grouped.set(key, {
        product_id: item.product_id,
        product_kode: item.product_kode,
        product_nama: item.product_nama,
        qty: 0,
        unit_price: unitPrice,
        total: 0,
      })
    }

    const row = grouped.get(key)
    row.qty += qty
    row.total = row.qty * row.unit_price
  }

  return Array.from(grouped.values())
}

function buildExtraChargeSnapshot() {
  const validRows = adjustmentRows.value
    .map(row => ({
      description: String(row.description || '').trim(),
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
    description: validRows.map((row, idx) => `${idx + 1}. ${row.description}`).join(' | '),
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
// HELPERS
// ───────────────────────────────────────────────────────────
function generatePreviewOrderNumber() {
  const year = new Date().getFullYear().toString().slice(-2)
  return `${year}001 (Auto)`
}

function parseDateInput(dateStr) {
  // Parse DD/MM/YY to YYYY-MM-DD
  const parts = dateStr.split('/')
  if (parts.length === 3) {
    const day = parts[0].padStart(2, '0')
    const month = parts[1].padStart(2, '0')
    const year = '20' + parts[2]
    return `${year}-${month}-${day}`
  }
  return dateStr
}

function formatRp(val) {
  if (val == null || isNaN(val)) return 'Rp 0'
  return 'Rp ' + Number(val).toLocaleString('id-ID')
}
</script>

<style scoped>
@import '@/assets/styles.css';
@import '@/assets/components/table.css';
@import '@/assets/components/modal.css';
@import '@/assets/pages/penjualan/penjualan-input-page.css';
</style>
