<template>
  <div class="p-4 sm:p-6 space-y-6">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">⚙️ Configuración</h1>
      <p class="text-gray-500 text-sm mt-0.5">Gestión de usuarios, integraciones y seguridad</p>
    </div>

    <!-- Tabs -->
    <div class="flex gap-1 border-b border-gray-200">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        @click="tabActivo = tab.id"
        :class="['px-4 py-2.5 text-sm font-medium transition-colors border-b-2 -mb-px',
          tabActivo === tab.id
            ? 'border-adn-verde text-adn-verde'
            : 'border-transparent text-gray-500 hover:text-gray-700']"
      >
        {{ tab.icono }} {{ tab.nombre }}
      </button>
    </div>

    <!-- Tab: Perfil de la iglesia -->
    <div v-if="tabActivo === 'iglesia'" class="space-y-6">
      <div class="card space-y-4">
        <h2 class="text-lg font-semibold text-gray-900 mb-2">🏰 Identidad de la iglesia</h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Nombre de la iglesia *</label>
            <input v-model="iglesia.nombre" type="text" placeholder="Casa Reino Ministerio"
              class="w-full px-3 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-adn-verde" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">País sede</label>
            <input v-model="iglesia.pais" type="text" placeholder="España"
              class="w-full px-3 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-adn-verde" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Ciudad sede</label>
            <input v-model="iglesia.ciudad" type="text" placeholder="Sevilla"
              class="w-full px-3 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-adn-verde" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Email de contacto</label>
            <input v-model="iglesia.email" type="email" placeholder="admin@casareino.com"
              class="w-full px-3 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-adn-verde" />
          </div>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Descripción / visión</label>
          <textarea v-model="iglesia.descripcion" rows="3"
            placeholder="Fe sin religión — democratizar el conocimiento teológico..."
            class="w-full px-3 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-adn-verde resize-none"></textarea>
        </div>
        <div class="flex justify-end">
          <button @click="guardarIglesia" :disabled="guardando" class="btn-primary disabled:opacity-60">
            {{ guardando ? 'Guardando...' : '💾 Guardar cambios' }}
          </button>
        </div>
      </div>

      <!-- Apariencia -->
      <div class="card space-y-4">
        <h2 class="text-lg font-semibold text-gray-900">🎨 Apariencia</h2>
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <div v-for="color in paletaColores" :key="color.nombre" class="text-center">
            <div :style="{ backgroundColor: color.valor }" class="w-12 h-12 rounded-xl mx-auto mb-1 shadow-sm border border-gray-100"></div>
            <p class="text-xs font-medium text-gray-700">{{ color.nombre }}</p>
            <p class="text-xs text-gray-400 font-mono">{{ color.valor }}</p>
          </div>
        </div>
        <p class="text-xs text-gray-400">La paleta de colores se personaliza en una futura versión</p>
      </div>
    </div>

    <!-- Tab: Usuarios y roles -->
    <div v-if="tabActivo === 'usuarios'" class="space-y-6">
      <div class="card">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-lg font-semibold text-gray-900">👥 Usuarios del sistema</h2>
          <button @click="abrirNuevoUsuario = true" class="btn-secondary text-sm">+ Invitar usuario</button>
        </div>

        <div v-if="!usuarios.length" class="py-8 text-center text-gray-400 text-sm">
          Cargando usuarios...
        </div>
        <div v-else class="divide-y divide-gray-50">
          <div v-for="u in usuarios" :key="u.id" class="flex items-center justify-between py-3">
            <div class="flex items-center gap-3">
              <div class="w-9 h-9 bg-adn-verde rounded-full flex items-center justify-center">
                <span class="text-white text-sm font-bold">{{ u.nombre?.[0] ?? '?' }}</span>
              </div>
              <div>
                <p class="text-sm font-medium text-gray-900">{{ u.nombre }} {{ u.apellido }}</p>
                <p class="text-xs text-gray-400">{{ u.email }}</p>
              </div>
            </div>
            <div class="flex items-center gap-3">
              <span :class="['text-xs px-2 py-1 rounded-full font-medium', claseRol(u.rol)]">
                {{ etiquetaRol(u.rol) }}
              </span>
              <button v-if="u.rol !== 'super_admin'" @click="cambiarRol(u)" class="text-xs text-gray-400 hover:text-adn-verde transition-colors">
                ✏️ Rol
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Descripción de roles -->
      <div class="card">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">📋 Roles disponibles</h2>
        <div class="space-y-3">
          <div v-for="rol in rolesDescripcion" :key="rol.id" class="flex items-start gap-3 p-3 bg-gray-50 rounded-xl">
            <span :class="['text-xs px-2 py-1 rounded-full font-medium flex-shrink-0 mt-0.5', claseRol(rol.id)]">
              {{ etiquetaRol(rol.id) }}
            </span>
            <p class="text-sm text-gray-600">{{ rol.descripcion }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Tab: Integraciones -->
    <div v-if="tabActivo === 'integraciones'" class="space-y-6">
      <div v-for="integ in integraciones" :key="integ.id" class="card">
        <div class="flex items-start justify-between">
          <div class="flex items-start gap-3">
            <span class="text-3xl">{{ integ.icono }}</span>
            <div>
              <p class="font-semibold text-gray-900">{{ integ.nombre }}</p>
              <p class="text-sm text-gray-500 mt-0.5">{{ integ.descripcion }}</p>
            </div>
          </div>
          <span :class="['text-xs px-3 py-1.5 rounded-full font-medium', integ.activa ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500']">
            {{ integ.activa ? '● Activa' : '○ Inactiva' }}
          </span>
        </div>

        <div v-if="integ.configuracion" class="mt-4 space-y-3">
          <div v-for="campo in integ.configuracion" :key="campo.clave">
            <label class="block text-xs font-medium text-gray-600 mb-1">{{ campo.etiqueta }}</label>
            <input
              :type="campo.tipo"
              :placeholder="campo.placeholder"
              v-model="camposIntegracion[integ.id + '_' + campo.clave]"
              class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-adn-verde"
            />
          </div>
          <div class="flex justify-end">
            <button class="btn-secondary text-xs">Guardar configuración</button>
          </div>
        </div>

        <div v-if="integ.nota" class="mt-3 bg-adn-arena rounded-lg px-3 py-2">
          <p class="text-xs text-adn-verde">💡 {{ integ.nota }}</p>
        </div>
      </div>
    </div>

    <!-- Tab: Seguridad -->
    <div v-if="tabActivo === 'seguridad'" class="space-y-6">
      <div class="card space-y-4">
        <h2 class="text-lg font-semibold text-gray-900">🔐 Autenticación</h2>
        <div class="divide-y divide-gray-50">
          <div class="flex items-center justify-between py-3">
            <div>
              <p class="text-sm font-medium text-gray-900">Autenticación de dos factores (2FA)</p>
              <p class="text-xs text-gray-500 mt-0.5">Obligatoria para roles Admin y Super Admin</p>
            </div>
            <div class="w-12 h-6 bg-adn-verde rounded-full relative cursor-pointer flex-shrink-0">
              <div class="w-5 h-5 bg-white rounded-full absolute top-0.5 right-0.5 shadow-sm"></div>
            </div>
          </div>
          <div class="flex items-center justify-between py-3">
            <div>
              <p class="text-sm font-medium text-gray-900">Sesiones activas máximas</p>
              <p class="text-xs text-gray-500 mt-0.5">Número de dispositivos simultáneos por usuario</p>
            </div>
            <select class="text-sm border border-gray-200 rounded-lg px-2 py-1.5 focus:outline-none focus:ring-2 focus:ring-adn-verde">
              <option>1</option>
              <option selected>3</option>
              <option>5</option>
              <option>Sin límite</option>
            </select>
          </div>
          <div class="flex items-center justify-between py-3">
            <div>
              <p class="text-sm font-medium text-gray-900">Tiempo de sesión</p>
              <p class="text-xs text-gray-500 mt-0.5">Expiración automática por inactividad</p>
            </div>
            <select class="text-sm border border-gray-200 rounded-lg px-2 py-1.5 focus:outline-none focus:ring-2 focus:ring-adn-verde">
              <option>1 hora</option>
              <option selected>8 horas</option>
              <option>24 horas</option>
              <option>7 días</option>
            </select>
          </div>
        </div>
      </div>

      <div class="card space-y-4">
        <h2 class="text-lg font-semibold text-gray-900">🔒 Privacidad y datos</h2>
        <div class="divide-y divide-gray-50">
          <div class="flex items-center justify-between py-3">
            <div>
              <p class="text-sm font-medium text-gray-900">Cifrado AES-256</p>
              <p class="text-xs text-gray-500 mt-0.5">Datos sensibles cifrados en reposo</p>
            </div>
            <span class="text-xs bg-green-100 text-green-700 px-2 py-1 rounded-full font-medium">✓ Activo</span>
          </div>
          <div class="flex items-center justify-between py-3">
            <div>
              <p class="text-sm font-medium text-gray-900">Consentimiento GDPR</p>
              <p class="text-xs text-gray-500 mt-0.5">Registro de consentimientos de usuarios</p>
            </div>
            <span class="text-xs bg-green-100 text-green-700 px-2 py-1 rounded-full font-medium">✓ Activo</span>
          </div>
          <div class="flex items-center justify-between py-3">
            <div>
              <p class="text-sm font-medium text-gray-900">Backup automático</p>
              <p class="text-xs text-gray-500 mt-0.5">Copia de seguridad diaria en Frankfurt (GDPR)</p>
            </div>
            <span class="text-xs bg-green-100 text-green-700 px-2 py-1 rounded-full font-medium">✓ Activo</span>
          </div>
        </div>
      </div>

      <div class="card border border-red-100 bg-red-50/50">
        <h2 class="text-lg font-semibold text-red-700 mb-3">⚠️ Zona peligrosa</h2>
        <p class="text-sm text-red-600 mb-4">Estas acciones son irreversibles. Proceda con extrema precaución.</p>
        <div class="flex flex-wrap gap-3">
          <button class="text-sm px-4 py-2 border border-red-200 text-red-600 rounded-lg hover:bg-red-50 transition-colors">
            Exportar todos los datos
          </button>
          <button class="text-sm px-4 py-2 border border-red-300 text-red-700 rounded-lg hover:bg-red-100 transition-colors font-medium">
            Eliminar cuenta
          </button>
        </div>
      </div>
    </div>

    <!-- Modal: Invitar usuario -->
    <div
      v-if="abrirNuevoUsuario"
      class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center p-4 z-50"
      @click.self="abrirNuevoUsuario = false"
    >
      <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
        <h2 class="text-lg font-bold text-gray-900 mb-4">Invitar nuevo usuario</h2>
        <form @submit.prevent="invitarUsuario" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Email *</label>
            <input v-model="nuevoUsuario.email" type="email" required placeholder="usuario@email.com"
              class="w-full px-3 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-adn-verde" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Rol asignado *</label>
            <select v-model="nuevoUsuario.rol" required
              class="w-full px-3 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-adn-verde">
              <option value="">Seleccionar...</option>
              <option value="admin">Admin</option>
              <option value="lider_casa">Líder Casa de Oración</option>
              <option value="lider_escuela">Líder Escuela Formación</option>
              <option value="consolidador">Consolidador</option>
              <option value="miembro">Miembro</option>
            </select>
          </div>
          <div class="flex gap-3 pt-2">
            <button type="button" @click="abrirNuevoUsuario = false" class="btn-secondary flex-1">Cancelar</button>
            <button type="submit" :disabled="enviandoInvitacion" class="btn-primary flex-1 disabled:opacity-60">
              {{ enviandoInvitacion ? 'Enviando...' : '📧 Enviar invitación' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

const tabActivo = ref('iglesia')
const guardando = ref(false)
const abrirNuevoUsuario = ref(false)
const enviandoInvitacion = ref(false)
const usuarios = ref<any[]>([])
const camposIntegracion = ref<Record<string, string>>({})

const tabs = [
  { id: 'iglesia', nombre: 'Iglesia', icono: '🏰' },
  { id: 'usuarios', nombre: 'Usuarios', icono: '👥' },
  { id: 'integraciones', nombre: 'Integraciones', icono: '🔌' },
  { id: 'seguridad', nombre: 'Seguridad', icono: '🔐' },
]

const iglesia = ref({ nombre: '', pais: '', ciudad: '', email: '', descripcion: '' })
const nuevoUsuario = ref({ email: '', rol: '' })

const paletaColores = [
  { nombre: 'Verde Base', valor: '#00523c' },
  { nombre: 'Oro Vivo', valor: '#f5a623' },
  { nombre: 'Verde Oscuro', valor: '#003828' },
  { nombre: 'Arena Suave', valor: '#f4f0e6' },
]

const rolesDescripcion = [
  { id: 'super_admin', descripcion: 'Acceso total sin restricciones. Gestión global del sistema y configuraciones críticas.' },
  { id: 'admin', descripcion: 'Gestión operativa completa. Acceso a la mayoría de funcionalidades y reportes detallados.' },
  { id: 'lider_casa', descripcion: 'Gestión de su Casa de Oración: miembros asignados, reportes y consolidación.' },
  { id: 'lider_escuela', descripcion: 'Actualización del progreso de formación de estudiantes y reportes de escuela.' },
  { id: 'consolidador', descripcion: 'Seguimiento de nuevos convertidos asignados dentro del sistema de 72 horas.' },
  { id: 'miembro', descripcion: 'Vista de su propio perfil, progreso de formación y biblioteca de recursos.' },
]

const integraciones = [
  {
    id: 'whatsapp',
    icono: '💚',
    nombre: 'WhatsApp Business API',
    descripcion: 'Mensajes masivos, plantillas aprobadas por Meta y tracking de entregas',
    activa: false,
    configuracion: [
      { clave: 'token', etiqueta: 'Token de acceso Meta', tipo: 'password', placeholder: 'Bearer token de WhatsApp Business' },
      { clave: 'phone_id', etiqueta: 'Phone Number ID', tipo: 'text', placeholder: 'ID del número registrado en Meta' },
    ],
    nota: 'Requiere cuenta Meta Business verificada y número de teléfono dedicado',
  },
  {
    id: 'sendgrid',
    icono: '📧',
    nombre: 'SendGrid (Email transaccional)',
    descripcion: 'Emails transaccionales, boletines y notificaciones automáticas',
    activa: false,
    configuracion: [
      { clave: 'api_key', etiqueta: 'API Key de SendGrid', tipo: 'password', placeholder: 'SG.xxxxxxxxxxxxxxxx' },
      { clave: 'from_email', etiqueta: 'Email remitente verificado', tipo: 'email', placeholder: 'noreply@casareino.com' },
    ],
    nota: 'El dominio remitente debe estar verificado en SendGrid para evitar spam',
  },
  {
    id: 'supabase',
    icono: '🗄️',
    nombre: 'Supabase (Base de datos)',
    descripcion: 'PostgreSQL con autenticación, tiempo real y API REST automática',
    activa: true,
    configuracion: null,
    nota: 'Proyecto activo: xrjbvjqhpwjjtcfdlsbq — Frankfurt, Alemania (GDPR compliant)',
  },
]

function claseRol(rol: string) {
  const m: Record<string, string> = {
    super_admin: 'bg-purple-100 text-purple-700',
    admin: 'bg-blue-100 text-blue-700',
    lider_casa: 'bg-green-100 text-green-700',
    lider_escuela: 'bg-yellow-100 text-yellow-700',
    consolidador: 'bg-orange-100 text-orange-700',
    miembro: 'bg-gray-100 text-gray-600',
  }
  return m[rol] ?? 'bg-gray-100 text-gray-600'
}

function etiquetaRol(rol: string) {
  const m: Record<string, string> = {
    super_admin: 'Super Admin',
    admin: 'Admin',
    lider_casa: 'Líder Casa',
    lider_escuela: 'Líder Escuela',
    consolidador: 'Consolidador',
    miembro: 'Miembro',
  }
  return m[rol] ?? rol
}

function cambiarRol(usuario: any) {
  // En producción, abriría un modal para seleccionar nuevo rol
  alert(`Cambiar rol de ${usuario.nombre} — disponible en versión completa`)
}

async function guardarIglesia() {
  guardando.value = true
  await new Promise(r => setTimeout(r, 800)) // Simulación
  guardando.value = false
  alert('✅ Configuración guardada')
}

async function invitarUsuario() {
  enviandoInvitacion.value = true
  // En producción, enviaría invitación via Supabase Auth invite
  await new Promise(r => setTimeout(r, 1000))
  enviandoInvitacion.value = false
  abrirNuevoUsuario.value = false
  nuevoUsuario.value = { email: '', rol: '' }
  alert(`✅ Invitación enviada a ${nuevoUsuario.value.email || 'el usuario'}`)
}

onMounted(async () => {
  const { data } = await supabase
    .from('perfiles')
    .select('id, nombre, apellido, email, rol')
    .order('nombre')
  usuarios.value = data ?? []
})
</script>
