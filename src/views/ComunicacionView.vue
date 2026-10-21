<template>
  <div class="p-4 sm:p-6 space-y-6">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">💬 Comunicación</h1>
      <p class="text-gray-500 text-sm mt-0.5">WhatsApp, email y notificaciones push</p>
    </div>

    <!-- Canales disponibles -->
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
      <div
        v-for="canal in canales"
        :key="canal.id"
        @click="canalActivo = canal.id"
        :class="['card cursor-pointer transition-all hover:shadow-md', canalActivo === canal.id ? 'ring-2 ring-adn-verde' : '']"
      >
        <div class="flex items-center gap-3 mb-2">
          <span class="text-3xl">{{ canal.icono }}</span>
          <div>
            <p class="font-semibold text-gray-900">{{ canal.nombre }}</p>
            <p class="text-xs text-gray-500">{{ canal.descripcion }}</p>
          </div>
        </div>
        <p :class="['text-xs font-medium px-2 py-1 rounded-full inline-block', canal.activo ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500']">
          {{ canal.activo ? '● Configurado' : '○ Sin configurar' }}
        </p>
      </div>
    </div>

    <!-- Composición de mensaje -->
    <div class="card">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">✉️ Nuevo mensaje</h2>

      <div class="space-y-4">
        <!-- Canal -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Canal de envío</label>
          <div class="flex gap-2">
            <button
              v-for="c in canales.filter(c => c.activo)"
              :key="c.id"
              @click="mensaje.canal = c.id"
              :class="['text-sm px-3 py-2 rounded-lg border font-medium transition-colors',
                mensaje.canal === c.id ? 'border-adn-verde bg-adn-verde text-white' : 'border-gray-200 text-gray-600 hover:border-adn-verde']"
            >
              {{ c.icono }} {{ c.nombre }}
            </button>
          </div>
        </div>

        <!-- Destinatarios -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Destinatarios</label>
          <div class="flex gap-2 flex-wrap mb-2">
            <button
              v-for="seg in segmentos"
              :key="seg.valor"
              @click="mensaje.segmento = seg.valor"
              :class="['text-xs px-3 py-1.5 rounded-full border transition-colors',
                mensaje.segmento === seg.valor ? 'border-adn-verde bg-adn-verde/10 text-adn-verde font-medium' : 'border-gray-200 text-gray-600 hover:border-gray-300']"
            >
              {{ seg.label }}
            </button>
          </div>
          <p class="text-xs text-gray-400">
            Destinatarios estimados: <span class="font-semibold text-gray-700">{{ destinatariosEstimados }}</span>
          </p>
        </div>

        <!-- Mensaje -->
        <div>
          <div class="flex items-center justify-between mb-1">
            <label class="block text-sm font-medium text-gray-700">Mensaje</label>
            <div class="flex gap-2">
              <button
                v-for="t in plantillas"
                :key="t.id"
                @click="aplicarPlantilla(t)"
                class="text-xs text-adn-verde hover:underline"
              >
                {{ t.nombre }}
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
            {{ mensaje.texto.length }} caracteres
            <span v-if="mensaje.canal === 'whatsapp'"> · WhatsApp: máx. 4096 chars</span>
          </p>
        </div>

        <!-- Acciones -->
        <div class="flex items-center justify-between pt-2">
          <button @click="programar = !programar" class="text-sm text-gray-500 hover:text-adn-verde transition-colors">
            🕐 Programar envío
          </button>
          <div class="flex gap-3">
            <button @click="previsualizar = true" class="btn-secondary text-sm">
              👁 Previsualizar
            </button>
            <button
              :disabled="!puedeEnviar"
              @click="enviarMensaje"
              class="btn-primary text-sm disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {{ enviando ? 'Enviando...' : `📤 Enviar a ${destinatariosEstimados}` }}
            </button>
          </div>
        </div>

        <!-- Programación -->
        <div v-if="programar" class="bg-adn-arena rounded-xl p-4 flex items-center gap-4">
          <span class="text-2xl">🕐</span>
          <div class="flex-1">
            <p class="text-sm font-medium text-gray-700 mb-1">Programar envío para:</p>
            <input
              v-model="mensaje.fechaProgramada"
              type="datetime-local"
              class="text-sm border border-gray-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-adn-verde"
            />
          </div>
          <button @click="programar = false" class="text-gray-400 hover:text-gray-600">×</button>
        </div>
      </div>
    </div>

    <!-- Historial de envíos -->
    <div class="card">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">📋 Historial de mensajes</h2>
      <div class="space-y-3">
        <div
          v-for="h in historial"
          :key="h.id"
          class="flex items-start gap-3 p-3 bg-gray-50 rounded-xl"
        >
          <span class="text-xl flex-shrink-0">{{ h.icono }}</span>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-gray-900 truncate">{{ h.texto }}</p>
            <p class="text-xs text-gray-400 mt-0.5">{{ h.fecha }} · {{ h.destinatarios }} destinatarios</p>
          </div>
          <span :class="['text-xs px-2 py-1 rounded-full font-medium flex-shrink-0', h.claseEstado]">
            {{ h.estado }}
          </span>
        </div>
      </div>
      <p class="text-center text-xs text-gray-400 mt-4">
        El historial completo estará disponible cuando se integre WhatsApp Business API
      </p>
    </div>

    <!-- Modal: Previsualizar -->
    <div
      v-if="previsualizar"
      class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center p-4 z-50"
      @click.self="previsualizar = false"
    >
      <div class="bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-lg font-bold text-gray-900">Previsualización</h2>
          <button @click="previsualizar = false" class="text-gray-400 hover:text-gray-600 text-xl">×</button>
        </div>

        <!-- Simulación WhatsApp -->
        <div v-if="mensaje.canal === 'whatsapp'" class="bg-[#ECE5DD] rounded-xl p-4">
          <div class="bg-white rounded-xl rounded-tl-none px-4 py-3 shadow-sm max-w-xs ml-auto">
            <p class="text-sm text-gray-800 whitespace-pre-wrap">{{ mensajePersonalizado }}</p>
            <p class="text-xs text-gray-400 text-right mt-1">{{ horaActual }} ✓✓</p>
          </div>
        </div>

        <!-- Simulación email -->
        <div v-else class="border border-gray-200 rounded-xl p-4">
          <p class="text-xs text-gray-400 mb-2">Para: miembro@email.com</p>
          <p class="text-xs text-gray-400 mb-3">Asunto: Mensaje de Casa Reino Ministerio</p>
          <p class="text-sm text-gray-800 whitespace-pre-wrap">{{ mensajePersonalizado }}</p>
        </div>

        <p class="text-xs text-gray-400 text-center mt-3">
          Vista previa con datos de ejemplo
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

const canalActivo = ref('whatsapp')
const previsualizar = ref(false)
const programar = ref(false)
const enviando = ref(false)

const mensaje = ref({
  canal: 'whatsapp',
  segmento: 'todos',
  texto: '',
  fechaProgramada: '',
})

const totalMiembros = ref(0)

const canales = [
  { id: 'whatsapp', nombre: 'WhatsApp', icono: '💚', descripcion: 'Business API', activo: true },
  { id: 'email', nombre: 'Email', icono: '📧', descripcion: 'SendGrid', activo: true },
  { id: 'push', nombre: 'Push', icono: '🔔', descripcion: 'Notificación app', activo: true },
]

const segmentos = [
  { valor: 'todos', label: '👥 Todos los miembros' },
  { valor: 'nuevos', label: '🌱 Nuevos (últimos 30 días)' },
  { valor: 'lideres', label: '⭐ Líderes' },
  { valor: 'consolidacion', label: '⚡ En consolidación' },
]

const plantillas = [
  { id: 'bienvenida', nombre: '👋 Bienvenida', texto: 'Hola {{nombre}}, ¡bienvenido a la familia de Casa Reino! Estamos felices de tenerte con nosotros. Si tienes alguna pregunta, no dudes en contactarnos. 🙏' },
  { id: 'recordatorio', nombre: '📅 Recordatorio', texto: 'Hola {{nombre}}, te recordamos que este {{dia}} tenemos nuestra reunión de Casa de Oración. ¡Te esperamos! 🏠' },
  { id: 'evento', nombre: '🎉 Evento', texto: 'Hola {{nombre}}, tienes una invitación especial para nuestro próximo evento. ¡No te lo pierdas! 🎊' },
]

const historial = [
  { id: 1, icono: '💚', texto: 'Recordatorio de reunión semanal', fecha: 'hace 2 días', destinatarios: 145, estado: 'Enviado', claseEstado: 'bg-green-100 text-green-700' },
  { id: 2, icono: '📧', texto: 'Boletín mensual · Octubre 2026', fecha: 'hace 1 semana', destinatarios: 203, estado: 'Enviado', claseEstado: 'bg-green-100 text-green-700' },
  { id: 3, icono: '🔔', texto: 'Nueva serie de enseñanza disponible', fecha: 'hace 2 semanas', destinatarios: 180, estado: 'Enviado', claseEstado: 'bg-green-100 text-green-700' },
]

const destinatariosEstimados = computed(() => {
  if (mensaje.value.segmento === 'todos') return totalMiembros.value
  if (mensaje.value.segmento === 'nuevos') return Math.floor(totalMiembros.value * 0.15)
  if (mensaje.value.segmento === 'lideres') return Math.floor(totalMiembros.value * 0.08)
  if (mensaje.value.segmento === 'consolidacion') return Math.floor(totalMiembros.value * 0.05)
  return 0
})

const puedeEnviar = computed(() =>
  mensaje.value.texto.trim().length > 5 && destinatariosEstimados.value > 0
)

const placeholderMensaje = computed(() => {
  if (mensaje.value.canal === 'whatsapp') return 'Escribe tu mensaje de WhatsApp... Usa {{nombre}} para personalizar'
  if (mensaje.value.canal === 'email') return 'Escribe el contenido del email...'
  return 'Escribe la notificación push (máx. 120 caracteres)...'
})

const mensajePersonalizado = computed(() =>
  mensaje.value.texto.replace(/\{\{nombre\}\}/g, 'Juan García').replace(/\{\{dia\}\}/g, 'viernes')
)

const horaActual = computed(() => {
  return new Date().toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' })
})

function aplicarPlantilla(t: any) {
  mensaje.value.texto = t.texto
}

async function enviarMensaje() {
  enviando.value = true
  // Simulación: en producción, llamaría a Edge Function que dispara WhatsApp/SendGrid
  await new Promise(r => setTimeout(r, 1500))
  enviando.value = false
  mensaje.value.texto = ''
  alert(`✅ Mensaje enviado a ${destinatariosEstimados.value} destinatarios por ${mensaje.value.canal}`)
}

onMounted(async () => {
  const { count } = await supabase.from('miembros').select('*', { count: 'exact', head: true }).eq('activo', true)
  totalMiembros.value = count ?? 0
})
</script>
