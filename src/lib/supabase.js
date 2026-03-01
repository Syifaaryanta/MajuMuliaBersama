import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('[Supabase] VITE_SUPABASE_URL atau VITE_SUPABASE_ANON_KEY belum diisi di .env')
}

export const supabase = createClient(supabaseUrl ?? '', supabaseAnonKey ?? '')
