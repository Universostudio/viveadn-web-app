<template>
  <div class="min-h-screen bg-gradient-to-br from-reino-azul to-reino-oscuro flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md p-8">
      <!-- Logo -->
      <div class="text-center mb-8">
        <div class="w-16 h-16 bg-reino-azul rounded-2xl flex items-center justify-center mx-auto mb-4">
          <span class="text-white text-3xl font-bold">V</span>
        </div>
        <h1 class="text-2xl font-bold text-reino-azul">ViveADN</h1>
        <p class="text-gray-500 text-sm mt-1">Sistema de Gestión Eclesiástica</p>
      </div>

      <!-- Formulario login -->
      <form v-if="!modoRecuperar" @submit.prevent="handleLogin" class="space-y-5">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Correo electrónico</label>
          <input
            v-model="email"
            type="email"
            required
            placeholder="pastor@iglesia.com"
            class="w-full px-4 py-3 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-reino-azul focus:border-transparent transition"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Contraseña</label>
          <input
            v-model="password"
            type="password"
            required
            placeholder="••••••••"
            class="w-full px-4 py-3 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-reino-azul focus:border-transparent transition"
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
          <span v-if="loading">Entrando...</span>
          <span v-else>Entrar al sistema</span>
        </button>

        <div class="text-center">
          <button
            type="button"
            @click="modoRecuperar = true"
            class="text-sm text-reino-azul hover:underline"
          >
            ¿Olvidaste tu contraseña?
          </button>
        </div>
      </form>

      <!-- Formulario recuperar contraseña -->
      <form v-else @submit.prevent="handleRecuperar" class="space-y-5">
        <div class="text-center mb-2">
          <h2 class="text-lg font-semibold text-gray-800">Recuperar contraseña</h2>
          <p class="text-sm text-gray-500 mt-1">Te enviaremos un enlace a tu correo</p>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Correo electrónico</label>
          <input
            v-model="email"
            type="email"
            required
            placeholder="pastor@iglesia.com"
            class="w-full px-4 py-3 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-reino-azul focus:border-transparent transition"
          />
        </div>

        <div v-if="error" class="bg-red-50 text-red-700 text-sm px-4 py-3 rounded-lg border border-red-200">
          {{ error }}
        </div>

        <div v-if="exito" class="bg-green-50 text-green-700 text-sm px-4 py-3 rounded-lg border border-green-200">
          ✅ Enlace enviado. Revisa tu correo <strong>{{ email }}</strong> y sigue las instrucciones.
        </div>

        <button
          v-if="!exito"
          type="submit"
          :disabled="loading"
          class="w-full btn-primary py-3 text-base disabled:opacity-60 disabled:cursor-not-allowed"
        >
          <span v-if="loading">Enviando...</span>
          <span v-else>Enviar enlace de recuperación</span>
        </button>

        <div class="text-center">
          <button
            type="button"
            @click="modoRecuperar = false; error = ''; exito = false"
            class="text-sm text-reino-azul hover:underline"
          >
            ← Volver al login
          </button>
        </div>
      </form>

      <p class="text-center text-xs text-gray-400 mt-6">
        © 2026 ViveADN · Casa Reino Ministerio
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

const auth = useAuthStore()
const router = useRouter()

const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)
const modoRecuperar = ref(false)
const exito = ref(false)

async function handleLogin() {
  error.value = ''
  loading.value = true
  try {
    await auth.login(email.value, password.value)
    router.push('/')
  } catch (e: any) {
    error.value = 'Correo o contraseña incorrectos'
  } finally {
    loading.value = false
  }
}

async function handleRecuperar() {
  error.value = ''
  exito.value = false
  loading.value = true
  try {
    const { error: err } = await supabase.auth.resetPasswordForEmail(email.value, {
      redirectTo: `${window.location.origin}/reset-password`,
    })
    if (err) throw err
    exito.value = true
  } catch (e: any) {
    error.value = 'No se pudo enviar el correo. Verifica la dirección.'
  } finally {
    loading.value = false
  }
}
</script>
