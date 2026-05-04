<template>
  <div class="dashboard-page" ref="pageEl" tabindex="-1">
    <Toast position="top-right" />

    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Dashboard Operasional</h1>
        <p class="g-subtitle">Grafik lintas modul untuk memantau performa penjualan, pembelian, gudang, penagihan, dan master data.</p>
      </div>

      <div class="g-header-right">
        <span class="last-updated" v-if="lastUpdatedLabel">Update: {{ lastUpdatedLabel }}</span>
      </div>
    </div>

    <div class="shortcut-strip">
      <kbd>F1 30 Hari</kbd>
      <kbd>F2 6 Bulan</kbd>
      <kbd>F3 1 Tahun</kbd>
      <kbd>F5 Refresh</kbd>
      <kbd>Esc Reset Filter</kbd>
    </div>

    <div class="range-filter">
      <button
        v-for="option in rangeOptions"
        :key="option.key"
        type="button"
        class="range-chip"
        :class="{ 'range-chip--active': activeRange === option.key }"
        @click="setRange(option.key)"
      >
        {{ option.label }}
      </button>
      <span class="range-note">Periode aktif: {{ selectedRangeLabel }}</span>
    </div>

    <div v-if="schemaWarnings.length" class="schema-warning">
      <i class="pi pi-info-circle"></i>
      <div>
        <strong>Beberapa data modul belum tersedia penuh</strong>
        <p>{{ schemaWarningsText }}</p>
      </div>
    </div>

    <div class="kpi-grid">
      <article class="kpi-card kpi-card--blue">
        <div class="kpi-icon"><i class="pi pi-wallet"></i></div>
        <div class="kpi-body">
          <span class="kpi-label">Omzet Periode</span>
          <strong class="kpi-value">{{ formatRp(kpi.omzet) }}</strong>
        </div>
      </article>

      <article class="kpi-card kpi-card--teal">
        <div class="kpi-icon"><i class="pi pi-shopping-cart"></i></div>
        <div class="kpi-body">
          <span class="kpi-label">Pembelian Periode</span>
          <strong class="kpi-value">{{ formatRp(kpi.pembelian) }}</strong>
        </div>
      </article>

      <article class="kpi-card kpi-card--green">
        <div class="kpi-icon"><i class="pi pi-chart-line"></i></div>
        <div class="kpi-body">
          <span class="kpi-label">HPP Estimasi</span>
          <strong class="kpi-value">{{ formatRp(kpi.hpp) }}</strong>
          <small class="kpi-sub">Margin {{ formatPercent(kpi.marginPct) }}</small>
        </div>
      </article>

      <article class="kpi-card kpi-card--orange">
        <div class="kpi-icon"><i class="pi pi-exclamation-circle"></i></div>
        <div class="kpi-body">
          <span class="kpi-label">Piutang Outstanding</span>
          <strong class="kpi-value">{{ formatRp(kpi.outstanding) }}</strong>
          <small class="kpi-sub">Overdue: {{ formatCount(kpi.overdueCount) }} transaksi</small>
        </div>
      </article>

      <article class="kpi-card kpi-card--amber">
        <div class="kpi-icon"><i class="pi pi-box"></i></div>
        <div class="kpi-body">
          <span class="kpi-label">Stok Kritis + Habis</span>
          <strong class="kpi-value">{{ formatCount(kpi.lowStockCount) }} item</strong>
          <small class="kpi-sub">Pantau di menu Gudang</small>
        </div>
      </article>

      <article class="kpi-card kpi-card--slate">
        <div class="kpi-icon"><i class="pi pi-users"></i></div>
        <div class="kpi-body">
          <span class="kpi-label">Master Data Aktif</span>
          <strong class="kpi-value">{{ formatCount(kpi.activeCustomers) }} customer</strong>
          <small class="kpi-sub">{{ formatCount(kpi.activeSuppliers) }} supplier</small>
        </div>
      </article>
    </div>

    <div class="quick-nav-grid">
      <button
        v-for="(item, index) in moduleLinks"
        :key="item.route"
        class="quick-nav-card"
        :class="{ 'quick-nav-card--active': selectedQuickIndex === index }"
        type="button"
        @mouseenter="selectedQuickIndex = index"
        @click="navigateToModule(index)"
      >
        <span class="quick-nav-index">{{ index + 1 }}</span>
        <div class="quick-nav-body">
          <h3>{{ item.title }}</h3>
          <p>{{ item.description }}</p>
        </div>
        <i class="pi pi-arrow-right"></i>
      </button>
    </div>

    <div class="chart-grid">
      <section class="chart-card chart-card--wide">
        <div class="chart-head">
          <div>
            <h3>Grafik HPP</h3>
            <p>Tren penjualan, pembelian, dan rasio omzet/HPP per bulan</p>
          </div>
          <button type="button" class="chart-link" @click="router.push('/penjualan')">Buka Penjualan</button>
        </div>
        <div class="chart-body chart-body--line">
          <canvas ref="salesPurchaseCanvas"></canvas>
        </div>
      </section>

      <section class="chart-card">
        <div class="chart-head">
          <div>
            <h3>Barang Keluar Hari Ini</h3>
            <p>Ringkas kategori barang yang keluar hari ini</p>
          </div>
          <button type="button" class="chart-link" @click="router.push('/gudang')">Buka Gudang</button>
        </div>
        <div class="stock-out-body">
          <div
            v-for="item in soldTodaySummary"
            :key="item.label"
            class="stock-out-row"
          >
            <span class="stock-out-name">{{ item.label }}</span>
            <span class="stock-out-qty">{{ formatCount(item.qty) }}</span>
          </div>
          <div v-if="!soldTodaySummary.length" class="stock-out-empty">Belum ada barang keluar hari ini.</div>
        </div>
      </section>

      <section class="chart-card">
        <div class="chart-head">
          <div>
            <h3>Penjualan Hari Ini</h3>
            <p>Nama customer dan subtotal penjualan hari ini</p>
          </div>
          <button type="button" class="chart-link" @click="router.push('/penjualan')">Buka Penjualan</button>
        </div>
        <div class="sales-today-body">
          <div
            v-for="item in salesTodaySummary"
            :key="item.name"
            class="sales-today-row"
          >
            <span class="sales-today-name">{{ item.name }}</span>
            <span class="sales-today-amount">{{ formatRp(item.subtotal) }}</span>
          </div>
          <div v-if="!salesTodaySummary.length" class="sales-today-empty">Belum ada penjualan hari ini.</div>
        </div>
      </section>

      <section class="chart-card chart-card--wide">
        <div class="chart-head">
          <div>
            <h3>Kalender Penjualan {{ salesCalendar.monthLabel }}</h3>
            <p>Kalender interaktif untuk melihat performa penjualan per hari</p>
          </div>
          <div class="sales-calendar-legend">
            <span class="legend-item legend-item--high">Tinggi</span>
            <span class="legend-item legend-item--mid">Sedang</span>
            <span class="legend-item legend-item--low">Rendah</span>
            <span class="legend-item legend-item--future">Belum hari ini</span>
          </div>
        </div>
        <div class="sales-calendar">
          <div class="sales-calendar-weekdays">
            <span v-for="day in calendarWeekdays" :key="day">{{ day }}</span>
          </div>
          <div class="sales-calendar-grid">
            <div
              v-for="cell in salesCalendar.cells"
              :key="cell.key"
              class="sales-calendar-cell"
              :class="[
                cell.inMonth ? `sales-calendar-cell--${cell.level}` : 'sales-calendar-cell--empty',
                { 'is-today': cell.isToday },
              ]"
              :title="cell.inMonth ? formatRp(cell.amount || 0) : ''"
            >
              <span v-if="cell.inMonth" class="sales-calendar-date">{{ cell.day }}</span>
              <span v-if="cell.inMonth" class="sales-calendar-value">{{ cell.amount > 0 ? formatCompactRp(cell.amount) : '-' }}</span>
            </div>
          </div>
        </div>
      </section>
    </div>

    <div v-if="loadError" class="error-banner">
      <i class="pi pi-exclamation-triangle"></i>
      <p>{{ loadError }}</p>
    </div>
  </div>
</template>

<script setup>
import Toast from 'primevue/toast'
import { useDashboardData } from './useDashboardData'

const {
  router,
  pageEl,
  loadError,
  lastUpdatedLabel,
  schemaWarnings,
  schemaWarningsText,
  rangeOptions,
  activeRange,
  selectedRangeLabel,
  setRange,
  moduleLinks,
  selectedQuickIndex,
  navigateToModule,
  kpi,
  formatRp,
  formatPercent,
  formatCount,
  formatCompactRp,
  salesPurchaseCanvas,
  soldTodaySummary,
  salesTodaySummary,
  monthlySalesTarget,
  calendarWeekdays,
  salesCalendar,
} = useDashboardData()
</script>

<style scoped>
@import '@/assets/pages/Dashboard/dashboard-page.css';
</style>
