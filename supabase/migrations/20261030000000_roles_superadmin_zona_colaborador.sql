-- Roles nuevos: Superadministrador (antes Propietario, siempre dos), Co-administrador,
-- Líder de Zona y Colaborador. La clave interna 'propietario' no cambia: solo su nombre visible,
-- para no romper políticas, funciones ni datos existentes.

-- 1. Nombre visible
update public.roles set nombre = 'Superadministrador',
  descripcion = 'Acceso total. Siempre debe haber al menos dos. Unico que puede asignar o retirar este rol.'
where clave = 'propietario';

-- 2. Líder de zona y autoría de registros (para el Colaborador)
alter table public.zonas add column if not exists lider_id uuid references public.perfiles(id) on delete set null;
alter table public.miembros add column if not exists creado_por uuid default auth.uid();
alter table public.consolidaciones add column if not exists creado_por uuid default auth.uid();
alter table public.asistencias add column if not exists creado_por uuid default auth.uid();

create or replace function private.es_lider_de_zona(p_zona uuid)
 returns boolean language sql stable security definer set search_path to ''
as $$
  select p_zona is not null and exists (
    select 1 from public.zonas z
    where z.id = p_zona and z.lider_id = (select auth.uid())
      and z.iglesia_id = (select private.get_iglesia_id())
  )
$$;

create or replace function private.es_lider_de_zona_de_casa(p_casa uuid)
 returns boolean language sql stable security definer set search_path to ''
as $$
  select p_casa is not null and exists (
    select 1 from public.casas_oracion c join public.zonas z on z.id = c.zona_id
    where c.id = p_casa and z.lider_id = (select auth.uid())
      and c.iglesia_id = (select private.get_iglesia_id())
  )
$$;
revoke execute on function private.es_lider_de_zona(uuid), private.es_lider_de_zona_de_casa(uuid) from public, anon;
grant execute on function private.es_lider_de_zona(uuid), private.es_lider_de_zona_de_casa(uuid) to authenticated, service_role;

-- 3. Permisos nuevos
insert into public.permisos (clave, modulo, descripcion, sensible) values
('casas.ver_zona', 'casas', 'Ver las casas de oracion de la zona que lidera', false),
('miembros.ver_zona', 'miembros', 'Ver los miembros de las casas de la zona que lidera', false),
('consolidacion.ver_zona', 'consolidacion', 'Ver la consolidacion de las casas de la zona que lidera', false),
('asistencia.ver_zona', 'asistencia', 'Ver la asistencia de las casas de la zona que lidera', false),
('miembros.ver_propios', 'miembros', 'Ver solo los miembros que el mismo registro', false),
('consolidacion.ver_propios', 'consolidacion', 'Ver solo los procesos que el mismo abrio', false),
('asistencia.ver_propia', 'asistencia', 'Ver solo la asistencia que el mismo registro', false)
on conflict (clave) do nothing;

-- 4. Políticas de lectura: se añade el alcance de zona y el de autoría
drop policy casas_ver on public.casas_oracion;
create policy casas_ver on public.casas_oracion for select to authenticated
  using ((iglesia_id = (select private.get_iglesia_id())) and (
    (select private.tiene_permiso('casas.ver'))
    or ((select private.tiene_permiso('casas.ver_propia')) and lider_id = (select auth.uid()))
    or ((select private.tiene_permiso('casas.ver_zona')) and private.es_lider_de_zona(zona_id))));

drop policy miembros_ver on public.miembros;
create policy miembros_ver on public.miembros for select to authenticated
  using ((iglesia_id = (select private.get_iglesia_id())) and (
    (select private.tiene_permiso('miembros.ver'))
    or ((select private.tiene_permiso('miembros.ver_asignados')) and (private.es_consolidador_de(id) or private.es_lider_de_casa(casa_oracion_id)))
    or ((select private.tiene_permiso('miembros.ver_zona')) and private.es_lider_de_zona_de_casa(casa_oracion_id))
    or ((select private.tiene_permiso('miembros.ver_propios')) and creado_por = (select auth.uid()))));

drop policy consolidaciones_ver on public.consolidaciones;
create policy consolidaciones_ver on public.consolidaciones for select to authenticated
  using ((iglesia_id = (select private.get_iglesia_id())) and (
    (select private.tiene_permiso('consolidacion.ver'))
    or ((select private.tiene_permiso('consolidacion.ver_asignados')) and consolidador_id = (select auth.uid()))
    or ((select private.tiene_permiso('consolidacion.ver_casa')) and private.es_lider_de_casa(casa_oracion_id))
    or ((select private.tiene_permiso('consolidacion.ver_zona')) and private.es_lider_de_zona_de_casa(casa_oracion_id))
    or ((select private.tiene_permiso('consolidacion.ver_propios')) and creado_por = (select auth.uid()))));

drop policy asistencias_ver on public.asistencias;
create policy asistencias_ver on public.asistencias for select to authenticated
  using ((iglesia_id = (select private.get_iglesia_id())) and (
    (select private.tiene_permiso('asistencia.ver'))
    or ((select private.tiene_permiso('asistencia.registrar_propia')) and private.es_lider_de_casa(casa_oracion_id))
    or ((select private.tiene_permiso('asistencia.ver_zona')) and private.es_lider_de_zona_de_casa(casa_oracion_id))
    or ((select private.tiene_permiso('asistencia.ver_propia')) and creado_por = (select auth.uid()))));

-- 5. Roles nuevos y su siembra (también para las iglesias que ya existen)
create or replace function private.sembrar_roles_nuevos(p_iglesia uuid)
 returns void language plpgsql security definer set search_path to ''
as $$
declare v_id uuid;
begin
  insert into public.roles (iglesia_id, clave, nombre, descripcion, es_sistema, es_propietario) values
    (p_iglesia,'coadministrador','Co-administrador','Opera miembros, casas, consolidacion, formacion y reportes. No gestiona usuarios, roles ni configuracion.',true,false),
    (p_iglesia,'lider_zona','Lider de Zona','Ve las casas de su zona, sus miembros, consolidacion y asistencia.',true,false),
    (p_iglesia,'colaborador','Colaborador','Registra asistencia y nuevos convertidos y ve solo lo que registra.',true,false)
  on conflict (iglesia_id, clave) do nothing;

  select id into v_id from public.roles where iglesia_id = p_iglesia and clave = 'coadministrador';
  insert into public.rol_permisos (rol_id, permiso)
    select v_id, clave from public.permisos
    where clave not in ('iglesia.configurar','roles.gestionar','usuarios.gestionar')
      and clave not like '%.ver_zona' and clave not like '%.ver_propi%' and clave not like '%.ver_asignados'
      and clave not in ('casas.ver_propia','asistencia.registrar_propia','consolidacion.ver_casa','consolidacion.registrar_contacto')
  on conflict do nothing;

  select id into v_id from public.roles where iglesia_id = p_iglesia and clave = 'lider_zona';
  insert into public.rol_permisos (rol_id, permiso)
    select v_id, unnest(array['casas.ver_zona','miembros.ver_zona','consolidacion.ver_zona','asistencia.ver_zona',
                              'zonas.ver','usuarios.ver','reportes.ver','gamificacion.ver'])
  on conflict do nothing;

  select id into v_id from public.roles where iglesia_id = p_iglesia and clave = 'colaborador';
  insert into public.rol_permisos (rol_id, permiso)
    select v_id, unnest(array['asistencia.registrar','asistencia.ver_propia','miembros.crear','miembros.ver_propios',
                              'consolidacion.crear','consolidacion.ver_propios','casas.ver','zonas.ver'])
  on conflict do nothing;
end;
$$;
revoke execute on function private.sembrar_roles_nuevos(uuid) from public, anon, authenticated;
grant execute on function private.sembrar_roles_nuevos(uuid) to service_role;

create or replace function private.trg_sembrar_roles()
 returns trigger language plpgsql security definer set search_path to ''
as $$
begin
  perform private.sembrar_roles(new.id);
  perform private.sembrar_roles_nuevos(new.id);
  return new;
end;
$$;

select private.sembrar_roles_nuevos(id) from public.iglesias;

-- 6. Siempre dos superadministradores: no se puede bajar de dos, ni dejar a la iglesia sin ninguno.
create or replace function private.trg_minimo_superadmins()
 returns trigger language plpgsql security definer set search_path to ''
as $$
declare v_antes int; v_baja boolean;
begin
  if tg_op = 'DELETE' then
    v_baja := old.rol = 'propietario' and coalesce(old.activo, true);
  else
    v_baja := old.rol = 'propietario' and coalesce(old.activo, true)
              and (new.rol is distinct from 'propietario' or not coalesce(new.activo, true));
  end if;
  if not v_baja then return coalesce(new, old); end if;
  -- si la iglesia se borra entera no hay nada que proteger
  if not exists (select 1 from public.iglesias where id = old.iglesia_id) then return coalesce(new, old); end if;
  select count(*) into v_antes from public.perfiles
    where iglesia_id = old.iglesia_id and rol = 'propietario' and coalesce(activo, true);
  if v_antes <= 2 then
    raise exception 'Debe haber al menos dos superadministradores activos';
  end if;
  return coalesce(new, old);
end;
$$;
drop trigger if exists minimo_superadmins on public.perfiles;
create trigger minimo_superadmins before update or delete on public.perfiles
  for each row execute function private.trg_minimo_superadmins();
