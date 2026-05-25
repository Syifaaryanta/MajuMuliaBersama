import { supabase } from '@/lib/supabase'

export const paymentMethodOptions = [
  { value: 'cash', label: 'Tunai' },
  { value: 'transfer', label: 'Transfer' },
]

export function formatRp(value) {
  const num = Number(value || 0)
  return `Rp ${num.toLocaleString('id-ID')}`
}

export function formatDate(value) {
  if (!value) return '-'
  const date = new Date(`${value}T00:00:00`)
  if (Number.isNaN(date.getTime())) return String(value)
  return date.toLocaleDateString('id-ID', {
    day: '2-digit',
    month: '2-digit',
    year: '2-digit',
  })
}

export function toIsoDate(date) {
  const d = new Date(date)
  const year = d.getFullYear()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

export function parseAmountInput(value) {
  const cleaned = String(value || '')
    .replace(/\s+/g, '')
    .replace(/\./g, '')
    .replace(',', '.')
    .replace(/[^0-9.-]/g, '')

  const num = Number(cleaned)
  if (!Number.isFinite(num)) return 0
  return num
}

export function formatAmountInput(value) {
  const num = Number(value || 0)
  if (!num) return ''
  return num.toLocaleString('id-ID', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  })
}

export function normalizeSearch(value) {
  return String(value || '').toLowerCase().trim()
}

export function filterBySearch(rows, query, textFn) {
  const q = normalizeSearch(query)
  if (!q) return rows
  return rows.filter(row => normalizeSearch(textFn(row)).includes(q))
}

export function paymentStatusLabel(status) {
  if (status === 'cash') return 'Tunai'
  if (status === 'paid') return 'Lunas'
  if (status === 'partial') return 'Cicilan'
  if (status === 'unpaid') return 'Belum Bayar'
  return status || '-'
}

export function paymentMethodLabel(method) {
  const key = String(method || '').toLowerCase()
  const found = paymentMethodOptions.find(item => item.value === key)
  if (found) return found.label
  return key || '-'
}

export function statusClass(status) {
  if (status === 'paid') return 'status-paid'
  if (status === 'partial') return 'status-partial'
  if (status === 'unpaid') return 'status-unpaid'
  if (status === 'cash') return 'status-cash'
  return ''
}

export function isDueSoon(row) {
  if (!row || !row.due_date || Number(row.outstanding_amount || 0) <= 0) return false
  const due = new Date(`${row.due_date}T00:00:00`)
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const diff = Math.ceil((due.getTime() - today.getTime()) / 86400000)
  return diff >= 0 && diff <= 7
}

export function isSchemaIssue(message) {
  const lower = String(message || '').toLowerCase()
  return (
    lower.includes('v_penagihan_sales') ||
    lower.includes('v_penagihan_payments') ||
    lower.includes('sales_payments') ||
    lower.includes('due_date') ||
    lower.includes('nota_merah') ||
    lower.includes('nota_putih') ||
    lower.includes('nota_kuning')
  )
}

function normalizeBillingRow(row) {
  return {
    ...row,
    grand_total: Number(row.grand_total || 0),
    total_paid: Number(row.total_paid || 0),
    outstanding_amount: Number(row.outstanding_amount || 0),
    overdue_days: Number(row.overdue_days || 0),
    is_overdue: Boolean(row.is_overdue),
    is_credit: Boolean(row.is_credit),
    is_cash: Boolean(row.is_cash),
    nota_merah: Boolean(row.nota_merah),
    nota_putih: Boolean(row.nota_putih),
    nota_kuning: Boolean(row.nota_kuning),
  }
}

function normalizePaymentRow(row) {
  return {
    ...row,
    amount: Number(row.amount || 0),
  }
}

export async function fetchPenagihanSales() {
  const { data, error } = await supabase
    .from('v_penagihan_sales')
    .select('*')
    .order('order_date', { ascending: false })
    .order('no_order', { ascending: false })

  if (error) throw error
  return (data || []).map(normalizeBillingRow)
}

export async function fetchPenagihanPayments() {
  const { data, error } = await supabase
    .from('v_penagihan_payments')
    .select('*')
    .order('payment_date', { ascending: false })
    .order('created_at', { ascending: false })

  if (error) throw error
  return (data || []).map(normalizePaymentRow)
}

export async function fetchPenagihanBundle() {
  const [sales, payments] = await Promise.all([
    fetchPenagihanSales(),
    fetchPenagihanPayments(),
  ])

  return { sales, payments }
}

function toCents(value) {
  return Math.round(Number(value || 0) * 100)
}

function fromCents(value) {
  return Number((Number(value || 0) / 100).toFixed(2))
}

function compareBillingFifo(a, b) {
  const dateA = String(a?.order_date || '')
  const dateB = String(b?.order_date || '')
  if (dateA !== dateB) {
    return dateA < dateB ? -1 : 1
  }

  const orderA = String(a?.no_order || '')
  const orderB = String(b?.no_order || '')
  if (orderA !== orderB) {
    return orderA < orderB ? -1 : 1
  }

  const idA = String(a?.sale_id || '')
  const idB = String(b?.sale_id || '')
  return idA < idB ? -1 : idA > idB ? 1 : 0
}

export function getCustomerOutstandingAmount(salesRows, customerId) {
  const key = String(customerId || '')
  if (!key) return 0

  const totalCents = (salesRows || [])
    .filter(row => {
      return String(row?.customer_id || '') === key
        && row?.is_credit
        && Number(row?.outstanding_amount || 0) > 0
    })
    .reduce((sum, row) => sum + toCents(row?.outstanding_amount), 0)

  return fromCents(totalCents)
}

export function allocateCustomerPaymentFifo({ salesRows, customerId, amount }) {
  const key = String(customerId || '')
  const targetRows = (salesRows || [])
    .filter(row => {
      return String(row?.customer_id || '') === key
        && row?.is_credit
        && Number(row?.outstanding_amount || 0) > 0
    })
    .slice()
    .sort(compareBillingFifo)

  const customerOutstandingCents = targetRows.reduce((sum, row) => {
    return sum + toCents(row.outstanding_amount)
  }, 0)

  const requestedCents = Math.max(0, toCents(amount))
  let remainingCents = requestedCents
  const allocations = []

  for (const row of targetRows) {
    if (remainingCents <= 0) break

    const outstandingCents = Math.max(0, toCents(row.outstanding_amount))
    if (outstandingCents <= 0) continue

    const allocatedCents = Math.min(remainingCents, outstandingCents)
    remainingCents -= allocatedCents

    allocations.push({
      row,
      amount: fromCents(allocatedCents),
      previousOutstanding: fromCents(outstandingCents),
      nextOutstanding: fromCents(outstandingCents - allocatedCents),
      isFullyPaid: allocatedCents >= outstandingCents,
    })
  }

  return {
    allocations,
    allocatedAmount: fromCents(requestedCents - remainingCents),
    unallocatedAmount: fromCents(remainingCents),
    customerOutstandingAmount: fromCents(customerOutstandingCents),
  }
}

export function subscribePenagihanAutoSync({ key = 'global', onSync, debounceMs = 180 } = {}) {
  if (typeof onSync !== 'function') {
    return () => {}
  }

  let disposed = false
  let debounceTimer = null
  let running = false
  let queued = false

  const runSync = async () => {
    if (disposed) return

    if (running) {
      queued = true
      return
    }

    running = true
    try {
      await onSync()
    } catch (err) {
      console.error('[subscribePenagihanAutoSync.runSync]', err)
    } finally {
      running = false
      if (queued) {
        queued = false
        await runSync()
      }
    }
  }

  const scheduleSync = () => {
    if (disposed) return

    if (debounceTimer) {
      clearTimeout(debounceTimer)
    }

    debounceTimer = setTimeout(() => {
      debounceTimer = null
      void runSync()
    }, Math.max(50, Number(debounceMs) || 180))
  }

  const channelName = `penagihan-auto-${key}-${Math.random().toString(36).slice(2, 8)}`

  const channel = supabase
    .channel(channelName)
    .on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'sales' },
      () => scheduleSync()
    )
    .on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'sales_payments' },
      () => scheduleSync()
    )
    .subscribe(status => {
      if (status === 'SUBSCRIBED') {
        scheduleSync()
      }
    })

  return () => {
    disposed = true

    if (debounceTimer) {
      clearTimeout(debounceTimer)
      debounceTimer = null
    }

    void supabase.removeChannel(channel)
  }
}

export async function insertSalesPayments(entries) {
  const payload = (entries || []).map(item => ({
    sale_id: item.saleId,
    payment_date: item.paymentDate,
    amount: item.amount,
    payment_method: item.paymentMethod,
    note: item.note || null,
  }))

  if (!payload.length) return

  const { error } = await supabase
    .from('sales_payments')
    .insert(payload)

  if (error) throw error
}

export async function insertSalesPayment({ saleId, paymentDate, amount, paymentMethod, note }) {
  await insertSalesPayments([
    { saleId, paymentDate, amount, paymentMethod, note },
  ])
}

export async function deleteSalesPaymentsBySaleId(saleId) {
  if (!saleId) return 0

  const { data, error } = await supabase
    .from('sales_payments')
    .delete()
    .eq('sale_id', saleId)
    .select('id')

  if (error) throw error
  return Array.isArray(data) ? data.length : 0
}

export async function updateSalesNotes(saleId, payload) {
  const { error } = await supabase
    .from('sales')
    .update(payload)
    .eq('id', saleId)

  if (error) throw error
}

export function buildAutoNotePayload(outstandingAmount) {
  const outstanding = Number(outstandingAmount || 0)
  const isDebt = outstanding > 0
  return {
    nota_merah: isDebt,
    nota_putih: !isDebt,
    nota_kuning: true,
  }
}

export function getMenuStats(sales, payments) {
  const creditRows = (sales || []).filter(row => row.is_credit)
  const cashRows = (sales || []).filter(row => row.is_cash)

  const totalOutstanding = creditRows.reduce((sum, row) => sum + Number(row.outstanding_amount || 0), 0)
  const overdueCount = creditRows.filter(row => row.is_overdue && Number(row.outstanding_amount || 0) > 0).length
  const dueTodayCount = creditRows.filter(row => {
    return Number(row.outstanding_amount || 0) > 0 && String(row.due_date || '') === toIsoDate(new Date())
  }).length

  const paymentTodayTotal = (payments || [])
    .filter(row => String(row.payment_date || '') === toIsoDate(new Date()))
    .reduce((sum, row) => sum + Number(row.amount || 0), 0)

  const needSyncNotaCount = (sales || []).filter(row => {
    const shouldRed = row.is_credit && Number(row.outstanding_amount || 0) > 0
    const shouldWhite = !shouldRed
    const redMismatch = shouldRed && !row.nota_merah
    const whiteMismatch = shouldWhite && !row.nota_putih
    const yellowMismatch = !row.nota_kuning
    return redMismatch || whiteMismatch || yellowMismatch
  }).length

  return {
    totalOutstanding,
    overdueCount,
    dueTodayCount,
    paymentTodayTotal,
    piutangAktifCount: creditRows.filter(row => Number(row.outstanding_amount || 0) > 0).length,
    tunaiCount: cashRows.length,
    riwayatCount: (payments || []).length,
    needSyncNotaCount,
  }
}
