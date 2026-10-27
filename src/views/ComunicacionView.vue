<template>
  <div class="p-4 sm:p-6 space-y-6">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">{{ t('comunicacion.titulo') }}</h1>
      <p class="text-gray-500 text-sm mt-0.5">{{ t('comunicacion.subtitulo') }}</p>
    </div>

    <!-- Aviso honesto: todavía no hay ningún canal conectado -->
    <div class="flex items-start gap-3 bg-amber-50 border border-amber-200 text-amber-900 rounded-xl px-4 py-3 text-sm">
      <Info class="w-5 h-5 flex-shrink-0 mt-0.5" aria-hidden="true" />
      <p>{{ t('comunicacion.aviso') }}</p>
    </div>

    <!-- Canales -->
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
      <div
        v-for="canal in canales"
        :key="canal.id"
        @click="mensaje.canal = canal.id"
        :class="['card cursor-pointer transition-all hover:shadow-md', mensaje.canal === canal.id ? 'ring-2 ring-adn-verde' : '']"
      >
        <div class="flex items-center gap-3 mb-2">
          <div class="w-10 h-10 rounded-lg bg-adn-verde/10 flex items-center justify-center flex-shrink-0">
            <component :is="canal.icono" class="w-5 h-5 text-adn-verde" aria-hidden="true" />
          </div>
          <div>
            <p class="font-semibold text-gray-900">{{ t(`comunicacion.canales.${canal.id}.nombre`) }}</p>
            <p class="text-xs text-gray-500">{{ t(`comunicacion.canales.${canal.id}.descripcion`) }}</p>
          </div>
        </div>
        <p class="text-xs font-medium px-2 py-1 rounded-full inline-flex items-center gap-1 bg-gray-100 text-gray-600">
          <CircleDashed class="w-3.5 h-3.5" aria-hidden="true" /> {{ t('comunicacion.pendienteConectar') }}
        </p>
      </div>
    </div>

    <!-- Composición de mensaje -->
    <div class="card">
      <h2 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
        <PenLine class="w-5 h-5 text-adn-verde" aria-hidden="true" /> {{ t('comunicacion.nuevoMensaje') }}
      </h2>

      <div class="space-y-4">
        <!-- Destinatarios -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">{{ t('comunicacion.destinatarios') }}</label>
          <div class="flex gap-2 flex-wrap mb-2">
            <button
              v-for="seg in segmentos"
              :key="seg.valor"
              @click="mensaje.segmento = seg.valor"
              :class="['text-xs px-3 py-1.5 rounded-full border transition-colors inline-flex items-center gap-1.5',
                mensaje.segmento === seg.valor ? 'border-adn-verde bg-adn-verde/10 text-adn-verde font-medium' : 'border-gray-200 text-gray-600 hover:border-gray-300']"
            >
              <component :is="seg.icono" class="w-3.5 h-3.5" aria-hidden="true" />
              {{ t(`comunicacion.segmentos.${seg.valor}`) }}
            </button>
          </div>
          <p v-if="mensaje.segmento === 'todos'" class="text-xs text-gray-400">
            {{ t('comunicacion.miembrosActivos') }} <span class="font-semibold text-gray-700">{{ totalMiembros }}</span>
          </p>
          <p v-else class="text-xs text-gray-400">{{ t('comunicacion.numeroExacto') }}</p>
        </div>

        <!-- Mensaje -->
        <div>
          <div class="flex items-center justify-between mb-1 gap-2 flex-wrap">
            <label class="block text-sm font-medium text-gray-700">{{ t('comunicacion.mensaje') }}</label>
            <div class="flex gap-3">
              <button
                v-for="p in plantillas"
                :key="p"
                @click="mensaje.texto = textoPlantilla(p)"
                class="text-xs text-adn-verde hover:underline"
              >
                {{ t(`comunicacion.plantillas.${p}.nombre`) }}
              </button>
            </div>
          </div>
          <textarea
            v-model="mensaje.texto"
            rows="5"
            :placeholder="placeholderMensaje"
            class="w-full px-3 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-adn-verde text-sm resize-none"
          ></textarea>
          <p class="text-xs text-gray-400 mt-1">
            {{ t('comunicacion.caracteres', mensaje.texto.length) }}
            <span v-if="mensaje.canal === 'whatsapp'"> · {{ t('comunicacion.limiteWhatsapp') }}</span>
            <span v-if="mensaje.canal === 'push'"> · {{ t('comunicacion.recomendadoPush') }}</span>
          </p>
        </div>

        <!-- Acciones -->
        <div class="flex items-center justify-end gap-3 pt-2 flex-wrap">
          <button @click="previsualizar = true" :disabled="!mensaje.texto.trim()" class="btn-secondary text-sm inline-flex items-center gap-2 disabled:opacity-50">
            <Eye class="w-4 h-4" aria-hidden="true" /> {{ t('comunicacion.vistaPrevia') }}
          </button>
          <button
            disabled
            :title="t('comunicacion.disponibleAlConectar')"
            class="btn-primary text-sm inline-flex items-center gap-2 opacity-50 cursor-not-allowed"
          >
            <Send class="w-4 h-4" aria-hidden="true" /> {{ t('comunicacion.enviar') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Historial -->
    <div class="card">
      <h2 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
        <History class="w-5 h-5 text-adn-verde" aria-hidden="true" /> {{ t('comunicacion.historial') }}
      </h2>
      <div class="py-8 text-center text-gray-400">
        <Inbox class="w-10 h-10 mx-auto mb-2 text-gray-300" aria-hidden="true" />
        <p class="text-sm">{{ t('comunicacion.sinEnvios') }}</p>
      </div>
    </div>

    <!-- Modal: Vista previa -->
    <div
      v-if="previsualizar"
      class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center p-4 z-50"
      @click.self="previsualizar = false"
    >
      <div class="bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-lg font-bold text-gray-900">{{ t('comunicacion.vistaPrevia') }}</h2>
          <button @click="previsualizar = false" class="text-gray-400 hover:text-gray-600" :aria-label="t('comun.cerrar')">
            <X class="w-5 h-5" aria-hidden="true" />
          </button>
        </div>

        <div v-if="mensaje.canal === 'whatsapp'" class="bg-[#ECE5DD] rounded-xl p-4">
          <div class="bg-white rounded-xl rounded-tl-none px-4 py-3 shadow-sm max-w-xs ml-auto">
            <p class="text-sm text-gray-800 whitespace-pre-wrap">{{ mensajePersonalizado }}</p>
            <p class="text-xs text-gray-400 text-right mt-1 inline-flex items-center gap-1 w-full justify-end">
              {{ horaActual }} <CheckCheck class="w-3.5 h-3.5" aria-hidden="true" />
            </p>
          </div>
        </div>

        <div v-else class="border border-gray-200 rounded-xl p-4">
          <p class="text-xs text-gray-400 mb-2">{{ t('comunicacion.para', { correo: t('comunicacion.correoEjemplo') }) }}</p>
          <p class="text-xs text-gray-400 mb-3">{{ t('comunicacion.asunto', { iglesia: auth.nombreIglesia || t('comunicacion.tuIglesia') }) }}</p>
          <p class="text-sm text-gray-800 whitespace-pre-wrap">{{ mensajePersonalizado }}</p>
        </div>

        <p class="text-xs text-gray-400 text-center mt-3">{{ t('comunicacion.datosEjemplo') }}</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import {
  Info, MessageCircle, Mail, Bell, CircleDashed, PenLine, Users, Sprout, Star, HeartHandshake,
  Eye, Send, History, Inbox, X, CheckCheck,
} from '@lucide/vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useI18n } from 'vue-i18n'
import { formatoHora } from '@/i18n'

const auth = useAuthStore()
const { t } = useI18n()

const previsualizar = ref(false)
const totalMiembros = ref(0)

const mensaje = ref({ canal: 'whatsapp', segmento: 'todos', texto: '' })

// Nombre y descripción de cada canal: comunicacion.canales.<id> en src/i18n
const canales = [
  { id: 'whatsapp', icono: MessageCircle },
  { id: 'email', icono: Mail },
  { id: 'push', icono: Bell },
]

// Etiqueta de cada segmento: comunicacion.segmentos.<valor> en src/i18n
const segmentos = [
  { valor: 'todos', icono: Users },
  { valor: 'nuevos', icono: Sprout },
  { valor: 'lideres', icono: Star },
  { valor: 'consolidacion', icono: HeartHandshake },
]

// Plantillas rápidas del redactor (comunicacion.plantillas.<id> en src/i18n).
// Las variables {{nombre}}, {{dia}} e {{iglesia}} son códigos fijos: no se traducen.
const plantillas = ['bienvenida', 'recordatorio', 'evento']
const VARIABLES = { nombre: '{{nombre}}', dia: '{{dia}}', iglesia: '{{iglesia}}' }

function textoPlantilla(id: string) {
  return t(`comunicacion.plantillas.${id}.texto`, { ...VARIABLES })
}

const placeholderMensaje = computed(() => {
  if (mensaje.value.canal === 'whatsapp') return t('comunicacion.placeholder.whatsapp', { variable: VARIABLES.nombre })
  if (mensaje.value.canal === 'email') return t('comunicacion.placeholder.email')
  return t('comunicacion.placeholder.push')
})

const mensajePersonalizado = computed(() =>
  mensaje.value.texto
    .replace(/\{\{nombre\}\}/g, t('comunicacion.ejemploNombre'))
    .replace(/\{\{dia\}\}/g, t('comunicacion.ejemploDia'))
    .replace(/\{\{iglesia\}\}/g, auth.nombreIglesia || t('comunicacion.tuIglesia')),
)

const horaActual = computed(() => formatoHora(new Date(), { hour: '2-digit', minute: '2-digit' }))

onMounted(async () => {
  const { count } = await supabase.from('miembros').select('*', { count: 'exact', head: true }).eq('activo', true)
  totalMiembros.value = count ?? 0
})
</script>
