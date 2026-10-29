-- Pruebas de los roles Superadministrador (minimo dos), Co-administrador, Lider de Zona y Colaborador.
\set ON_ERROR_STOP on
begin;
do $$ begin
  if exists (select 1 from public.iglesias where slug not like 'prueba-%') then
    raise exception 'Este script no se ejecuta en una base con iglesias reales';
  end if;
end $$;

create or replace function pg_temp.igual(obtenido int, esperado int, msg text) returns void language plpgsql as $$
begin
  if obtenido is distinct from esperado then raise exception 'FALLO: % (esperado %, obtenido %)', msg, esperado, obtenido; end if;
  raise notice 'OK: %', msg;
end $$;
create or replace function pg_temp.debe_fallar(q text, msg text) returns void language plpgsql as $$
begin
  begin execute q; exception when others then raise notice 'OK: % (%)', msg, sqlerrm; return; end;
  raise exception 'FALLO: % debia fallar y funciono', msg;
end $$;
-- Bloqueado = da error o no afecta a ninguna fila (la seguridad por filas falla en silencio)
create or replace function pg_temp.bloqueado(q text, msg text) returns void language plpgsql as $$
declare n int;
begin
  begin execute q; get diagnostics n = row_count;
  exception when others then raise notice 'OK: % (%)', msg, sqlerrm; return; end;
  if n > 0 then raise exception 'FALLO: % afecto a % filas', msg, n; end if;
  raise notice 'OK: % (0 filas)', msg;
end $$;

insert into auth.users (id) select ('c0000000-0000-0000-0000-0000000000' || lpad(n::text, 2, '0'))::uuid from generate_series(1, 9) n;
insert into public.iglesias (id, nombre, slug, pais, ciudad, plan) values
  ('11000000-0000-0000-0000-00000000000a', 'Prueba R', 'prueba-r', 'ES', 'Sevilla', 'premium');
insert into public.perfiles (id, iglesia_id, nombre, apellido, email, rol, activo) values
  ('c0000000-0000-0000-0000-000000000001', '11000000-0000-0000-0000-00000000000a', 'S1', 'R', 's1@prueba.test', 'propietario', true),
  ('c0000000-0000-0000-0000-000000000002', '11000000-0000-0000-0000-00000000000a', 'S2', 'R', 's2@prueba.test', 'propietario', true),
  ('c0000000-0000-0000-0000-000000000003', '11000000-0000-0000-0000-00000000000a', 'Co', 'R', 'co@prueba.test', 'coadministrador', true),
  ('c0000000-0000-0000-0000-000000000004', '11000000-0000-0000-0000-00000000000a', 'Z1', 'R', 'z1@prueba.test', 'lider_zona', true),
  ('c0000000-0000-0000-0000-000000000005', '11000000-0000-0000-0000-00000000000a', 'Cl', 'R', 'cl@prueba.test', 'colaborador', true),
  ('c0000000-0000-0000-0000-000000000006', '11000000-0000-0000-0000-00000000000a', 'S3', 'R', 's3@prueba.test', 'miembro', true);
insert into public.zonas (id, iglesia_id, codigo, nombre, lider_id) values
  ('12000000-0000-0000-0000-000000000001', '11000000-0000-0000-0000-00000000000a', 'ZN', 'Norte', 'c0000000-0000-0000-0000-000000000004'),
  ('12000000-0000-0000-0000-000000000002', '11000000-0000-0000-0000-00000000000a', 'ZS', 'Sur', null);
insert into public.casas_oracion (id, iglesia_id, zona_id, codigo_zona, nombre, pais, ciudad, direccion) values
  ('13000000-0000-0000-0000-000000000001', '11000000-0000-0000-0000-00000000000a', '12000000-0000-0000-0000-000000000001', 'ZN-100001', 'Casa N', 'ES', 'Sevilla', 'x'),
  ('13000000-0000-0000-0000-000000000002', '11000000-0000-0000-0000-00000000000a', '12000000-0000-0000-0000-000000000002', 'ZS-100002', 'Casa S', 'ES', 'Sevilla', 'x');
insert into public.miembros (id, iglesia_id, nombre, apellido, casa_oracion_id) values
  ('14000000-0000-0000-0000-000000000001', '11000000-0000-0000-0000-00000000000a', 'M', 'Norte', '13000000-0000-0000-0000-000000000001'),
  ('14000000-0000-0000-0000-000000000002', '11000000-0000-0000-0000-00000000000a', 'M', 'Sur', '13000000-0000-0000-0000-000000000002');

grant execute on function pg_temp.igual(int, int, text), pg_temp.debe_fallar(text, text), pg_temp.bloqueado(text, text) to authenticated;

-- Superadministrador: minimo dos
select set_config('request.jwt.claim.sub', 'c0000000-0000-0000-0000-000000000001', true);
set local role authenticated;
select pg_temp.debe_fallar($q$ update public.perfiles set rol = 'administrador' where id = 'c0000000-0000-0000-0000-000000000002' $q$, 'con dos superadministradores no se retira a ninguno');
select pg_temp.debe_fallar($q$ update public.perfiles set activo = false where id = 'c0000000-0000-0000-0000-000000000002' $q$, 'con dos superadministradores no se desactiva a ninguno');
update public.perfiles set rol = 'propietario' where id = 'c0000000-0000-0000-0000-000000000006';
update public.perfiles set rol = 'miembro' where id = 'c0000000-0000-0000-0000-000000000006';
reset role;
select pg_temp.igual((select count(*)::int from public.perfiles where iglesia_id = '11000000-0000-0000-0000-00000000000a' and rol = 'propietario' and activo), 2, 'con un tercero se puede retirar a uno y quedan dos');

-- Co-administrador: opera pero no gestiona usuarios
select set_config('request.jwt.claim.sub', 'c0000000-0000-0000-0000-000000000003', true);
set local role authenticated;
select pg_temp.igual((select count(*)::int from public.miembros), 2, 'co-administrador ve todos los miembros');
select pg_temp.bloqueado($q$ update public.perfiles set rol = 'administrador' where id = 'c0000000-0000-0000-0000-000000000006' $q$, 'co-administrador no cambia roles');
reset role;

-- Lider de zona: solo su zona
select set_config('request.jwt.claim.sub', 'c0000000-0000-0000-0000-000000000004', true);
set local role authenticated;
select pg_temp.igual((select count(*)::int from public.casas_oracion), 1, 'lider de zona ve solo las casas de su zona');
select pg_temp.igual((select count(*)::int from public.miembros), 1, 'lider de zona ve solo los miembros de su zona');
select pg_temp.bloqueado($q$ update public.miembros set nombre = 'X' where id = '14000000-0000-0000-0000-000000000001' $q$, 'lider de zona no edita miembros');
reset role;

-- Colaborador: ve solo lo que registra
select set_config('request.jwt.claim.sub', 'c0000000-0000-0000-0000-000000000005', true);
set local role authenticated;
select pg_temp.igual((select count(*)::int from public.miembros), 0, 'colaborador no ve miembros que no registro');
insert into public.miembros (iglesia_id, nombre, apellido) values ('11000000-0000-0000-0000-00000000000a', 'Nuevo', 'Registrado');
select pg_temp.igual((select count(*)::int from public.miembros), 1, 'colaborador ve el miembro que registro');
select pg_temp.bloqueado($q$ delete from public.miembros where nombre = 'Nuevo' $q$, 'colaborador no elimina');
reset role;

-- Borrar una iglesia entera no se bloquea por la regla de dos superadministradores
delete from public.iglesias where id = '11000000-0000-0000-0000-00000000000a';
select pg_temp.igual((select count(*)::int from public.perfiles where iglesia_id = '11000000-0000-0000-0000-00000000000a'), 0, 'borrar la iglesia borra sus perfiles');
rollback;
