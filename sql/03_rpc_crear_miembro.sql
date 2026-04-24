-- ============================================================
-- FRATER APP — Script 3: RPC crear_miembro
-- Reemplaza la Edge Function — ejecutar en SQL Editor
-- ============================================================
-- Esta función crea el usuario en auth.users, auth.identities
-- y public.miembros en una sola transacción atómica.
-- Solo puede ser llamada por usuarios con rol Admin o Super_Admin.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.crear_miembro(
  p_nombre     TEXT,
  p_email      TEXT,
  p_rol        TEXT    DEFAULT 'miembro',
  p_telefono   TEXT    DEFAULT NULL,
  p_ministerio TEXT    DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_caller_rol TEXT;
  v_new_id     UUID := gen_random_uuid();
  v_codigo     TEXT;
BEGIN

  -- 1. Verificar que el llamante sea Admin o Super_Admin
  SELECT rol INTO v_caller_rol
  FROM public.miembros
  WHERE id = auth.uid();

  IF v_caller_rol IS NULL OR v_caller_rol NOT IN ('Super_Admin', 'Admin') THEN
    RAISE EXCEPTION 'Permiso denegado. Se requiere rol Admin o Super_Admin.';
  END IF;

  -- 2. Validar campos requeridos
  IF p_nombre IS NULL OR trim(p_nombre) = '' THEN
    RAISE EXCEPTION 'El campo nombre es requerido.';
  END IF;
  IF p_email IS NULL OR trim(p_email) = '' THEN
    RAISE EXCEPTION 'El campo email es requerido.';
  END IF;
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
    RAISE EXCEPTION 'Ya existe un usuario con el correo %.', p_email;
  END IF;

  -- 3. Generar código de acceso de 6 caracteres (sin ambiguos: O,0,1,I,L)
  SELECT string_agg(
    substr('ABCDEFGHJKMNPQRSTUVWXYZ23456789',
      (get_byte(gen_random_bytes(1)) % 32) + 1, 1), '')
  INTO v_codigo
  FROM generate_series(1, 6);

  -- 4. Insertar en auth.users con contraseña cifrada (bcrypt)
  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at,
    recovery_token, recovery_sent_at, email_change_token_new, email_change,
    email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data,
    is_super_admin, created_at, updated_at,
    phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at,
    email_change_token_current, email_change_confirm_status,
    banned_until, reauthentication_token, reauthentication_sent_at
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_new_id, 'authenticated', 'authenticated',
    p_email, crypt(v_codigo, gen_salt('bf')),
    NOW(), NOW(), '', NOW(),
    '', NULL, '', '', NULL, NOW(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('nombre', p_nombre),
    FALSE, NOW(), NOW(),
    NULL, NULL, '', '', NULL,
    '', 0, NULL, '', NULL
  );

  -- 5. Insertar en auth.identities (requerido para login email/password)
  INSERT INTO auth.identities (
    id, user_id, provider_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) VALUES (
    v_new_id, v_new_id, p_email,
    jsonb_build_object('sub', v_new_id::TEXT, 'email', p_email),
    'email', NOW(), NOW(), NOW()
  );

  -- 6. Insertar en public.miembros
  INSERT INTO public.miembros (id, nombre, email, rol, telefono, ministerio)
  VALUES (v_new_id, p_nombre, p_email, p_rol, p_telefono, p_ministerio);

  -- 7. Devolver resultado con el código generado
  RETURN jsonb_build_object(
    'success',       true,
    'user_id',       v_new_id,
    'nombre',        p_nombre,
    'email',         p_email,
    'rol',           p_rol,
    'codigo_acceso', v_codigo
  );

EXCEPTION WHEN others THEN
  -- Revertir registros parciales si algo falla
  DELETE FROM auth.identities WHERE user_id = v_new_id;
  DELETE FROM auth.users      WHERE id      = v_new_id;
  DELETE FROM public.miembros WHERE id      = v_new_id;
  RAISE;
END;
$$;

-- Revocar ejecución pública; solo usuarios autenticados pueden llamarla
REVOKE ALL ON FUNCTION public.crear_miembro FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crear_miembro TO authenticated;
