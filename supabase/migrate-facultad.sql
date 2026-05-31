-- Facultad de Fe y Liderazgo — inscripciones + calificaciones
-- Ejecutar en Supabase SQL Editor

-- 1. Tabla de inscripciones
CREATE TABLE IF NOT EXISTS public.facultad_inscripciones (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  nombre          text NOT NULL,
  telefono        text,
  correo          text NOT NULL,
  modulo          text NOT NULL,
  ha_cursado_antes boolean DEFAULT false,
  modulo_hasta    text,
  estado          text DEFAULT 'pendiente'
                  CHECK (estado IN ('pendiente','inscrito','graduado','retirado')),
  notas           text,
  created_at      timestamptz DEFAULT now()
);

-- 2. Tabla de calificaciones (1 por módulo por inscripción)
CREATE TABLE IF NOT EXISTS public.facultad_calificaciones (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  inscripcion_id  uuid REFERENCES public.facultad_inscripciones(id) ON DELETE CASCADE NOT NULL,
  user_id         uuid,
  modulo          text NOT NULL,
  calificacion    numeric(5,2),
  observaciones   text,
  created_by      uuid,
  created_at      timestamptz DEFAULT now(),
  UNIQUE (inscripcion_id, modulo)
);

-- RLS
ALTER TABLE public.facultad_inscripciones  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facultad_calificaciones ENABLE ROW LEVEL SECURITY;

-- Drop policies si ya existen (idempotente)
DROP POLICY IF EXISTS "fi_user_insert"      ON public.facultad_inscripciones;
DROP POLICY IF EXISTS "fi_user_select_own"  ON public.facultad_inscripciones;
DROP POLICY IF EXISTS "fi_admin_all"        ON public.facultad_inscripciones;
DROP POLICY IF EXISTS "fc_user_select_own"  ON public.facultad_calificaciones;
DROP POLICY IF EXISTS "fc_admin_all"        ON public.facultad_calificaciones;

-- Inscripciones: usuario inserta la suya; admin (user_metadata.role='admin') acceso total
CREATE POLICY "fi_user_insert" ON public.facultad_inscripciones
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "fi_user_select_own" ON public.facultad_inscripciones
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "fi_admin_all" ON public.facultad_inscripciones
  FOR ALL TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- Calificaciones: usuario ve las suyas; admin acceso total
CREATE POLICY "fc_user_select_own" ON public.facultad_calificaciones
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "fc_admin_all" ON public.facultad_calificaciones
  FOR ALL TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- Índices
CREATE INDEX IF NOT EXISTS idx_fi_user   ON public.facultad_inscripciones(user_id);
CREATE INDEX IF NOT EXISTS idx_fi_estado ON public.facultad_inscripciones(estado);
CREATE INDEX IF NOT EXISTS idx_fc_inscr  ON public.facultad_calificaciones(inscripcion_id);
