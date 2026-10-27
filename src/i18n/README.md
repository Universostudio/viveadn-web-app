# Idiomas de la web (i18n)

La interfaz usa [vue-i18n](https://vue-i18n.intlify.dev/) 11.4.14 en modo composición. El español es el idioma base y el de respaldo: si falta un texto en otro idioma, se muestra en español.

## Cómo funciona

- `index.ts` crea el plugin, define la lista `IDIOMAS` (código y nombre nativo) y exporta:
  - `setIdioma(codigo)`: cambia el idioma, actualiza `<html lang>` y guarda la elección en `localStorage` (`viveadn.idioma`).
  - `formatoFecha`, `formatoFechaHora`, `formatoHora`, `formatoNumero`: formatean con la región del idioma activo. No escribas `'es-ES'` a mano.
- Idioma inicial: el guardado; si no hay, el primero del navegador que tengamos (pt-* → pt-BR, fr-* → fr, en-* → en, es-* → es); si no, español.
- Los textos están en `locales/<codigo>.json`, agrupados por área: `comun`, `menu`, `login`, `reset`, `panel`, `miembros`, `ficha`, `casas`, `consolidacion`, `formacion`, `comunicacion`, `reportes`, `configuracion`, `plataforma`, `alertas`, `compromiso`, `zonas`.
- En los componentes: `const { t } = useI18n()` y `{{ t('miembros.titulo') }}`.
  - Variables: `"Bienvenido, {nombre}"` → `t('panel.bienvenida', { nombre })`.
  - Plurales con `|`: `"{n} día | {n} días"` → `t('ficha.dias', n)`.
  - Caracteres especiales: `@` se escribe `{'@'}` (por ejemplo en correos de ejemplo); `{`, `}` y `|` también son especiales.
- Lo que viene de la base de datos (nombres, notas, roles, planes) no se traduce. Los valores que se guardan (por ejemplo `en_crecimiento` o `nombre_nivel`) siguen en español; solo se traduce la etiqueta visible.

## Añadir un idioma (por ejemplo italiano)

1. Copia `locales/es.json` como `locales/it.json` y traduce los textos sin tocar las claves.
2. En `index.ts`: importa el archivo, añádelo a `messages` y a `IDIOMAS` (`{ codigo: 'it', nombre: 'Italiano' }`), a `REGION_INTL` (`it: 'it-IT'`) y a `detectarNavegador`. El selector de idioma lee `IDIOMAS`, así que aparece solo.
3. Ejecuta `npm run check:idiomas`: falla si falta o sobra alguna clave respecto a `es.json`, o si hay textos vacíos. También corre en GitHub antes de compilar.

## Estado de las traducciones

- `en`, `fr` y `pt-BR` son borradores pendientes de revisión por hablantes nativos.
- Las plantillas de WhatsApp aprobadas por Meta y los correos de autenticación (Supabase) se traducen por separado; no salen de estos archivos.
