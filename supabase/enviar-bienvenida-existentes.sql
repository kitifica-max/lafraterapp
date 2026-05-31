-- ══════════════════════════════════════════════════════════════
-- ENVIAR CORREO DE BIENVENIDA A USUARIOS YA CREADOS
-- Ejecutar en Supabase SQL Editor
-- Requiere extensión pg_net (ya incluida en Supabase)
-- ══════════════════════════════════════════════════════════════

-- 1. Reemplaza YOUR_RESEND_API_KEY con tu key real (re_xxxx...)
-- 2. El correo incluye un link para que configuren su contraseña

DO $$
DECLARE
  rec          RECORD;
  reset_link   text;
  html_body    text;
  first_name   text;
  RESEND_KEY   text := 'YOUR_RESEND_API_KEY';  -- ← cambia esto
  APP_URL      text := 'https://lafratersv.com';
BEGIN
  FOR rec IN
    SELECT
      au.id,
      au.email,
      COALESCE(p.nombre, split_part(au.email, '@', 1)) AS nombre
    FROM auth.users au
    LEFT JOIN public.profiles p ON p.id = au.id
    WHERE au.email IS NOT NULL
      AND au.deleted_at IS NULL
    ORDER BY au.created_at
  LOOP
    first_name := split_part(rec.nombre, ' ', 1);

    -- Link de reset de contraseña vía Supabase auth
    reset_link := APP_URL || '/reset-password.html';

    -- Construir HTML del correo
    html_body := format(
      $html$
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#F4F6F9;font-family:Arial,sans-serif;">
<table width="100%%" cellpadding="0" cellspacing="0" style="background:#F4F6F9;padding:40px 16px;">
<tr><td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%%;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
  <tr><td style="background:#0A1931;padding:32px;text-align:center;">
    <img src="%s/img/LogoFrater_1.png" height="40" alt="Frater" style="display:block;margin:0 auto 12px;">
    <p style="margin:0;color:rgba(255,255,255,0.5);font-size:11px;font-weight:700;letter-spacing:2px;text-transform:uppercase;">Fraternidad Cristiana de El Salvador</p>
  </td></tr>
  <tr><td style="padding:36px 32px 20px;">
    <p style="margin:0 0 6px;font-size:11px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:#185ADB;">Tu cuenta en La Frater</p>
    <h1 style="margin:0 0 16px;font-size:22px;font-weight:700;color:#1E293B;">¡Hola, %s! 👋</h1>
    <p style="margin:0 0 20px;font-size:15px;color:#64748B;line-height:1.7;">Tu cuenta en la app de La Frater está lista con el correo <strong>%s</strong>. Haz clic abajo para configurar tu contraseña y acceder.</p>
    <table cellpadding="0" cellspacing="0" style="background:#F8FAFC;border:1.5px solid #E2E8F0;border-radius:12px;padding:16px 20px;margin-bottom:24px;width:100%%;">
      <tr><td style="font-size:13px;color:#64748B;"><strong style="color:#1E293B;">Correo:</strong> %s</td></tr>
    </table>
    <a href="%s/forgot-password.html" style="display:inline-block;background:#185ADB;color:#fff;text-decoration:none;padding:14px 32px;border-radius:10px;font-weight:600;font-size:15px;">Configurar mi contraseña →</a>
    <p style="margin:16px 0 0;font-size:12px;color:#94A3B8;">Ingresa tu correo en el formulario para recibir el link de restablecimiento.</p>
  </td></tr>
  <tr><td style="padding:0 32px;"><hr style="border:none;border-top:1px solid #E2E8F0;"></td></tr>
  <tr><td style="padding:20px 32px;text-align:center;">
    <p style="margin:0;font-size:12px;color:#94A3B8;"><a href="%s" style="color:#185ADB;text-decoration:none;">lafratersv.com</a></p>
  </td></tr>
</table>
</td></tr>
</table>
</body>
</html>
      $html$,
      APP_URL,       -- logo src
      first_name,    -- nombre
      rec.email,     -- correo en párrafo
      rec.email,     -- correo en tabla
      APP_URL,       -- link forgot-password
      APP_URL        -- footer link
    );

    -- Enviar vía Resend usando pg_net
    PERFORM net.http_post(
      url     := 'https://api.resend.com/emails',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || RESEND_KEY,
        'Content-Type',  'application/json'
      ),
      body    := jsonb_build_object(
        'from',    'La Frater <info@lafratersv.com>',
        'to',      jsonb_build_array(rec.email),
        'subject', '¡Tu cuenta en La Frater está lista! Configura tu contraseña',
        'html',    html_body
      )
    );

    RAISE NOTICE 'Correo enviado a: %', rec.email;
  END LOOP;

  RAISE NOTICE '✓ Proceso completado.';
END $$;
