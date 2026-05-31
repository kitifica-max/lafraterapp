import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!;
const FROM_EMAIL = "Frater App <info@lafratersv.com>";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const {
    tipo,           // 'solicitud' | 'aceptada' | 'rechazada'
    ministerio_nombre,
    lider_email,
    lider_nombre,
    usuario_nombre,
    usuario_email,
    mensaje_usuario,
    nota_lider,
    crm_url,
  } = await req.json();

  let to: string;
  let subject: string;
  let html: string;

  if (tipo === "solicitud") {
    to = lider_email;
    subject = `Nueva solicitud para unirse a ${ministerio_nombre}`;
    html = `
      <div style="font-family:sans-serif;max-width:560px;margin:0 auto;color:#1a1a2e;">
        <div style="background:#0A1931;padding:28px 32px;border-radius:12px 12px 0 0;text-align:center;">
          <p style="color:#fff;font-size:1.4rem;font-weight:700;margin:0;">Frater App</p>
          <p style="color:rgba(255,255,255,0.7);font-size:0.85rem;margin:6px 0 0;">Fraternidad Cristiana de El Salvador</p>
        </div>
        <div style="background:#f9f9f9;padding:32px;border-radius:0 0 12px 12px;">
          <p style="font-size:1rem;font-weight:600;margin:0 0 8px;">Hola${lider_nombre ? `, ${lider_nombre}` : ""} 👋</p>
          <p style="color:#555;line-height:1.7;margin:0 0 20px;">
            <strong>${usuario_nombre || "Un miembro"}</strong> ha solicitado unirse al ministerio de
            <strong>${ministerio_nombre}</strong>. Puedes revisar y aprobar o rechazar esta solicitud desde el CRM.
          </p>
          ${mensaje_usuario ? `
          <div style="background:#fff;border-left:4px solid #0A1931;border-radius:0 8px 8px 0;padding:14px 18px;margin:0 0 24px;">
            <p style="font-size:0.8rem;color:#999;margin:0 0 4px;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;">Mensaje del solicitante</p>
            <p style="color:#333;margin:0;line-height:1.6;">"${mensaje_usuario}"</p>
          </div>` : ""}
          <div style="text-align:center;margin:28px 0;">
            <a href="${crm_url || "https://lafratersv.com/crm-ministerios.html"}"
               style="background:#0A1931;color:#fff;padding:13px 28px;border-radius:8px;text-decoration:none;font-weight:600;font-size:0.95rem;display:inline-block;">
              Revisar solicitud en el CRM →
            </a>
          </div>
          <p style="color:#aaa;font-size:0.78rem;text-align:center;margin:0;">
            Este correo fue generado automáticamente por Frater App. Por favor no respondas a este mensaje.
          </p>
        </div>
      </div>`;
  } else {
    to = usuario_email;
    const aceptada = tipo === "aceptada";
    subject = aceptada
      ? `¡Bienvenido/a al ministerio de ${ministerio_nombre}!`
      : `Tu solicitud para ${ministerio_nombre}`;
    html = `
      <div style="font-family:sans-serif;max-width:560px;margin:0 auto;color:#1a1a2e;">
        <div style="background:#0A1931;padding:28px 32px;border-radius:12px 12px 0 0;text-align:center;">
          <p style="color:#fff;font-size:1.4rem;font-weight:700;margin:0;">Frater App</p>
          <p style="color:rgba(255,255,255,0.7);font-size:0.85rem;margin:6px 0 0;">Fraternidad Cristiana de El Salvador</p>
        </div>
        <div style="background:#f9f9f9;padding:32px;border-radius:0 0 12px 12px;">
          <p style="font-size:1rem;font-weight:600;margin:0 0 8px;">
            Hola${usuario_nombre ? `, ${usuario_nombre}` : ""} ${aceptada ? "🎉" : "🙏"}
          </p>
          ${aceptada ? `
          <p style="color:#555;line-height:1.7;margin:0 0 16px;">
            ¡Nos alegra mucho comunicarte que tu solicitud para unirte al ministerio de
            <strong>${ministerio_nombre}</strong> ha sido <strong style="color:#059669;">aceptada</strong>!
            Ya puedes participar en el chat y las actividades del ministerio desde la app.
          </p>
          <p style="color:#555;line-height:1.7;margin:0 0 24px;">
            ¡Bienvenido/a a la familia! Dios te ha traído hasta aquí con un propósito. 🌟
          </p>` : `
          <p style="color:#555;line-height:1.7;margin:0 0 16px;">
            Gracias por tu interés en el ministerio de <strong>${ministerio_nombre}</strong>.
            En esta ocasión, tu solicitud no pudo ser aprobada.
          </p>
          ${nota_lider ? `
          <div style="background:#fff;border-left:4px solid #e5e7eb;border-radius:0 8px 8px 0;padding:14px 18px;margin:0 0 16px;">
            <p style="font-size:0.8rem;color:#999;margin:0 0 4px;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;">Nota del líder</p>
            <p style="color:#333;margin:0;line-height:1.6;">"${nota_lider}"</p>
          </div>` : ""}
          <p style="color:#555;line-height:1.7;margin:0 0 24px;">
            Recuerda que hay otros ministerios en los que puedes participar. ¡Te esperamos! 💙
          </p>`}
          <div style="text-align:center;margin:28px 0;">
            <a href="https://lafratersv.com/app.html"
               style="background:#0A1931;color:#fff;padding:13px 28px;border-radius:8px;text-decoration:none;font-weight:600;font-size:0.95rem;display:inline-block;">
              Abrir la app →
            </a>
          </div>
          <p style="color:#aaa;font-size:0.78rem;text-align:center;margin:0;">
            Este correo fue generado automáticamente por Frater App.
          </p>
        </div>
      </div>`;
  }

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ from: FROM_EMAIL, to, subject, html }),
  });

  const data = await res.json();
  return new Response(JSON.stringify(data), {
    status: res.status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
