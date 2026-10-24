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

  const modulosActivos = ref<Set<string>>(new Set())
  const moduloDePermiso = ref<Record<string, string>>({})

  function tieneModulo(clave: string) {
    return modulosActivos.value.has(clave)
  }

  // true si el rol incluye alguno de los permisos y el plan de la iglesia tiene su módulo
  function can(...claves: string[]) {
    return claves.some(c => {
      const modulo = moduloDePermiso.value[c]
      if (!modulo || !modulosActivos.value.has(modulo)) return false
      return rolInfo.value?.es_propietario === true || permisos.value.has(c)
    })
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

      // Módulos activos: los del plan más los contratados aparte
      const [{ data: delPlan }, { data: extra }, { data: catalogo }] = await Promise.all([
        supabase.from('plan_modulos').select('modulo').eq('plan', ig?.plan ?? ''),
        supabase.from('iglesia_modulos').select('modulo, activo, desde, hasta').eq('iglesia_id', data.iglesia_id),
        supabase.from('permisos').select('clave, modulo'),
      ])
      const ahora = Date.now()
      const activos = new Set<string>((delPlan ?? []).map((x: any) => x.modulo))
      for (const e of extra ?? []) {
        const vigente = e.activo && new Date(e.desde).getTime() <= ahora && (!e.hasta || new Date(e.hasta).getTime() > ahora)
        if (vigente) activos.add(e.modulo)
      }
      modulosActivos.value = activos
      moduloDePermiso.value = Object.fromEntries((catalogo ?? []).map((p: any) => [p.clave, p.modulo]))
    }
  }

  function limpiar() {
    perfil.value = null
    iglesia.value = null
    rolInfo.value = null
    permisos.value = new Set()
    modulosActivos.value = new Set()
    moduloDePermiso.value = {}
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

  return { user, perfil, iglesia, nombreIglesia, loading, isLoggedIn, iglesiaId, rol, nombreRol, nombreCompleto, can, tieneModulo, init, login, logout }
})
