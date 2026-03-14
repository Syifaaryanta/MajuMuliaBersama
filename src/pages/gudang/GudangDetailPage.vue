<template>
  <div class="gudang-detail-page" ref="pageEl" tabindex="-1">

    <!-- ── LOADING ─────────────────────────────────────── -->
    <div v-if="loading" class="detail-loading">
      <i class="pi pi-spin pi-spinner"></i>
      <span>Memuat data...</span>
    </div>

    <!-- ── NOT FOUND ────────────────────────────────────── -->
    <div v-else-if="!product" class="detail-not-found">
      <i class="pi pi-exclamation-circle"></i>
      <h2>Produk tidak ditemukan</h2>
      <button class="btn-back-sm" @click="goBack">
        <i class="pi pi-arrow-left"></i>
        <span class="btn-label">Kembali</span>
      </button>
    </div>

    <!-- ── CONTENT ──────────────────────────────────────── -->
    <template v-else>

      <!-- Back nav + action bar -->
      <div class="detail-topbar">
        <button class="btn-back" @click="goBack">
          <i class="pi pi-arrow-left"></i>
          <span class="btn-label">Kembali</span>
        </button>
        <span class="topbar-hint"><kbd>Esc</kbd> kembali &nbsp;·&nbsp; <kbd>F1</kbd> foto fullscreen</span>
      </div>

      <!-- ── HERO ──────────────────────────────────────── -->
      <div class="detail-hero">
        <!-- Left: info -->
        <div class="detail-hero-info">
          <div class="hero-badges">
            <span class="hero-kode">{{ product.kode }}</span>
            <span class="hero-satuan">{{ product.satuan }}</span>
          </div>
          <h1 class="hero-nama">{{ product.nama }}</h1>

          <!-- Quick stats -->
          <div class="hero-stats">
            <div class="hero-stat">
              <i class="pi pi-box"></i>
              <div>
                <span class="hs-label">Total Stok</span>
                <span class="hs-value" :class="{ 'hs-value--low': totalStok <= 3 }">
                  {{ totalStok }} <small>{{ product.satuan }}</small>
                </span>
              </div>
            </div>
            <div class="hero-stat">
              <i class="pi pi-users"></i>
              <div>
                <span class="hs-label">Supplier</span>
                <span class="hs-value">{{ product.prices?.length ?? 0 }}</span>
              </div>
            </div>
            <div class="hero-stat" v-if="lowestPrice">
              <i class="pi pi-tag"></i>
              <div>
                <span class="hs-label">Harga Terendah</span>
                <span class="hs-value">{{ formatRp(lowestPrice) }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Right: foto utama -->
        <div v-if="product.foto_urls?.length" class="detail-hero-foto">
          <div class="hero-foto-wrap" @click="openLightbox(0)">
            <img :src="product.foto_urls[0]" alt="foto utama" class="hero-foto-img" />
            <div class="hero-foto-overlay">
              <i class="pi pi-search-plus"></i>
              <span>{{ product.foto_urls.length }} foto</span>
            </div>
          </div>
        </div>
        <div v-else class="detail-hero-foto-placeholder">
          <i class="pi pi-image"></i>
          <span>Belum ada foto</span>
        </div>
      </div>

      <!-- ── BODY GRID ─────────────────────────────────── -->
      <div class="detail-body">

        <!-- Gallery (if >1 foto) -->
        <section v-if="product.foto_urls?.length > 1" class="detail-card">
          <div class="card-header">
            <i class="pi pi-images"></i>
            <h3>Foto Barang</h3>
            <span class="card-hint"><kbd>F1</kbd> buka fullscreen</span>
          </div>
          <div class="foto-gallery">
            <div
              v-for="(url, idx) in product.foto_urls"
              :key="url"
              class="foto-item"
              @click="openLightbox(idx)"
              :class="{ 'foto-item--first': idx === 0 }"
            >
              <img :src="url" :alt="`Foto ${idx+1}`" class="foto-img" />
              <div class="foto-overlay"><i class="pi pi-search-plus"></i></div>
            </div>
          </div>
        </section>

        <!-- Deskripsi -->
        <section v-if="product.deskripsi" class="detail-card">
          <div class="card-header">
            <i class="pi pi-align-left"></i>
            <h3>Deskripsi</h3>
          </div>
          <p class="detail-deskripsi">{{ product.deskripsi }}</p>
        </section>

        <!-- Stok & Harga per Supplier -->
        <section class="detail-card detail-card--full">
          <div class="card-header">
            <i class="pi pi-truck"></i>
            <h3>Stok & Harga per Supplier</h3>
          </div>
          <div class="price-cards-grid">
            <div v-for="(price, idx) in product.prices" :key="idx" class="price-card">
              <div class="pc-header">
                <i class="pi pi-building"></i>
                <span class="pc-supplier">{{ price.supplier_nama }}</span>
              </div>
              <div class="pc-body">
                <div class="pc-item">
                  <span class="pc-label">Stok</span>
                  <span class="pc-value stok-val" :class="{ 'stok-low': price.stok <= 3 }">
                    {{ price.stok }} {{ product.satuan }}
                  </span>
                </div>
                <div class="pc-item">
                  <span class="pc-label">Harga Beli</span>
                  <span class="pc-value">{{ formatRp(price.harga_beli) }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Also show full table for easy comparison -->
          <table class="price-table" v-if="product.prices?.length > 1">
            <thead>
              <tr>
                <th>Supplier</th>
                <th class="tr">Stok</th>
                <th class="tr">Harga Beli</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(price, idx) in product.prices" :key="`t${idx}`">
                <td><span class="supplier-chip">{{ price.supplier_nama }}</span></td>
                <td class="tr">
                  <span class="stok-val" :class="{ 'stok-low': price.stok <= 3 }">
                    {{ price.stok }} {{ product.satuan }}
                  </span>
                </td>
                <td class="tr"><span class="harga-val">{{ formatRp(price.harga_beli) }}</span></td>
              </tr>
              <tr class="total-row">
                <td><b>Total</b></td>
                <td class="tr"><b>{{ totalStok }} {{ product.satuan }}</b></td>
                <td class="tr"><span class="total-hint">terendah: {{ formatRp(lowestPrice) }}</span></td>
              </tr>
            </tbody>
          </table>
        </section>

      </div>
    </template>

    <!-- ── LIGHTBOX ──────────────────────────────────────── -->
    <Teleport to="body">
      <Transition name="modal-fade">
        <div v-if="lightbox.show" class="lightbox-overlay" @click="closeLightbox">
          <div class="lightbox-content" @click.stop>
            <button class="lightbox-close" @click="closeLightbox"><i class="pi pi-times"></i></button>
            <button v-if="lightbox.currentIndex > 0" class="lightbox-prev" @click="prevPhoto">
              <i class="pi pi-chevron-left"></i>
            </button>
            <div class="lightbox-image-wrap">
              <img
                :src="product?.foto_urls?.[lightbox.currentIndex]"
                class="lightbox-image"
                :alt="`Foto ${lightbox.currentIndex + 1}`"
              />
            </div>
            <button v-if="lightbox.currentIndex < (product?.foto_urls?.length ?? 0) - 1" class="lightbox-next" @click="nextPhoto">
              <i class="pi pi-chevron-right"></i>
            </button>
            <div class="lightbox-counter">
              {{ lightbox.currentIndex + 1 }} / {{ product?.foto_urls?.length }}
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router  = useRouter()
const route   = useRoute()
const pageEl  = ref(null)
const loading = ref(true)
const product = ref(null)
const lightbox = reactive({ show: false, currentIndex: 0 })

// ── Computed ───────────────────────────────────────────────
const totalStok = computed(() =>
  product.value?.prices?.reduce((s, p) => s + (p.stok ?? 0), 0) ?? 0
)
const lowestPrice = computed(() => {
  const prices = product.value?.prices?.map(p => p.harga_beli).filter(p => p > 0) ?? []
  return prices.length ? Math.min(...prices) : null
})

// ── Data ───────────────────────────────────────────────────
async function loadProduct(productId) {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('products')
      .select(`
        id, kode, nama, deskripsi, satuan, foto_urls,
        product_prices (
          id, stok, harga_beli, aktif,
          suppliers ( id, nama )
        )
      `)
      .eq('id', productId)
      .eq('aktif', true)
      .single()

    if (error) throw error

    const activePrices = data.product_prices?.filter(pp => pp.aktif) ?? []
    product.value = {
      id: data.id,
      kode: data.kode,
      nama: data.nama,
      deskripsi: data.deskripsi ?? '',
      satuan: data.satuan,
      foto_urls: data.foto_urls ?? [],
      prices: activePrices.map(pp => ({
        id: pp.id,
        stok: pp.stok ?? 0,
        harga_beli: pp.harga_beli ?? 0,
        supplier_id: pp.suppliers?.id,
        supplier_nama: pp.suppliers?.nama ?? '—',
      })),
    }
  } catch (err) {
    console.error('[GudangDetail] loadProduct:', err)
    product.value = null
  } finally {
    loading.value = false
  }
}

// ── Navigation ─────────────────────────────────────────────
function goBack() {
  if (window.history.state?.back) {
    router.back()
  } else {
    router.push('/gudang/cek-semua')
  }
}

// ── Lightbox ───────────────────────────────────────────────
function openLightbox(index) { lightbox.currentIndex = index; lightbox.show = true }
function closeLightbox()     { lightbox.show = false }
function prevPhoto()         { if (lightbox.currentIndex > 0) lightbox.currentIndex-- }
function nextPhoto()         { const max = (product.value?.foto_urls?.length ?? 1) - 1; if (lightbox.currentIndex < max) lightbox.currentIndex++ }

// ── Utilities ──────────────────────────────────────────────
function formatRp(val) {
  if (!val && val !== 0) return '—'
  return 'Rp ' + Number(val).toLocaleString('id-ID')
}

// ── Keyboard ───────────────────────────────────────────────
function onGlobalKey(e) {
  if (lightbox.show) {
    if (e.key === 'Escape')          { e.preventDefault(); closeLightbox() }
    else if (e.key === 'ArrowLeft')  { e.preventDefault(); prevPhoto() }
    else if (e.key === 'ArrowRight') { e.preventDefault(); nextPhoto() }
    return
  }
  if (e.key === 'Escape')  { e.preventDefault(); goBack() }
  if (e.key === 'F1' && product.value?.foto_urls?.length) { e.preventDefault(); openLightbox(0) }
}

// ── Lifecycle ──────────────────────────────────────────────
onMounted(() => {
  pageEl.value?.focus()
  window.addEventListener('keydown', onGlobalKey)
  const productId = route.query.product_id
  if (productId) {
    loadProduct(productId)
  } else {
    loading.value = false
  }
})

onUnmounted(() => {
  window.removeEventListener('keydown', onGlobalKey)
})
</script>

<style scoped>
@import '@/assets/pages/gudang/gudang-detail-page.css';
</style>
