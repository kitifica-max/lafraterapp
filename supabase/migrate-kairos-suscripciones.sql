-- ─────────────────────────────────────────────────────────────
-- Kairos Suscripciones — tabla para el plan de lectura opcional
-- Ejecutar en Supabase SQL Editor
-- ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.kairos_suscripciones (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  fecha_inicio date DEFAULT CURRENT_DATE NOT NULL,
  activo      boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

ALTER TABLE public.kairos_suscripciones ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "kairos_user_own"   ON public.kairos_suscripciones;
DROP POLICY IF EXISTS "kairos_admin_all"  ON public.kairos_suscripciones;

-- Usuario puede leer y escribir su propia fila
CREATE POLICY "kairos_user_own" ON public.kairos_suscripciones
  FOR ALL USING (auth.uid() = user_id);

-- Admin puede leer todas las filas
CREATE POLICY "kairos_admin_all" ON public.kairos_suscripciones
  FOR SELECT USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- Índice para consultas de CRM
CREATE INDEX IF NOT EXISTS idx_kairos_sub_activo ON public.kairos_suscripciones(activo, fecha_inicio DESC);
