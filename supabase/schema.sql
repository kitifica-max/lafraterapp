-- ============================================================
-- FRATER APP — Schema Supabase
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- ============================================================

-- ── 1. PROFILES ─────────────────────────────────────────────
create table if not exists public.profiles (
  id          uuid references auth.users(id) on delete cascade primary key,
  nombre      text,
  telefono    text,
  avatar_url  text,
  created_at  timestamptz default now()
);

-- Trigger: crea perfil automáticamente al registrar usuario
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, nombre)
  values (new.id, new.raw_user_meta_data->>'nombre')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── 2. EVENTOS ──────────────────────────────────────────────
create table if not exists public.eventos (
  id          uuid default gen_random_uuid() primary key,
  titulo      text not null,
  descripcion text,
  fecha       date not null,
  hora        text,
  lugar       text,
  tipo        text,   -- 'Jóvenes', 'General', 'Mujeres', 'Familia', etc.
  icono       text default '📅',
  cupos       text default 'Abierto',
  activo      boolean default true,
  created_at  timestamptz default now()
);

-- ── 3. MINISTERIOS ──────────────────────────────────────────
create table if not exists public.ministerios (
  id            uuid default gen_random_uuid() primary key,
  nombre        text not null,
  descripcion   text,
  horario       text,
  lugar         text,
  lideres       text,   -- nombres separados por coma
  icono         text default '👥',
  miembros      integer default 0,
  activo        boolean default true,
  created_at    timestamptz default now()
);

-- ── 4. ARTÍCULOS ────────────────────────────────────────────
create table if not exists public.articulos (
  id          uuid default gen_random_uuid() primary key,
  titulo      text not null,
  resumen     text,
  contenido   text,
  categoria   text,
  autor       text,
  imagen_emoji text default '📰',
  publicado   boolean default false,
  created_at  timestamptz default now()
);

-- ── 5. PLAN DE LECTURA ──────────────────────────────────────
create table if not exists public.plan_lectura (
  id        uuid default gen_random_uuid() primary key,
  dia       integer not null unique,  -- 1 a 365
  titulo    text,
  lecturas  jsonb not null default '[]'  -- ["Juan 1:1-14", "Salmos 23"]
);

-- ── 6. PROGRESO DE LECTURA ──────────────────────────────────
create table if not exists public.progreso_lectura (
  id                  uuid default gen_random_uuid() primary key,
  user_id             uuid references auth.users(id) on delete cascade,
  dia                 integer not null,
  leidas              jsonb default '[]',  -- [true, false, true]
  completado          boolean default false,
  updated_at          timestamptz default now(),
  unique(user_id, dia)
);

-- ── 7. PETICIONES DE ORACIÓN ────────────────────────────────
create table if not exists public.peticiones_oracion (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references auth.users(id) on delete set null,
  nombre      text,
  categoria   text,
  peticion    text not null,
  anonima     boolean default false,
  created_at  timestamptz default now()
);

-- ── 8. ASISTENCIA ───────────────────────────────────────────
create table if not exists public.asistencia (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references auth.users(id) on delete set null,
  servicio    text not null,
  fecha       date not null,
  created_at  timestamptz default now()
);

-- ── 9. REGISTROS A EVENTOS ──────────────────────────────────
create table if not exists public.registros_evento (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references auth.users(id) on delete cascade,
  evento_id   uuid references public.eventos(id) on delete cascade,
  created_at  timestamptz default now(),
  unique(user_id, evento_id)
);

-- ── 10. MIEMBROS DE MINISTERIOS ─────────────────────────────
create table if not exists public.miembros_ministerio (
  id              uuid default gen_random_uuid() primary key,
  user_id         uuid references auth.users(id) on delete cascade,
  ministerio_id   uuid references public.ministerios(id) on delete cascade,
  created_at      timestamptz default now(),
  unique(user_id, ministerio_id)
);


-- ============================================================
-- RLS (Row Level Security)
-- ============================================================

alter table public.profiles             enable row level security;
alter table public.eventos              enable row level security;
alter table public.ministerios          enable row level security;
alter table public.articulos            enable row level security;
alter table public.plan_lectura         enable row level security;
alter table public.progreso_lectura     enable row level security;
alter table public.peticiones_oracion   enable row level security;
alter table public.asistencia           enable row level security;
alter table public.registros_evento     enable row level security;
alter table public.miembros_ministerio  enable row level security;

-- profiles: lectura/escritura solo del propio perfil
create policy "perfil_propio_select" on public.profiles for select using (auth.uid() = id);
create policy "perfil_propio_update" on public.profiles for update using (auth.uid() = id);

-- eventos: lectura pública para usuarios autenticados
create policy "eventos_read" on public.eventos for select to authenticated using (activo = true);

-- ministerios: lectura pública para usuarios autenticados
create policy "ministerios_read" on public.ministerios for select to authenticated using (activo = true);

-- articulos: solo publicados
create policy "articulos_read" on public.articulos for select to authenticated using (publicado = true);

-- plan_lectura: lectura pública para autenticados
create policy "plan_read" on public.plan_lectura for select to authenticated using (true);

-- progreso_lectura: cada usuario gestiona el suyo
create policy "progreso_select" on public.progreso_lectura for select using (auth.uid() = user_id);
create policy "progreso_insert" on public.progreso_lectura for insert with check (auth.uid() = user_id);
create policy "progreso_update" on public.progreso_lectura for update using (auth.uid() = user_id);

-- peticiones_oracion: solo insertar (anónimas o con user_id)
create policy "oracion_insert" on public.peticiones_oracion for insert to authenticated with check (true);

-- asistencia: solo insertar
create policy "asistencia_insert" on public.asistencia for insert to authenticated with check (true);

-- registros_evento: el usuario gestiona los suyos
create policy "registro_select" on public.registros_evento for select using (auth.uid() = user_id);
create policy "registro_insert" on public.registros_evento for insert with check (auth.uid() = user_id);
create policy "registro_delete" on public.registros_evento for delete using (auth.uid() = user_id);

-- miembros_ministerio: el usuario gestiona los suyos
create policy "miembro_select" on public.miembros_ministerio for select using (auth.uid() = user_id);
create policy "miembro_insert" on public.miembros_ministerio for insert with check (auth.uid() = user_id);
create policy "miembro_delete" on public.miembros_ministerio for delete using (auth.uid() = user_id);


-- ============================================================
-- DATOS SEMILLA (Seed Data)
-- ============================================================

-- Ministerios
insert into public.ministerios (nombre, descripcion, horario, lugar, lideres, icono, miembros) values
  ('Jóvenes Universitarios', 'Espacio para jóvenes universitarios que buscan crecer en su fe mientras navegan los desafíos de la vida académica y profesional.', 'Sábados 6:00 PM', 'Salón 2', 'Ana García, Marco Pérez', '👥', 48),
  ('Ministerio de Alabanza', 'Equipo de músicos y cantantes que lidera los tiempos de adoración en los servicios de la iglesia.', 'Ensayos martes y jueves 7:00 PM', 'Sala de música', 'Carlos Mendoza', '🎸', 22),
  ('Frater Kids (Voluntariado)', 'Voluntarios que cuidan y enseñan a los niños durante los servicios dominicales.', 'Domingos 8:30 AM', 'Área infantil', 'Rosa López', '👧', 30),
  ('Círculo de Mujeres', 'Comunidad de mujeres que se apoyan mutuamente en la fe, familia y propósito.', 'Reuniones mensuales — primer sábado', 'Cafetería Frater', 'Patricia Morales', '☕', 65)
on conflict do nothing;

-- Artículos
insert into public.articulos (titulo, resumen, contenido, categoria, autor, imagen_emoji, publicado) values
  (
    'Resumen del Retiro Anual',
    'Revive los mejores momentos de nuestro campamento y escucha los testimonios.',
    'Este año nuestro retiro anual superó todas las expectativas. Más de 200 personas de todas las generaciones se reunieron durante tres días para buscar a Dios, renovar fuerzas y construir lazos más profundos como comunidad.\n\nEl tema central fue "Raíces Profundas", basado en Jeremías 17:7-8. Los testimonios compartidos fueron poderosos: familias restauradas, jóvenes encontrando propósito y personas tomando decisiones de fe.\n\nGracias a todos los que participaron, sirvieron y oraron. ¡Hasta el próximo año!',
    'Comunidad', 'Pastor Daniel Ruiz', '⛺', true
  ),
  (
    'Jornada Médica en la Comunidad',
    'Gracias a todos los voluntarios, atendimos a más de 150 familias este mes.',
    'La jornada médica realizada el pasado fin de semana fue un éxito rotundo. Más de 40 voluntarios —médicos, enfermeros y personal de apoyo— atendieron a 152 familias en la colonia Las Flores.\n\nSe brindaron consultas generales, atención dental básica y entrega de medicamentos. También se oró con cada familia que lo solicitó.\n\nEsta es la quinta jornada que realizamos este año. ¡Gracias por hacer posible este impacto!',
    'Obras Sociales', 'Equipo de Misiones', '🏥', true
  )
on conflict do nothing;

-- Eventos (usando fechas dinámicas relativas a "hoy")
insert into public.eventos (titulo, descripcion, fecha, hora, lugar, tipo, icono) values
  ('Noche de Adoración', 'Una noche especial de alabanza y adoración para los jóvenes. Habrá música en vivo, tiempo de oración y refrigerios.', current_date + 2, '6:00 PM', 'Auditorio Principal', 'Jóvenes', '🎵'),
  ('Servicio Dominical', 'Únete a nuestro servicio semanal de adoración y predicación de la Palabra.', current_date + 3, '9:00 AM', 'Auditorio Principal', 'General', '⛪'),
  ('Té y Plática — Mujeres', 'Un tiempo especial de comunidad, oración y charla inspiradora para todas las mujeres de la iglesia.', current_date + 5, '4:00 PM', 'Cafetería Frater', 'Mujeres', '☕'),
  ('Estudio Bíblico Semanal', 'Profundizamos juntos en la Palabra. Esta semana: el libro de Hechos capítulos 5-7.', current_date + 7, '7:00 PM', 'Sala de conferencias', 'General', '📖')
on conflict do nothing;

-- Plan de lectura — días alrededor de hoy (día del año actual)
-- Día 111
insert into public.plan_lectura (dia, titulo, lecturas) values
(111, 'Lectura del Día 111', '["Mateo 26:1-30", "Salmos 111", "Proverbios 27:1-4"]'),
(112, 'Lectura del Día 112', '["Mateo 26:31-56", "Salmos 112", "Proverbios 27:5-9"]'),
(113, 'Lectura del Día 113', '["Juan 1:1-14", "Salmos 23", "Proverbios 3:1-6"]'),
(114, 'Lectura del Día 114', '["Juan 1:15-51", "Salmos 114", "Proverbios 28:1-5"]'),
(115, 'Lectura del Día 115', '["Juan 2:1-25", "Salmos 115", "Proverbios 28:6-10"]'),
(116, 'Lectura del Día 116', '["Juan 3:1-21", "Salmos 116", "Proverbios 28:11-14"]'),
(117, 'Lectura del Día 117', '["Juan 3:22-36", "Salmos 117", "Proverbios 28:15-20"]'),
(118, 'Lectura del Día 118', '["Juan 4:1-30", "Salmos 118:1-14", "Proverbios 28:21-24"]'),
(119, 'Lectura del Día 119', '["Juan 4:31-54", "Salmos 118:15-29", "Proverbios 28:25-28"]'),
(120, 'Lectura del Día 120', '["Juan 5:1-30", "Salmos 119:1-16", "Proverbios 29:1-4"]')
on conflict (dia) do nothing;
