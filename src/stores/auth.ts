import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Perfil, Iglesia } from '@/lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<any>(null)
  const perfil = ref<Perfil | null>(null)
  const iglesia = ref<Iglesia | null>(null)
  const loading = ref(true)
  const permisos = ref<Set<string>>(new Set())
  const rolInfo = ref<{ nombre: string; es_propietario: boolean } | null>(null)

  // true si el rol del usuario incluye alguno de los permisos indicados
  function can(...claves: string[]) {
    if (rolInfo.value?.es_propietario) return true
    return claves.some(c => permisos.value.has(c))
  }

  const nombreRol = computed(() => rolInfo.value?.nombre ?? perfil.value?.rol ?? '')
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
      else limpiar()
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

      const { data: r } = await supabase
        .from('roles')
        .select('nombre, es_propietario, rol_permisos(permiso)')
        .eq('iglesia_id', data.iglesia_id)
        .eq('clave', data.rol)
        .maybeSingle()
      rolInfo.value = r ? { nombre: r.nombre, es_propietario: r.es_propietario } : null
      permisos.value = new Set((r?.rol_permisos ?? []).map((x: any) => x.permiso))
    }
  }

  function limpiar() {
    perfil.value = null
    iglesia.value = null
    rolInfo.value = null
    permisos.value = new Set()
  }

  async function login(email: string, password: string) {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }

  async function logout() {
    await supabase.auth.signOut()
    user.value = null
    limpiar()
  }

  return { user, perfil, iglesia, nombreIglesia, loading, isLoggedIn, iglesiaId, rol, nombreRol, nombreCompleto, can, init, login, logout }
})
