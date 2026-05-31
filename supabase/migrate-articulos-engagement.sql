-- Articulos engagement: imagenes, vistas, likes
-- Ejecutar en Supabase SQL Editor

-- 1. Agregar columna imagenes (array de URLs)
ALTER TABLE public.articulos
  ADD COLUMN IF NOT EXISTS imagenes text[] DEFAULT '{}';

-- 2. Tabla de vistas (1 por usuario por artículo)
CREATE TABLE IF NOT EXISTS public.articulos_vistas (
  id         uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  articulo_id uuid REFERENCES public.articulos(id) ON DELETE CASCADE NOT NULL,
  user_id     uuid NOT NULL,
  created_at  timestamptz DEFAULT now(),
  UNIQUE(articulo_id, user_id)
);

-- 3. Tabla de likes (1 por usuario por artículo)
CREATE TABLE IF NOT EXISTS public.articulos_likes (
  id         uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  articulo_id uuid REFERENCES public.articulos(id) ON DELETE CASCADE NOT NULL,
  user_id     uuid NOT NULL,
  created_at  timestamptz DEFAULT now(),
  UNIQUE(articulo_id, user_id)
);

-- RLS
ALTER TABLE public.articulos_vistas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.articulos_likes  ENABLE ROW LEVEL SECURITY;

CREATE POLICY "insert_own_vistas"  ON public.articulos_vistas FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "read_all_vistas"    ON public.articulos_vistas FOR SELECT TO authenticated USING (true);
CREATE POLICY "manage_own_likes"   ON public.articulos_likes  FOR ALL    TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "read_all_likes"     ON public.articulos_likes  FOR SELECT TO authenticated USING (true);

-- Índices
CREATE INDEX IF NOT EXISTS idx_vistas_articulo ON public.articulos_vistas(articulo_id);
CREATE INDEX IF NOT EXISTS idx_likes_articulo  ON public.articulos_likes(articulo_id);

-- 4. Función para obtener emails de todos los usuarios (para notificaciones)
CREATE OR REPLACE FUNCTION public.get_users_for_article_notification()
RETURNS TABLE (email text, nombre text)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    au.email,
    COALESCE(p.nombre, split_part(au.email, '@', 1)) AS nombre
  FROM auth.users au
  LEFT JOIN public.profiles p ON p.id = au.id
  WHERE au.email IS NOT NULL
    AND au.email_confirmed_at IS NOT NULL
  ORDER BY au.created_at;
$$;

-- NOTA: También crear el bucket "articulos-imagenes" en Supabase Storage
-- Dashboard → Storage → New bucket → articulos-imagenes → Public: ON
