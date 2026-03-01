import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const profile = ref(null)
  const initialized = ref(false)
  const loading = ref(false)

  const userRole = computed(() => profile.value?.role ?? null)
  const displayName = computed(() => profile.value?.nama ?? user.value?.email ?? '')

  async function init() {
    try {
      const { data: { session } } = await supabase.auth.getSession()
      user.value = session?.user ?? null
      if (user.value) await fetchProfile()
    } catch (err) {
      console.warn('[auth] init error:', err.message)
    } finally {
      initialized.value = true
    }

    supabase.auth.onAuthStateChange(async (_event, session) => {
      user.value = session?.user ?? null
      if (user.value) await fetchProfile()
      else profile.value = null
    })
  }

  async function fetchProfile() {
    if (!user.value) return
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.value.id)
        .maybeSingle()          // maybeSingle: tidak lempar 406 jika 0 baris
      if (!error && data) profile.value = data
      else if (error) console.warn('[auth] fetchProfile:', error.message)
    } catch (err) {
      console.warn('[auth] fetchProfile error:', err.message)
    }
  }

  async function login(email, password) {
    loading.value = true
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    loading.value = false
    if (error) throw error
    user.value = data.user
    await fetchProfile()
  }

  async function logout() {
    await supabase.auth.signOut()
    user.value = null
    profile.value = null
  }

  return { user, profile, initialized, loading, userRole, displayName, init, login, logout, fetchProfile }
})
