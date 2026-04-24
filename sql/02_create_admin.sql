-- ============================================================
-- FRATER APP — Script 2: Creación del Usuario Super Admin
-- Ejecutar DESPUÉS de 01_setup_tables.sql
-- ============================================================
-- INSTRUCCIONES:
--   1. Abre Supabase Dashboard > SQL Editor
--   2. Cambia la contraseña temporal en la variable temp_password
--   3. Ejecuta este script completo
--   4. Guarda la contraseña generada — la necesitarás para el primer login
-- ============================================================

DO $$
DECLARE
  new_user_id  UUID   := gen_random_uuid();
  admin_email  TEXT   := 'admin@lafratersv.com';
  admin_nombre TEXT   := 'Daniel Pineda';
  -- CAMBIA ESTA CONTRASEÑA antes de ejecutar:
  temp_password TEXT  := 'FraterAdmin2024!';
  existing_id  UUID;
BEGIN

  -- Limpiar intentos fallidos previos (usuario creado sin identities)
  SELECT id INTO existing_id FROM auth.users WHERE email = admin_email;
  IF existing_id IS NOT NULL THEN
    IF EXISTS (SELECT 1 FROM auth.identities WHERE user_id = existing_id) THEN
      RAISE NOTICE 'El usuario % ya existe y está completo. No se modificó.', admin_email;
      RETURN;
    ELSE
      -- Borrar el usuario incompleto para reintentar
      DELETE FROM public.miembros WHERE id = existing_id;
      DELETE FROM auth.users      WHERE id = existing_id;
      RAISE NOTICE 'Usuario incompleto eliminado. Recreando...';
    END IF;
  END IF;

  -- 1. Insertar en auth.users
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    invited_at,
    confirmation_token,
    confirmation_sent_at,
    recovery_token,
    recovery_sent_at,
    email_change_token_new,
    email_change,
    email_change_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at,
    phone,
    phone_confirmed_at,
    phone_change,
    phone_change_token,
    phone_change_sent_at,
    email_change_token_current,
    email_change_confirm_status,
    banned_until,
    reauthentication_token,
    reauthentication_sent_at
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',  -- instance_id
    new_user_id,
    'authenticated',
    'authenticated',
    admin_email,
    crypt(temp_password, gen_salt('bf')),    -- contraseña cifrada con bcrypt
    NOW(),                                   -- email_confirmed_at (confirmado de inmediato)
    NOW(),
    '',
    NOW(),
    '',
    NULL,
    '',
    '',
    NULL,
    NOW(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('nombre', admin_nombre),
    FALSE,
    NOW(),
    NOW(),
    NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL
  );

  -- 2. Insertar en auth.identities (requerido para login email/password en GoTrue v2)
  INSERT INTO auth.identities (
    id,
    user_id,
    provider_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    new_user_id,
    new_user_id,
    admin_email,
    jsonb_build_object('sub', new_user_id::TEXT, 'email', admin_email),
    'email',
    NOW(),
    NOW(),
    NOW()
  );

  -- 3. Insertar en public.miembros (bypassing RLS porque estamos en SQL Editor)
  INSERT INTO public.miembros (id, nombre, email, rol)
  VALUES (new_user_id, admin_nombre, admin_email, 'Super_Admin');

  RAISE NOTICE '✅ Usuario Super Admin creado exitosamente.';
  RAISE NOTICE '   ID:         %', new_user_id;
  RAISE NOTICE '   Email:      %', admin_email;
  RAISE NOTICE '   Contraseña: % (cámbiala después del primer login)', temp_password;

END $$;
