-- ============================================================
-- FRATER — Storage buckets: eventos-arte y avatares
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- ============================================================

-- ── 1. Buckets ───────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('eventos-arte', 'eventos-arte', true,  2097152, ARRAY['image/jpeg','image/png','image/webp']),
  ('avatares',     'avatares',     true,  2097152, ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO NOTHING;

-- ── 2. Políticas eventos-arte (solo admin sube, todos leen) ──
CREATE POLICY "eventos_arte_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'eventos-arte');

CREATE POLICY "eventos_arte_admin_insert" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'eventos-arte'
    AND (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

CREATE POLICY "eventos_arte_admin_update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'eventos-arte'
    AND (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

CREATE POLICY "eventos_arte_admin_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'eventos-arte'
    AND (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- ── 3. Políticas avatares (cada usuario gestiona el suyo) ────
CREATE POLICY "avatares_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatares');

CREATE POLICY "avatares_insert" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatares'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "avatares_update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatares'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "avatares_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'avatares'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- ── 4. Columnas en tablas ────────────────────────────────────
ALTER TABLE public.eventos  ADD COLUMN IF NOT EXISTS imagen_url text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url text;
