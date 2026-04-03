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

export function getPurchaseReceivingItemKey(item, index = 0) {
  const productId = String(item?.product_id ?? '')
  const productKode = String(item?.product_kode ?? '')
  const productNama = String(item?.product_nama ?? '')
  const unitCost = Number(item?.unit_cost || 0)
  return `${productId}|${productKode}|${productNama}|${unitCost}|${index}`
}

function normalizeReceivingValidations(items, sourceMap = {}) {
  const normalized = {}
  const rows = Array.isArray(items) ? items : []
  const prev = sourceMap && typeof sourceMap === 'object' ? sourceMap : {}

  rows.forEach((item, idx) => {
    const key = getPurchaseReceivingItemKey(item, idx)
    normalized[key] = Boolean(prev[key])
  })

  return normalized
}

export function isPurchaseOrderFullyValidated(order) {
  const rows = Array.isArray(order?.items) ? order.items : []
  if (!rows.length) return false

  const validations = normalizeReceivingValidations(rows, order?.receiving_validations || {})
  return Object.values(validations).every(Boolean)
}

export function generatePurchaseOrderNo() {
  const year = new Date().getFullYear().toString().slice(-2)
  const prefix = `PO${year}`
  const rows = listPurchaseOrders()
  const nums = rows
    .map(row => String(row.no_order || ''))
    .filter(no => no.startsWith(prefix))
    .map(no => no.slice(prefix.length))
    .filter(suffix => /^\d{3}$/.test(suffix))
    .map(suffix => parseInt(suffix, 10))
    .filter(n => Number.isFinite(n))

  const next = (nums.length ? Math.max(...nums) : 0) + 1
  return `${prefix}${String(next).padStart(3, '0')}`
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
  const duplicateIndex = rows.findIndex(row => row.request_fingerprint === requestFingerprint)
  const existingRow = index >= 0 ? rows[index] : (duplicateIndex >= 0 ? rows[duplicateIndex] : null)
  const receivingValidations = normalizeReceivingValidations(
    order.items || [],
    order.receiving_validations || existingRow?.receiving_validations || {}
  )
  const payload = {
    ...order,
    receiving_validations: receivingValidations,
    request_fingerprint: requestFingerprint,
    updated_at: new Date().toISOString(),
  }

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

  const validations = normalizeReceivingValidations(
    rows[index].items || [],
    rows[index].receiving_validations || {}
  )

  Object.keys(validations).forEach(key => {
    validations[key] = true
  })

  rows[index] = {
    ...rows[index],
    status: 'received',
    receiving_validations: validations,
    received_at: receivedAt,
    updated_at: receivedAt,
  }

  saveAll(rows)
  return rows[index]
}

export function removePurchaseOrder(noOrder) {
  const rows = listPurchaseOrders()
  const nextRows = rows.filter(row => row.no_order !== noOrder)
  if (nextRows.length === rows.length) return false
  saveAll(nextRows)
  return true
}

export function getTermLabel(termValue) {
  if (termValue === 'tunai' || termValue === 'lunas') return 'Tunai'
  return `${termValue} Bulan`
}
