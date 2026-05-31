-- ============================================================
-- FRATER — Tags de miembro (miembro | líder | admin)
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- ============================================================

-- Agregar columna tags a profiles (si no existe)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS tags text[] DEFAULT ARRAY['miembro'];

-- Índice para consultas por tag
CREATE INDEX IF NOT EXISTS idx_profiles_tags ON public.profiles USING GIN (tags);

-- Actualizar perfiles existentes: si no tienen tags, asignar 'miembro'
UPDATE public.profiles
  SET tags = ARRAY['miembro']
  WHERE tags IS NULL OR array_length(tags, 1) IS NULL;

-- Nota: El acceso al CRM sigue controlado por user_metadata.role en Auth (JWT).
-- Los tags en profiles son la representación visual/semántica del rol para el CRM.
