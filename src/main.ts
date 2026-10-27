import './assets/main.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import i18n from './i18n'
import { useAuthStore } from './stores/auth'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)
app.use(i18n)

// Inicializar auth antes de montar para que el guard tenga sesión disponible
const auth = useAuthStore()
auth.init().then(() => {
  app.mount('#app')
})
