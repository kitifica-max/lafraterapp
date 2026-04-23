import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Cliente admin con service_role — puede crear usuarios en auth.users
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // Cliente con la sesión del llamante para verificar identidad
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization") ?? "" },
        },
      }
    );

    // 1. Verificar que el llamante esté autenticado
    const {
      data: { user: caller },
      error: authError,
    } = await supabaseClient.auth.getUser();

    if (authError || !caller) {
      return json({ error: "No autorizado" }, 401);
    }

    // 2. Verificar que el llamante sea Admin o Super_Admin
    const { data: callerProfile, error: profileError } = await supabaseAdmin
      .from("miembros")
      .select("rol")
      .eq("id", caller.id)
      .single();

    if (
      profileError ||
      !callerProfile ||
      !["Super_Admin", "Admin"].includes(callerProfile.rol)
    ) {
      return json(
        { error: "Permiso denegado. Se requiere rol Admin o Super_Admin." },
        403
      );
    }

    // 3. Parsear el cuerpo de la petición
    const { nombre, email, rol = "miembro", telefono, ministerio } =
      await req.json();

    if (!nombre || !email) {
      return json({ error: "nombre y email son campos requeridos." }, 400);
    }

    // 4. Generar código de acceso único de 6 caracteres
    //    Se excluyen caracteres ambiguos: O, 0, 1, I, L
    const chars = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
    const randomBytes = new Uint8Array(6);
    crypto.getRandomValues(randomBytes);
    const codigoAcceso = Array.from(randomBytes)
      .map((b) => chars[b % chars.length])
      .join("");

    // 5. Crear usuario en auth.users con la contraseña generada
    const { data: newUserData, error: createError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password: codigoAcceso,
        email_confirm: true,          // confirmar email de inmediato (sin verificación)
        user_metadata: { nombre },
      });

    if (createError) {
      return json({ error: createError.message }, 400);
    }

    // 6. Insertar en la tabla pública miembros
    const { error: insertError } = await supabaseAdmin.from("miembros").insert({
      id: newUserData.user.id,
      nombre,
      email,
      rol,
      telefono: telefono || null,
      ministerio: ministerio || null,
    });

    if (insertError) {
      // Revertir: eliminar el usuario de auth si el insert falla
      await supabaseAdmin.auth.admin.deleteUser(newUserData.user.id);
      return json({ error: insertError.message }, 400);
    }

    // 7. Responder con el código de acceso para mostrarlo al administrador
    return json({
      success: true,
      user_id: newUserData.user.id,
      nombre,
      email,
      rol,
      codigo_acceso: codigoAcceso,
    });
  } catch (err) {
    return json({ error: (err as Error).message }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
