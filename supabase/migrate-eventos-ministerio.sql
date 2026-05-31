-- Agregar columna ministerio_id a eventos (FK a ministerios)
-- Ejecutar en Supabase SQL Editor

ALTER TABLE public.eventos
  ADD COLUMN IF NOT EXISTS ministerio_id uuid REFERENCES public.ministerios(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_eventos_ministerio ON public.eventos(ministerio_id);
