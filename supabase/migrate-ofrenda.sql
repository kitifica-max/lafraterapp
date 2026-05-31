-- ============================================================
-- FRATER — Ofrenda: tipos, cuentas bancarias, comprobantes
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- ============================================================

-- ── 1. TIPOS DE OFRENDA ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ofrenda_tipos (
  id        uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre    text NOT NULL,
  icono     text DEFAULT '💰',
  activo    boolean DEFAULT true,
  orden     int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.ofrenda_tipos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ofrenda_tipos_read" ON public.ofrenda_tipos
  FOR SELECT TO authenticated USING (activo = true);
CREATE POLICY "admin_ofrenda_tipos_all" ON public.ofrenda_tipos
  FOR ALL USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_ofrenda_tipos_read_all" ON public.ofrenda_tipos
  FOR SELECT USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

INSERT INTO public.ofrenda_tipos (nombre, icono, orden) VALUES
  ('Diezmo',       '🌱', 1),
  ('Ofrenda',      '❤️',  2),
  ('Misiones',     '✈️',  3),
  ('Construcción', '🏗️', 4)
ON CONFLICT DO NOTHING;

-- ── 2. CUENTAS BANCARIAS ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ofrenda_cuentas (
  id             uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  banco          text NOT NULL,
  numero_cuenta  text NOT NULL,
  titular        text NOT NULL,
  tipo_cuenta    text DEFAULT 'Corriente',
  activo         boolean DEFAULT true,
  orden          int DEFAULT 0,
  created_at     timestamptz DEFAULT now()
);
ALTER TABLE public.ofrenda_cuentas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ofrenda_cuentas_read" ON public.ofrenda_cuentas
  FOR SELECT TO authenticated USING (activo = true);
CREATE POLICY "admin_ofrenda_cuentas_all" ON public.ofrenda_cuentas
  FOR ALL USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_ofrenda_cuentas_read_all" ON public.ofrenda_cuentas
  FOR SELECT USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

INSERT INTO public.ofrenda_cuentas (banco, numero_cuenta, titular, tipo_cuenta, orden) VALUES
  ('Banco Agrícola', '0000-0000-00', 'Fraternidad Cristiana de El Salvador', 'Corriente', 1),
  ('Davivienda',     '0000-0000-00', 'Fraternidad Cristiana de El Salvador', 'Corriente', 2)
ON CONFLICT DO NOTHING;

-- ── 3. COMPROBANTES DE OFRENDA ──────────────────────────────
CREATE TABLE IF NOT EXISTS public.comprobantes_ofrenda (
  id               uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id          uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  tipo             text NOT NULL,
  banco            text NOT NULL,
  monto            numeric(10,2),
  referencia       text,
  nombre_remitente text,
  estado           text DEFAULT 'pendiente', -- pendiente | verificado | rechazado
  nota_admin       text,
  created_at       timestamptz DEFAULT now()
);
ALTER TABLE public.comprobantes_ofrenda ENABLE ROW LEVEL SECURITY;

CREATE POLICY "comprobantes_insert" ON public.comprobantes_ofrenda
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "comprobantes_read_own" ON public.comprobantes_ofrenda
  FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "admin_comprobantes_all" ON public.comprobantes_ofrenda
  FOR ALL USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
