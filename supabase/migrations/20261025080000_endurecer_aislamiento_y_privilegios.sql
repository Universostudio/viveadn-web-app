-- =====================================================================
-- Endurecimiento tras la revision independiente del 24-10-2026
-- Corrige los hallazgos S6 a S14 del documento de estado.
--   S6  propietario: nadie salvo el propietario puede crearlo, cambiarlo o
--       desactivarlo; la iglesia conserva siempre un propietario activo.
--   S7  referencias entre iglesias: claves foraneas compuestas por iglesia
--       y funciones de ayuda filtradas por iglesia.
--   S9  usuarios desactivados sin acceso.
--   S10 crm_id lo fija el servidor; la secuencia no es accesible.
--   S11 el consolidador solo edita contactos, resultado, notas y cierre.
--   S12 indices para las politicas y las claves foraneas.
--   S14 privilegios sobrantes y roles del sistema inmutables.
-- =====================================================================

-- ---------------------------------------------------------------------
-- S9. Un perfil desactivado deja de pertenecer a efectos de acceso
-- ---------------------------------------------------------------------
create or replace function private.get_iglesia_id()
 returns uuid
 language sql
 stable security definer
 set search_path to ''
as $function$
  select iglesia_id from public.perfiles where id = (select auth.uid()) and activo
$function$;

-- ---------------------------------------------------------------------
-- S7. Funciones de ayuda limitadas a la iglesia de quien consulta
-- ---------------------------------------------------------------------
create or replace function private.es_consolidador_de(p_miembro uuid)
 returns boolean
 language sql
 stable security definer
 set search_path to ''
as $function$
  select exists (
    select 1 from public.consolidaciones c
    where c.miembro_id = p_miembro
      and c.consolidador_id = (select auth.uid())
      and c.iglesia_id = (select private.get_iglesia_id())
  )
$function$;

create or replace function private.es_lider_de_casa(p_casa uuid)
 returns boolean
 language sql
 stable security definer
 set search_path to ''
as $function$
  select exists (
    select 1 from public.casas_oracion c
    where c.id = p_casa
      and c.lider_id = (select auth.uid())
      and c.iglesia_id = (select private.get_iglesia_id())
  )
$function$;

-- S7. Claves foraneas compuestas: toda referencia apunta a la misma iglesia
alter table public.miembros add constraint miembros_iglesia_id_id_key unique (iglesia_id, id);
alter table public.casas_oracion add constraint casas_oracion_iglesia_id_id_key unique (iglesia_id, id);
alter table public.perfiles add constraint perfiles_iglesia_id_id_key unique (iglesia_id, id);
alter table public.zonas add constraint zonas_iglesia_id_id_key unique (iglesia_id, id);

alter table public.asistencias drop constraint asistencias_casa_oracion_id_fkey,
  add constraint asistencias_casa_oracion_fk foreign key (iglesia_id, casa_oracion_id) references public.casas_oracion (iglesia_id, id);
alter table public.asistencias drop constraint asistencias_miembro_id_fkey,
  add constraint asistencias_miembro_fk foreign key (iglesia_id, miembro_id) references public.miembros (iglesia_id, id);

alter table public.casas_oracion drop constraint casas_oracion_lider_id_fkey,
  add constraint casas_oracion_lider_fk foreign key (iglesia_id, lider_id) references public.perfiles (iglesia_id, id);
alter table public.casas_oracion drop constraint casas_oracion_zona_id_fkey,
  add constraint casas_oracion_zona_fk foreign key (iglesia_id, zona_id) references public.zonas (iglesia_id, id);

alter table public.consolidaciones drop constraint consolidaciones_miembro_id_fkey,
  add constraint consolidaciones_miembro_fk foreign key (iglesia_id, miembro_id) references public.miembros (iglesia_id, id);
alter table public.consolidaciones drop constraint consolidaciones_casa_oracion_id_fkey,
  add constraint consolidaciones_casa_oracion_fk foreign key (iglesia_id, casa_oracion_id) references public.casas_oracion (iglesia_id, id);
alter table public.consolidaciones drop constraint consolidaciones_consolidador_id_fkey,
  add constraint consolidaciones_consolidador_fk foreign key (iglesia_id, consolidador_id) references public.perfiles (iglesia_id, id);

alter table public.logros drop constraint logros_miembro_id_fkey,
  add constraint logros_miembro_fk foreign key (iglesia_id, miembro_id) references public.miembros (iglesia_id, id);

alter table public.miembros drop constraint miembros_casa_oracion_id_fkey,
  add constraint miembros_casa_oracion_fk foreign key (iglesia_id, casa_oracion_id) references public.casas_oracion (iglesia_id, id);

alter table public.progreso_formacion drop constraint progreso_formacion_miembro_id_fkey,
  add constraint progreso_formacion_miembro_fk foreign key (iglesia_id, miembro_id) references public.miembros (iglesia_id, id);
alter table public.progreso_formacion drop constraint progreso_formacion_actualizado_por_fkey,
  add constraint progreso_formacion_actualizado_por_fk foreign key (iglesia_id, actualizado_por) references public.perfiles (iglesia_id, id);

-- ---------------------------------------------------------------------
-- S6. Proteccion del propietario
-- ---------------------------------------------------------------------
-- Los perfiles los crea solo el servidor (invitaciones con service_role)
drop policy if exists perfiles_crear on public.perfiles;

create or replace function private.hay_otro_propietario_activo(p_iglesia uuid, p_excluir uuid)
 returns boolean
 language sql
 stable security definer
 set search_path to ''
as $function$
  select exists (
    select 1 from public.perfiles
    where iglesia_id = p_iglesia and rol = 'propietario' and activo and id <> p_excluir
  )
$function$;
revoke execute on function private.hay_otro_propietario_activo(uuid, uuid) from public, anon;
grant execute on function private.hay_otro_propietario_activo(uuid, uuid) to authenticated, service_role;

create or replace function private.guardar_perfil()
 returns trigger
 language plpgsql
 set search_path to ''
as $function$
begin
  -- Sin sesion (service_role, migraciones): sin restricciones
  if (select auth.uid()) is null then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.rol = 'propietario' and not private.es_propietario() then
      raise exception 'Solo el propietario puede crear otro propietario';
    end if;
    return new;
  end if;

  if new.id is distinct from old.id then
    raise exception 'No se puede cambiar el identificador de un usuario';
  end if;
  if new.iglesia_id is distinct from old.iglesia_id then
    raise exception 'No se puede cambiar la iglesia de un usuario';
  end if;
  if new.email is distinct from old.email then
    raise exception 'El correo se cambia desde la cuenta de acceso, no desde el perfil';
  end if;
  if (new.rol is distinct from old.rol or new.activo is distinct from old.activo)
     and not private.tiene_permiso('usuarios.gestionar') then
    raise exception 'Sin permiso para cambiar el rol o el estado de un usuario';
  end if;
  if new.id = (select auth.uid()) and new.activo is distinct from old.activo then
    raise exception 'No puedes cambiar tu propio estado';
  end if;
  if (new.rol = 'propietario' or old.rol = 'propietario')
     and (new.rol is distinct from old.rol or new.activo is distinct from old.activo)
     and not private.es_propietario() then
    raise exception 'Solo el propietario puede asignar, retirar o desactivar el rol de propietario';
  end if;
  if old.rol = 'propietario' and old.activo
     and (new.rol is distinct from 'propietario' or not coalesce(new.activo, false))
     and not private.hay_otro_propietario_activo(old.iglesia_id, old.id) then
    raise exception 'La iglesia debe conservar al menos un propietario activo';
  end if;
  return new;
end;
$function$;

drop trigger if exists perfiles_guardar on public.perfiles;
create trigger perfiles_guardar before insert or update on public.perfiles
  for each row execute function private.guardar_perfil();

-- ---------------------------------------------------------------------
-- S10. crm_id lo asigna siempre el servidor
-- ---------------------------------------------------------------------
create or replace function private.fijar_crm_id()
 returns trigger
 language plpgsql
 security definer
 set search_path to ''
as $function$
begin
  if tg_op = 'INSERT' then
    -- Con sesion se ignora cualquier valor enviado; sin sesion (importaciones) se respeta si viene
    if (select auth.uid()) is not null or new.crm_id is null then
      new.crm_id := public.generar_crm_id();
    end if;
  elsif (select auth.uid()) is not null then
    new.crm_id := old.crm_id;
  end if;
  return new;
end;
$function$;
revoke execute on function private.fijar_crm_id() from public, anon, authenticated, service_role;

alter table public.miembros alter column crm_id drop default;
create trigger miembros_crm_id before insert or update on public.miembros
  for each row execute function private.fijar_crm_id();

revoke all on sequence public.crm_id_seq from anon, authenticated;
revoke execute on function public.generar_crm_id() from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- S11. El consolidador sin permiso de edicion solo registra contactos
-- ---------------------------------------------------------------------
create or replace function private.guardar_consolidacion()
 returns trigger
 language plpgsql
 set search_path to ''
as $function$
declare
  v_libres text[] := array['primer_contacto_fecha','primer_contacto_notas',
    'segundo_contacto_fecha','segundo_contacto_notas','tercer_contacto_fecha',
    'tercer_contacto_notas','resultado','notas','completado','completado_at','updated_at'];
begin
  if (select auth.uid()) is null then
    return new;
  end if;
  if new.iglesia_id is distinct from old.iglesia_id or new.miembro_id is distinct from old.miembro_id then
    raise exception 'No se puede cambiar el miembro ni la iglesia de una consolidacion';
  end if;
  if new.consolidador_id is distinct from old.consolidador_id
     and not private.tiene_permiso('consolidacion.reasignar') then
    raise exception 'Sin permiso para reasignar el consolidador';
  end if;
  if not private.tiene_permiso('consolidacion.editar') then
    if private.tiene_permiso('consolidacion.reasignar') then
      v_libres := v_libres || 'consolidador_id';
    end if;
    if (to_jsonb(new) - v_libres) is distinct from (to_jsonb(old) - v_libres) then
      raise exception 'Solo puedes registrar contactos, resultado, notas y el cierre';
    end if;
  end if;
  return new;
end;
$function$;

-- Asistencias: el lider solo mueve asistencias dentro de sus casas
drop policy if exists asistencias_editar on public.asistencias;
create policy asistencias_editar on public.asistencias for update to authenticated
  using ((iglesia_id = (select private.get_iglesia_id())) and ((select private.tiene_permiso('asistencia.registrar')) or ((select private.tiene_permiso('asistencia.registrar_propia')) and private.es_lider_de_casa(casa_oracion_id))))
  with check ((iglesia_id = (select private.get_iglesia_id())) and ((select private.tiene_permiso('asistencia.registrar')) or ((select private.tiene_permiso('asistencia.registrar_propia')) and private.es_lider_de_casa(casa_oracion_id))));

-- ---------------------------------------------------------------------
-- S14. Roles del sistema: clave, tipo e iglesia inmutables
-- ---------------------------------------------------------------------
create or replace function private.guardar_rol()
 returns trigger
 language plpgsql
 set search_path to ''
as $function$
begin
  if (select auth.uid()) is null then
    return new;
  end if;
  if new.iglesia_id is distinct from old.iglesia_id then
    raise exception 'No se puede cambiar la iglesia de un rol';
  end if;
  if new.es_sistema is distinct from old.es_sistema or new.es_propietario is distinct from old.es_propietario then
    raise exception 'No se puede cambiar el tipo de un rol';
  end if;
  if old.es_sistema and new.clave is distinct from old.clave then
    raise exception 'No se puede cambiar la clave de un rol del sistema';
  end if;
  return new;
end;
$function$;
create trigger roles_guardar before update on public.roles
  for each row execute function private.guardar_rol();

revoke execute on function private.guardar_perfil() from public, anon, authenticated, service_role;
revoke execute on function private.guardar_consolidacion() from public, anon, authenticated, service_role;
revoke execute on function private.guardar_rol() from public, anon, authenticated, service_role;

-- ---------------------------------------------------------------------
-- S12. Indices para politicas y claves foraneas
-- ---------------------------------------------------------------------
create index if not exists asistencias_casa_idx on public.asistencias (iglesia_id, casa_oracion_id);
create index if not exists asistencias_miembro_idx on public.asistencias (iglesia_id, miembro_id);
create index if not exists casas_oracion_lider_idx on public.casas_oracion (iglesia_id, lider_id);
create index if not exists casas_oracion_zona_idx on public.casas_oracion (iglesia_id, zona_id);
create index if not exists consolidaciones_miembro_idx on public.consolidaciones (iglesia_id, miembro_id);
create index if not exists consolidaciones_consolidador_idx on public.consolidaciones (iglesia_id, consolidador_id);
create index if not exists consolidaciones_casa_idx on public.consolidaciones (iglesia_id, casa_oracion_id);
create index if not exists logros_miembro_idx on public.logros (iglesia_id, miembro_id);
create index if not exists miembros_casa_idx on public.miembros (iglesia_id, casa_oracion_id);
create index if not exists progreso_formacion_miembro_idx on public.progreso_formacion (iglesia_id, miembro_id);
create index if not exists progreso_formacion_actualizado_idx on public.progreso_formacion (iglesia_id, actualizado_por);
create index if not exists perfiles_rol_idx on public.perfiles (iglesia_id, rol);
create index if not exists iglesias_plan_idx on public.iglesias (plan);
create index if not exists permisos_modulo_idx on public.permisos (modulo);
create index if not exists plan_modulos_modulo_idx on public.plan_modulos (modulo);
create index if not exists rol_permisos_permiso_idx on public.rol_permisos (permiso);
create index if not exists iglesia_modulos_modulo_idx on public.iglesia_modulos (modulo);
create index if not exists plataforma_auditoria_actor_idx on public.plataforma_auditoria (actor);

-- ---------------------------------------------------------------------
-- S14. Privilegios sobrantes
-- ---------------------------------------------------------------------
-- anon no necesita ninguna tabla ni secuencia: todo exige sesion
revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;
-- authenticated: sin TRUNCATE (se salta RLS), REFERENCES ni TRIGGER
revoke truncate, references, trigger on all tables in schema public from authenticated;
revoke all on sequence public.plataforma_auditoria_id_seq from authenticated;
do $$
begin
  if current_setting('server_version_num')::int >= 170000 then
    execute 'revoke maintain on all tables in schema public from anon, authenticated';
  end if;
end $$;

-- Lo mismo para tablas y funciones futuras
alter default privileges for role postgres in schema public revoke all on tables from anon;
alter default privileges for role postgres in schema public revoke all on sequences from anon;
alter default privileges for role postgres in schema public revoke truncate, references, trigger on tables from authenticated;
alter default privileges for role postgres in schema public revoke execute on functions from anon;
alter default privileges for role postgres revoke execute on functions from public;
