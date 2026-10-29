-- Invitaciones propias de un solo uso que caducan a los 15 dias.
-- Supabase solo permite enlaces de correo de hasta 24 horas, asi que las invitaciones de acceso
-- se gestionan aqui. En la tabla solo se guarda la huella SHA-256 del enlace, nunca el enlace.
-- Toda escritura la hace la funcion de servidor `invitaciones` con service_role.

create table public.invitaciones (
  id uuid primary key default gen_random_uuid(),
  iglesia_id uuid not null references public.iglesias(id) on delete cascade,
  email text not null check (email = lower(email) and email ~ '^[^\s@]+@[^\s@]+\.[^\s@]+$'),
  nombre text not null check (length(nombre) between 1 and 60),
  apellido text not null check (length(apellido) between 1 and 60),
  rol text not null,
  token_hash text not null unique check (token_hash ~ '^[0-9a-f]{64}$'),
  creada_por uuid references public.perfiles(id) on delete set null,
  creada_en timestamptz not null default now(),
  caduca_en timestamptz not null default now() + interval '15 days',
  usada_en timestamptz,
  revocada_en timestamptz,
  foreign key (iglesia_id, rol) references public.roles(iglesia_id, clave)
);

-- Una sola invitacion pendiente por correo y por iglesia
create unique index invitaciones_pendiente_unica on public.invitaciones (iglesia_id, email)
  where usada_en is null and revocada_en is null;

alter table public.invitaciones enable row level security;

create policy invitaciones_ver on public.invitaciones for select to authenticated
  using (iglesia_id = (select private.get_iglesia_id()) and (select private.tiene_permiso('usuarios.gestionar')));

grant select on public.invitaciones to authenticated;
grant all on public.invitaciones to service_role;

-- Reclamar es atomico: solo una peticion puede gastar la invitacion, y solo si sigue vigente.
create or replace function public.reclamar_invitacion(p_hash text)
 returns table (id uuid, iglesia_id uuid, email text, nombre text, apellido text, rol text)
 language sql security invoker set search_path to ''
as $$
  update public.invitaciones i set usada_en = now()
  where i.token_hash = p_hash and i.usada_en is null and i.revocada_en is null and i.caduca_en > now()
  returning i.id, i.iglesia_id, i.email, i.nombre, i.apellido, i.rol
$$;

-- Si algo falla despues de reclamar, se devuelve a pendiente para que la persona pueda reintentar.
create or replace function public.liberar_invitacion(p_id uuid)
 returns void language sql security invoker set search_path to ''
as $$
  update public.invitaciones set usada_en = null where id = p_id and revocada_en is null
$$;

revoke execute on function public.reclamar_invitacion(text), public.liberar_invitacion(uuid) from public, anon, authenticated;
grant execute on function public.reclamar_invitacion(text), public.liberar_invitacion(uuid) to service_role;
