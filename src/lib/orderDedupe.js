function stableStringify(value) {
  if (value === null || value === undefined) return 'null'
  if (typeof value !== 'object') return JSON.stringify(value)

  if (Array.isArray(value)) {
    return `[${value.map(stableStringify).join(',')}]`
  }

  const keys = Object.keys(value).sort()
  const body = keys
    .map(key => `${JSON.stringify(key)}:${stableStringify(value[key])}`)
    .join(',')
  return `{${body}}`
}

function hashFnv1a(input) {
  let hash = 0x811c9dc5
  for (let i = 0; i < input.length; i += 1) {
    hash ^= input.charCodeAt(i)
    hash = Math.imul(hash, 0x01000193)
  }
  return (hash >>> 0).toString(16).padStart(8, '0')
}

export function secondBucket(value = new Date()) {
  const date = value instanceof Date ? value : new Date(value)
  return date.toISOString().slice(0, 19)
}

export function buildDedupeKey(prefix, payload, bucket = secondBucket()) {
  const signature = stableStringify(payload)
  const hash = hashFnv1a(signature)
  return `${prefix}_${bucket}_${hash}`
}

export function buildPurchaseOrderFingerprint(order, bucket = secondBucket()) {
  const normalizedItems = (order.items || [])
    .map(item => ({
      product_id: item.product_id ?? null,
      product_kode: item.product_kode ?? null,
      qty: Number(item.qty || 0),
      unit_cost: Number(item.unit_cost || 0),
      total: Number(item.total || 0),
    }))
    .sort((a, b) => String(a.product_id).localeCompare(String(b.product_id)))

  return buildDedupeKey('PO', {
    order_date: order.order_date || null,
    supplier_id: order.supplier?.id ?? null,
    supplier_nama: order.supplier?.nama ?? null,
    terms: order.terms || null,
    subtotal: Number(order.subtotal || 0),
    status: order.status || 'ordered',
    items: normalizedItems,
  }, bucket)
}

export function buildSalesDraftFingerprint(payload, bucket = secondBucket()) {
  return buildDedupeKey('SO_DRAFT', {
    order_date: payload.order_date || null,
    customer_id: payload.customer_id || null,
    diantar: Boolean(payload.diantar),
    limit_bulan: Number(payload.limit_bulan || 0),
    salesman: payload.salesman || 'A',
    subtotal: Number(payload.subtotal || 0),
    status: payload.status || 'draft',
  }, bucket)
}
