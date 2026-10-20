<template>
  <div class="flex h-screen bg-gray-50 overflow-hidden">
    <!-- Sidebar -->
    <aside class="w-64 bg-white border-r border-gray-100 flex flex-col shadow-sm flex-shrink-0">
      <!-- Logo -->
      <div class="px-6 py-5 border-b border-gray-100">
        <div class="flex items-center gap-3">
          <div class="w-9 h-9 bg-reino-azul rounded-lg flex items-center justify-center">
            <span class="text-white text-lg font-bold">V</span>
          </div>
          <div>
            <p class="font-bold text-reino-azul text-sm leading-tight">ViveADN</p>
            <p class="text-xs text-gray-400">{{ iglesiaName }}</p>
          </div>
        </div>
      </div>

      <!-- Navegación -->
      <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        <RouterLink v-for="item in navItems" :key="item.to" :to="item.to" custom v-slot="{ isActive, navigate }">
          <div @click="navigate" :class="['nav-item', isActive ? 'active' : '']">
            <span class="text-xl">{{ item.icon }}</span>
            <span class="text-sm font-medium">{{ item.label }}</span>
            <!-- Badge alerta consolidación -->
            <span v-if="item.badge && consolidacionPendientes > 0"
              class="ml-auto bg-red-500 text-white text-xs rounded-full px-2 py-0.5 font-bold">
              {{ consolidacionPendientes }}
            </span>
          </div>
        </RouterLink>
      </nav>

      <!-- Usuario -->
      <div class="px-3 py-4 border-t border-gray-100">
        <div class="flex items-center gap-3 px-3 py-2">
          <div class="w-8 h-8 bg-reino-dorado rounded-full flex items-center justify-center flex-shrink-0">
            <span class="text-white text-sm font-bold">{{ inicial }}</span>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-gray-900 truncate">{{ nombreCompleto }}</p>
            <p class="text-xs text-gray-400 truncate capitalize">{{ rol }}</p>
          </div>
          <button @click="logout" class="text-gray-400 hover:text-red-500 transition-colors" title="Salir">
            <span class="text-lg">🚪</span>
          </button>
        </div>
      </div>
    </aside>

    <!-- Contenido principal -->
    <main class="flex-1 overflow-y-auto">
      <RouterView />
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

const auth = useAuthStore()
const router = useRouter()

const nombreCompleto = computed(() => auth.nombreCompleto)
const rol = computed(() => auth.rol ?? '')
const inicial = computed(() => auth.perfil?.nombre?.[0]?.toUpperCase() ?? 'U')
const iglesiaName = ref('CRM Reino')
const consolidacionPendientes = ref(0)

const navItems = [
  { to: '/',              icon: '🏠', label: 'Dashboard' },
  { to: '/miembros',      icon: '👥', label: 'Miembros' },
  { to: '/casas',         icon: '🏘️', label: 'Casas de Oración' },
  { to: '/consolidacion', icon: '⚡', label: 'Consolidación', badge: true },
  { to: '/formacion',     icon: '📚', label: 'Formación' },
  { to: '/comunicacion',  icon: '💬', label: 'Comunicación' },
  { to: '/reportes',      icon: '📊', label: 'Reportes' },
  { to: '/configuracion', icon: '⚙️', label: 'Configuración' },
]

async function logout() {
  await auth.logout()
  router.push('/login')
}

onMounted(async () => {
  // Contar consolidaciones críticas (naranja + rojo)
  const { count } = await supabase
    .from('consolidaciones')
    .select('*', { count: 'exact', head: true })
    .in('estado_alerta', ['naranja', 'rojo'])
    .eq('completado', false)

  consolidacionPendientes.value = count ?? 0
})
</script>
