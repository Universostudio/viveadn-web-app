<template>
  <div class="min-h-screen bg-gradient-to-br from-adn-verde to-adn-oscuro flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md p-8">
      <!-- Logo -->
      <div class="text-center mb-8">
        <div class="w-16 h-16 bg-adn-verde rounded-2xl flex items-center justify-center mx-auto mb-4">
          <span class="text-white text-3xl font-bold">V</span>
        </div>
        <h1 class="text-2xl font-bold text-adn-verde">ViveADN</h1>
        <p class="text-gray-500 text-sm mt-1">Nueva contraseña</p>
      </div>

      <form v-if="!exito" @submit.prevent="handleReset" class="space-y-5">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Nueva contraseña</label>
          <input
            v-model="password"
            type="password"
            required
            minlength="8"
            placeholder="Mínimo 8 caracteres"
            class="w-full px-4 py-3 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-adn-verde focus:border-transparent transition"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Confirmar contraseña</label>
          <input
            v-model="confirmar"
            type="password"
            required
            placeholder="Repite la contraseña"
            class="w-full px-4 py-3 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-adn-verde focus:border-transparent transition"
          />
        </div>

        <div v-if="error" class="bg-red-50 text-red-700 text-sm px-4 py-3 rounded-lg border border-red-200">
          {{ error }}
        </div>

        <button
          type="submit"
          :disabled="loading"
          class="w-full btn-primary py-3 text-base disabled:opacity-60 disabled:cursor-not-allowed"
        >
          <span v-if="loading">Guardando...</span>
          <span v-else>Guardar nueva contraseña</span>
        </button>
      </form>

      <div v-else class="text-center space-y-4">
        <p class="text-4xl">✅</p>
        <p class="text-gray-700 font-medium">Contraseña actualizada correctamente</p>
        <button @click="router.push('/login')" class="btn-primary px-6 py-2">
          Ir al login
        </button>
      </div>

      <p class="text-center text-xs text-gray-400 mt-6">
        © 2026 ViveADN · Casa Reino Ministerio
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const password = ref('')
const confirmar = ref('')
const error = ref('')
const loading = ref(false)
const exito = ref(false)

async function handleReset() {
  error.value = ''
  if (password.value !== confirmar.value) {
    error.value = 'Las contraseñas no coinciden'
    return
  }
  loading.value = true
  try {
    const { error: err } = await supabase.auth.updateUser({ password: password.value })
    if (err) throw err
    exito.value = true
  } catch (e: any) {
    error.value = 'Error al actualizar la contraseña. El enlace puede haber expirado.'
  } finally {
    loading.value = false
  }
}
</script>
