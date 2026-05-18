import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonHeaders() {
  return {
    "Content-Type": "application/json",
    ...corsHeaders,
  };
}

function extractJson(text: string): any {
  const cleaned = text
    .replace(/```json/gi, "```")
    .replace(/```/g, "")
    .trim();

  const first = cleaned.indexOf("{");
  const last = cleaned.lastIndexOf("}");

  if (first === -1 || last === -1 || last <= first) {
    throw new Error("AI çıktısı JSON değil.");
  }

  return JSON.parse(cleaned.slice(first, last + 1));
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // -------------------------
    // AUTH CHECK
    // -------------------------
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: jsonHeaders() }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const {
      data: { user },
      error: userErr,
    } = await supabase.auth.getUser();

    if (userErr || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid user" }),
        { status: 401, headers: jsonHeaders() }
      );
    }

    // -------------------------
    // BODY VALIDATION
    // -------------------------
    const body = await req.json().catch(() => ({}));

    const businessId = body?.businessId;
    if (!businessId || typeof businessId !== "string") {
      return new Response(
        JSON.stringify({ error: "businessId zorunlu" }),
        { status: 400, headers: jsonHeaders() }
      );
    }

    const inc = Number(body?.income) || 0;
    const exp = Number(body?.expense) || 0;
    const unpaid = Number(body?.unpaidInvoices) || 0;
    const critical = Number(body?.criticalStock) || 0;
    const totalP = Number(body?.totalProducts) || 0;

    // -------------------------
    // OWNERSHIP CHECK (Security Hardening)
    // -------------------------
    const { data: role } = await supabase
      .from("user_business_roles")
      .select("id")
      .eq("business_id", businessId)
      .eq("user_id", user.id)
      .maybeSingle();

    if (!role) {
      return new Response(
        JSON.stringify({ error: "Forbidden" }),
        { status: 403, headers: jsonHeaders() }
      );
    }

    // -------------------------
    // PREMIUM CHECK
    // -------------------------
    const { data: business, error: bizErr } = await supabase
      .from("businesses")
      .select("plan")
      .eq("id", businessId)
      .single();

    if (bizErr || !business) {
      return new Response(
        JSON.stringify({ error: "Business not found" }),
        { status: 404, headers: jsonHeaders() }
      );
    }

    if (business.plan === "free") {
      return new Response(
        JSON.stringify({ error: "Premium feature" }),
        { status: 403, headers: jsonHeaders() }
      );
    }

    // -------------------------
    // SCORE CALCULATION
    // -------------------------
    const profitMargin = inc > 0 ? (inc - exp) / inc : 0;
    const expenseRatio = inc > 0 ? exp / inc : 1;
    const collectionRatio = inc > 0 ? unpaid / inc : 1;
    const net = inc - exp;
    const criticalRatio = totalP > 0 ? critical / totalP : 0;

    let profitScore =
      profitMargin > 0.3 ? 30 :
      profitMargin > 0.15 ? 20 :
      profitMargin > 0.05 ? 10 : 0;

    let expenseScore =
      expenseRatio < 0.5 ? 20 :
      expenseRatio < 0.7 ? 15 :
      expenseRatio < 0.85 ? 8 : 0;

    let collectionScore =
      collectionRatio < 0.1 ? 20 :
      collectionRatio < 0.25 ? 15 :
      collectionRatio < 0.4 ? 8 : 0;

    const cashScore = net > 0 ? 15 : net === 0 ? 7 : 0;

    let stockScore =
      criticalRatio < 0.05 ? 15 :
      criticalRatio < 0.15 ? 10 :
      criticalRatio < 0.3 ? 5 : 0;

    const financialHealthScore =
      profitScore +
      expenseScore +
      collectionScore +
      cashScore +
      stockScore;

    // -------------------------
    // AI CALL (Timeout Protected)
    // -------------------------
    const prompt = `
Finansal Sağlık Skoru: ${financialHealthScore}/100
Gelir: ${inc}
Gider: ${exp}
Tahsil Edilmemiş: ${unpaid}
Kritik Stok: ${critical}
Toplam Ürün: ${totalP}

Skora göre 3 stratejik öneri üret.
SADECE JSON dön:

{
  "risk_level": "Düşük|Orta|Yüksek",
  "actions": ["...", "...", "..."]
}
`.trim();

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);

    let aiOutput: any = {};

    try {
      const aiRes = await fetch(
        `${Deno.env.get("GOOGLE_API_BASE_URL")}/models/${Deno.env.get("GOOGLE_MODEL")}:generateContent?key=${Deno.env.get("GOOGLE_API_KEY")}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: { temperature: 0.3 },
          }),
          signal: controller.signal,
        }
      );

      const result = await aiRes.json();
      const outputText =
        result?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

      aiOutput = extractJson(outputText);
    } catch {
      aiOutput = {
        risk_level:
          financialHealthScore < 40
            ? "Yüksek"
            : financialHealthScore < 70
            ? "Orta"
            : "Düşük",
        actions: [
          "Nakit akışınızı haftalık takip edin.",
          "Sabit giderleri optimize edin.",
          "Stok planlamasını yeniden gözden geçirin.",
        ],
      };
    } finally {
      clearTimeout(timeout);
    }

    // -------------------------
    // SAVE INSIGHT (Non-blocking)
    // -------------------------
    try {
      await supabase.from("ai_insights").insert({
        business_id: businessId,
        scope: "financial_health",
        input: {
          income: inc,
          expense: exp,
          unpaidInvoices: unpaid,
          criticalStock: critical,
          totalProducts: totalP,
          financialHealthScore,
        },
        output: JSON.stringify(aiOutput),
        provider: "google",
        model: Deno.env.get("GOOGLE_MODEL"),
        created_by: user.id,
      });
    } catch (_) {}

    return new Response(
      JSON.stringify({
        financialHealthScore,
        risk_level: aiOutput.risk_level ?? "Orta",
        actions: aiOutput.actions ?? [],
      }),
      { headers: jsonHeaders() }
    );

  } catch (err) {
    return new Response(
      JSON.stringify({ error: err?.message ?? "Internal error" }),
      { status: 500, headers: jsonHeaders() }
    );
  }
});
