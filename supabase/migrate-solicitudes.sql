-- ============================================================
-- FRATER — Solicitudes de membresía en ministerios
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- ============================================================

-- ── 1. Añadir lider_email a ministerios ─────────────────────
ALTER TABLE public.ministerios ADD COLUMN IF NOT EXISTS lider_email text;

-- ── 2. Tabla de solicitudes ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.solicitudes_ministerio (
  id             uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id        uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  ministerio_id  uuid REFERENCES public.ministerios(id) ON DELETE CASCADE NOT NULL,
  estado         text DEFAULT 'pendiente', -- pendiente | aceptada | rechazada
  mensaje        text,
  nota_lider     text,
  user_email     text,
  user_nombre    text,
  created_at     timestamptz DEFAULT now(),
  updated_at     timestamptz DEFAULT now(),
  UNIQUE(user_id, ministerio_id)
);
ALTER TABLE public.solicitudes_ministerio ENABLE ROW LEVEL SECURITY;

CREATE POLICY "solicitudes_insert" ON public.solicitudes_ministerio
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "solicitudes_read_own" ON public.solicitudes_ministerio
  FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "solicitudes_update_own_read" ON public.solicitudes_ministerio
  FOR UPDATE TO authenticated USING (user_id = auth.uid());
CREATE POLICY "admin_solicitudes_all" ON public.solicitudes_ministerio
  FOR ALL USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
