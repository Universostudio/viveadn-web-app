<template>
  <div class="flex h-[100dvh] bg-adn-arena overflow-hidden">
    <!-- Fondo oscuro del menú en móvil -->
    <div
      v-if="menuAbierto"
      class="fixed inset-0 bg-black/40 z-30 lg:hidden"
      @click="menuAbierto = false"
    ></div>

    <!-- Sidebar: menú deslizable en móvil, fija en escritorio -->
    <aside
      :class="[
        'fixed inset-y-0 left-0 z-40 w-64 bg-white border-r border-gray-100 flex flex-col shadow-sm transition-transform duration-200',
        'lg:static lg:translate-x-0 lg:flex-shrink-0',
        menuAbierto ? 'translate-x-0' : '-translate-x-full'
      ]"
    >
      <!-- Logo -->
      <div class="px-6 py-5 border-b border-gray-100">
        <div class="flex items-center gap-3">
          <div class="w-9 h-9 bg-adn-verde rounded-lg flex items-center justify-center">
            <span class="text-white text-lg font-bold">V</span>
          </div>
          <div>
            <p class="font-display font-bold text-adn-verde text-sm leading-tight">ViveADN</p>
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
          <div class="w-8 h-8 bg-adn-oro rounded-full flex items-center justify-center flex-shrink-0">
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
    <div class="flex-1 flex flex-col min-w-0">
      <!-- Barra superior (solo móvil) -->
      <header class="lg:hidden flex items-center gap-3 px-4 py-3 bg-white border-b border-gray-100 flex-shrink-0">
        <button
          @click="menuAbierto = true"
          class="w-10 h-10 -ml-2 flex items-center justify-center rounded-lg text-adn-verde hover:bg-adn-arena text-2xl"
          aria-label="Abrir menú"
        >☰</button>
        <p class="font-display font-bold text-adn-verde">ViveADN</p>
      </header>

      <main class="flex-1 overflow-y-auto">
        <RouterView />
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

const auth = useAuthStore()
const router = useRouter()
const route = useRoute()
const menuAbierto = ref(false)

// Cierra el menú móvil al cambiar de página
watch(() => route.fullPath, () => { menuAbierto.value = false })

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
