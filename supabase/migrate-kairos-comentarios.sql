-- ─────────────────────────────────────────────────────────────────────────
-- Kairos Comentarios — comentarios comunitarios por lectura
-- Ejecutar en Supabase SQL Editor
-- ─────────────────────────────────────────────────────────────────────────

-- Comentarios de lecturas
CREATE TABLE IF NOT EXISTS public.kairos_comentarios (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  dia         integer NOT NULL,
  lectura_idx integer NOT NULL,
  texto       text NOT NULL CHECK (char_length(texto) BETWEEN 1 AND 500),
  likes_count integer DEFAULT 0,
  created_at  timestamptz DEFAULT now()
);

-- Likes (evita doble like por usuario)
CREATE TABLE IF NOT EXISTS public.kairos_likes (
  user_id       uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  comentario_id uuid REFERENCES public.kairos_comentarios(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, comentario_id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_kcmt_dia_idx ON public.kairos_comentarios(dia, lectura_idx, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_kcmt_user   ON public.kairos_comentarios(user_id);

-- RLS comentarios
ALTER TABLE public.kairos_comentarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kairos_likes       ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "kcmt_read_all"    ON public.kairos_comentarios;
DROP POLICY IF EXISTS "kcmt_insert_own"  ON public.kairos_comentarios;
DROP POLICY IF EXISTS "kcmt_delete_own"  ON public.kairos_comentarios;
DROP POLICY IF EXISTS "klikes_own"       ON public.kairos_likes;

-- Todos los autenticados pueden leer comentarios
CREATE POLICY "kcmt_read_all" ON public.kairos_comentarios
  FOR SELECT TO authenticated USING (true);

-- Solo el autor puede insertar el suyo
CREATE POLICY "kcmt_insert_own" ON public.kairos_comentarios
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Solo el autor puede borrar el suyo (o admin)
CREATE POLICY "kcmt_delete_own" ON public.kairos_comentarios
  FOR DELETE USING (
    auth.uid() = user_id
    OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- Likes: usuario gestiona los suyos
CREATE POLICY "klikes_own" ON public.kairos_likes
  FOR ALL USING (auth.uid() = user_id);

-- Función para incrementar/decrementar likes_count de forma atómica
CREATE OR REPLACE FUNCTION public.toggle_kairos_like(p_comentario_id uuid)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user uuid := auth.uid();
  v_exists boolean;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM public.kairos_likes
    WHERE user_id = v_user AND comentario_id = p_comentario_id
  ) INTO v_exists;

  IF v_exists THEN
    DELETE FROM public.kairos_likes WHERE user_id = v_user AND comentario_id = p_comentario_id;
    UPDATE public.kairos_comentarios SET likes_count = GREATEST(0, likes_count - 1) WHERE id = p_comentario_id;
    RETURN json_build_object('liked', false);
  ELSE
    INSERT INTO public.kairos_likes(user_id, comentario_id) VALUES (v_user, p_comentario_id);
    UPDATE public.kairos_comentarios SET likes_count = likes_count + 1 WHERE id = p_comentario_id;
    RETURN json_build_object('liked', true);
  END IF;
END;
$$;
