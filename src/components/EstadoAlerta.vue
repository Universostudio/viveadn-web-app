<template>
  <!-- Estado de la alerta de 72 horas: icono y palabra, nunca solo color -->
  <span :class="['inline-flex items-center gap-1.5 rounded-full font-semibold whitespace-nowrap', estilo.clase, compacto ? 'px-2 py-0.5 text-xs' : 'px-2.5 py-1 text-xs']">
    <component :is="estilo.icono" class="w-3.5 h-3.5 flex-shrink-0" aria-hidden="true" />
    <span>{{ t(estilo.texto) }}</span>
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { CircleCheck, Clock, TriangleAlert, Siren, CircleHelp } from '@lucide/vue'
import { useI18n } from 'vue-i18n'

const props = defineProps<{ estado?: string | null; compacto?: boolean }>()
const { t } = useI18n()

// texto: clave de traducción de la etiqueta visible

const ESTILOS = {
  verde: { icono: CircleCheck, texto: 'alertas.estado.verde', clase: 'bg-emerald-100 text-emerald-800' },
  amarillo: { icono: Clock, texto: 'alertas.estado.amarillo', clase: 'bg-amber-100 text-amber-800' },
  naranja: { icono: TriangleAlert, texto: 'alertas.estado.naranja', clase: 'bg-orange-100 text-orange-800' },
  rojo: { icono: Siren, texto: 'alertas.estado.rojo', clase: 'bg-red-100 text-red-800' },
} as const

const estilo = computed(() =>
  ESTILOS[props.estado as keyof typeof ESTILOS] ?? { icono: CircleHelp, texto: 'alertas.sinEstado', clase: 'bg-gray-100 text-gray-600' },
)
</script>
