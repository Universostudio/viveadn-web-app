<template>
  <!-- Estado de la alerta de 72 horas: icono y palabra, nunca solo color -->
  <span :class="['inline-flex items-center gap-1.5 rounded-full font-semibold whitespace-nowrap', estilo.clase, compacto ? 'px-2 py-0.5 text-xs' : 'px-2.5 py-1 text-xs']">
    <component :is="estilo.icono" class="w-3.5 h-3.5 flex-shrink-0" aria-hidden="true" />
    <span>{{ estilo.texto }}</span>
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { CircleCheck, Clock, TriangleAlert, Siren, CircleHelp } from '@lucide/vue'

const props = defineProps<{ estado?: string | null; compacto?: boolean }>()

const ESTILOS = {
  verde: { icono: CircleCheck, texto: 'A tiempo', clase: 'bg-emerald-100 text-emerald-800' },
  amarillo: { icono: Clock, texto: 'Atención', clase: 'bg-amber-100 text-amber-800' },
  naranja: { icono: TriangleAlert, texto: 'Urgente', clase: 'bg-orange-100 text-orange-800' },
  rojo: { icono: Siren, texto: 'Crítico', clase: 'bg-red-100 text-red-800' },
} as const

const estilo = computed(() =>
  ESTILOS[props.estado as keyof typeof ESTILOS] ?? { icono: CircleHelp, texto: 'Sin estado', clase: 'bg-gray-100 text-gray-600' },
)
</script>
