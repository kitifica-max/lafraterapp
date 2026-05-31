import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const APP_URL = 'https://lafratersv.com';

const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

Deno.serve(async (req) => {
  try {
    const { articulo_id } = await req.json();
    if (!articulo_id) return new Response('Missing articulo_id', { status: 400 });

    const { data: art, error: artErr } = await sb
      .from('articulos').select('*').eq('id', articulo_id).single();
    if (artErr || !art) return new Response('Article not found', { status: 404 });

    const { data: users, error: usrErr } = await sb.rpc('get_users_for_article_notification');
    if (usrErr) return new Response(usrErr.message, { status: 500 });
    if (!users?.length) return new Response(JSON.stringify({ sent: 0 }), { status: 200 });

    const imageUrl: string | null = art.imagenes?.[0] ?? null;
    const artUrl = `${APP_URL}/articulo_detalle.html?id=${art.id}`;

    function buildEmail(nombre: string): string {
      return `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>${art.titulo}</title>
</head>
<body style="margin:0;padding:0;background:#F4F6F9;font-family:'Helvetica Neue',Arial,sans-serif;-webkit-font-smoothing:antialiased;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F4F6F9;padding:40px 16px;">
<tr><td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">

  <!-- Header -->
  <tr>
    <td style="background:#0A1931;padding:28px 32px;text-align:center;">
      <img src="${APP_URL}/img/LogoFrater_1.png" height="36" alt="Frater" style="display:block;margin:0 auto 10px;">
      <p style="margin:0;color:rgba(255,255,255,0.55);font-size:11px;font-weight:700;letter-spacing:2px;text-transform:uppercase;">Nuevo artículo publicado</p>
    </td>
  </tr>

  ${imageUrl ? `
  <!-- Cover image -->
  <tr>
    <td style="padding:0;">
      <img src="${imageUrl}" width="600" alt="${art.titulo}" style="display:block;width:100%;max-height:280px;object-fit:cover;">
    </td>
  </tr>` : ''}

  <!-- Body -->
  <tr>
    <td style="padding:36px 32px 28px;">
      <p style="margin:0 0 8px;font-size:11px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:#185ADB;">${art.categoria || 'Artículo'}</p>
      <h1 style="margin:0 0 10px;font-size:22px;font-weight:700;color:#1E293B;line-height:1.3;">${art.titulo}</h1>
      ${art.autor ? `<p style="margin:0 0 20px;font-size:13px;color:#64748B;">Por ${art.autor}</p>` : '<p style="margin:0 0 20px;"></p>'}
      <p style="margin:0 0 8px;font-size:15px;color:#64748B;line-height:1.6;">Hola ${nombre},</p>
      ${art.resumen ? `<p style="margin:0 0 28px;font-size:15px;color:#64748B;line-height:1.7;">${art.resumen}</p>` : '<p style="margin:0 0 28px;font-size:15px;color:#64748B;line-height:1.7;">Hay un nuevo artículo esperando por ti en la app de La Frater.</p>'}
      <a href="${artUrl}" style="display:inline-block;background:#185ADB;color:#ffffff;text-decoration:none;padding:14px 28px;border-radius:10px;font-weight:600;font-size:15px;letter-spacing:0.2px;">Leer artículo completo</a>
    </td>
  </tr>

  <!-- Divider -->
  <tr><td style="padding:0 32px;"><hr style="border:none;border-top:1px solid #E2E8F0;margin:0;"></td></tr>

  <!-- Footer -->
  <tr>
    <td style="padding:20px 32px;text-align:center;">
      <p style="margin:0 0 4px;font-size:12px;color:#94A3B8;">Recibiste este correo porque eres miembro de La Frater.</p>
      <p style="margin:0;font-size:12px;color:#94A3B8;">
        <a href="${APP_URL}" style="color:#185ADB;text-decoration:none;">lafratersv.com</a>
      </p>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>`;
    }

    let sent = 0;
    const BATCH = 50;
    for (let i = 0; i < users.length; i += BATCH) {
      const batch = users.slice(i, i + BATCH);
      await Promise.allSettled(
        batch.map(async (u: { email: string; nombre: string }) => {
          const firstName = (u.nombre || '').split(' ')[0] || 'Hermano/a';
          const res = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${RESEND_API_KEY}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              from: 'La Frater <info@lafratersv.com>',
              to: [u.email],
              subject: `Nuevo artículo: ${art.titulo}`,
              html: buildEmail(firstName),
            }),
          });
          if (res.ok) sent++;
        })
      );
    }

    return new Response(JSON.stringify({ sent, total: users.length }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(String(e), { status: 500 });
  }
});
