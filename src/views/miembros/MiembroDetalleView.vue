<template>
  <div class="p-4 sm:p-6 space-y-6">
    <!-- Back + header -->
    <div class="flex items-center gap-3">
      <RouterLink to="/miembros" class="text-gray-400 hover:text-adn-verde transition-colors text-2xl">←</RouterLink>
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Perfil del miembro</h1>
        <p class="text-gray-500 text-sm">{{ miembro?.crm_id }}</p>
      </div>
    </div>

    <div v-if="cargando" class="py-20 text-center text-gray-400">
      <p class="text-4xl mb-2">⏳</p>
      <p>Cargando perfil...</p>
    </div>

    <div v-else-if="!miembro" class="py-20 text-center text-gray-400">
      <p class="text-4xl mb-2">❓</p>
      <p>Miembro no encontrado</p>
      <RouterLink to="/miembros" class="text-adn-verde hover:underline text-sm mt-2 inline-block">
        ← Volver a miembros
      </RouterLink>
    </div>

    <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Columna principal -->
      <div class="lg:col-span-2 space-y-6">
        <!-- Tarjeta perfil -->
        <div class="card">
          <div class="flex items-start gap-4">
            <div class="w-16 h-16 bg-adn-verde rounded-2xl flex items-center justify-center flex-shrink-0">
              <span class="text-white text-2xl font-bold">{{ miembro.nombre[0] }}</span>
            </div>
            <div class="flex-1">
              <div class="flex items-start justify-between">
                <div>
                  <h2 class="text-xl font-bold text-gray-900">{{ miembro.nombre }} {{ miembro.apellido }}</h2>
                  <p class="text-sm text-gray-500 font-mono mt-0.5">{{ miembro.crm_id }}</p>
                </div>
                <span :class="['text-xs px-3 py-1 rounded-full font-medium', claseNivel(miembro.nivel_compromiso)]">
                  {{ etiquetaNivel(miembro.nivel_compromiso) }}
                </span>
              </div>
              <div class="flex flex-wrap gap-4 mt-4 text-sm text-gray-600">
                <span v-if="miembro.email">📧 {{ miembro.email }}</span>
                <span v-if="miembro.telefono">📱 {{ miembro.telefono }}</span>
                <span v-if="miembro.casas_oracion">🏘️ {{ miembro.casas_oracion.nombre }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Historial de consolidación -->
        <div class="card">
          <h3 class="font-semibold text-gray-900 mb-4">⚡ Historial de consolidación</h3>
          <div v-if="!consolidaciones.length" class="py-6 text-center text-gray-400 text-sm">
            Sin historial de consolidación
          </div>
          <div v-else class="space-y-3">
            <div
              v-for="c in consolidaciones"
              :key="c.id"
              class="flex items-center justify-between p-3 bg-gray-50 rounded-lg text-sm"
            >
              <div>
                <p class="font-medium text-gray-800">{{ formatFecha(c.fecha_conversion) }}</p>
                <p class="text-xs text-gray-500 mt-0.5" v-if="c.notas">{{ c.notas }}</p>
              </div>
              <span :class="['text-xs px-2 py-1 rounded-full font-medium', c.completado ? 'bg-green-100 text-green-700' : clasePill(c.estado_alerta)]">
                {{ c.completado ? '✓ Completado' : etiquetaAlerta(c.estado_alerta) }}
              </span>
            </div>
          </div>
        </div>

        <!-- Progreso formación -->
        <div class="card">
          <h3 class="font-semibold text-gray-900 mb-4">📚 Progreso de formación</h3>
          <div v-if="!progreso.length" class="py-6 text-center text-gray-400 text-sm">
            Sin progreso registrado aún
          </div>
          <div v-else class="space-y-4">
            <div v-for="p in progresoOrdenado" :key="p.id">
              <div class="flex items-center justify-between text-sm mb-1">
                <span class="font-medium text-gray-800">{{ etiquetaNivel(p.nivel) }}</span>
                <span class="text-gray-500">{{ p.porcentaje_completado }}%</span>
              </div>
              <div class="h-2.5 bg-gray-100 rounded-full overflow-hidden">
                <div
                  class="h-full bg-adn-verde rounded-full transition-all"
                  :style="{ width: `${p.porcentaje_completado}%` }"
                ></div>
              </div>
              <p v-if="p.completado" class="text-xs text-green-600 mt-1">
                ✓ Completado {{ formatFecha(p.fecha_completacion) }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Columna lateral -->
      <div class="space-y-6">
        <!-- Gamificación -->
        <div class="card">
          <h3 class="font-semibold text-gray-900 mb-4">🎮 Participación</h3>
          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <span class="text-sm text-gray-600">Puntos totales</span>
              <span class="font-bold text-adn-oro text-lg">{{ miembro.puntos_totales ?? 0 }}</span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-sm text-gray-600">🔥 Racha actual</span>
              <span class="font-bold text-orange-500">{{ miembro.racha_dias ?? 0 }} días</span>
            </div>
          </div>
        </div>

        <!-- Logros -->
        <div class="card">
          <h3 class="font-semibold text-gray-900 mb-3">🏆 Logros</h3>
          <div v-if="!logros.length" class="py-4 text-center text-gray-400 text-sm">
            Sin logros aún
          </div>
          <div v-else class="grid grid-cols-3 gap-2">
            <div
              v-for="l in logros"
              :key="l.id"
              class="bg-yellow-50 border border-yellow-100 rounded-xl p-2 text-center"
              :title="l.nombre"
            >
              <p class="text-2xl">{{ l.icono }}</p>
              <p class="text-xs text-gray-600 mt-1 truncate">{{ l.nombre }}</p>
            </div>
          </div>
        </div>

        <!-- Info adicional -->
        <div class="card">
          <h3 class="font-semibold text-gray-900 mb-3">ℹ️ Información</h3>
          <dl class="space-y-2 text-sm">
            <div class="flex justify-between">
              <dt class="text-gray-500">Registrado</dt>
              <dd class="text-gray-800 font-medium">{{ formatFecha(miembro.created_at) }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-gray-500">Estado</dt>
              <dd>
                <span :class="['text-xs px-2 py-0.5 rounded-full font-medium', miembro.activo ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500']">
                  {{ miembro.activo ? 'Activo' : 'Inactivo' }}
                </span>
              </dd>
            </div>
            <div v-if="miembro.casas_oracion" class="flex justify-between">
              <dt class="text-gray-500">Zona</dt>
              <dd class="text-gray-800 font-mono text-xs font-medium">{{ miembro.casas_oracion.zona_codigo }}</dd>
            </div>
          </dl>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import type { AlertaColor, NivelCompromiso } from '@/lib/supabase'

const route = useRoute()
const cargando = ref(true)
const miembro = ref<any>(null)
const consolidaciones = ref<any[]>([])
const progreso = ref<any[]>([])
const logros = ref<any[]>([])

const nivelOrden: Record<string, number> = {
  fundamentos: 0, crecimiento: 1, servicio: 2, liderazgo: 3, multiplicacion: 4
}

const progresoOrdenado = computed(() =>
  [...progreso.value].sort((a, b) => (nivelOrden[a.nivel] ?? 9) - (nivelOrden[b.nivel] ?? 9))
)

function formatFecha(fecha?: string) {
  if (!fecha) return '—'
  return new Date(fecha).toLocaleDateString('es-ES', { day: '2-digit', month: 'short', year: 'numeric' })
}

function claseNivel(nivel: NivelCompromiso) {
  const m: Record<NivelCompromiso, string> = {
    nuevo: 'bg-gray-100 text-gray-600',
    en_crecimiento: 'bg-blue-100 text-blue-700',
    maduro: 'bg-green-100 text-green-700',
    lider: 'bg-purple-100 text-purple-700',
    multiplicador: 'bg-yellow-100 text-yellow-700',
  }
  return m[nivel] ?? 'bg-gray-100 text-gray-600'
}

function etiquetaNivel(nivel: string) {
  const m: Record<string, string> = {
    nuevo: 'Nuevo', en_crecimiento: 'Crecimiento', maduro: 'Maduro',
    lider: 'Líder', multiplicador: 'Multiplicador',
    fundamentos: 'Fundamentos', crecimiento: 'Crecimiento', servicio: 'Servicio',
    liderazgo: 'Liderazgo', multiplicacion: 'Multiplicación',
  }
  return m[nivel] ?? nivel
}

function clasePill(alerta: AlertaColor) {
  const m: Record<AlertaColor, string> = {
    verde: 'bg-green-100 text-green-700',
    amarillo: 'bg-yellow-100 text-yellow-700',
    naranja: 'bg-orange-100 text-orange-700',
    rojo: 'bg-red-100 text-red-700',
  }
  return m[alerta] ?? 'bg-gray-100 text-gray-600'
}

function etiquetaAlerta(alerta: AlertaColor) {
  const m: Record<AlertaColor, string> = {
    verde: 'Normal', amarillo: 'Atención', naranja: 'Urgente', rojo: 'Crítico'
  }
  return m[alerta] ?? alerta
}

onMounted(async () => {
  const id = route.params.id as string
  const [miembroRes, consolRes, progresoRes, logrosRes] = await Promise.all([
    supabase
      .from('miembros')
      .select('*, casas_oracion(nombre, zona_codigo)')
      .eq('id', id)
      .single(),
    supabase
      .from('consolidaciones')
      .select('id, fecha_conversion, estado_alerta, completado, notas')
      .eq('miembro_id', id)
      .order('fecha_conversion', { ascending: false }),
    supabase
      .from('progreso_formacion')
      .select('*')
      .eq('miembro_id', id),
    supabase
      .from('logros')
      .select('id, nombre, icono')
      .eq('miembro_id', id),
  ])
  miembro.value = miembroRes.data
  consolidaciones.value = consolRes.data ?? []
  progreso.value = progresoRes.data ?? []
  logros.value = logrosRes.data ?? []
  cargando.value = false
})
</script>
