import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Perfil, Iglesia } from '@/lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<any>(null)
  const perfil = ref<Perfil | null>(null)
  const iglesia = ref<Iglesia | null>(null)
  const loading = ref(true)

  const isLoggedIn = computed(() => !!user.value)
  const iglesiaId = computed(() => perfil.value?.iglesia_id)
  const rol = computed(() => perfil.value?.rol)
  const nombreIglesia = computed(() => iglesia.value?.nombre ?? '')
  const nombreCompleto = computed(() =>
    perfil.value ? `${perfil.value.nombre} ${perfil.value.apellido}` : ''
  )

  async function init() {
    loading.value = true
    const { data: { session } } = await supabase.auth.getSession()
    user.value = session?.user ?? null
    if (user.value) await cargarPerfil()
    loading.value = false

    supabase.auth.onAuthStateChange(async (_event, session) => {
      user.value = session?.user ?? null
      if (user.value) await cargarPerfil()
      else { perfil.value = null; iglesia.value = null }
    })
  }

  async function cargarPerfil() {
    if (!user.value) return
    const { data } = await supabase
      .from('perfiles')
      .select('*')
      .eq('id', user.value.id)
      .single()
    perfil.value = data
    if (data?.iglesia_id) {
      const { data: ig } = await supabase
        .from('iglesias')
        .select('*')
        .eq('id', data.iglesia_id)
        .single()
      iglesia.value = ig
    }
  }

  async function login(email: string, password: string) {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }

  async function logout() {
    await supabase.auth.signOut()
    user.value = null
    perfil.value = null
    iglesia.value = null
  }

  return { user, perfil, iglesia, nombreIglesia, loading, isLoggedIn, iglesiaId, rol, nombreCompleto, init, login, logout }
})
