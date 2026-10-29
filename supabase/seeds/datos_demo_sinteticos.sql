-- Datos 100 % sintéticos para una iglesia marcada como demo. No lee ni copia nada de OP72.
-- Nombres al azar de listas genéricas; sin teléfonos, documentos ni direcciones reales; correo contacto@viveadn.com.
-- Uso: psql -v slug=iglesia-demo -v zonas=6 -v casas=18 -v personas=300 -v recientes=24 -v rojos=2 -f datos_demo_sinteticos.sql
select set_config('demo.slug', :'slug', false), set_config('demo.zonas', :'zonas', false), set_config('demo.casas', :'casas', false),
       set_config('demo.personas', :'personas', false), set_config('demo.recientes', :'recientes', false), set_config('demo.rojos', :'rojos', false) \gset
do $$
declare
  v_slug text := current_setting('demo.slug'); nz int := current_setting('demo.zonas')::int; nc int := current_setting('demo.casas')::int;
  np int := current_setting('demo.personas')::int; nr int := current_setting('demo.recientes')::int; nrojo int := current_setting('demo.rojos')::int;
  v_ig uuid; v_demo boolean;
  nombres text[] := array['Lucía','Pablo','Marta','Andrés','Sara','Jorge','Elena','Daniel','Camila','Mateo','Valentina','Samuel','Isabela','David','Ruth','Esteban','Noemí','Gabriel','Abigail','Tomás','Paula','Nicolás','Débora','Santiago','Carolina','Emmanuel','Natalia','Felipe','Lidia','Rafael','Julieta','Ismael','Adriana','Joaquín','Rebeca','Álvaro','Miriam','Simón','Priscila','Hugo'];
  apellidos text[] := array['Romero','Cano','Gil','Vela','Molina','Peña','Ruiz','Herrera','Soto','Navarro','Vargas','Ortiz','Castro','Mejía','Rojas','Prieto','Cortés','Lara','Quintero','Salas','Duarte','Ibáñez','Campos','Bravo','Medina','Pardo','Ríos','Serrano','Fuentes','Aguirre'];
  niveles text[] := array['nuevo','nuevo','en_crecimiento','en_crecimiento','maduro','lider'];
  letras text[] := array['ZN','ZS','ZE','ZO','ZC'];
  zonas uuid[] := '{}'; casas uuid[] := '{}'; z uuid; c uuid; cod text; m uuid; i int; h int; horas int;
begin
  select id, es_demo into v_ig, v_demo from public.iglesias where slug = v_slug;
  if v_ig is null then raise exception 'No existe la iglesia %', v_slug; end if;
  if not v_demo then raise exception 'La iglesia % no está marcada como demo', v_slug; end if;
  if exists (select 1 from public.miembros where iglesia_id = v_ig) then raise exception 'La iglesia ya tiene miembros'; end if;
  perform setseed(0.42);
  for i in 1..nz loop
    z := gen_random_uuid(); zonas := zonas || z;
    insert into public.zonas (id, iglesia_id, codigo, nombre) values (z, v_ig, 'Z'||i, 'Zona '||i);
  end loop;
  for i in 1..nc loop
    c := gen_random_uuid(); casas := casas || c;
    loop
      cod := letras[1 + (i-1) % 5] || '-' || (100000 + floor(random()*899999)::int)::text;
      exit when not exists (select 1 from public.casas_oracion where codigo_zona = cod);
    end loop;
    insert into public.casas_oracion (id, iglesia_id, zona_id, codigo_zona, nombre, pais, estado, ciudad, sector, direccion)
    values (c, v_ig, zonas[1 + (i-1) % nz], cod,
            'Casa de Oración '||i, 'España','Andalucía','Sevilla', 'Sector '||i, 'Dirección de ejemplo '||i);
  end loop;
  for i in 1..np loop
    m := gen_random_uuid(); h := 1 + floor(random()*nc)::int;
    insert into public.miembros (id, iglesia_id, nombre, apellido, email, casa_oracion_id, nivel_compromiso, fecha_conversion, bautizado, nivel_formacion, progreso_formacion, puntos, racha_dias, activo)
    values (m, v_ig, nombres[1+floor(random()*40)::int], apellidos[1+floor(random()*30)::int]||' '||apellidos[1+floor(random()*30)::int],
            'contacto@viveadn.com', casas[h], niveles[1+floor(random()*6)::int],
            current_date - (floor(random()*900))::int, random() < 0.6, 1+floor(random()*5)::int, floor(random()*101)::int, floor(random()*800)::int, floor(random()*30)::int, true);
    if i > np - nr then
      -- convertidos recientes: los primeros 'rojos' pasan de 72 h; el resto se reparte entre verde, amarillo y naranja
      horas := case when i - (np - nr) <= nrojo then 76 + floor(random()*60)::int
                    else 1 + floor(random()*71)::int end;
      update public.miembros set nivel_compromiso='nuevo', fecha_conversion=current_date where id=m;
      insert into public.consolidaciones (iglesia_id, miembro_id, casa_oracion_id, fecha_conversion)
      values (v_ig, m, casas[h], now() - (horas || ' hours')::interval);
    end if;
  end loop;
  raise notice 'Datos sintéticos en %: % zonas, % casas, % personas, % consolidaciones (% en rojo)', v_slug, nz, nc, np, nr, nrojo;
end $$;
