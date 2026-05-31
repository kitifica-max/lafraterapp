-- ============================================================
-- FRATER CRM — Políticas RLS para administradores
-- Ejecutar DESPUÉS de schema.sql en Supabase SQL Editor
-- ============================================================

-- Helper: verifica si el usuario autenticado tiene role=admin
-- en user_metadata (asignado durante el registro CRM)

-- ── Profiles: admin puede leer todos ─────────────────
create policy "admin_profiles_read" on public.profiles
  for select
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── Eventos: admin puede leer todos (inc. inactivos) y escribir ──
create policy "admin_eventos_read_all" on public.eventos
  for select
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

create policy "admin_eventos_insert" on public.eventos
  for insert
  with check ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

create policy "admin_eventos_update" on public.eventos
  for update
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

create policy "admin_eventos_delete" on public.eventos
  for delete
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── Ministerios: admin CRUD ───────────────────────────
create policy "admin_ministerios_read_all" on public.ministerios
  for select
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

create policy "admin_ministerios_insert" on public.ministerios
  for insert
  with check ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

create policy "admin_ministerios_update" on public.ministerios
  for update
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

create policy "admin_ministerios_delete" on public.ministerios
  for delete
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── Artículos: admin CRUD (incluye no publicados) ─────
create policy "admin_articulos_read_all" on public.articulos
  for select
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

create policy "admin_articulos_insert" on public.articulos
  for insert
  with check ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

create policy "admin_articulos_update" on public.articulos
  for update
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

create policy "admin_articulos_delete" on public.articulos
  for delete
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── Plan de lectura: admin CRUD ───────────────────────
create policy "admin_plan_insert" on public.plan_lectura
  for insert
  with check ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

create policy "admin_plan_update" on public.plan_lectura
  for update
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

create policy "admin_plan_delete" on public.plan_lectura
  for delete
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── Peticiones de oración: admin puede leer todas ─────
create policy "admin_oraciones_read" on public.peticiones_oracion
  for select
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── Asistencia: admin puede leer todas ───────────────
create policy "admin_asistencia_read" on public.asistencia
  for select
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── Registros de eventos: admin puede leer todos ──────
create policy "admin_registros_read" on public.registros_evento
  for select
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── Miembros de ministerios: admin puede leer todos ───
create policy "admin_miembros_read" on public.miembros_ministerio
  for select
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
