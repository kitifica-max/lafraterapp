-- ── MIGRACIÓN: Ofrenda Contabilidad ─────────────────────────────────────────
-- Ejecutar en Supabase SQL Editor

-- 1. Agregar DUI y profile_id a comprobantes_ofrenda
ALTER TABLE public.comprobantes_ofrenda
  ADD COLUMN IF NOT EXISTS dui text,
  ADD COLUMN IF NOT EXISTS profile_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 2. Tabla de colectas en efectivo (servicio dominical)
CREATE TABLE IF NOT EXISTS public.colectas_efectivo (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  fecha_servicio date NOT NULL,
  tipo text NOT NULL DEFAULT 'Ofrenda General',
  monto numeric(10,2) NOT NULL CHECK (monto > 0),
  contado_por text,
  notas text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

-- RLS colectas
ALTER TABLE public.colectas_efectivo ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admins_manage_colectas" ON public.colectas_efectivo
  USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin', 'super_admin')
  );

-- 3. Tabla de configuración de acceso contable
CREATE TABLE IF NOT EXISTS public.ofrenda_config (
  key text PRIMARY KEY,
  value text NOT NULL,
  updated_at timestamptz DEFAULT now()
);

-- Insertar código de acceso (cámbialo si deseas)
INSERT INTO public.ofrenda_config (key, value)
VALUES ('access_code', '71A7-2NNX-9TF1')
ON CONFLICT (key) DO NOTHING;

-- RLS: solo admins pueden leer/escribir config
ALTER TABLE public.ofrenda_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admins_read_config" ON public.ofrenda_config
  FOR SELECT USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin', 'super_admin')
  );

CREATE POLICY "admins_update_config" ON public.ofrenda_config
  FOR ALL USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin', 'super_admin')
  );
