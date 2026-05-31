-- =============================================================================
-- PASO 1 — Ejecutar este bloque ahora en SQL Editor
-- =============================================================================

-- Función SECURITY DEFINER que accede a auth.users para obtener emails
CREATE OR REPLACE FUNCTION public.get_kairos_subscribers_for_email()
RETURNS TABLE(user_id uuid, email text, nombre text, fecha_inicio date)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    ks.user_id,
    u.email,
    COALESCE(
      p.nombre,
      u.raw_user_meta_data->>'nombre',
      split_part(u.email, '@', 1)
    ) AS nombre,
    ks.fecha_inicio
  FROM public.kairos_suscripciones ks
  JOIN auth.users u ON u.id = ks.user_id
  LEFT JOIN public.profiles p ON p.id = ks.user_id
  WHERE ks.activo = true;
$$;

-- =============================================================================
-- PASO 2 — Habilitar extensiones en el Dashboard (solo una vez)
--   Dashboard → Database → Extensions → activar "pg_cron" y "pg_net"
-- =============================================================================

-- =============================================================================
-- PASO 3 — Ejecutar este bloque DESPUÉS de activar las extensiones
--   Reemplaza [PROJECT_REF] con: Dashboard → Settings → General → Reference ID
--   Reemplaza [SERVICE_ROLE_KEY] con: Dashboard → Settings → API → service_role
-- =============================================================================

SELECT cron.schedule(
  'kairos-daily-email',
  '0 12 * * *',   -- 6:00 AM El Salvador (UTC-6 = 12:00 UTC)
  $$
  SELECT net.http_post(
    url        := 'https://[PROJECT_REF].supabase.co/functions/v1/kairos-daily-email',
    headers    := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer [SERVICE_ROLE_KEY]'
                  ),
    body       := '{}'::jsonb
  );
  $$
);

-- Verificar que quedó registrado:
-- SELECT * FROM cron.job;

-- Eliminar (para recrear si cambias algo):
-- SELECT cron.unschedule('kairos-daily-email');
