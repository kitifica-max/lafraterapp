import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const RESEND_API_KEY    = Deno.env.get('RESEND_API_KEY')!;
const SUPABASE_URL      = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const APP_URL           = 'https://lafratersv.com';

const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function send(to: string, subject: string, html: string) {
  return fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'La Frater <info@lafratersv.com>',
      to: [to],
      subject,
      html,
    }),
  });
}

function confirmacionEmail(ins: Record<string, string>): string {
  const firstName = (ins.nombre || '').split(' ')[0] || 'Hermano/a';
  return `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Inscripción confirmada</title>
</head>
<body style="margin:0;padding:0;background:#F4F6F9;font-family:'Helvetica Neue',Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F4F6F9;padding:40px 16px;">
<tr><td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">

  <tr>
    <td style="background:#0A1931;padding:28px 32px;text-align:center;">
      <img src="${APP_URL}/img/LogoFrater_1.png" height="36" alt="Frater" style="display:block;margin:0 auto 10px;">
      <p style="margin:0;color:rgba(255,255,255,0.55);font-size:11px;font-weight:700;letter-spacing:2px;text-transform:uppercase;">Facultad de Fe y Liderazgo</p>
    </td>
  </tr>

  <tr>
    <td style="padding:36px 32px 28px;">
      <p style="margin:0 0 6px;font-size:11px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:#185ADB;">Inscripción recibida</p>
      <h1 style="margin:0 0 20px;font-size:22px;font-weight:700;color:#1E293B;line-height:1.3;">Tu lugar está reservado</h1>
      <p style="margin:0 0 20px;font-size:15px;color:#64748B;line-height:1.7;">Hola ${firstName}, hemos recibido tu inscripción a la <strong style="color:#1E293B;">Facultad de Fe y Liderazgo</strong>. En los próximos días nos pondremos en contacto contigo con los detalles.</p>

      <table cellpadding="0" cellspacing="0" width="100%" style="background:#F8FAFC;border-radius:10px;padding:16px 20px;margin-bottom:28px;">
        <tr><td style="font-size:13px;color:#64748B;padding:4px 0;"><strong style="color:#1E293B;">Módulo:</strong> ${ins.modulo}</td></tr>
        <tr><td style="font-size:13px;color:#64748B;padding:4px 0;"><strong style="color:#1E293B;">Correo:</strong> ${ins.correo}</td></tr>
        ${ins.telefono ? `<tr><td style="font-size:13px;color:#64748B;padding:4px 0;"><strong style="color:#1E293B;">Teléfono:</strong> ${ins.telefono}</td></tr>` : ''}
        ${ins.ha_cursado_antes ? `<tr><td style="font-size:13px;color:#64748B;padding:4px 0;"><strong style="color:#1E293B;">Módulo anterior:</strong> ${ins.modulo_hasta || '—'}</td></tr>` : ''}
      </table>

      <a href="${APP_URL}/profile.html" style="display:inline-block;background:#185ADB;color:#fff;text-decoration:none;padding:14px 28px;border-radius:10px;font-weight:600;font-size:15px;">Ver mi historial académico</a>
    </td>
  </tr>

  <tr><td style="padding:0 32px;"><hr style="border:none;border-top:1px solid #E2E8F0;margin:0;"></td></tr>
  <tr>
    <td style="padding:20px 32px;text-align:center;">
      <p style="margin:0;font-size:12px;color:#94A3B8;">Recibiste este correo porque te inscribiste en La Frater. <a href="${APP_URL}" style="color:#185ADB;text-decoration:none;">lafratersv.com</a></p>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>`;
}

function adminAlertEmail(ins: Record<string, string>, adminNombre: string): string {
  return `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Nueva inscripción – Facultad</title>
</head>
<body style="margin:0;padding:0;background:#F4F6F9;font-family:'Helvetica Neue',Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F4F6F9;padding:40px 16px;">
<tr><td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">

  <tr>
    <td style="background:#0A1931;padding:28px 32px;text-align:center;">
      <img src="${APP_URL}/img/LogoFrater_1.png" height="36" alt="Frater" style="display:block;margin:0 auto 10px;">
      <p style="margin:0;color:rgba(255,255,255,0.55);font-size:11px;font-weight:700;letter-spacing:2px;text-transform:uppercase;">Alerta administrativa</p>
    </td>
  </tr>

  <tr>
    <td style="padding:36px 32px 28px;">
      <p style="margin:0 0 6px;font-size:11px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:#185ADB;">Nueva inscripción</p>
      <h1 style="margin:0 0 16px;font-size:20px;font-weight:700;color:#1E293B;">Facultad de Fe y Liderazgo</h1>
      <p style="margin:0 0 20px;font-size:14px;color:#64748B;">Hola ${adminNombre}, se acaba de recibir una nueva inscripción:</p>

      <table cellpadding="0" cellspacing="0" width="100%" style="background:#F8FAFC;border-radius:10px;padding:16px 20px;margin-bottom:28px;">
        <tr><td style="font-size:13px;color:#64748B;padding:4px 0;"><strong style="color:#1E293B;">Nombre:</strong> ${ins.nombre}</td></tr>
        <tr><td style="font-size:13px;color:#64748B;padding:4px 0;"><strong style="color:#1E293B;">Correo:</strong> ${ins.correo}</td></tr>
        ${ins.telefono ? `<tr><td style="font-size:13px;color:#64748B;padding:4px 0;"><strong style="color:#1E293B;">Teléfono:</strong> ${ins.telefono}</td></tr>` : ''}
        <tr><td style="font-size:13px;color:#64748B;padding:4px 0;"><strong style="color:#1E293B;">Módulo:</strong> ${ins.modulo}</td></tr>
        ${ins.ha_cursado_antes ? `<tr><td style="font-size:13px;color:#64748B;padding:4px 0;"><strong style="color:#1E293B;">Módulo anterior:</strong> ${ins.modulo_hasta || '—'}</td></tr>` : ''}
      </table>

      <a href="https://supabase.com/dashboard" style="display:inline-block;background:#185ADB;color:#fff;text-decoration:none;padding:12px 24px;border-radius:10px;font-weight:600;font-size:14px;">Ir al CRM</a>
    </td>
  </tr>

  <tr><td style="padding:0 32px;"><hr style="border:none;border-top:1px solid #E2E8F0;margin:0;"></td></tr>
  <tr>
    <td style="padding:20px 32px;text-align:center;">
      <p style="margin:0;font-size:12px;color:#94A3B8;"><a href="${APP_URL}" style="color:#185ADB;text-decoration:none;">lafratersv.com</a></p>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>`;
}

Deno.serve(async (req) => {
  try {
    const { inscripcion_id } = await req.json();
    if (!inscripcion_id) return new Response('Missing inscripcion_id', { status: 400 });

    const { data: ins, error: insErr } = await sb
      .from('facultad_inscripciones').select('*').eq('id', inscripcion_id).single();
    if (insErr || !ins) return new Response('Inscripcion not found', { status: 404 });

    const { data: admins } = await sb.rpc('get_admin_emails');

    const results = await Promise.allSettled([
      send(ins.correo, 'Tu inscripción a la Facultad de Fe y Liderazgo fue recibida', confirmacionEmail(ins)),
      ...(admins || []).map((a: { email: string; nombre: string }) =>
        send(a.email, `Nueva inscripción – Facultad: ${ins.nombre}`, adminAlertEmail(ins, a.nombre))
      ),
    ]);

    const sent = results.filter(r => r.status === 'fulfilled').length;
    return new Response(JSON.stringify({ sent, total: results.length }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(String(e), { status: 500 });
  }
});
