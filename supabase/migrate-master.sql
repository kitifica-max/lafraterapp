-- ============================================================
-- FRATER APP — Migración Maestra Completa
-- Seguro de ejecutar múltiples veces (idempotente)
-- Supabase Dashboard > SQL Editor > Run
-- ============================================================

-- ============================================================
-- SECCIÓN 1: TABLAS
-- ============================================================

-- ── 1.1 PROFILES ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id                        uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  nombre                    text,
  telefono                  text,
  avatar_url                text,
  fecha_nacimiento          date,
  genero                    text,
  direccion                 text,
  estado_civil              text,
  fecha_ingreso             date,
  bautizado                 boolean DEFAULT false,
  facultad_fe_liderazgo     boolean DEFAULT false,
  created_at                timestamptz DEFAULT now()
);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url              text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fecha_nacimiento         date;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS genero                   text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS direccion                text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS estado_civil             text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fecha_ingreso            date;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bautizado                boolean DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS facultad_fe_liderazgo   boolean DEFAULT false;

-- ── 1.2 EVENTOS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.eventos (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  titulo      text NOT NULL,
  descripcion text,
  fecha       date NOT NULL,
  hora        text,
  lugar       text,
  tipo        text,
  icono       text DEFAULT '📅',
  cupos       text DEFAULT 'Abierto',
  imagen_url  text,
  activo      boolean DEFAULT true,
  created_at  timestamptz DEFAULT now()
);
ALTER TABLE public.eventos ADD COLUMN IF NOT EXISTS imagen_url text;

-- ── 1.3 MINISTERIOS ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ministerios (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre        text NOT NULL,
  descripcion   text,
  horario       text,
  lugar         text,
  lideres       text,
  lider_email   text,
  icono         text DEFAULT '👥',
  activo        boolean DEFAULT true,
  created_at    timestamptz DEFAULT now()
);
ALTER TABLE public.ministerios ADD COLUMN IF NOT EXISTS lider_email text;
-- Remover columna miembros hardcodeada si existe (calculada dinámicamente)
-- ALTER TABLE public.ministerios DROP COLUMN IF EXISTS miembros;

-- ── 1.4 ARTÍCULOS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.articulos (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  titulo        text NOT NULL,
  resumen       text,
  contenido     text,
  categoria     text,
  autor         text,
  imagen_emoji  text DEFAULT '📰',
  publicado     boolean DEFAULT false,
  created_at    timestamptz DEFAULT now()
);

-- ── 1.5 PLAN DE LECTURA ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.plan_lectura (
  id       uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  dia      integer NOT NULL UNIQUE,
  titulo   text,
  lecturas jsonb NOT NULL DEFAULT '[]'
);

-- ── 1.6 PROGRESO DE LECTURA ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.progreso_lectura (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  dia         integer NOT NULL,
  leidas      jsonb DEFAULT '[]',
  completado  boolean DEFAULT false,
  updated_at  timestamptz DEFAULT now(),
  UNIQUE(user_id, dia)
);

-- ── 1.7 PETICIONES DE ORACIÓN ───────────────────────────────
CREATE TABLE IF NOT EXISTS public.peticiones_oracion (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  nombre      text,
  categoria   text,
  peticion    text NOT NULL,
  anonima     boolean DEFAULT false,
  created_at  timestamptz DEFAULT now()
);

-- ── 1.8 ASISTENCIA (auto-registro usuario desde app) ────────
CREATE TABLE IF NOT EXISTS public.asistencia (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  servicio    text NOT NULL,
  fecha       date NOT NULL,
  created_at  timestamptz DEFAULT now()
);

-- ── 1.9 ASISTENCIA DOMINICAL (registro manual por admin) ────
-- Admin registra totales por fecha de servicio dominical
CREATE TABLE IF NOT EXISTS public.asistencia_dominical (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  fecha       date NOT NULL UNIQUE,
  servicio    text DEFAULT 'Servicio Dominical',
  total       integer DEFAULT 0,
  hombres     integer DEFAULT 0,
  mujeres     integer DEFAULT 0,
  ninos       integer DEFAULT 0,
  visitas     integer DEFAULT 0,
  notas       text,
  created_by  uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_at  timestamptz DEFAULT now(),
  created_at  timestamptz DEFAULT now()
);

-- ── 1.10 REGISTROS A EVENTOS ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.registros_evento (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  evento_id   uuid REFERENCES public.eventos(id) ON DELETE CASCADE,
  created_at  timestamptz DEFAULT now(),
  UNIQUE(user_id, evento_id)
);

-- ── 1.11 MIEMBROS DE MINISTERIOS ────────────────────────────
CREATE TABLE IF NOT EXISTS public.miembros_ministerio (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  ministerio_id   uuid REFERENCES public.ministerios(id) ON DELETE CASCADE,
  created_at      timestamptz DEFAULT now(),
  UNIQUE(user_id, ministerio_id)
);

-- ── 1.12 SOLICITUDES DE MEMBRESÍA ───────────────────────────
CREATE TABLE IF NOT EXISTS public.solicitudes_ministerio (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  ministerio_id   uuid REFERENCES public.ministerios(id) ON DELETE CASCADE NOT NULL,
  estado          text DEFAULT 'pendiente',
  mensaje         text,
  nota_lider      text,
  user_email      text,
  user_nombre     text,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now(),
  UNIQUE(user_id, ministerio_id)
);

-- ── 1.13 SERVICIOS FIJOS ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.servicios (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre      text NOT NULL,
  hora        text,
  lugar       text,
  activo      boolean DEFAULT true,
  orden       int DEFAULT 0,
  created_at  timestamptz DEFAULT now()
);

-- ── 1.14 MENSAJES DE MINISTERIO ─────────────────────────────
CREATE TABLE IF NOT EXISTS public.mensajes_ministerio (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  ministerio_id   uuid REFERENCES public.ministerios(id) ON DELETE CASCADE NOT NULL,
  user_id         uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  contenido       text NOT NULL,
  created_at      timestamptz DEFAULT now()
);

-- ── 1.15 TIPOS DE OFRENDA ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ofrenda_tipos (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre      text NOT NULL,
  icono       text DEFAULT '💰',
  activo      boolean DEFAULT true,
  orden       int DEFAULT 0,
  created_at  timestamptz DEFAULT now()
);

-- ── 1.16 CUENTAS BANCARIAS ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ofrenda_cuentas (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  banco           text NOT NULL,
  numero_cuenta   text NOT NULL,
  titular         text NOT NULL,
  tipo_cuenta     text DEFAULT 'Corriente',
  activo          boolean DEFAULT true,
  orden           int DEFAULT 0,
  created_at      timestamptz DEFAULT now()
);

-- ── 1.17 COMPROBANTES DE OFRENDA ────────────────────────────
CREATE TABLE IF NOT EXISTS public.comprobantes_ofrenda (
  id                uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id           uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  tipo              text NOT NULL,
  banco             text NOT NULL,
  monto             numeric(10,2),
  referencia        text,
  nombre_remitente  text,
  estado            text DEFAULT 'pendiente',
  nota_admin        text,
  created_at        timestamptz DEFAULT now()
);


-- ============================================================
-- SECCIÓN 2: FUNCIÓN Y TRIGGER AUTO-PERFIL
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, nombre)
  VALUES (new.id, new.raw_user_meta_data->>'nombre')
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- ============================================================
-- SECCIÓN 3: ROW LEVEL SECURITY — habilitar en todas
-- ============================================================

ALTER TABLE public.profiles               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eventos                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ministerios            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.articulos              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_lectura           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.progreso_lectura       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.peticiones_oracion     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asistencia             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asistencia_dominical   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registros_evento       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.miembros_ministerio    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.solicitudes_ministerio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.servicios              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mensajes_ministerio    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ofrenda_tipos          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ofrenda_cuentas        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comprobantes_ofrenda   ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- SECCIÓN 4: POLÍTICAS DE USUARIO (app PWA)
-- ============================================================

-- profiles
DROP POLICY IF EXISTS "perfil_propio_select"            ON public.profiles;
DROP POLICY IF EXISTS "perfil_propio_update"            ON public.profiles;
DROP POLICY IF EXISTS "profiles_read_all_authenticated" ON public.profiles;
CREATE POLICY "perfil_propio_update"            ON public.profiles FOR UPDATE  USING (auth.uid() = id);
CREATE POLICY "profiles_read_all_authenticated" ON public.profiles FOR SELECT  TO authenticated USING (true);

-- eventos: lectura de activos para autenticados + pública sin auth (cartelera)
DROP POLICY IF EXISTS "eventos_read"        ON public.eventos;
DROP POLICY IF EXISTS "eventos_public_read" ON public.eventos;
CREATE POLICY "eventos_read"        ON public.eventos FOR SELECT TO authenticated USING (activo = true);
CREATE POLICY "eventos_public_read" ON public.eventos FOR SELECT USING (activo = true);

-- ministerios
DROP POLICY IF EXISTS "ministerios_read" ON public.ministerios;
CREATE POLICY "ministerios_read" ON public.ministerios FOR SELECT TO authenticated USING (activo = true);

-- artículos
DROP POLICY IF EXISTS "articulos_read" ON public.articulos;
CREATE POLICY "articulos_read" ON public.articulos FOR SELECT TO authenticated USING (publicado = true);

-- plan_lectura
DROP POLICY IF EXISTS "plan_read" ON public.plan_lectura;
CREATE POLICY "plan_read" ON public.plan_lectura FOR SELECT TO authenticated USING (true);

-- progreso_lectura
DROP POLICY IF EXISTS "progreso_select" ON public.progreso_lectura;
DROP POLICY IF EXISTS "progreso_insert" ON public.progreso_lectura;
DROP POLICY IF EXISTS "progreso_update" ON public.progreso_lectura;
CREATE POLICY "progreso_select" ON public.progreso_lectura FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "progreso_insert" ON public.progreso_lectura FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "progreso_update" ON public.progreso_lectura FOR UPDATE USING (auth.uid() = user_id);

-- peticiones_oracion
DROP POLICY IF EXISTS "oracion_insert" ON public.peticiones_oracion;
CREATE POLICY "oracion_insert" ON public.peticiones_oracion FOR INSERT TO authenticated WITH CHECK (true);

-- asistencia (usuario registra la propia)
DROP POLICY IF EXISTS "asistencia_insert" ON public.asistencia;
DROP POLICY IF EXISTS "asistencia_read_own" ON public.asistencia;
CREATE POLICY "asistencia_insert"   ON public.asistencia FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "asistencia_read_own" ON public.asistencia FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- registros_evento
DROP POLICY IF EXISTS "registro_select" ON public.registros_evento;
DROP POLICY IF EXISTS "registro_insert" ON public.registros_evento;
DROP POLICY IF EXISTS "registro_delete" ON public.registros_evento;
CREATE POLICY "registro_select" ON public.registros_evento FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "registro_insert" ON public.registros_evento FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "registro_delete" ON public.registros_evento FOR DELETE USING (auth.uid() = user_id);

-- miembros_ministerio: usuarios leen los suyos; admin gestiona todos
DROP POLICY IF EXISTS "miembro_select" ON public.miembros_ministerio;
DROP POLICY IF EXISTS "miembro_insert" ON public.miembros_ministerio;
DROP POLICY IF EXISTS "miembro_delete" ON public.miembros_ministerio;
CREATE POLICY "miembro_select" ON public.miembros_ministerio FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "miembro_delete" ON public.miembros_ministerio FOR DELETE USING (auth.uid() = user_id);

-- solicitudes_ministerio
DROP POLICY IF EXISTS "solicitudes_insert"          ON public.solicitudes_ministerio;
DROP POLICY IF EXISTS "solicitudes_read_own"        ON public.solicitudes_ministerio;
DROP POLICY IF EXISTS "solicitudes_update_own_read" ON public.solicitudes_ministerio;
CREATE POLICY "solicitudes_insert"   ON public.solicitudes_ministerio FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "solicitudes_read_own" ON public.solicitudes_ministerio FOR SELECT TO authenticated USING (user_id = auth.uid());

-- servicios
DROP POLICY IF EXISTS "servicios_read_active" ON public.servicios;
CREATE POLICY "servicios_read_active" ON public.servicios FOR SELECT TO authenticated USING (activo = true);

-- mensajes_ministerio: solo miembros del ministerio o admin
DROP POLICY IF EXISTS "mensajes_read_members"   ON public.mensajes_ministerio;
DROP POLICY IF EXISTS "mensajes_insert_members" ON public.mensajes_ministerio;
CREATE POLICY "mensajes_read_members" ON public.mensajes_ministerio
  FOR SELECT TO authenticated USING (
    ministerio_id IN (
      SELECT ministerio_id FROM public.miembros_ministerio WHERE user_id = auth.uid()
    )
    OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );
CREATE POLICY "mensajes_insert_members" ON public.mensajes_ministerio
  FOR INSERT TO authenticated WITH CHECK (
    user_id = auth.uid() AND
    ministerio_id IN (
      SELECT ministerio_id FROM public.miembros_ministerio WHERE user_id = auth.uid()
    )
  );

-- ofrenda_tipos
DROP POLICY IF EXISTS "ofrenda_tipos_read" ON public.ofrenda_tipos;
CREATE POLICY "ofrenda_tipos_read" ON public.ofrenda_tipos FOR SELECT TO authenticated USING (activo = true);

-- ofrenda_cuentas
DROP POLICY IF EXISTS "ofrenda_cuentas_read" ON public.ofrenda_cuentas;
CREATE POLICY "ofrenda_cuentas_read" ON public.ofrenda_cuentas FOR SELECT TO authenticated USING (activo = true);

-- comprobantes_ofrenda
DROP POLICY IF EXISTS "comprobantes_insert"   ON public.comprobantes_ofrenda;
DROP POLICY IF EXISTS "comprobantes_read_own" ON public.comprobantes_ofrenda;
CREATE POLICY "comprobantes_insert"   ON public.comprobantes_ofrenda FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "comprobantes_read_own" ON public.comprobantes_ofrenda FOR SELECT TO authenticated USING (user_id = auth.uid());


-- ============================================================
-- SECCIÓN 5: POLÍTICAS DE ADMINISTRADOR (CRM)
-- Helper: (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
-- ============================================================

-- profiles: admin lee y edita todos
DROP POLICY IF EXISTS "admin_profiles_read"   ON public.profiles;
DROP POLICY IF EXISTS "admin_profiles_update" ON public.profiles;
CREATE POLICY "admin_profiles_read"   ON public.profiles FOR SELECT USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_profiles_update" ON public.profiles FOR UPDATE USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- eventos: admin CRUD completo (incluyendo inactivos)
DROP POLICY IF EXISTS "admin_eventos_read_all" ON public.eventos;
DROP POLICY IF EXISTS "admin_eventos_insert"   ON public.eventos;
DROP POLICY IF EXISTS "admin_eventos_update"   ON public.eventos;
DROP POLICY IF EXISTS "admin_eventos_delete"   ON public.eventos;
CREATE POLICY "admin_eventos_read_all" ON public.eventos FOR SELECT USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_eventos_insert"   ON public.eventos FOR INSERT WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_eventos_update"   ON public.eventos FOR UPDATE USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_eventos_delete"   ON public.eventos FOR DELETE USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ministerios: admin CRUD completo
DROP POLICY IF EXISTS "admin_ministerios_read_all" ON public.ministerios;
DROP POLICY IF EXISTS "admin_ministerios_insert"   ON public.ministerios;
DROP POLICY IF EXISTS "admin_ministerios_update"   ON public.ministerios;
DROP POLICY IF EXISTS "admin_ministerios_delete"   ON public.ministerios;
CREATE POLICY "admin_ministerios_read_all" ON public.ministerios FOR SELECT USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_ministerios_insert"   ON public.ministerios FOR INSERT WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_ministerios_update"   ON public.ministerios FOR UPDATE USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_ministerios_delete"   ON public.ministerios FOR DELETE USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- artículos: admin CRUD completo (incluyendo no publicados)
DROP POLICY IF EXISTS "admin_articulos_read_all" ON public.articulos;
DROP POLICY IF EXISTS "admin_articulos_insert"   ON public.articulos;
DROP POLICY IF EXISTS "admin_articulos_update"   ON public.articulos;
DROP POLICY IF EXISTS "admin_articulos_delete"   ON public.articulos;
CREATE POLICY "admin_articulos_read_all" ON public.articulos FOR SELECT USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_articulos_insert"   ON public.articulos FOR INSERT WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_articulos_update"   ON public.articulos FOR UPDATE USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_articulos_delete"   ON public.articulos FOR DELETE USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- plan_lectura: admin CRUD completo
DROP POLICY IF EXISTS "admin_plan_insert" ON public.plan_lectura;
DROP POLICY IF EXISTS "admin_plan_update" ON public.plan_lectura;
DROP POLICY IF EXISTS "admin_plan_delete" ON public.plan_lectura;
DROP POLICY IF EXISTS "admin_plan_read"   ON public.plan_lectura;
CREATE POLICY "admin_plan_read"   ON public.plan_lectura FOR SELECT USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_plan_insert" ON public.plan_lectura FOR INSERT WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_plan_update" ON public.plan_lectura FOR UPDATE USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_plan_delete" ON public.plan_lectura FOR DELETE USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- peticiones_oracion: admin lee todas
DROP POLICY IF EXISTS "admin_oraciones_read" ON public.peticiones_oracion;
CREATE POLICY "admin_oraciones_read" ON public.peticiones_oracion FOR SELECT USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- asistencia (auto-registro app): admin lee todas
DROP POLICY IF EXISTS "admin_asistencia_read" ON public.asistencia;
CREATE POLICY "admin_asistencia_read" ON public.asistencia FOR SELECT USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- asistencia_dominical: admin CRUD completo
DROP POLICY IF EXISTS "admin_asistencia_dominical_all" ON public.asistencia_dominical;
CREATE POLICY "admin_asistencia_dominical_all" ON public.asistencia_dominical
  FOR ALL USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- registros_evento: admin lee todos
DROP POLICY IF EXISTS "admin_registros_read" ON public.registros_evento;
CREATE POLICY "admin_registros_read" ON public.registros_evento FOR SELECT USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- miembros_ministerio: admin CRUD (para aceptar/rechazar solicitudes)
DROP POLICY IF EXISTS "admin_miembros_read" ON public.miembros_ministerio;
DROP POLICY IF EXISTS "admin_miembros_all"  ON public.miembros_ministerio;
CREATE POLICY "admin_miembros_all" ON public.miembros_ministerio
  FOR ALL USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- solicitudes_ministerio: admin CRUD completo
DROP POLICY IF EXISTS "admin_solicitudes_all" ON public.solicitudes_ministerio;
CREATE POLICY "admin_solicitudes_all" ON public.solicitudes_ministerio
  FOR ALL USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- servicios: admin CRUD completo
DROP POLICY IF EXISTS "admin_servicios_all"      ON public.servicios;
DROP POLICY IF EXISTS "admin_servicios_read_all" ON public.servicios;
CREATE POLICY "admin_servicios_all" ON public.servicios
  FOR ALL USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- mensajes_ministerio: admin lee y envía a cualquier ministerio
DROP POLICY IF EXISTS "admin_mensajes_read"   ON public.mensajes_ministerio;
DROP POLICY IF EXISTS "admin_mensajes_insert" ON public.mensajes_ministerio;
CREATE POLICY "admin_mensajes_read"   ON public.mensajes_ministerio FOR SELECT USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_mensajes_insert" ON public.mensajes_ministerio FOR INSERT WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ofrenda_tipos: admin CRUD
DROP POLICY IF EXISTS "admin_ofrenda_tipos_all"      ON public.ofrenda_tipos;
DROP POLICY IF EXISTS "admin_ofrenda_tipos_read_all" ON public.ofrenda_tipos;
CREATE POLICY "admin_ofrenda_tipos_all" ON public.ofrenda_tipos
  FOR ALL USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ofrenda_cuentas: admin CRUD
DROP POLICY IF EXISTS "admin_ofrenda_cuentas_all"      ON public.ofrenda_cuentas;
DROP POLICY IF EXISTS "admin_ofrenda_cuentas_read_all" ON public.ofrenda_cuentas;
CREATE POLICY "admin_ofrenda_cuentas_all" ON public.ofrenda_cuentas
  FOR ALL USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- comprobantes_ofrenda: admin CRUD
DROP POLICY IF EXISTS "admin_comprobantes_all" ON public.comprobantes_ofrenda;
CREATE POLICY "admin_comprobantes_all" ON public.comprobantes_ofrenda
  FOR ALL USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');


-- ============================================================
-- SECCIÓN 6: STORAGE BUCKETS
-- ============================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('eventos-arte', 'eventos-arte', true, 2097152, ARRAY['image/jpeg','image/png','image/webp']),
  ('avatares',     'avatares',     true, 2097152, ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO NOTHING;

-- Storage: eventos-arte (admin sube, todos leen)
DROP POLICY IF EXISTS "eventos_arte_read"         ON storage.objects;
DROP POLICY IF EXISTS "eventos_arte_admin_insert" ON storage.objects;
DROP POLICY IF EXISTS "eventos_arte_admin_update" ON storage.objects;
DROP POLICY IF EXISTS "eventos_arte_admin_delete" ON storage.objects;
CREATE POLICY "eventos_arte_read"         ON storage.objects FOR SELECT USING (bucket_id = 'eventos-arte');
CREATE POLICY "eventos_arte_admin_insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'eventos-arte' AND (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "eventos_arte_admin_update" ON storage.objects FOR UPDATE USING (bucket_id = 'eventos-arte' AND (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY "eventos_arte_admin_delete" ON storage.objects FOR DELETE USING (bucket_id = 'eventos-arte' AND (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- Storage: avatares (cada usuario gestiona su carpeta /{user_id}/avatar.ext)
DROP POLICY IF EXISTS "avatares_read"   ON storage.objects;
DROP POLICY IF EXISTS "avatares_insert" ON storage.objects;
DROP POLICY IF EXISTS "avatares_update" ON storage.objects;
DROP POLICY IF EXISTS "avatares_delete" ON storage.objects;
CREATE POLICY "avatares_read"   ON storage.objects FOR SELECT USING (bucket_id = 'avatares');
CREATE POLICY "avatares_insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatares' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "avatares_update" ON storage.objects FOR UPDATE USING (bucket_id = 'avatares' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "avatares_delete" ON storage.objects FOR DELETE USING (bucket_id = 'avatares' AND auth.uid()::text = (storage.foldername(name))[1]);


-- ============================================================
-- SECCIÓN 7: DATOS SEMILLA (solo si tablas están vacías)
-- ============================================================

-- Ministerios
INSERT INTO public.ministerios (nombre, descripcion, horario, lugar, lideres, icono) VALUES
  ('Jóvenes Universitarios', 'Espacio para jóvenes universitarios que buscan crecer en su fe mientras navegan los desafíos de la vida académica y profesional.', 'Sábados 6:00 PM', 'Salón 2', 'Ana García, Marco Pérez', '👥'),
  ('Ministerio de Alabanza', 'Equipo de músicos y cantantes que lidera los tiempos de adoración en los servicios de la iglesia.', 'Ensayos martes y jueves 7:00 PM', 'Sala de música', 'Carlos Mendoza', '🎸'),
  ('Frater Kids (Voluntariado)', 'Voluntarios que cuidan y enseñan a los niños durante los servicios dominicales.', 'Domingos 8:30 AM', 'Área infantil', 'Rosa López', '👧'),
  ('Círculo de Mujeres', 'Comunidad de mujeres que se apoyan mutuamente en la fe, familia y propósito.', 'Reuniones mensuales — primer sábado', 'Cafetería Frater', 'Patricia Morales', '☕')
ON CONFLICT DO NOTHING;

-- Artículos
INSERT INTO public.articulos (titulo, resumen, contenido, categoria, autor, imagen_emoji, publicado) VALUES
  ('Resumen del Retiro Anual', 'Revive los mejores momentos de nuestro campamento y escucha los testimonios.', 'Este año nuestro retiro anual superó todas las expectativas. Más de 200 personas de todas las generaciones se reunieron durante tres días para buscar a Dios, renovar fuerzas y construir lazos más profundos como comunidad. El tema central fue "Raíces Profundas", basado en Jeremías 17:7-8.', 'Comunidad', 'Pastor Daniel Ruiz', '⛺', true),
  ('Jornada Médica en la Comunidad', 'Gracias a todos los voluntarios, atendimos a más de 150 familias este mes.', 'La jornada médica realizada el pasado fin de semana fue un éxito rotundo. Más de 40 voluntarios atendieron a 152 familias. Se brindaron consultas generales, atención dental básica y entrega de medicamentos.', 'Obras Sociales', 'Equipo de Misiones', '🏥', true)
ON CONFLICT DO NOTHING;

-- Eventos (fechas relativas a hoy)
INSERT INTO public.eventos (titulo, descripcion, fecha, hora, lugar, tipo, icono) VALUES
  ('Noche de Adoración', 'Una noche especial de alabanza y adoración para los jóvenes. Habrá música en vivo, tiempo de oración y refrigerios.', current_date + 2, '6:00 PM', 'Auditorio Principal', 'Jóvenes', '🎵'),
  ('Servicio Dominical', 'Únete a nuestro servicio semanal de adoración y predicación de la Palabra.', current_date + 3, '9:00 AM', 'Auditorio Principal', 'General', '⛪'),
  ('Té y Plática — Mujeres', 'Un tiempo especial de comunidad, oración y charla inspiradora para todas las mujeres de la iglesia.', current_date + 5, '4:00 PM', 'Cafetería Frater', 'Mujeres', '☕'),
  ('Estudio Bíblico Semanal', 'Profundizamos juntos en la Palabra. Esta semana: el libro de Hechos capítulos 5-7.', current_date + 7, '7:00 PM', 'Sala de conferencias', 'General', '📖')
ON CONFLICT DO NOTHING;

-- Servicios fijos
INSERT INTO public.servicios (nombre, hora, lugar, orden) VALUES
  ('Servicio Dominical',   '9:00 AM', 'Auditorio Principal',  1),
  ('Servicio de Jóvenes',  '6:00 PM', 'Salón 2',              2),
  ('Estudio Bíblico',      '7:00 PM', 'Sala de conferencias', 3),
  ('Reunión de Oración',   '6:30 PM', 'Capilla',              4)
ON CONFLICT DO NOTHING;

-- Tipos de ofrenda
INSERT INTO public.ofrenda_tipos (nombre, icono, orden) VALUES
  ('Diezmo',       '🌱', 1),
  ('Ofrenda',      '❤️',  2),
  ('Misiones',     '✈️',  3),
  ('Construcción', '🏗️', 4)
ON CONFLICT DO NOTHING;

-- Cuentas bancarias
INSERT INTO public.ofrenda_cuentas (banco, numero_cuenta, titular, tipo_cuenta, orden) VALUES
  ('Banco Agrícola', '0000-0000-00', 'Fraternidad Cristiana de El Salvador', 'Corriente', 1),
  ('Davivienda',     '0000-0000-00', 'Fraternidad Cristiana de El Salvador', 'Corriente', 2)
ON CONFLICT DO NOTHING;
