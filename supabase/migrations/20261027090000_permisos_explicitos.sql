-- Permisos explícitos para todo objeto nuevo en el esquema public.
--
-- Supabase deja de conceder permisos automáticos a las tablas nuevas de public
-- el 30-10-2026 en todos los proyectos existentes:
-- https://supabase.com/changelog/45329-breaking-change-tables-not-exposed-to-data-and-graphql-api-automatically
-- Esta migración adelanta ese comportamiento y lo extiende a secuencias y funciones,
-- para que ningún objeto quede expuesto a la API por omisión.
--
-- Efecto: solo afecta a objetos creados a partir de ahora. Las tablas, secuencias y
-- funciones existentes conservan sus permisos actuales.
--
-- Regla desde esta migración: toda migración que cree una tabla incluye, en el mismo
-- archivo, (1) sus GRANT explícitos, (2) ENABLE ROW LEVEL SECURITY y (3) sus políticas.
-- Toda función nueva incluye su GRANT EXECUTE solo a los roles que la usen.
-- supabase/tests/permisos.sql falla si falta cualquiera de las tres piezas.

alter default privileges for role postgres in schema public
  revoke all on tables from anon, authenticated, service_role;

alter default privileges for role postgres in schema public
  revoke all on sequences from anon, authenticated, service_role;

alter default privileges for role postgres in schema public
  revoke execute on functions from anon, authenticated, service_role;
