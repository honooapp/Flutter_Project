import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const WINDOW_MIN = 10;      // finestra rate limit in minuti
const MAX_PER_EMAIL = 5;    // tentativi per email per finestra
const MAX_PER_IP = 20;      // tentativi per IP per finestra

serve(async (req) => {
  try {
    const { email, redirectUrl } = await req.json();
    if (!email) return new Response(JSON.stringify({ error: "email required" }), { status: 400 });

    const ip = req.headers.get("x-forwarded-for") ?? req.headers.get("cf-connecting-ip") ?? "0.0.0.0";

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const sb = createClient(supabaseUrl, supabaseKey);

    // rate limit per email
    const { count: emailCount } = await sb
      .from("auth_otp_attempts")
      .select("*", { count: "exact", head: true })
      .gte("created_at", new Date(Date.now() - WINDOW_MIN * 60 * 1000).toISOString())
      .eq("email", email);

    if ((emailCount ?? 0) >= MAX_PER_EMAIL) {
      return new Response(JSON.stringify({ error: "too_many_requests_email" }), { status: 429 });
    }

    // rate limit per IP
    const { count: ipCount } = await sb
      .from("auth_otp_attempts")
      .select("*", { count: "exact", head: true })
      .gte("created_at", new Date(Date.now() - WINDOW_MIN * 60 * 1000).toISOString())
      .eq("ip", ip);

    if ((ipCount ?? 0) >= MAX_PER_IP) {
      return new Response(JSON.stringify({ error: "too_many_requests_ip" }), { status: 429 });
    }

    // registra tentativo
    await sb.from("auth_otp_attempts").insert({ email, ip });

    // invia magic link
    const admin = sb.auth.admin;
    const { error } = await admin.generateLink({
      type: "magiclink",
      email,
      options: { emailRedirectTo: redirectUrl }
    });
    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 400 });

    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
