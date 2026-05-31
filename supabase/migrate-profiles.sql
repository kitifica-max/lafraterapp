-- Migración: campos extendidos de perfil de miembro
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS fecha_nacimiento  date,
  ADD COLUMN IF NOT EXISTS genero            text,
  ADD COLUMN IF NOT EXISTS direccion         text,
  ADD COLUMN IF NOT EXISTS estado_civil      text,
  ADD COLUMN IF NOT EXISTS fecha_ingreso     date,
  ADD COLUMN IF NOT EXISTS bautizado         boolean default false,
  ADD COLUMN IF NOT EXISTS facultad_fe_liderazgo boolean default false;

-- Política: admin puede actualizar perfiles
DROP POLICY IF EXISTS "admin_profiles_update" ON public.profiles;
CREATE POLICY "admin_profiles_update" ON public.profiles
  FOR UPDATE
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
