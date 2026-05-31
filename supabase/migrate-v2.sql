-- ============================================================
-- FRATER v2 — Servicios + Mensajes ministerio + Políticas
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- ============================================================

-- ── 1. SERVICIOS (control de asistencia desde CRM) ──────────
CREATE TABLE IF NOT EXISTS public.servicios (
  id      uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre  text NOT NULL,
  hora    text,
  lugar   text,
  activo  boolean DEFAULT true,
  orden   int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.servicios ENABLE ROW LEVEL SECURITY;

CREATE POLICY "servicios_read_active" ON public.servicios
  FOR SELECT TO authenticated USING (activo = true);

CREATE POLICY "admin_servicios_all" ON public.servicios
  FOR ALL USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

INSERT INTO public.servicios (nombre, hora, lugar, orden) VALUES
  ('Servicio Dominical',   '9:00 AM',  'Auditorio Principal',    1),
  ('Servicio de Jóvenes',  '6:00 PM',  'Salón 2',                2),
  ('Estudio Bíblico',      '7:00 PM',  'Sala de conferencias',   3),
  ('Reunión de Oración',   '6:30 PM',  'Capilla',                4)
ON CONFLICT DO NOTHING;

-- ── 2. MENSAJES DE MINISTERIO ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.mensajes_ministerio (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  ministerio_id uuid REFERENCES public.ministerios(id) ON DELETE CASCADE NOT NULL,
  user_id       uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  contenido     text NOT NULL,
  created_at    timestamptz DEFAULT now()
);

ALTER TABLE public.mensajes_ministerio ENABLE ROW LEVEL SECURITY;

-- Solo miembros del ministerio leen sus mensajes
CREATE POLICY "mensajes_read_members" ON public.mensajes_ministerio
  FOR SELECT TO authenticated USING (
    ministerio_id IN (
      SELECT ministerio_id FROM public.miembros_ministerio WHERE user_id = auth.uid()
    )
    OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- Miembros envían mensajes solo a sus ministerios
CREATE POLICY "mensajes_insert_members" ON public.mensajes_ministerio
  FOR INSERT TO authenticated WITH CHECK (
    user_id = auth.uid() AND
    ministerio_id IN (
      SELECT ministerio_id FROM public.miembros_ministerio WHERE user_id = auth.uid()
    )
  );

-- ── 3. PROFILES — lectura pública para directorio ───────────
CREATE POLICY "profiles_read_all_authenticated" ON public.profiles
  FOR SELECT TO authenticated USING (true);

-- Admin puede actualizar cualquier perfil
DROP POLICY IF EXISTS "admin_profiles_update" ON public.profiles;
CREATE POLICY "admin_profiles_update" ON public.profiles
  FOR UPDATE USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── 4. ADMIN: leer mensajes (moderación) ────────────────────
CREATE POLICY "admin_mensajes_read" ON public.mensajes_ministerio
  FOR SELECT USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

CREATE POLICY "admin_servicios_read_all" ON public.servicios
  FOR SELECT USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
