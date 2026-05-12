<template>
  <div class="laporan-page" ref="pageEl" tabindex="-1">
    <header class="laporan-header">
      <div class="laporan-header__text">
        <h2 class="laporan-header__title">Laporan Bisnis</h2>
        <p class="laporan-header__desc">
          Ringkasan dan laporan detail untuk penjualan, pembelian, stok, dan keuangan.
        </p>
      </div>
    </header>

    <section class="laporan-grid">
      <article
        v-for="(card, index) in cards"
        :key="card.path"
        class="laporan-card laporan-card--link"
        role="button"
        tabindex="0"
        @click="goDetail(card.path)"
        @keydown.enter.prevent="goDetail(card.path)"
        @keydown.space.prevent="goDetail(card.path)"
        :ref="setCardRef"
        :data-index="index"
      >
        <span class="laporan-card__icon" aria-hidden="true">
          <i :class="card.icon"></i>
        </span>
        <div class="laporan-card__header">
          <div class="laporan-card__text">
            <h3>{{ card.title }}</h3>
            <p class="laporan-card__desc">{{ card.desc }}</p>
          </div>
          <i class="pi pi-arrow-right laporan-card__chevron"></i>
        </div>
      </article>
    </section>
  </div>
</template>

<script setup>
import { ref, onBeforeUpdate, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const pageEl = ref(null)
const cardRefs = ref([])

const cards = [
  {
    title: 'Ringkasan bisnis',
    path: '/laporan/ringkasan-bisnis',
    icon: 'pi pi-chart-bar',
    desc: 'Omzet, laba kotor, stok, piutang, dan tren.',
  },
  {
    title: 'Penjualan detail',
    path: '/laporan/penjualan-detail',
    icon: 'pi pi-shopping-cart',
    desc: 'Rincian transaksi per waktu, pelanggan, dan margin.',
  },
  {
    title: 'Pembelian detail',
    path: '/laporan/pembelian-detail',
    icon: 'pi pi-credit-card',
    desc: 'Pembelian per supplier, produk, dan histori harga.',
  },
  {
    title: 'Stok dan persediaan',
    path: '/laporan/stok-persediaan',
    icon: 'pi pi-box',
    desc: 'Stok akhir, pergerakan, dan fast/slow moving.',
  },
  {
    title: 'Penagihan dan piutang',
    path: '/laporan/penagihan-piutang',
    icon: 'pi pi-wallet',
    desc: 'Aging piutang, jatuh tempo, dan pembayaran.',
  },
  {
    title: 'Hutang',
    path: '/laporan/hutang',
    icon: 'pi pi-briefcase',
    desc: 'Umur hutang, jadwal bayar, dan invoice.',
  },
  {
    title: 'Arus kas sederhana',
    path: '/laporan/arus-kas',
    icon: 'pi pi-arrows-h',
    desc: 'Kas masuk/keluar dari penjualan dan pembelian.',
  },
  {
    title: 'Audit dan aktivitas',
    path: '/laporan/audit-aktivitas',
    icon: 'pi pi-shield',
    desc: 'Perubahan stok, pembatalan, dan aktivitas user.',
  },
]

onBeforeUpdate(() => {
  cardRefs.value = []
})

function setCardRef(el) {
  if (el) cardRefs.value.push(el)
}

function getActiveIndex() {
  const active = document.activeElement
  const index = cardRefs.value.findIndex(el => el === active)
  return index >= 0 ? index : 0
}

function getColumns() {
  const first = cardRefs.value[0]
  if (!first) return 1
  const firstTop = first.offsetTop
  const sameRow = cardRefs.value.filter(el => Math.abs(el.offsetTop - firstTop) <= 4)
  return Math.max(1, sameRow.length)
}

function focusCard(index) {
  const target = cardRefs.value[index]
  if (target) target.focus()
}

function handleKeydown(e) {
  if (e.target?.tagName === 'INPUT' || e.target?.tagName === 'TEXTAREA') return
  if (e.key === 'Escape') {
    e.preventDefault()
    router.push('/dashboard')
    return
  }

  if (e.key === 'F1') {
    e.preventDefault()
    goFilter(cards[getActiveIndex()]?.path)
    return
  }

  if (e.key === 'F2') {
    e.preventDefault()
    goExport(cards[getActiveIndex()]?.path)
    return
  }

  if (['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(e.key)) {
    e.preventDefault()
    const columns = getColumns()
    const current = getActiveIndex()
    let next = current

    if (e.key === 'ArrowLeft') next = current - 1
    if (e.key === 'ArrowRight') next = current + 1
    if (e.key === 'ArrowUp') next = current - columns
    if (e.key === 'ArrowDown') next = current + columns

    if (next < 0) next = 0
    if (next >= cardRefs.value.length) next = cardRefs.value.length - 1
    focusCard(next)
  }
}

function goDetail(path) {
  router.push(path)
}

function goFilter(path) {
  router.push({ path, query: { action: 'filter' } })
}

function goExport(path) {
  router.push({ path, query: { action: 'export' } })
}

onMounted(() => {
  pageEl.value?.focus()
  window.addEventListener('keydown', handleKeydown)
  setTimeout(() => focusCard(0), 0)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<style scoped>
@import '@/assets/Styles/laporan/laporan-page.css';
</style>
