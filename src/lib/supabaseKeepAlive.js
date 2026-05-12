import { supabase } from './supabase'

const DEFAULT_INTERVAL_MS = 24 * 60 * 60 * 1000

async function pingSupabase() {
  if (!supabase) return
  try {
    await supabase
      .from('products')
      .select('id', { count: 'exact', head: true })
      .limit(1)
  } catch (error) {
    const message = error?.message || String(error)
    console.warn('[Supabase] keep-alive ping failed:', message)
  }
}

export function startSupabaseKeepAlive(intervalMs = DEFAULT_INTERVAL_MS) {
  if (typeof window === 'undefined') return
  pingSupabase()
  window.setInterval(pingSupabase, intervalMs)
}
