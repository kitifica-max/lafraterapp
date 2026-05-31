-- Permite leer eventos activos sin necesidad de iniciar sesión
-- (para cartelera.html pública)
CREATE POLICY "eventos_public_read" ON public.eventos
  FOR SELECT USING (activo = true);
