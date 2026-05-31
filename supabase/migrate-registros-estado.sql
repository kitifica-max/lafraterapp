-- Añadir columna estado a registros_evento para rastrear cancelaciones
-- Ejecutar en Supabase SQL Editor

ALTER TABLE public.registros_evento
  ADD COLUMN IF NOT EXISTS estado text DEFAULT 'activo'
  CHECK (estado IN ('activo', 'cancelado'));

-- Marcar todos los existentes como activos
UPDATE public.registros_evento SET estado = 'activo' WHERE estado IS NULL;

CREATE INDEX IF NOT EXISTS idx_reg_evento_estado ON public.registros_evento(evento_id, estado);
