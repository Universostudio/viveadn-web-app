import { createClient } from 'npm:@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } })

const ORIGENES_PERMITIDOS = [
  'https://viveadn.com',
  'https://www.viveadn.com',
  'https://viveadn-web-app.vercel.app',
  'http://localhost:5173',
]

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const SLUG_RE = /^[a-z0-9]+(-[a-z0-9]+)*$/

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  if (req.method !== 'POST') return json({ error: 'Metodo no permitido' }, 405)

  try {
    const url = Deno.env.get('SUPABASE_URL')!
    const anon = Deno.env.get('SUPABASE_ANON_KEY')!
    const service = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    // 1. Quien llama debe ser administrador de la plataforma
    const userClient = createClient(url, anon, {
      global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
    })
    const { data: { user } } = await userClient.auth.getUser()
    if (!user) return json({ error: 'No autenticado' }, 401)

    const admin = createClient(url, service, { auth: { persistSession: false, autoRefreshToken: false } })
    const { data: esAdmin } = await admin.from('plataforma_admins').select('user_id').eq('user_id', user.id).maybeSingle()
    if (!esAdmin) return json({ error: 'Sin permiso' }, 403)

    const body = await req.json().catch(() => ({}))
    const auditar = async (accion: string, iglesia_id: string | null, detalle: Record<string, unknown> = {}) => {
      await admin.from('plataforma_auditoria').insert({ actor: user.id, accion, iglesia_id, detalle })
    }

    switch (body.accion) {
      case 'listar': {
        const [{ data: iglesias }, { data: addons }, { data: planes }, { data: modulos }, { data: planModulos }] = await Promise.all([
          admin.from('iglesias').select('id, nombre, slug, plan, activa, es_demo, pais, ciudad, created_at').order('created_at'),
          admin.from('iglesia_modulos').select('iglesia_id, modulo, activo, origen'),
          admin.from('planes').select('*').order('orden'),
          admin.from('modulos').select('*').order('orden'),
          admin.from('plan_modulos').select('plan, modulo'),
        ])
        const conteos = await Promise.all((iglesias ?? []).map(async (i) => {
          const [m, u] = await Promise.all([
            admin.from('miembros').select('id', { count: 'exact', head: true }).eq('iglesia_id', i.id),
            admin.from('perfiles').select('id', { count: 'exact', head: true }).eq('iglesia_id', i.id),
          ])
          return [i.id, { miembros: m.count ?? 0, usuarios: u.count ?? 0 }] as const
        }))
        const porId = Object.fromEntries(conteos)
        return json({
          iglesias: (iglesias ?? []).map(i => ({ ...i, ...porId[i.id], addons: (addons ?? []).filter(a => a.iglesia_id === i.id) })),
          planes, modulos, plan_modulos: planModulos,
        })
      }

      case 'crear_iglesia': {
        const nombre = String(body.nombre ?? '').trim()
        const slug = String(body.slug ?? '').trim().toLowerCase()
        const plan = String(body.plan ?? 'semilla')
        const email = String(body.email ?? '').trim().toLowerCase()
        const nombreProp = String(body.nombre_propietario ?? '').trim()
        const apellidoProp = String(body.apellido_propietario ?? '').trim()
        if (nombre.length < 2 || nombre.length > 80) return json({ error: 'El nombre debe tener entre 2 y 80 caracteres' }, 400)
        if (!SLUG_RE.test(slug) || slug.length < 3 || slug.length > 40) return json({ error: 'La direccion solo admite letras minusculas, numeros y guiones (3 a 40)' }, 400)
        if (!EMAIL_RE.test(email)) return json({ error: 'El correo del propietario no es valido' }, 400)
        if (!nombreProp || !apellidoProp) return json({ error: 'Falta el nombre y apellido del propietario' }, 400)
        const { data: planOk } = await admin.from('planes').select('clave').eq('clave', plan).eq('activo', true).maybeSingle()
        if (!planOk) return json({ error: 'El plan no existe' }, 400)
        const { data: existe } = await admin.from('iglesias').select('id').eq('slug', slug).maybeSingle()
        if (existe) return json({ error: 'Esa direccion ya esta en uso' }, 409)

        const origen = ORIGENES_PERMITIDOS.includes(body.origen) ? body.origen : 'https://viveadn.com'
        const { data: ig, error: eIg } = await admin.from('iglesias')
          .insert({ nombre, slug, plan, pais: body.pais ?? null, ciudad: body.ciudad ?? null, es_demo: body.es_demo === true })
          .select('id').single()
        if (eIg || !ig) return json({ error: 'No se pudo crear la iglesia' }, 500)

        const { data: inv, error: eInv } = await admin.auth.admin.inviteUserByEmail(email, {
          redirectTo: `${origen}/reset-password`,
          data: { nombre: nombreProp, apellido: apellidoProp },
        })
        if (eInv || !inv?.user) {
          await admin.from('iglesias').delete().eq('id', ig.id)
          const yaExiste = /already|registered|exists/i.test(eInv?.message ?? '')
          return json({ error: yaExiste ? 'Ese correo ya tiene una cuenta en la plataforma' : 'No se pudo enviar la invitacion' }, yaExiste ? 409 : 500)
        }

        const { error: ePerfil } = await admin.from('perfiles').insert({
          id: inv.user.id, iglesia_id: ig.id, nombre: nombreProp, apellido: apellidoProp, email, rol: 'propietario',
        })
        if (ePerfil) {
          await admin.auth.admin.deleteUser(inv.user.id)
          await admin.from('iglesias').delete().eq('id', ig.id)
          return json({ error: 'No se pudo crear el perfil del propietario' }, 500)
        }
        await auditar('crear_iglesia', ig.id, { nombre, slug, plan, propietario: email })
        return json({ ok: true, iglesia_id: ig.id })
      }

      case 'cambiar_plan': {
        const { data: planOk } = await admin.from('planes').select('clave').eq('clave', body.plan).maybeSingle()
        if (!planOk) return json({ error: 'El plan no existe' }, 400)
        const { error } = await admin.from('iglesias').update({ plan: body.plan }).eq('id', body.iglesia_id)
        if (error) return json({ error: 'No se pudo cambiar el plan' }, 500)
        await auditar('cambiar_plan', body.iglesia_id, { plan: body.plan })
        return json({ ok: true })
      }

      case 'modulo_addon': {
        const { data: mod } = await admin.from('modulos').select('clave').eq('clave', body.modulo).maybeSingle()
        if (!mod) return json({ error: 'El modulo no existe' }, 400)
        if (body.activo === true) {
          const { error } = await admin.from('iglesia_modulos')
            .upsert({ iglesia_id: body.iglesia_id, modulo: body.modulo, activo: true, origen: body.origen === 'cortesia' ? 'cortesia' : 'addon', desde: new Date().toISOString(), hasta: null })
          if (error) return json({ error: 'No se pudo activar el modulo' }, 500)
        } else {
          const { error } = await admin.from('iglesia_modulos').delete().eq('iglesia_id', body.iglesia_id).eq('modulo', body.modulo)
          if (error) return json({ error: 'No se pudo quitar el modulo' }, 500)
        }
        await auditar('modulo_addon', body.iglesia_id, { modulo: body.modulo, activo: body.activo === true })
        return json({ ok: true })
      }

      case 'estado': {
        const activa = body.activa === true
        const { error } = await admin.from('iglesias').update({ activa }).eq('id', body.iglesia_id)
        if (error) return json({ error: 'No se pudo cambiar el estado' }, 500)
        await auditar(activa ? 'activar_iglesia' : 'suspender_iglesia', body.iglesia_id)
        return json({ ok: true })
      }

      default:
        return json({ error: 'Accion desconocida' }, 400)
    }
  } catch (_e) {
    return json({ error: 'Error interno' }, 500)
  }
})
