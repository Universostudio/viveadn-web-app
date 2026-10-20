/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // ViveADN / CRM Reino brand colors
        reino: {
          azul:    '#1a4d8f',
          dorado:  '#d4af37',
          oscuro:  '#0f2d56',
          claro:   '#2d6cc7',
        },
        alerta: {
          verde:    '#10b981',
          amarillo: '#f59e0b',
          naranja:  '#f97316',
          rojo:     '#ef4444',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
