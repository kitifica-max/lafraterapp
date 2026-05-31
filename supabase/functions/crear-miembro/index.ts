import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const RESEND_API_KEY      = Deno.env.get('RESEND_API_KEY')!;
const SUPABASE_URL        = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const APP_URL             = 'https://lafratersv.com';

const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false }
});

function generarPassword(): string {
  const palabras = ['Luz','Paz','Fe','Amor','Vida','Gracia','Fuerza','Gozo','Gloria','Cielo'];
  const palabra = palabras[Math.floor(Math.random() * palabras.length)];
  const nums = Math.floor(1000 + Math.random() * 9000);
  return `Frater-${palabra}-${nums}`;
}

async function sendEmail(to: string, subject: string, html: string) {
  return fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: 'La Frater <info@lafratersv.com>', to: [to], subject, html }),
  });
}

function bienvenidaEmail(nombre: string, email: string, password: string, tag: string): string {
  const firstName = nombre.split(' ')[0] || 'Hermano/a';
  const tagLabel  = tag === 'lider' ? 'Líder' : tag === 'admin' ? 'Administrador' : 'Miembro';
  const crmNote   = (tag === 'lider' || tag === 'admin')
    ? `<tr><td style="padding:0 32px 20px;"><div style="background:#EFF6FF;border:1.5px solid #BFDBFE;border-radius:12px;padding:14px 18px;"><p style="margin:0 0 4px;font-size:12px;font-weight:700;color:#1D4ED8;letter-spacing:1px;text-transform:uppercase;">Acceso al CRM</p><p style="margin:0;font-size:13px;color:#1E3A5F;line-height:1.6;">Como <strong>${tagLabel}</strong> también puedes acceder al panel de administración en <a href="${APP_URL}/crm-login.html" style="color:#185ADB;">lafratersv.com/crm-login.html</a> con las mismas credenciales.</p></div></td></tr>`
    : '';
  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#F4F6F9;font-family:'Helvetica Neue',Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F4F6F9;padding:40px 16px;">
<tr><td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
  <tr>
    <td style="background:#0A1931;padding:32px;text-align:center;">
      <img src="${APP_URL}/img/LogoFrater_1.png" height="40" alt="Frater" style="display:block;margin:0 auto 12px;">
      <p style="margin:0;color:rgba(255,255,255,0.5);font-size:11px;font-weight:700;letter-spacing:2px;text-transform:uppercase;">Bienvenido a La Frater</p>
    </td>
  </tr>
  <tr>
    <td style="padding:36px 32px 12px;">
      <p style="margin:0 0 6px;font-size:11px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:#185ADB;">Tu cuenta está lista</p>
      <h1 style="margin:0 0 18px;font-size:22px;font-weight:700;color:#1E293B;line-height:1.3;">¡Hola, ${firstName}! 🎉</h1>
      <p style="margin:0 0 24px;font-size:15px;color:#64748B;line-height:1.7;">Un administrador de La Fraternidad Cristiana ha creado tu cuenta en la app. Ya puedes acceder con las siguientes credenciales:</p>
    </td>
  </tr>
  <tr>
    <td style="padding:0 32px 28px;">
      <table cellpadding="0" cellspacing="0" width="100%" style="background:#F8FAFC;border:1.5px solid #E2E8F0;border-radius:12px;overflow:hidden;">
        <tr>
          <td style="padding:16px 20px;border-bottom:1px solid #E2E8F0;">
            <p style="margin:0 0 3px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:1px;color:#94A3B8;">CORREO ELECTRÓNICO</p>
            <p style="margin:0;font-size:15px;font-weight:600;color:#1E293B;">${email}</p>
          </td>
        </tr>
        <tr>
          <td style="padding:16px 20px;">
            <p style="margin:0 0 3px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:1px;color:#94A3B8;">CONTRASEÑA TEMPORAL</p>
            <p style="margin:0;font-size:20px;font-weight:800;color:#185ADB;letter-spacing:0.04em;font-family:monospace;">${password}</p>
          </td>
        </tr>
      </table>
    </td>
  </tr>
  ${crmNote}
  <tr>
    <td style="padding:0 32px 28px;">
      <p style="margin:0 0 20px;font-size:14px;color:#64748B;line-height:1.7;">Te recomendamos cambiar tu contraseña desde el perfil de la app después de iniciar sesión por primera vez.</p>
      <a href="${APP_URL}/login.html" style="display:inline-block;background:#185ADB;color:#fff;text-decoration:none;padding:14px 28px;border-radius:10px;font-weight:600;font-size:15px;">Iniciar sesión →</a>
    </td>
  </tr>
  <tr><td style="padding:0 32px;"><hr style="border:none;border-top:1px solid #E2E8F0;"></td></tr>
  <tr>
    <td style="padding:20px 32px;text-align:center;">
      <p style="margin:0;font-size:12px;color:#94A3B8;">Recibiste este correo porque fuiste registrado en <a href="${APP_URL}" style="color:#185ADB;text-decoration:none;">lafratersv.com</a>.</p>
    </td>
  </tr>
</table>
</td></tr>
</table>
</body>
</html>`;
}

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });

  try {
    const body = await req.json();
    const { nombre, email, telefono, nacimiento, genero, estado_civil, direccion, dui, ingreso, bautizado, facultad, tag } = body;

    if (!nombre || !email) return json({ error: 'Nombre y correo son obligatorios.' }, 400);

    // Normalizar tag: solo valores válidos, default 'miembro'
    const validTags = ['miembro', 'lider', 'admin'];
    const userTag   = validTags.includes(tag) ? tag : 'miembro';

    const password = generarPassword();

    // Crear usuario con service role (sin confirmación de email)
    const { data: userData, error: authErr } = await sb.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { nombre, role: userTag },  // role controla acceso al CRM
    });

    if (authErr) {
      const msg = authErr.message.includes('already registered') || authErr.message.includes('already been registered')
        ? 'Este correo ya está registrado. Elimínalo primero desde Supabase Auth → Users.'
        : authErr.message;
      return json({ error: msg }, 400);
    }

    const userId = userData.user.id;

    // Esperar trigger de profiles
    await new Promise(r => setTimeout(r, 800));

    // Actualizar perfil con tags
    const profileData: Record<string, unknown> = {
      nombre,
      correo: email,
      tags: [userTag],
    };
    if (telefono)    profileData.telefono = telefono;
    if (nacimiento)  profileData.fecha_nacimiento = nacimiento;
    if (genero)      profileData.genero = genero;
    if (estado_civil) profileData.estado_civil = estado_civil;
    if (direccion)   profileData.direccion = direccion;
    if (dui)         profileData.dui = dui;
    if (ingreso)     profileData.fecha_ingreso = ingreso;
    if (bautizado !== undefined && bautizado !== '') profileData.bautizado = bautizado === true || bautizado === 'true';
    if (facultad  !== undefined && facultad  !== '') profileData.facultad_fe_liderazgo = facultad === true || facultad === 'true';

    await sb.from('profiles').update(profileData).eq('id', userId);

    // Enviar email de bienvenida (con nota de CRM si es líder/admin)
    const emailRes = await sendEmail(email, '¡Bienvenido/a a La Frater! Tus credenciales de acceso', bienvenidaEmail(nombre, email, password, userTag));
    const emailBody = await emailRes.json().catch(() => ({}));
    const emailSent = emailRes.ok;

    return json({ success: true, user_id: userId, password, email_sent: emailSent, email_debug: emailBody });

  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
