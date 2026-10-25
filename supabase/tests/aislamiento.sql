-- =====================================================================
-- Pruebas de aislamiento entre iglesias y de permisos por rol.
-- Cada bloque reproduce un ataque o una operacion legitima. Si un ataque
-- funciona, el script se detiene con un mensaje que empieza por FALLO.
-- Todo ocurre dentro de una transaccion que se deshace al final.
-- NUNCA se ejecuta en produccion: se niega si encuentra iglesias reales.
-- =====================================================================
\set ON_ERROR_STOP on
begin;

do $$
begin
  if exists (select 1 from public.iglesias where slug not like 'prueba-%') then
    raise exception 'Este script no se ejecuta en una base con iglesias reales';
  end if;
end $$;

-- ---------------------------------------------------------------------
-- Datos de prueba (como postgres, sin sesion)
-- A: propietario pa, administrador aa, lider la, consolidador ca, admin inactivo ia
-- B: propietario pb, lider lb
-- ---------------------------------------------------------------------
insert into auth.users (id) values
  ('a0000000-0000-0000-0000-0000000000a1'), ('a0000000-0000-0000-0000-0000000000a2'),
  ('a0000000-0000-0000-0000-0000000000a3'), ('a0000000-0000-0000-0000-0000000000a4'),
  ('a0000000-0000-0000-0000-0000000000a5'), ('a0000000-0000-0000-0000-0000000000a9'),
  ('b0000000-0000-0000-0000-0000000000b1'), ('b0000000-0000-0000-0000-0000000000b3');

insert into public.iglesias (id, nombre, slug, pais, ciudad, plan) values
  ('10000000-0000-0000-0000-00000000000a', 'Prueba A', 'prueba-a', 'ES', 'Sevilla', 'premium'),
  ('10000000-0000-0000-0000-00000000000b', 'Prueba B', 'prueba-b', 'CO', 'Bogota', 'premium');

insert into public.perfiles (id, iglesia_id, nombre, apellido, email, rol, activo) values
  ('a0000000-0000-0000-0000-0000000000a1', '10000000-0000-0000-0000-00000000000a', 'Pa', 'A', 'pa@prueba.test', 'propietario', true),
  ('a0000000-0000-0000-0000-0000000000a2', '10000000-0000-0000-0000-00000000000a', 'Aa', 'A', 'aa@prueba.test', 'administrador', true),
  ('a0000000-0000-0000-0000-0000000000a3', '10000000-0000-0000-0000-00000000000a', 'La', 'A', 'la@prueba.test', 'lider_casa', true),
  ('a0000000-0000-0000-0000-0000000000a4', '10000000-0000-0000-0000-00000000000a', 'Ca', 'A', 'ca@prueba.test', 'consolidador', true),
  ('a0000000-0000-0000-0000-0000000000a5', '10000000-0000-0000-0000-00000000000a', 'Ia', 'A', 'ia@prueba.test', 'administrador', false),
  ('b0000000-0000-0000-0000-0000000000b1', '10000000-0000-0000-0000-00000000000b', 'Pb', 'B', 'pb@prueba.test', 'propietario', true),
  ('b0000000-0000-0000-0000-0000000000b3', '10000000-0000-0000-0000-00000000000b', 'Lb', 'B', 'lb@prueba.test', 'lider_casa', true);

insert into public.casas_oracion (id, iglesia_id, codigo_zona, nombre, lider_id, pais, ciudad, direccion) values
  ('20000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-00000000000a', 'ZN-000001', 'Casa A', 'a0000000-0000-0000-0000-0000000000a3', 'ES', 'Sevilla', 'Calle A'),
  ('20000000-0000-0000-0000-00000000000b', '10000000-0000-0000-0000-00000000000b', 'ZN-000002', 'Casa B', 'b0000000-0000-0000-0000-0000000000b3', 'CO', 'Bogota', 'Calle B');

insert into public.miembros (id, iglesia_id, nombre, apellido, casa_oracion_id) values
  ('30000000-0000-0000-0000-0000000000a1', '10000000-0000-0000-0000-00000000000a', 'MiembroA1', 'A', '20000000-0000-0000-0000-00000000000a'),
  ('30000000-0000-0000-0000-0000000000a2', '10000000-0000-0000-0000-00000000000a', 'MiembroA2', 'A', null),
  ('30000000-0000-0000-0000-0000000000b1', '10000000-0000-0000-0000-00000000000b', 'MiembroB1', 'B', '20000000-0000-0000-0000-00000000000b'),
  ('30000000-0000-0000-0000-0000000000b2', '10000000-0000-0000-0000-00000000000b', 'SecretoB2', 'B', null);

insert into public.consolidaciones (id, iglesia_id, miembro_id, consolidador_id) values
  ('40000000-0000-0000-0000-0000000000a1', '10000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-0000000000a2', 'a0000000-0000-0000-0000-0000000000a4');

-- Funcion de prueba: afirma que una sentencia falla
create function pg_temp.debe_fallar(p_sql text, p_nombre text) returns void language plpgsql as $$
begin
  begin
    execute p_sql;
  exception when others then
    return;
  end;
  raise exception 'FALLO %: la operacion debia rechazarse y se acepto', p_nombre;
end $$;
grant execute on function pg_temp.debe_fallar(text, text) to authenticated, anon;

create function pg_temp.igual(p_valor bigint, p_esperado bigint, p_nombre text) returns void language plpgsql as $$
begin
  if p_valor is distinct from p_esperado then
    raise exception 'FALLO %: se obtuvo %, se esperaba %', p_nombre, p_valor, p_esperado;
  end if;
end $$;
grant execute on function pg_temp.igual(bigint, bigint, text) to authenticated, anon;

-- ---------------------------------------------------------------------
-- 1. Lectura aislada (propietario de A)
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', 'a0000000-0000-0000-0000-0000000000a1', true);
set local role authenticated;
select pg_temp.igual((select count(*) from public.iglesias), 1, 'propietario A ve solo su iglesia');
select pg_temp.igual((select count(*) from public.miembros), 2, 'propietario A ve solo sus 2 miembros');
select pg_temp.igual((select count(*) from public.miembros where nombre = 'SecretoB2'), 0, 'propietario A no ve miembros de B');
select pg_temp.igual((select count(*) from public.roles where iglesia_id <> '10000000-0000-0000-0000-00000000000a'), 0, 'propietario A no ve roles de B');

-- S6: el propietario no puede quedarse sin propietario
select pg_temp.debe_fallar($q$ update public.perfiles set rol = 'administrador' where id = 'a0000000-0000-0000-0000-0000000000a1' $q$, 'S6 unico propietario se degrada a si mismo');
select pg_temp.debe_fallar($q$ update public.perfiles set activo = false where id = 'a0000000-0000-0000-0000-0000000000a1' $q$, 'S6 propietario se desactiva a si mismo');

-- S14: roles del sistema inmutables
select pg_temp.debe_fallar($q$ update public.roles set clave = 'admin2' where clave = 'administrador' $q$, 'S14 renombrar clave de rol del sistema');
select pg_temp.debe_fallar($q$ truncate public.miembros $q$, 'S14 TRUNCATE salta RLS');
reset role;

-- ---------------------------------------------------------------------
-- 2. Administrador de A intenta apoderarse del propietario (S6)
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', 'a0000000-0000-0000-0000-0000000000a2', true);
set local role authenticated;
select pg_temp.debe_fallar($q$ insert into public.perfiles (id, iglesia_id, nombre, apellido, email, rol) values ('a0000000-0000-0000-0000-0000000000a9', '10000000-0000-0000-0000-00000000000a', 'X', 'X', 'x@prueba.test', 'propietario') $q$, 'S6 insertar perfil propietario');
select pg_temp.debe_fallar($q$ insert into public.perfiles (id, iglesia_id, nombre, apellido, email, rol) values ('a0000000-0000-0000-0000-0000000000a9', '10000000-0000-0000-0000-00000000000a', 'X', 'X', 'x@prueba.test', 'miembro') $q$, 'S6 crear perfiles desde el cliente');
select pg_temp.debe_fallar($q$ update public.perfiles set activo = false where id = 'a0000000-0000-0000-0000-0000000000a1' $q$, 'S6 desactivar al propietario');
select pg_temp.debe_fallar($q$ update public.perfiles set rol = 'administrador' where id = 'a0000000-0000-0000-0000-0000000000a1' $q$, 'S6 degradar al propietario');
select pg_temp.debe_fallar($q$ update public.perfiles set id = 'a0000000-0000-0000-0000-0000000000a9' where id = 'a0000000-0000-0000-0000-0000000000a1' $q$, 'S6 trasladar la fila del propietario');
select pg_temp.debe_fallar($q$ update public.perfiles set rol = 'propietario' where id = 'a0000000-0000-0000-0000-0000000000a2' $q$, 'S6 hacerse propietario');
select pg_temp.debe_fallar($q$ update public.perfiles set activo = false where id = 'a0000000-0000-0000-0000-0000000000a2' $q$, 'S6 cambiar su propio estado');
delete from public.perfiles where id = 'a0000000-0000-0000-0000-0000000000a1';

-- Operacion legitima: el administrador cambia el rol de un lider y lo devuelve
update public.perfiles set rol = 'consolidador' where id = 'a0000000-0000-0000-0000-0000000000a3';
update public.perfiles set rol = 'lider_casa' where id = 'a0000000-0000-0000-0000-0000000000a3';

-- ---------------------------------------------------------------------
-- 3. Referencias a otra iglesia (S7)
-- ---------------------------------------------------------------------
select pg_temp.debe_fallar($q$ insert into public.consolidaciones (iglesia_id, miembro_id, consolidador_id) values ('10000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-0000000000b2', 'b0000000-0000-0000-0000-0000000000b3') $q$, 'S7 consolidacion que apunta a miembro y lider de B');
select pg_temp.debe_fallar($q$ insert into public.consolidaciones (iglesia_id, miembro_id) values ('10000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-0000000000b2') $q$, 'S7 consolidacion que apunta a miembro de B');
select pg_temp.debe_fallar($q$ insert into public.miembros (iglesia_id, nombre, apellido, casa_oracion_id) values ('10000000-0000-0000-0000-00000000000a', 'X', 'X', '20000000-0000-0000-0000-00000000000b') $q$, 'S7 miembro en casa de B');
select pg_temp.debe_fallar($q$ update public.casas_oracion set lider_id = 'b0000000-0000-0000-0000-0000000000b3' where id = '20000000-0000-0000-0000-00000000000a' $q$, 'S7 lider de B en casa de A');
select pg_temp.debe_fallar($q$ insert into public.asistencias (iglesia_id, casa_oracion_id, miembro_id) values ('10000000-0000-0000-0000-00000000000a', '20000000-0000-0000-0000-00000000000b', '30000000-0000-0000-0000-0000000000b1') $q$, 'S7 asistencia en casa de B');
select pg_temp.debe_fallar($q$ insert into public.miembros (iglesia_id, nombre, apellido) values ('10000000-0000-0000-0000-00000000000b', 'X', 'X') $q$, 'S7 insertar miembro en B');

-- S10: crm_id lo fija el servidor
insert into public.miembros (id, iglesia_id, nombre, apellido, crm_id) values ('30000000-0000-0000-0000-0000000000a3', '10000000-0000-0000-0000-00000000000a', 'Nuevo', 'A', 'CRM-HACK');
select pg_temp.igual((select count(*) from public.miembros where crm_id = 'CRM-HACK'), 0, 'S10 crm_id enviado por el cliente se ignora');
update public.miembros set crm_id = 'CRM-HACK2' where id = '30000000-0000-0000-0000-0000000000a3';
select pg_temp.igual((select count(*) from public.miembros where crm_id = 'CRM-HACK2'), 0, 'S10 crm_id no se puede cambiar');
select pg_temp.debe_fallar($q$ select setval('public.crm_id_seq', 999) $q$, 'S10 mover la secuencia');
select pg_temp.debe_fallar($q$ select public.generar_crm_id() $q$, 'S10 consumir la secuencia');
reset role;

-- El lider de B sigue viendo solo lo suyo despues de los intentos
select set_config('request.jwt.claim.sub', 'b0000000-0000-0000-0000-0000000000b3', true);
set local role authenticated;
select pg_temp.igual((select count(*) from public.miembros), 1, 'S7 lider de B ve solo el miembro de su casa');
reset role;

-- El propietario de A sigue existiendo
select pg_temp.igual((select count(*) from public.perfiles where id = 'a0000000-0000-0000-0000-0000000000a1' and rol = 'propietario' and activo), 1, 'S6 el propietario de A sigue intacto');

-- ---------------------------------------------------------------------
-- 4. Usuario desactivado (S9)
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', 'a0000000-0000-0000-0000-0000000000a5', true);
set local role authenticated;
select pg_temp.igual((select count(*) from public.iglesias), 0, 'S9 inactivo no ve su iglesia');
select pg_temp.igual((select count(*) from public.roles), 0, 'S9 inactivo no ve roles');
select pg_temp.igual((select count(*) from public.perfiles), 0, 'S9 inactivo no ve perfiles');
select pg_temp.igual((select count(*) from public.rol_permisos), 0, 'S9 inactivo no ve permisos de rol');
reset role;

-- ---------------------------------------------------------------------
-- 5. Consolidador (S11)
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', 'a0000000-0000-0000-0000-0000000000a4', true);
set local role authenticated;
select pg_temp.igual((select count(*) from public.miembros), 1, 'consolidador ve solo su nuevo convertido');
update public.consolidaciones set primer_contacto_fecha = now(), primer_contacto_notas = 'Llamada' where id = '40000000-0000-0000-0000-0000000000a1';
select pg_temp.igual((select count(*) from public.consolidaciones where primer_contacto_notas = 'Llamada'), 1, 'S11 consolidador registra un contacto');
select pg_temp.debe_fallar($q$ update public.consolidaciones set fecha_conversion = now() - interval '5 days' where id = '40000000-0000-0000-0000-0000000000a1' $q$, 'S11 falsear la fecha de conversion');
select pg_temp.debe_fallar($q$ update public.consolidaciones set casa_oracion_id = '20000000-0000-0000-0000-00000000000a' where id = '40000000-0000-0000-0000-0000000000a1' $q$, 'S11 cambiar la casa');
select pg_temp.debe_fallar($q$ update public.consolidaciones set estado_alerta = 'rojo' where id = '40000000-0000-0000-0000-0000000000a1' $q$, 'S11 cambiar el color de la alerta');
update public.consolidaciones set completado = true, completado_at = now() where id = '40000000-0000-0000-0000-0000000000a1';
reset role;

-- ---------------------------------------------------------------------
-- 6. Sin sesion (anon)
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', '', true);
set local role anon;
select pg_temp.debe_fallar($q$ select count(*) from public.miembros $q$, 'S14 anon lee miembros');
select pg_temp.debe_fallar($q$ select private.tiene_permiso('miembros.ver') $q$, 'anon ejecuta funciones privadas');
reset role;

select 'TODAS LAS PRUEBAS PASARON' as resultado;
rollback;
