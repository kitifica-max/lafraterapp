-- Agregar columnas faltantes a profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS dui    text,
  ADD COLUMN IF NOT EXISTS correo text;
