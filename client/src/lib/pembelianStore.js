import { supabase } from '@/lib/supabase'
import { buildPurchaseOrderFingerprint } from '@/lib/orderDedupe'

export function getPurchaseReceivingItemKey(item, index = 0) {
  const productId = String(item?.product_id ?? '')
  const productKode = String(item?.product_kode ?? '')
  const productNama = String(item?.product_nama ?? '')
  const unitCost = Number(item?.unit_cost || 0)
  return `${productId}|${productKode}|${productNama}|${unitCost}|${index}`
}

function toIsoDate(value) {
  const raw = String(value || '').trim()
  if (!raw) return null

  const match = raw.match(/^(\d{4}-\d{2}-\d{2})/)
  if (match?.[1]) return match[1]

  const date = new Date(raw)
  if (Number.isNaN(date.getTime())) return null
  return date.toISOString().slice(0, 10)
}

function toNumber(value, fallback = 0) {
  const num = Number(value)
  return Number.isFinite(num) ? num : fallback
}

function normalizePurchaseItems(items = []) {
  const rows = Array.isArray(items) ? items : []
  return rows.map((item, idx) => {
    const qty = toNumber(item?.qty, 0)
    const unitCost = toNumber(item?.unit_cost, 0)
    const total = toNumber(item?.total, qty * unitCost)
    return {
      product_id: item?.product_id || null,
      product_kode: String(item?.product_kode || ''),
      product_nama: String(item?.product_nama || '-'),
      qty,
      unit_cost: unitCost,
      total,
      receiving_key: item?.receiving_key || getPurchaseReceivingItemKey(item, idx),
    }
  })
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

function mapPurchaseRowToOrder(row, purchaseItems = []) {
  const supplier = {
    id: row?.supplier_id || null,
    nama: row?.supplier_nama || '',
    alamat: row?.supplier_alamat || '',
  }

  return {
    id: row?.id || null,
    no_order: row?.no_order || '',
    order_date: row?.order_date || null,
    no_faktur: row?.no_faktur || null,
    supplier,
    supplier_id: supplier.id,
    supplier_nama: supplier.nama,
    supplier_alamat: supplier.alamat,
    terms: row?.terms != null ? String(row.terms) : 'tunai',
    items: normalizePurchaseItems(purchaseItems),
    subtotal: toNumber(row?.subtotal, 0),
    status: row?.status || 'ordered',
    received_at: row?.received_at || null,
    receiving_validations: row?.receiving_validations || {},
    receiving_validated_at: row?.receiving_validated_at || {},
    request_fingerprint: row?.request_fingerprint || null,
    created_at: row?.created_at || null,
    updated_at: row?.updated_at || null,
  }
}

async function getPurchaseItemsByIds(purchaseIds = []) {
  const ids = (purchaseIds || []).filter(Boolean)
  if (!ids.length) return []

  const { data, error } = await supabase
    .from('purchase_items')
    .select('purchase_id, product_id, product_kode, product_nama, qty, unit_cost, total, receiving_key')
    .in('purchase_id', ids)

  if (error) throw error
  return data || []
}

function mergePurchasesWithItems(purchases = [], purchaseItems = []) {
  const itemsByPurchaseId = (purchaseItems || []).reduce((acc, item) => {
    if (!acc[item.purchase_id]) acc[item.purchase_id] = []
    acc[item.purchase_id].push(item)
    return acc
  }, {})

  return (purchases || []).map(row => mapPurchaseRowToOrder(row, itemsByPurchaseId[row.id] || []))
}

export async function listPurchaseOrders() {
  const { data: purchases, error: purchasesError } = await supabase
    .from('purchases')
    .select([
      'id',
      'no_order',
      'order_date',
      'no_faktur',
      'supplier_id',
      'supplier_nama',
      'supplier_alamat',
      'terms',
      'subtotal',
      'status',
      'received_at',
      'receiving_validations',
      'receiving_validated_at',
      'request_fingerprint',
      'created_at',
      'updated_at',
    ].join(', '))
    .order('updated_at', { ascending: false })

  if (purchasesError) throw purchasesError

  const rows = purchases || []
  const purchaseItems = await getPurchaseItemsByIds(rows.map(row => row.id))
  return mergePurchasesWithItems(rows, purchaseItems)
}

export async function getPurchaseOrderByNo(noOrder) {
  const targetNo = String(noOrder || '').trim()
  if (!targetNo) return null

  const { data: purchaseRow, error: purchaseError } = await supabase
    .from('purchases')
    .select([
      'id',
      'no_order',
      'order_date',
      'no_faktur',
      'supplier_id',
      'supplier_nama',
      'supplier_alamat',
      'terms',
      'subtotal',
      'status',
      'received_at',
      'receiving_validations',
      'receiving_validated_at',
      'request_fingerprint',
      'created_at',
      'updated_at',
    ].join(', '))
    .eq('no_order', targetNo)
    .order('updated_at', { ascending: false })
    .limit(1)
    .maybeSingle()

  if (purchaseError) throw purchaseError
  if (!purchaseRow) return null

  const { data: purchaseItems, error: itemsError } = await supabase
    .from('purchase_items')
    .select('purchase_id, product_id, product_kode, product_nama, qty, unit_cost, total, receiving_key')
    .eq('purchase_id', purchaseRow.id)

  if (itemsError) throw itemsError

  return mapPurchaseRowToOrder(purchaseRow, purchaseItems || [])
}

export async function generatePurchaseOrderNo() {
  const year = new Date().getFullYear().toString().slice(-2)
  const prefix = `PO${year}`

  const { data, error } = await supabase
    .from('purchases')
    .select('no_order')
    .like('no_order', `${prefix}%`)

  if (error) throw error

  const nums = (data || [])
    .map(row => String(row.no_order || ''))
    .filter(no => no.startsWith(prefix))
    .map(no => no.slice(prefix.length))
    .filter(suffix => /^\d{3}$/.test(suffix))
    .map(suffix => parseInt(suffix, 10))
    .filter(n => Number.isFinite(n))

  const next = (nums.length ? Math.max(...nums) : 0) + 1
  return `${prefix}${String(next).padStart(3, '0')}`
}

export async function upsertPurchaseOrder(order) {
  if (!order?.no_order) {
    throw new Error('No. Order wajib diisi sebelum menyimpan data pembelian.')
  }

  const now = new Date().toISOString()
  const normalizedItems = normalizePurchaseItems(order.items || [])
  const subtotal = toNumber(
    order?.subtotal,
    normalizedItems.reduce((sum, item) => sum + toNumber(item.total, 0), 0)
  )
  const requestFingerprint =
    order?.request_fingerprint || buildPurchaseOrderFingerprint({
      ...order,
      items: normalizedItems,
      subtotal,
    })

  const receivingValidations = normalizeReceivingValidations(
    normalizedItems,
    order?.receiving_validations || {}
  )

  const sourceValidatedAt = order?.receiving_validated_at || {}
  const receivingValidatedAt = {}
  normalizedItems.forEach((item, idx) => {
    const key = item.receiving_key || getPurchaseReceivingItemKey(item, idx)
    if (!receivingValidations[key]) return
    receivingValidatedAt[key] = sourceValidatedAt[key] || item.received_at || order?.received_at || now
  })

  const normalizedStatus = ['draft', 'ordered', 'received'].includes(String(order?.status || ''))
    ? String(order.status)
    : 'ordered'

  const payload = {
    no_order: String(order.no_order).trim(),
    order_date: toIsoDate(order?.order_date) || toIsoDate(now),
    no_faktur: order?.no_faktur || order?.faktur || null,
    supplier_id: order?.supplier?.id || order?.supplier_id || null,
    supplier_nama: order?.supplier?.nama || order?.supplier_nama || null,
    supplier_alamat: order?.supplier?.alamat || order?.supplier_alamat || null,
    terms: order?.terms != null ? String(order.terms) : null,
    subtotal,
    status: normalizedStatus,
    received_at: normalizedStatus === 'received' ? (order?.received_at || now) : null,
    receiving_validations: receivingValidations,
    receiving_validated_at: receivingValidatedAt,
    request_fingerprint: requestFingerprint,
  }

  const selectColumns = [
    'id',
    'no_order',
    'order_date',
    'no_faktur',
    'supplier_id',
    'supplier_nama',
    'supplier_alamat',
    'terms',
    'subtotal',
    'status',
    'received_at',
    'receiving_validations',
    'receiving_validated_at',
    'request_fingerprint',
    'created_at',
    'updated_at',
  ].join(', ')

  let upsertedPurchase = null

  const upsertAttempt = await supabase
    .from('purchases')
    .upsert(payload, { onConflict: 'no_order' })
    .select(selectColumns)
    .single()

  if (!upsertAttempt.error) {
    upsertedPurchase = upsertAttempt.data
  } else if (String(upsertAttempt.error.code || '') === '42P10') {
    const existing = await supabase
      .from('purchases')
      .select('id')
      .eq('no_order', payload.no_order)
      .order('updated_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (existing.error) throw existing.error

    if (existing.data?.id) {
      const updateAttempt = await supabase
        .from('purchases')
        .update(payload)
        .eq('id', existing.data.id)
        .select(selectColumns)
        .single()

      if (updateAttempt.error) throw updateAttempt.error
      upsertedPurchase = updateAttempt.data
    } else {
      const insertAttempt = await supabase
        .from('purchases')
        .insert(payload)
        .select(selectColumns)
        .single()

      if (insertAttempt.error) throw insertAttempt.error
      upsertedPurchase = insertAttempt.data
    }
  } else {
    throw upsertAttempt.error
  }

  const purchaseId = upsertedPurchase?.id
  if (!purchaseId) return null

  const { error: clearItemsError } = await supabase
    .from('purchase_items')
    .delete()
    .eq('purchase_id', purchaseId)

  if (clearItemsError) throw clearItemsError

  if (normalizedItems.length > 0) {
    const itemPayload = normalizedItems.map(item => ({
      purchase_id: purchaseId,
      product_id: item.product_id,
      product_kode: item.product_kode,
      product_nama: item.product_nama,
      qty: item.qty,
      unit_cost: item.unit_cost,
      total: item.total,
      receiving_key: item.receiving_key,
    }))

    const { error: insertItemsError } = await supabase
      .from('purchase_items')
      .insert(itemPayload)

    if (insertItemsError) throw insertItemsError
  }

  return mapPurchaseRowToOrder(upsertedPurchase, normalizedItems)
}

export async function markPurchaseOrderReceived(noOrder, receivedAt = new Date().toISOString()) {
  const order = await getPurchaseOrderByNo(noOrder)
  if (!order) return null

  const validations = normalizeReceivingValidations(order.items || [], order.receiving_validations || {})
  const validatedAt = {}

  Object.keys(validations).forEach(key => {
    validations[key] = true
    validatedAt[key] = receivedAt
  })

  return upsertPurchaseOrder({
    ...order,
    status: 'received',
    received_at: receivedAt,
    receiving_validations: validations,
    receiving_validated_at: validatedAt,
  })
}

export async function removePurchaseOrder(noOrder) {
  const targetNo = String(noOrder || '').trim()
  if (!targetNo) return false

  const { data, error } = await supabase
    .from('purchases')
    .delete()
    .eq('no_order', targetNo)
    .select('id')

  if (error) throw error
  return Array.isArray(data) && data.length > 0
}

export function getTermLabel(termValue) {
  if (termValue === 'tunai' || termValue === 'lunas') return 'Tunai'
  return `${termValue} Bulan`
}
