import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Tipos principales
export type AlertaColor = 'verde' | 'amarillo' | 'naranja' | 'rojo'
// Los roles son datos de cada iglesia (tabla roles); la clave es un texto libre
export type Rol = string
export type NivelCompromiso = 'nuevo' | 'en_crecimiento' | 'maduro' | 'lider' | 'multiplicador'

export interface Iglesia {
  id: string
  nombre: string
  slug: string
  logo_url?: string
  color_primario: string
  color_secundario: string
  pais: string
  ciudad: string
  email_contacto?: string
  plan: string
  activa: boolean
  created_at: string
}

export interface Perfil {
  id: string
  iglesia_id: string
  nombre: string
  apellido: string
  email: string
  telefono?: string
  foto_url?: string
  rol: Rol
  activo: boolean
}

export interface Miembro {
  id: string
  iglesia_id: string
  crm_id: string
  casa_oracion_id?: string
  nombre: string
  apellido: string
  email?: string
  telefono?: string
  nivel_formacion: number
  progreso_formacion: number
  puntos: number
  racha_dias: number
  nivel_compromiso: NivelCompromiso
  tipo: string
  activo: boolean
  created_at: string
}

export interface CasaOracion {
  id: string
  iglesia_id: string
  codigo_zona: string
  nombre?: string
  lider_id?: string
  ciudad: string
  direccion: string
  dia_reunion?: string
  hora_reunion?: string
  capacidad: number
  etapa: string
  activa: boolean
}

export interface Consolidacion {
  id: string
  iglesia_id: string
  miembro_id: string
  consolidador_id?: string
  fecha_conversion: string
  fecha_limite: string
  estado_alerta: AlertaColor
  primer_contacto_fecha?: string
  segundo_contacto_fecha?: string
  tercer_contacto_fecha?: string
  resultado?: string
  completado: boolean
  notas?: string
}
