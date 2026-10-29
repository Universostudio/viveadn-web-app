-- Invitaciones: un solo uso, caducidad de 15 dias, revocacion y aislamiento entre iglesias.
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
grant execute on function pg_temp.igual(int, int, text) to authenticated, service_role;

insert into auth.users (id) values ('d0000000-0000-0000-0000-000000000001'), ('d0000000-0000-0000-0000-000000000002'), ('d0000000-0000-0000-0000-000000000003');
insert into public.iglesias (id, nombre, slug, pais, ciudad, plan) values
  ('15000000-0000-0000-0000-00000000000a', 'Prueba I1', 'prueba-i1', 'ES', 'Sevilla', 'premium'),
  ('15000000-0000-0000-0000-00000000000b', 'Prueba I2', 'prueba-i2', 'ES', 'Sevilla', 'premium');
insert into public.perfiles (id, iglesia_id, nombre, apellido, email, rol, activo) values
  ('d0000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-00000000000a', 'S', 'Uno', 's@i1.test', 'propietario', true),
  ('d0000000-0000-0000-0000-000000000002', '15000000-0000-0000-0000-00000000000a', 'M', 'Dos', 'm@i1.test', 'miembro', true),
  ('d0000000-0000-0000-0000-000000000003', '15000000-0000-0000-0000-00000000000b', 'S', 'Tres', 's@i2.test', 'propietario', true);

insert into public.invitaciones (iglesia_id, email, nombre, apellido, rol, token_hash, caduca_en) values
  ('15000000-0000-0000-0000-00000000000a', 'a@x.test', 'A', 'A', 'colaborador', repeat('a', 64), now() + interval '15 days'),
  ('15000000-0000-0000-0000-00000000000a', 'b@x.test', 'B', 'B', 'colaborador', repeat('b', 64), now() - interval '1 minute'),
  ('15000000-0000-0000-0000-00000000000a', 'c@x.test', 'C', 'C', 'colaborador', repeat('c', 64), now() + interval '15 days');
update public.invitaciones set revocada_en = now() where token_hash = repeat('c', 64);

select pg_temp.igual((select count(*)::int from public.invitaciones where caduca_en - creada_en <= interval '15 days 1 minute' and caduca_en > creada_en + interval '14 days'), 2, 'la caducidad por defecto es de 15 dias');

set local role service_role;
select pg_temp.igual((select count(*)::int from public.reclamar_invitacion(repeat('a', 64))), 1, 'una invitacion vigente se puede reclamar');
select pg_temp.igual((select count(*)::int from public.reclamar_invitacion(repeat('a', 64))), 0, 'una invitacion ya usada no se reclama dos veces');
select pg_temp.igual((select count(*)::int from public.reclamar_invitacion(repeat('b', 64))), 0, 'una invitacion caducada no se reclama');
select pg_temp.igual((select count(*)::int from public.reclamar_invitacion(repeat('c', 64))), 0, 'una invitacion revocada no se reclama');
select pg_temp.igual((select count(*)::int from public.reclamar_invitacion(repeat('9', 64))), 0, 'una huella inexistente no se reclama');
select public.liberar_invitacion((select id from public.invitaciones where token_hash = repeat('a', 64)));
select pg_temp.igual((select count(*)::int from public.reclamar_invitacion(repeat('a', 64))), 1, 'liberada tras un fallo, se puede reclamar otra vez');
select public.liberar_invitacion((select id from public.invitaciones where token_hash = repeat('c', 64)));
select pg_temp.igual((select count(*)::int from public.reclamar_invitacion(repeat('c', 64))), 0, 'liberar no revive una invitacion revocada');
reset role;

-- Aislamiento: el superadministrador de otra iglesia no ve estas invitaciones; un miembro tampoco
select set_config('request.jwt.claim.sub', 'd0000000-0000-0000-0000-000000000003', true);
set local role authenticated;
select pg_temp.igual((select count(*)::int from public.invitaciones), 0, 'otra iglesia no ve las invitaciones');
reset role;
select set_config('request.jwt.claim.sub', 'd0000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select pg_temp.igual((select count(*)::int from public.invitaciones), 0, 'un miembro sin permiso no ve las invitaciones');
reset role;
select set_config('request.jwt.claim.sub', 'd0000000-0000-0000-0000-000000000001', true);
set local role authenticated;
select pg_temp.igual((select count(*)::int from public.invitaciones), 3, 'el superadministrador ve las de su iglesia');
do $$ begin
  begin insert into public.invitaciones (iglesia_id, email, nombre, apellido, rol, token_hash) values ('15000000-0000-0000-0000-00000000000a','z@x.test','Z','Z','miembro',repeat('d',64));
  exception when others then raise notice 'OK: un usuario no puede crear invitaciones directamente'; return; end;
  raise exception 'FALLO: un usuario creo una invitacion directamente';
end $$;
reset role;
rollback;
