import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    // -------------------------
    // AUTH CHECK
    // -------------------------
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: jsonHeaders() }
      )
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    )

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid user" }),
        { status: 401, headers: jsonHeaders() }
      )
    }

    // -------------------------
    // BODY VALIDATION
    // -------------------------
    const body = await req.json().catch(() => ({}))
    const businessId = body?.businessId

    if (!businessId || typeof businessId !== "string") {
      return new Response(
        JSON.stringify({ error: "businessId required" }),
        { status: 400, headers: jsonHeaders() }
      )
    }

    // -------------------------
    // SECURITY: BUSINESS OWNERSHIP CHECK
    // -------------------------
    const { data: role } = await supabase
      .from("user_business_roles")
      .select("id")
      .eq("business_id", businessId)
      .eq("user_id", user.id)
      .maybeSingle()

    if (!role) {
      return new Response(
        JSON.stringify({ error: "Forbidden" }),
        { status: 403, headers: jsonHeaders() }
      )
    }

    // -------------------------
    // FETCH LAST 90 DAYS DATA
    // -------------------------
    const since = new Date(
      Date.now() - 90 * 24 * 60 * 60 * 1000
    ).toISOString()

    const { data: tx, error: txError } = await supabase
      .from("transactions")
      .select("amount,type,date")
      .eq("business_id", businessId)
      .gte("date", since)

    if (txError) {
      return new Response(
        JSON.stringify({ error: txError.message }),
        { status: 400, headers: jsonHeaders() }
      )
    }

    const dailyMap: Record<string, number> = {}

    for (const t of tx ?? []) {
      const day = new Date(t.date).toISOString().split("T")[0]
      if (!dailyMap[day]) dailyMap[day] = 0

      const value = Number(t.amount) || 0
      dailyMap[day] += t.type === "income" ? value : -value
    }

    const series = Object.entries(dailyMap)
      .sort((a, b) => a[0].localeCompare(b[0]))
      .map(([date, value]) => ({ date, value }))

    if (series.length < 7) {
      return new Response(
        JSON.stringify({
          forecast_30_days: 0,
          risk_level: "medium",
          confidence: 0,
          forecast_series: [],
          analysis: "Tahmin için yeterli veri bulunmuyor.",
        }),
        { headers: jsonHeaders() }
      )
    }

    // -------------------------
    // GEMINI CALL (SAFE)
    // -------------------------
    const prompt = `
Son 90 günlük net nakit akışı:
${JSON.stringify(series)}

30 günlük günlük tahmin üret.
Toplam tahmini hesapla.
Risk seviyesi (low|medium|high).
0-100 güven skoru.
Kısa CFO yorumu.

SADECE JSON dön:
{
  "forecast_30_days": number,
  "risk_level": "low|medium|high",
  "confidence": number,
  "forecast_series": [{ "day": 1, "value": number }],
  "analysis": string
}
`

    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), 15000)

    const aiRes = await fetch(
      `${Deno.env.get("GOOGLE_API_BASE_URL")}/models/${Deno.env.get("GOOGLE_MODEL")}:generateContent?key=${Deno.env.get("GOOGLE_API_KEY")}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
        }),
        signal: controller.signal,
      }
    ).finally(() => clearTimeout(timeout))

    const aiJson = await aiRes.json()
    let text =
      aiJson?.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}"

    text = text.replace(/```json/g, "").replace(/```/g, "").trim()

    let parsed: any

    try {
      parsed = JSON.parse(text)
    } catch {
      parsed = {
        forecast_30_days: 0,
        risk_level: "medium",
        confidence: 40,
        forecast_series: [],
        analysis: text,
      }
    }

    // -------------------------
    // VALIDATION
    // -------------------------
    if (!Array.isArray(parsed.forecast_series)) {
      parsed.forecast_series = []
    }

    if (typeof parsed.forecast_30_days !== "number") {
      parsed.forecast_30_days = 0
    }

    if (!["low", "medium", "high"].includes(parsed.risk_level)) {
      parsed.risk_level = "medium"
    }

    if (typeof parsed.confidence !== "number") {
      parsed.confidence = 50
    }

    // -------------------------
    // SAVE INSIGHT (SAFE)
    // -------------------------
    try {
      await supabase.from("ai_insights").insert({
        business_id: businessId,
        scope: "cashflow_forecast",
        input: { series },
        output: JSON.stringify(parsed),
        provider: "google",
        model: Deno.env.get("GOOGLE_MODEL"),
        created_by: user.id,
      })
    } catch (_) {
      // log but do not fail request
    }

    return new Response(
      JSON.stringify(parsed),
      { headers: jsonHeaders() }
    )

  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: jsonHeaders() }
    )
  }
})

function jsonHeaders() {
  return {
    "Content-Type": "application/json",
    ...corsHeaders,
  }
}
