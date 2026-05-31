import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const APP_URL = 'https://lafratersv.com';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

Deno.serve(async () => {
  // Get all active subscribers with email + name via SECURITY DEFINER function
  const { data: subs, error } = await supabase.rpc('get_kairos_subscribers_for_email');
  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  if (!subs?.length) return new Response('No subscribers', { status: 200 });

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const results = await Promise.allSettled(
    subs.map(async (sub: { user_id: string; email: string; nombre: string; fecha_inicio: string }) => {
      const inicio = new Date(sub.fecha_inicio + 'T00:00:00');
      inicio.setHours(0, 0, 0, 0);
      const diffDays = Math.floor((today.getTime() - inicio.getTime()) / 86400000);
      const diaPersonal = Math.min(Math.max(diffDays + 1, 1), 365);

      // Get today's readings
      const { data: plan } = await supabase
        .from('plan_lectura').select('lecturas').eq('dia', diaPersonal).single();
      const lecturas: string[] = plan?.lecturas
        ? (Array.isArray(plan.lecturas) ? plan.lecturas : JSON.parse(plan.lecturas))
        : [];

      // Check if behind: count completed days vs diaPersonal
      const { count: diasCompletados } = await supabase
        .from('progreso_lectura')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', sub.user_id)
        .eq('completado', true);

      const atrasado = (diasCompletados || 0) < diaPersonal - 1;
      const diasAtras = diaPersonal - 1 - (diasCompletados || 0);

      const nombre = sub.nombre.split(' ')[0];
      const html = buildEmail({ nombre, diaPersonal, lecturas, atrasado, diasAtras });

      const subject = atrasado
        ? `⚠️ Tienes ${diasAtras} día${diasAtras > 1 ? 's' : ''} pendiente${diasAtras > 1 ? 's' : ''} — Plan Kairós`
        : `📖 Tu lectura del Día ${diaPersonal} — Plan Kairós`;

      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: 'Frater <info@lafratersv.com>',
          to: [sub.email],
          subject,
          html,
        }),
      });

      if (!res.ok) throw new Error(`Resend error for ${sub.email}: ${await res.text()}`);
      return sub.email;
    })
  );

  const sent = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected').map(r => (r as PromiseRejectedResult).reason?.message);

  return new Response(JSON.stringify({ sent, failed }), {
    headers: { 'Content-Type': 'application/json' },
  });
});

function buildEmail({ nombre, diaPersonal, lecturas, atrasado, diasAtras }: {
  nombre: string; diaPersonal: number; lecturas: string[]; atrasado: boolean; diasAtras: number;
}) {
  const lecturasHtml = lecturas.map(l =>
    `<tr><td style="padding:10px 0;border-bottom:1px solid #f0f0f0;">
      <a href="https://lafratersv.com/kairos-leer.html?dia=${diaPersonal}&idx=${lecturas.indexOf(l)}"
         style="color:#1d4ed8;text-decoration:none;font-weight:500;">${l}</a>
    </td></tr>`
  ).join('');

  const alertaBanner = atrasado ? `
    <div style="background:#fef3c7;border-left:4px solid #f59e0b;border-radius:8px;padding:14px 18px;margin-bottom:24px;">
      <p style="margin:0;font-size:14px;color:#92400e;">
        <strong>Llevas ${diasAtras} día${diasAtras > 1 ? 's' : ''} pendiente${diasAtras > 1 ? 's' : ''}.</strong>
        Empieza por el más antiguo y ve avanzando. ¡Tú puedes ponerte al día!
      </p>
    </div>` : '';

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f4f6fb;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f6fb;padding:32px 16px;">
    <tr><td align="center">
      <table width="100%" style="max-width:560px;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08);">

        <!-- Header -->
        <tr><td style="background:linear-gradient(135deg,#0a1931,#1a3a6b);padding:32px 32px 28px;text-align:center;">
          <p style="margin:0 0 6px;font-size:13px;color:rgba(255,255,255,0.6);letter-spacing:1.5px;text-transform:uppercase;">Plan Kairós</p>
          <h1 style="margin:0;font-size:26px;color:#ffffff;font-weight:800;">Día ${diaPersonal}</h1>
          <p style="margin:8px 0 0;font-size:14px;color:rgba(255,255,255,0.75);">Buenos días, ${nombre} 🌅</p>
        </td></tr>

        <!-- Body -->
        <tr><td style="padding:28px 32px;">
          ${alertaBanner}
          <p style="margin:0 0 20px;font-size:15px;color:#374151;line-height:1.6;">
            ${atrasado
              ? `Hoy es una gran oportunidad para ponerte al día con tu lectura. Empieza con el día más antiguo pendiente, avanza a tu ritmo.`
              : `Aquí están tus lecturas para hoy. Son lecturas cortas de ~3 minutos cada una. ¡Tranquilo, tú puedes!`}
          </p>

          <p style="margin:0 0 12px;font-size:12px;font-weight:700;color:#9ca3af;text-transform:uppercase;letter-spacing:1px;">Tus lecturas de hoy</p>
          <table width="100%" cellpadding="0" cellspacing="0" style="border-top:1px solid #f0f0f0;">
            ${lecturasHtml}
          </table>

          <div style="text-align:center;margin-top:28px;">
            <a href="https://lafratersv.com/plan_detalles.html"
               style="display:inline-block;background:#1d4ed8;color:#fff;text-decoration:none;padding:14px 32px;border-radius:10px;font-weight:700;font-size:15px;">
              Abrir mis lecturas →
            </a>
          </div>
        </td></tr>

        <!-- Footer -->
        <tr><td style="background:#f9fafb;padding:20px 32px;text-align:center;border-top:1px solid #f0f0f0;">
          <p style="margin:0;font-size:12px;color:#9ca3af;line-height:1.6;">
            Enviado por <strong>Iglesia Frater El Salvador</strong><br>
            Este correo es parte de tu suscripción al Plan Kairós.<br>
            <a href="https://lafratersv.com/ajustes.html" style="color:#6b7280;">Gestionar preferencias</a>
          </p>
        </td></tr>

      </table>
    </td></tr>
  </table>
</body>
</html>`;
}
