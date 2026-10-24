# Base de datos de ViveADN

Proyecto de producción en Supabase: **viveadn-saas** (ref `xrjbvjqhpwjjtcfdlsbq`, región eu-west-1).
La cuenta tiene otros proyectos de Supabase: comprueba siempre esta referencia antes de ejecutar nada.

## Contenido

- `schema/esquema_completo.sql`: estado completo de la base a 24 de octubre de 2026 (tablas, funciones, triggers, seguridad por filas y permisos). Sirve para reconstruir la base en un proyecto **nuevo y vacío**. No se ejecuta contra producción.
- `schema/seed.sql`: datos de catálogo (módulos, planes, permisos). Sin datos de personas.
- `functions/plataforma/index.ts`: función del panel de plataforma, igual a la desplegada (versión 1).
- `migrations/`: a partir de ahora, cada cambio de base de datos es un archivo aquí.

## Reglas

1. Ningún cambio de base de datos se hace a mano en el editor SQL de producción.
2. Cada cambio es una migración nueva en `migrations/`, con nombre `AAAAMMDDHHMMSS_descripcion.sql`, revisada antes de aplicarse.
3. Al aplicar una migración en producción se registra con el mismo nombre en Supabase, para que el historial coincida.
4. Si se cambia la función `plataforma`, se actualiza aquí en el mismo commit que se despliega.
5. Nunca se suben claves: `.env` está excluido del repositorio.

## Historial ya registrado en producción

Estas cuatro migraciones ya están aplicadas y su contenido está incluido en `esquema_completo.sql`:

| Versión | Nombre |
|---|---|
| 20261024013525 | roles_y_permisos_por_iglesia |
| 20261024015036 | catalogo_modulos_y_planes |
| 20261024015537 | panel_plataforma_base |
| 20261024015554 | plataforma_auditoria |

Lo anterior a ellas (iglesias, miembros, casas, consolidación, endurecimiento de seguridad) se aplicó a mano y solo existe en `esquema_completo.sql`.

## Reconstruir en un proyecto nuevo

1. Crear un proyecto de Supabase vacío.
2. Ejecutar `schema/esquema_completo.sql` y después `schema/seed.sql`.
3. Desplegar `functions/plataforma`.
4. Crear el usuario administrador e insertarlo en `plataforma_admins`.
5. Aplicar en orden las migraciones de `migrations/` posteriores al 24 de octubre de 2026.
