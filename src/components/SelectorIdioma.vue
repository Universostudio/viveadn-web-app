<template>
  <div class="flex items-center gap-2">
    <label :for="id" class="text-xs text-gray-500 inline-flex items-center gap-1.5 flex-shrink-0">
      <Languages class="w-4 h-4" aria-hidden="true" />
      <span :class="ocultarEtiqueta ? 'sr-only' : ''">{{ t('comun.idioma') }}</span>
    </label>
    <select
      :id="id"
      :value="locale"
      @change="cambiar(($event.target as HTMLSelectElement).value)"
      class="flex-1 min-w-0 text-sm border border-gray-200 rounded-lg px-2 py-1.5 bg-white text-gray-700 focus:outline-none focus:ring-2 focus:ring-adn-verde"
    >
      <option v-for="i in IDIOMAS" :key="i.codigo" :value="i.codigo" :lang="i.codigo">{{ i.nombre }}</option>
    </select>
  </div>
</template>

<script setup lang="ts">
import { Languages } from '@lucide/vue'
import { useI18n } from 'vue-i18n'
import { IDIOMAS, setIdioma, type CodigoIdioma } from '@/i18n'

withDefaults(defineProps<{ id?: string; ocultarEtiqueta?: boolean }>(), {
  id: 'selector-idioma',
  ocultarEtiqueta: false,
})

const { t, locale } = useI18n()

function cambiar(codigo: string) {
  setIdioma(codigo as CodigoIdioma)
}
</script>
