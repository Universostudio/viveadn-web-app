import { createI18n } from 'vue-i18n'
import es from './locales/es.json'
import en from './locales/en.json'
import fr from './locales/fr.json'
import ptBR from './locales/pt-BR.json'

// Idiomas disponibles con su nombre en su propia lengua (así los ve quien los busca)
export const IDIOMAS = [
  { codigo: 'es', nombre: 'Español' },
  { codigo: 'en', nombre: 'English' },
  { codigo: 'fr', nombre: 'Français' },
  { codigo: 'pt-BR', nombre: 'Português (Brasil)' },
] as const

export type CodigoIdioma = (typeof IDIOMAS)[number]['codigo']

export const IDIOMA_BASE: CodigoIdioma = 'es'
const CLAVE_GUARDADO = 'viveadn.idioma'

// Configuración regional para fechas y números de cada idioma
const REGION_INTL: Record<CodigoIdioma, string> = {
  es: 'es-ES',
  en: 'en-US',
  fr: 'fr-FR',
  'pt-BR': 'pt-BR',
}

function esIdioma(valor: unknown): valor is CodigoIdioma {
  return IDIOMAS.some(i => i.codigo === valor)
}

function leerGuardado(): CodigoIdioma | null {
  try {
    const valor = localStorage.getItem(CLAVE_GUARDADO)
    return esIdioma(valor) ? valor : null
  } catch {
    return null
  }
}

function guardar(codigo: CodigoIdioma) {
  try {
    localStorage.setItem(CLAVE_GUARDADO, codigo)
  } catch {
    // Sin almacenamiento disponible: el idioma vale solo para esta visita
  }
}

// Primer idioma del navegador que tengamos (pt-* → pt-BR, fr-* → fr, ...)
function detectarNavegador(): CodigoIdioma | null {
  if (typeof navigator === 'undefined') return null
  const preferidos = navigator.languages?.length ? navigator.languages : [navigator.language]
  for (const etiqueta of preferidos) {
    const base = (etiqueta ?? '').toLowerCase().split('-')[0]
    if (base === 'pt') return 'pt-BR'
    if (base === 'fr') return 'fr'
    if (base === 'en') return 'en'
    if (base === 'es') return 'es'
  }
  return null
}

const idiomaInicial: CodigoIdioma = leerGuardado() ?? detectarNavegador() ?? IDIOMA_BASE

// En francés el 0 y el 1 van en singular; el resto de idiomas usa la regla por defecto
function pluralFrances(cantidad: number, opciones: number) {
  const n = Math.abs(cantidad)
  if (opciones === 2) return n <= 1 ? 0 : 1
  return n === 0 ? 0 : n === 1 ? 1 : 2
}

export const i18n = createI18n({
  legacy: false,
  globalInjection: true,
  locale: idiomaInicial,
  fallbackLocale: IDIOMA_BASE,
  messages: { es, en, fr, 'pt-BR': ptBR } as Record<CodigoIdioma, typeof es>,
  pluralRules: { fr: pluralFrances },
})

export function idiomaActual(): CodigoIdioma {
  const valor = i18n.global.locale.value
  return esIdioma(valor) ? valor : IDIOMA_BASE
}

function aplicarAlDocumento(codigo: CodigoIdioma) {
  if (typeof document !== 'undefined') document.documentElement.lang = codigo
}

export function setIdioma(codigo: CodigoIdioma) {
  if (!esIdioma(codigo)) return
  i18n.global.locale.value = codigo
  aplicarAlDocumento(codigo)
  guardar(codigo)
}

// Al arrancar, <html lang> ya refleja el idioma elegido
aplicarAlDocumento(idiomaInicial)

// Región Intl del idioma activo (reactiva: dentro de computed o plantillas se actualiza sola)
export function regionActual(): string {
  return REGION_INTL[idiomaActual()]
}

export function formatoFecha(fecha: string | number | Date, opciones?: Intl.DateTimeFormatOptions): string {
  return new Date(fecha).toLocaleDateString(regionActual(), opciones)
}

export function formatoFechaHora(fecha: string | number | Date, opciones?: Intl.DateTimeFormatOptions): string {
  return new Date(fecha).toLocaleString(regionActual(), opciones)
}

export function formatoHora(fecha: string | number | Date, opciones?: Intl.DateTimeFormatOptions): string {
  return new Date(fecha).toLocaleTimeString(regionActual(), opciones)
}

export function formatoNumero(valor: number, opciones?: Intl.NumberFormatOptions): string {
  return new Intl.NumberFormat(regionActual(), opciones).format(valor)
}

export default i18n
