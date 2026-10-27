<template>
  <div class="p-4 sm:p-6 space-y-6">
    <div class="flex items-start justify-between gap-3 flex-wrap">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Plataforma</h1>
        <p class="text-gray-500 text-sm mt-0.5">Iglesias, planes y complementos de ViveADN</p>
      </div>
      <button @click="abrirNueva = true" class="btn-primary inline-flex items-center gap-2"><Plus class="w-4 h-4" aria-hidden="true" /> Nueva iglesia</button>
    </div>

    <p v-if="mensaje" :class="['text-sm px-4 py-3 rounded-lg border', mensajeError ? 'bg-red-50 text-red-700 border-red-200' : 'bg-green-50 text-green-700 border-green-200']">
      {{ mensaje }}
    </p>

    <div v-if="cargando" class="py-12 text-center text-gray-400 text-sm">Cargando iglesias...</div>

    <div v-else class="space-y-4">
      <div v-for="ig in iglesias" :key="ig.id" class="card space-y-4">
        <div class="flex items-start justify-between gap-3 flex-wrap">
          <div class="min-w-0">
            <div class="flex items-center gap-2 flex-wrap">
              <h2 class="text-lg font-semibold text-gray-900 truncate">{{ ig.nombre }}</h2>
              <span v-if="ig.es_demo" class="text-xs bg-adn-arena text-adn-profundo px-2 py-0.5 rounded-full font-medium">Demo</span>
              <span :class="['text-xs px-2 py-0.5 rounded-full font-medium', ig.activa ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700']">
                {{ ig.activa ? 'Activa' : 'Suspendida' }}
              </span>
            </div>
            <p class="text-xs text-gray-400 mt-0.5">
              {{ ig.slug }} · {{ ig.miembros }} miembros · {{ ig.usuarios }} usuarios
              <span v-if="limiteMiembros(ig)"> · límite {{ limiteMiembros(ig) }} miembros</span>
            </p>
          </div>

          <div class="flex items-center gap-2">
            <label class="text-xs text-gray-500">Plan</label>
            <select :value="ig.plan" @change="cambiarPlan(ig, ($event.target as HTMLSelectElement).value)"
              class="text-sm border border-gray-200 rounded-lg px-2 py-1.5 focus:outline-none focus:ring-2 focus:ring-adn-verde">
              <option v-for="p in planes" :key="p.clave" :value="p.clave">{{ p.nombre }}</option>
            </select>
          </div>
        </div>

        <div>
          <p class="text-xs font-medium text-gray-600 mb-2">Complementos</p>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="m in modulosOpcionales(ig)" :key="m.clave"
              @click="alternarModulo(ig, m)"
              :disabled="m.delPlan"
              :title="m.delPlan ? 'Ya viene incluido en el plan' : ''"
              :class="['text-xs px-3 py-1.5 rounded-full border transition-colors',
                m.delPlan ? 'bg-gray-50 text-gray-400 border-gray-100 cursor-default'
                : m.activo ? 'bg-adn-verde text-white border-adn-verde'
                : 'bg-white text-gray-600 border-gray-200 hover:border-adn-verde']"
            >
              <span class="inline-flex items-center gap-1.5">
                <component :is="m.delPlan ? Check : m.activo ? CircleCheck : Circle" class="w-3.5 h-3.5" aria-hidden="true" />{{ m.nombre }}
              </span>
            </button>
          </div>
        </div>

        <div class="flex justify-end">
          <button @click="alternarEstado(ig)" class="text-xs text-gray-400 hover:text-red-600 transition-colors">
            {{ ig.activa ? 'Suspender iglesia' : 'Reactivar iglesia' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal: nueva iglesia -->
    <div v-if="abrirNueva" class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center p-4 z-50" @click.self="abrirNueva = false">
      <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6 max-h-[90vh] overflow-y-auto">
        <h2 class="text-lg font-bold text-gray-900 mb-4">Nueva iglesia</h2>
        <form @submit.prevent="crearIglesia" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Nombre *</label>
            <input v-model="nueva.nombre" required minlength="2" maxlength="80" class="campo" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Dirección interna *</label>
            <input v-model="nueva.slug" required pattern="[a-z0-9]+(-[a-z0-9]+)*" minlength="3" maxlength="40" placeholder="casa-reino" class="campo" />
            <p class="text-xs text-gray-400 mt-1">Solo minúsculas, números y guiones</p>
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">País *</label>
              <input v-model="nueva.pais" required maxlength="80" class="campo" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Ciudad *</label>
              <input v-model="nueva.ciudad" required maxlength="80" class="campo" />
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Plan</label>
            <select v-model="nueva.plan" class="campo">
              <option v-for="p in planes" :key="p.clave" :value="p.clave">{{ p.nombre }}</option>
            </select>
          </div>
          <div class="border-t border-gray-100 pt-4 space-y-3">
            <p class="text-sm font-medium text-gray-700">Propietario (recibirá una invitación por correo)</p>
            <div class="grid grid-cols-2 gap-3">
              <input v-model="nueva.nombre_propietario" required placeholder="Nombre" class="campo" />
              <input v-model="nueva.apellido_propietario" required placeholder="Apellido" class="campo" />
            </div>
            <input v-model="nueva.email" type="email" required placeholder="correo@iglesia.org" class="campo" />
          </div>
          <label class="flex items-center gap-2 text-sm text-gray-600">
            <input v-model="nueva.es_demo" type="checkbox" class="rounded" /> Es una iglesia de demostración
          </label>
          <p v-if="errorNueva" class="text-sm text-red-600">{{ errorNueva }}</p>
          <div class="flex gap-3 pt-2">
            <button type="button" @click="abrirNueva = false" class="btn-secondary flex-1">Cancelar</button>
            <button type="submit" :disabled="creando" class="btn-primary flex-1 disabled:opacity-60">
              {{ creando ? 'Creando...' : 'Crear e invitar' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Check, Circle, CircleCheck, Plus } from '@lucide/vue'
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

const iglesias = ref<any[]>([])
const planes = ref<any[]>([])
const modulos = ref<any[]>([])
const planModulos = ref<any[]>([])
const cargando = ref(true)
const mensaje = ref('')
const mensajeError = ref(false)
const abrirNueva = ref(false)
const creando = ref(false)
const errorNueva = ref('')

const vacia = () => ({
  nombre: '', slug: '', pais: '', ciudad: '', plan: 'semilla',
  nombre_propietario: '', apellido_propietario: '', email: '', es_demo: false,
})
const nueva = ref(vacia())

async function llamar(cuerpo: Record<string, unknown>) {
  const { data, error } = await supabase.functions.invoke('plataforma', {
    body: { ...cuerpo, origen: window.location.origin },
  })
  if (error) {
    // La función devuelve el motivo en el cuerpo de la respuesta de error
    let motivo = 'No se pudo completar la acción'
    try {
      const resp = (error as any).context
      if (resp?.json) motivo = (await resp.json()).error ?? motivo
    } catch { /* se queda el mensaje genérico */ }
    throw new Error(motivo)
  }
  return data
}

async function cargar() {
  cargando.value = true
  try {
    const d = await llamar({ accion: 'listar' })
    iglesias.value = d.iglesias
    planes.value = d.planes
    modulos.value = d.modulos
    planModulos.value = d.plan_modulos
  } catch (e: any) {
    avisar(e.message, true)
  }
  cargando.value = false
}

function avisar(texto: string, error = false) {
  mensaje.value = texto
  mensajeError.value = error
}

function limiteMiembros(ig: any) {
  return planes.value.find(p => p.clave === ig.plan)?.max_miembros ?? null
}

// Módulos que no son del núcleo: incluidos por el plan o contratables aparte
function modulosOpcionales(ig: any) {
  return modulos.value
    .filter(m => m.tipo !== 'nucleo')
    .map(m => ({
      ...m,
      delPlan: planModulos.value.some(pm => pm.plan === ig.plan && pm.modulo === m.clave),
      activo: ig.addons.some((a: any) => a.modulo === m.clave && a.activo),
    }))
}

async function ejecutar(cuerpo: Record<string, unknown>, ok: string) {
  try {
    await llamar(cuerpo)
    avisar(ok)
    await cargar()
  } catch (e: any) {
    avisar(e.message, true)
    await cargar()
  }
}

const cambiarPlan = (ig: any, plan: string) =>
  ejecutar({ accion: 'cambiar_plan', iglesia_id: ig.id, plan }, `Plan de ${ig.nombre} actualizado.`)

const alternarModulo = (ig: any, m: any) =>
  ejecutar({ accion: 'modulo_addon', iglesia_id: ig.id, modulo: m.clave, activo: !m.activo },
    `${m.nombre} ${m.activo ? 'quitado de' : 'activado en'} ${ig.nombre}.`)

function alternarEstado(ig: any) {
  const pregunta = ig.activa
    ? `¿Suspender ${ig.nombre}? Sus usuarios perderán el acceso hasta que la reactives.`
    : `¿Reactivar ${ig.nombre}?`
  if (!window.confirm(pregunta)) return
  ejecutar({ accion: 'estado', iglesia_id: ig.id, activa: !ig.activa },
    ig.activa ? `${ig.nombre} suspendida.` : `${ig.nombre} reactivada.`)
}

async function crearIglesia() {
  creando.value = true
  errorNueva.value = ''
  try {
    await llamar({ accion: 'crear_iglesia', ...nueva.value })
    abrirNueva.value = false
    avisar(`Iglesia creada. Se envió la invitación a ${nueva.value.email}.`)
    nueva.value = vacia()
    await cargar()
  } catch (e: any) {
    errorNueva.value = e.message
  }
  creando.value = false
}

onMounted(cargar)
</script>

<style scoped>
.campo {
  @apply w-full px-3 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-adn-verde;
}
</style>
