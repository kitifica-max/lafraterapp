-- ============================================================
-- FRATER APP — Script 1: Tablas y Políticas RLS
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- ============================================================

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------
-- TABLA: miembros
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.miembros (
  id           UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre       TEXT        NOT NULL,
  email        TEXT        NOT NULL UNIQUE,
  rol          TEXT        NOT NULL DEFAULT 'miembro'
                           CHECK (rol IN ('miembro', 'lider', 'Admin', 'Super_Admin')),
  telefono     TEXT,
  ministerio   TEXT,
  fecha_ingreso DATE       DEFAULT CURRENT_DATE,
  activo       BOOLEAN     DEFAULT TRUE,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-actualizar updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_miembros_updated_at ON public.miembros;
CREATE TRIGGER trg_miembros_updated_at
  BEFORE UPDATE ON public.miembros
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ------------------------------------------------------------
ALTER TABLE public.miembros ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas previas para evitar conflictos
DROP POLICY IF EXISTS "admins_full_access"    ON public.miembros;
DROP POLICY IF EXISTS "members_read_own"      ON public.miembros;
DROP POLICY IF EXISTS "block_public_insert"   ON public.miembros;

-- Super_Admin y Admin tienen acceso total
CREATE POLICY "admins_full_access" ON public.miembros
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.miembros m
      WHERE m.id = auth.uid()
        AND m.rol IN ('Super_Admin', 'Admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.miembros m
      WHERE m.id = auth.uid()
        AND m.rol IN ('Super_Admin', 'Admin')
    )
  );

-- Miembros normales solo pueden leer su propio perfil
CREATE POLICY "members_read_own" ON public.miembros
  FOR SELECT TO authenticated
  USING (id = auth.uid());

-- Confirmar que no hay insert público
-- (Sin política de INSERT para roles no-admin = bloqueado por defecto)

-- ------------------------------------------------------------
-- FUNCIÓN HELPER: obtener rol del usuario actual
-- Útil para el frontend al verificar permisos
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_my_rol()
RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT rol FROM public.miembros WHERE id = auth.uid();
$$;
