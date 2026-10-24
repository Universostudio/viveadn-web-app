import './assets/main.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { useAuthStore } from './stores/auth'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)

// Inicializar auth antes de montar para que el guard tenga sesión disponible
const auth = useAuthStore()
// La pantalla de inicio se queda al menos 900 ms para que se vea completa
const inicio = performance.now()
auth.init().finally(() => {
  app.mount('#app')
  const splash = document.getElementById('splash')
  if (!splash) return
  const espera = Math.max(0, 900 - (performance.now() - inicio))
  window.setTimeout(() => {
    splash.classList.add('salida')
    window.setTimeout(() => splash.remove(), 500)
  }, espera)
})
