import { buildPurchaseOrderFingerprint, secondBucket } from '@/lib/orderDedupe'

const STORAGE_KEY = 'pembelian_orders_v1'

function safeParse(raw, fallback) {
  try {
    return raw ? JSON.parse(raw) : fallback
  } catch {
    return fallback
  }
}

export function listPurchaseOrders() {
  const rows = safeParse(localStorage.getItem(STORAGE_KEY), [])
  return Array.isArray(rows) ? rows : []
}

function saveAll(rows) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(rows))
}

export function generatePurchaseOrderNo() {
  const year = new Date().getFullYear().toString().slice(-2)
  const prefix = `PO${year}`
  const rows = listPurchaseOrders()
  const nums = rows
    .map(row => String(row.no_order || ''))
    .filter(no => no.startsWith(prefix))
    .map(no => parseInt(no.slice(prefix.length), 10))
    .filter(n => Number.isFinite(n))

  const next = (nums.length ? Math.max(...nums) : 0) + 1
  return `${prefix}${String(next).padStart(5, '0')}`
}

export function getPurchaseOrderByNo(noOrder) {
  const rows = listPurchaseOrders()
  return rows.find(row => row.no_order === noOrder) || null
}

export function upsertPurchaseOrder(order) {
  const rows = listPurchaseOrders()
  const bucket = secondBucket()
  const requestFingerprint = order.request_fingerprint || buildPurchaseOrderFingerprint(order, bucket)
  const index = rows.findIndex(row => row.no_order === order.no_order)
  const payload = {
    ...order,
    request_fingerprint: requestFingerprint,
    updated_at: new Date().toISOString(),
  }

  const duplicateIndex = rows.findIndex(row => row.request_fingerprint === requestFingerprint)

  if (index >= 0) {
    rows[index] = payload
  } else if (duplicateIndex >= 0) {
    rows[duplicateIndex] = {
      ...rows[duplicateIndex],
      ...payload,
      no_order: rows[duplicateIndex].no_order,
    }
  } else {
    rows.push({
      ...payload,
      created_at: payload.created_at || new Date().toISOString(),
    })
  }

  saveAll(rows)
  return payload
}

export function markPurchaseOrderReceived(noOrder, receivedAt = new Date().toISOString()) {
  const rows = listPurchaseOrders()
  const index = rows.findIndex(row => row.no_order === noOrder)
  if (index < 0) return null

  rows[index] = {
    ...rows[index],
    status: 'received',
    received_at: receivedAt,
    updated_at: receivedAt,
  }

  saveAll(rows)
  return rows[index]
}

export function getTermLabel(termValue) {
  if (termValue === 'lunas') return 'Lunas'
  return `${termValue} Bulan`
}
