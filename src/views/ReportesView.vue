<template>
  <div class="p-4 sm:p-6 space-y-6">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">📊 Reportes</h1>
      <p class="text-gray-500 text-sm mt-0.5">Análisis y estadísticas del ministerio</p>
    </div>

    <!-- Selector de período -->
    <div class="card flex flex-wrap items-center gap-3">
      <span class="text-sm font-medium text-gray-700">Período:</span>
      <div class="flex gap-2">
        <button
          v-for="p in periodos"
          :key="p.valor"
          @click="periodo = p.valor"
          :class="['text-sm px-3 py-1.5 rounded-lg font-medium transition-colors',
            periodo === p.valor ? 'bg-adn-verde text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200']"
        >
          {{ p.label }}
        </button>
      </div>
    </div>

    <!-- KPIs principales -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
      <div class="card-stat">
        <span class="text-2xl">👥</span>
        <div>
          <p class="text-2xl font-bold text-gray-900">{{ kpis.totalMiembros }}</p>
          <p class="text-xs text-gray-500">Miembros activos</p>
          <p class="text-xs text-green-600 mt-0.5">+{{ kpis.nuevosMiembros }} nuevos</p>
        </div>
      </div>
      <div class="card-stat">
        <span class="text-2xl">⚡</span>
        <div>
          <p class="text-2xl font-bold text-gray-900">{{ kpis.consolidacionesCompletadas }}</p>
          <p class="text-xs text-gray-500">Consolidaciones</p>
          <p class="text-xs text-adn-verde mt-0.5">{{ kpis.tasaExito }}% tasa éxito</p>
        </div>
      </div>
      <div class="card-stat">
        <span class="text-2xl">🏘️</span>
        <div>
          <p class="text-2xl font-bold text-gray-900">{{ kpis.casasActivas }}</p>
          <p class="text-xs text-gray-500">Casas activas</p>
        </div>
      </div>
      <div class="card-stat">
        <span class="text-2xl">📚</span>
        <div>
          <p class="text-2xl font-bold text-gray-900">{{ kpis.progresoFormacion }}</p>
          <p class="text-xs text-gray-500">En formación</p>
        </div>
      </div>
    </div>

    <!-- Consolidación por estado -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div class="card">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">⚡ Consolidación 72h</h2>
        <div class="space-y-3">
          <div v-for="estado in estadosConsolidacion" :key="estado.label" class="flex items-center gap-3">
            <span class="text-lg">{{ estado.icono }}</span>
            <div class="flex-1">
              <div class="flex justify-between text-sm mb-1">
                <span class="text-gray-700">{{ estado.label }}</span>
                <span class="font-semibold">{{ estado.count }}</span>
              </div>
              <div class="h-2 bg-gray-100 rounded-full overflow-hidden">
                <div :class="['h-full rounded-full', estado.color]"
                  :style="{ width: `${totalConsolidaciones ? (estado.count / totalConsolidaciones) * 100 : 0}%` }">
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Formación por nivel -->
      <div class="card">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">📚 Alumnos por nivel</h2>
        <div class="space-y-3">
          <div v-for="nivel in nivelesFormacion" :key="nivel.clave" class="flex items-center gap-3">
            <span class="text-lg">{{ nivel.icono }}</span>
            <div class="flex-1">
              <div class="flex justify-between text-sm mb-1">
                <span class="text-gray-700">{{ nivel.nombre }}</span>
                <span class="font-semibold">{{ nivel.count }}</span>
              </div>
              <div class="h-2 bg-gray-100 rounded-full overflow-hidden">
                <div class="h-full bg-adn-verde rounded-full"
                  :style="{ width: `${maxNivel ? (nivel.count / maxNivel) * 100 : 0}%` }">
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Distribución por zona -->
    <div class="card">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">🗺️ Distribución por zona</h2>
      <div v-if="!zonas.length" class="py-8 text-center text-gray-400 text-sm">Sin datos de zonas</div>
      <div v-else class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
        <div v-for="z in zonas" :key="z.codigo" class="bg-gray-50 rounded-xl p-3 text-center">
          <p class="text-xs font-mono font-bold text-adn-verde">{{ z.codigo }}</p>
          <p class="text-xl font-bold text-gray-900 mt-1">{{ z.casas }}</p>
          <p class="text-xs text-gray-500">casas</p>
          <p class="text-xs text-gray-400 mt-0.5">{{ z.miembros }} miembros</p>
        </div>
      </div>
    </div>

    <!-- Últimas consolidaciones completadas -->
    <div class="card">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg font-semibold text-gray-900">✅ Consolidaciones completadas recientemente</h2>
      </div>
      <div v-if="!completadas.length" class="py-8 text-center text-gray-400 text-sm">
        Sin consolidaciones completadas en este período
      </div>
      <div v-else class="divide-y divide-gray-50">
        <div v-for="c in completadas" :key="c.id" class="flex items-center justify-between py-3">
          <div class="flex items-center gap-3">
            <div class="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
              <span class="text-green-600 text-sm font-bold">{{ c.miembros?.nombre?.[0] ?? '?' }}</span>
            </div>
            <div>
              <p class="text-sm font-medium text-gray-900">{{ c.miembros?.nombre }} {{ c.miembros?.apellido }}</p>
              <p class="text-xs text-gray-400">{{ formatFecha(c.fecha_conversion) }}</p>
            </div>
          </div>
          <span class="text-xs bg-green-100 text-green-700 px-2 py-1 rounded-full font-medium">✓ Completado</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '@/lib/supabase'

const periodo = ref('30')
const periodos = [
  { valor: '7', label: 'Última semana' },
  { valor: '30', label: 'Último mes' },
  { valor: '90', label: 'Trimestre' },
  { valor: '365', label: 'Este año' },
]

const kpis = ref({ totalMiembros: 0, nuevosMiembros: 0, consolidacionesCompletadas: 0, tasaExito: 0, casasActivas: 0, progresoFormacion: 0 })
const consolidacionData = ref({ verde: 0, amarillo: 0, naranja: 0, rojo: 0, completadas: 0 })
const nivelesData = ref<Record<string, number>>({})
const zonas = ref<any[]>([])
const completadas = ref<any[]>([])

const estadosConsolidacion = computed(() => [
  { label: '0-24h Normal', icono: '🟢', count: consolidacionData.value.verde, color: 'bg-green-400' },
  { label: '24-48h Atención', icono: '🟡', count: consolidacionData.value.amarillo, color: 'bg-yellow-400' },
  { label: '48-72h Urgente', icono: '🟠', count: consolidacionData.value.naranja, color: 'bg-orange-400' },
  { label: '+72h Crítico', icono: '🔴', count: consolidacionData.value.rojo, color: 'bg-red-500' },
])

const totalConsolidaciones = computed(() =>
  estadosConsolidacion.value.reduce((a, e) => a + e.count, 0)
)

const nivelesFormacion = computed(() => [
  { clave: 'fundamentos', nombre: 'Fundamentos', icono: '🌱', count: nivelesData.value['fundamentos'] ?? 0 },
  { clave: 'crecimiento', nombre: 'Crecimiento', icono: '🌿', count: nivelesData.value['crecimiento'] ?? 0 },
  { clave: 'servicio', nombre: 'Servicio', icono: '🤝', count: nivelesData.value['servicio'] ?? 0 },
  { clave: 'liderazgo', nombre: 'Liderazgo', icono: '⭐', count: nivelesData.value['liderazgo'] ?? 0 },
  { clave: 'multiplicacion', nombre: 'Multiplicación', icono: '🚀', count: nivelesData.value['multiplicacion'] ?? 0 },
])

const maxNivel = computed(() => Math.max(...nivelesFormacion.value.map(n => n.count), 1))

function formatFecha(fecha: string) {
  return new Date(fecha).toLocaleDateString('es-ES', { day: '2-digit', month: 'short', year: 'numeric' })
}

function fechaDesde() {
  const d = new Date()
  d.setDate(d.getDate() - parseInt(periodo.value))
  return d.toISOString()
}

async function cargarReportes() {
  const desde = fechaDesde()
  const [miembrosRes, miembrosNuevosRes, consolRes, consolCompRes, casasRes, formacionRes, zonasRes, completadasRes] = await Promise.all([
    supabase.from('miembros').select('*', { count: 'exact', head: true }).eq('activo', true),
    supabase.from('miembros').select('*', { count: 'exact', head: true }).gte('created_at', desde),
    supabase.from('consolidaciones').select('estado_alerta').eq('completado', false),
    supabase.from('consolidaciones').select('*', { count: 'exact', head: true }).eq('completado', true).gte('updated_at', desde),
    supabase.from('casas_oracion').select('*', { count: 'exact', head: true }).eq('activa', true),
    supabase.from('progreso_formacion').select('nivel').eq('completado', false),
    supabase.from('casas_oracion').select('zona_id, zonas(codigo), miembros(count)').eq('activa', true),
    supabase.from('consolidaciones').select('*, miembros(nombre, apellido)').eq('completado', true).gte('updated_at', desde).order('updated_at', { ascending: false }).limit(8),
  ])

  kpis.value.totalMiembros = miembrosRes.count ?? 0
  kpis.value.nuevosMiembros = miembrosNuevosRes.count ?? 0
  kpis.value.consolidacionesCompletadas = consolCompRes.count ?? 0
  kpis.value.casasActivas = casasRes.count ?? 0
  kpis.value.progresoFormacion = formacionRes.data?.length ?? 0

  const totalConsol = (consolRes.data?.length ?? 0) + (consolCompRes.count ?? 0)
  kpis.value.tasaExito = totalConsol > 0 ? Math.round(((consolCompRes.count ?? 0) / totalConsol) * 100) : 0

  // Consolidación por estado
  const cd = { verde: 0, amarillo: 0, naranja: 0, rojo: 0, completadas: consolCompRes.count ?? 0 }
  consolRes.data?.forEach((c: any) => { cd[c.estado_alerta as keyof typeof cd]++ })
  consolidacionData.value = cd

  // Formación por nivel
  const nd: Record<string, number> = {}
  formacionRes.data?.forEach((p: any) => { nd[p.nivel] = (nd[p.nivel] ?? 0) + 1 })
  nivelesData.value = nd

  // Zonas
  const zonasMap: Record<string, { casas: number; miembros: number }> = {}
  zonasRes.data?.forEach((c: any) => {
    const cod = c.zonas?.codigo ?? 'N/A'
    if (!zonasMap[cod]) zonasMap[cod] = { casas: 0, miembros: 0 }
    zonasMap[cod].casas++
    zonasMap[cod].miembros += c.miembros?.[0]?.count ?? 0
  })
  zonas.value = Object.entries(zonasMap).map(([codigo, v]) => ({ codigo, ...v }))

  completadas.value = completadasRes.data ?? []
}

watch(periodo, cargarReportes)
onMounted(cargarReportes)
</script>
