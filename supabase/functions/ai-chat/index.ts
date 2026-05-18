// supabase/functions/ai-chat/index.ts

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2.45.4";

/**
 * Required ENV
 * - SUPABASE_URL
 * - SUPABASE_ANON_KEY
 * - SUPABASE_SERVICE_ROLE_KEY
 * - GOOGLE_API_BASE_URL  Example: https://generativelanguage.googleapis.com/v1beta
 * - GOOGLE_MODEL         Example: gemini-2.5-flash
 * - GOOGLE_API_KEY
 */

type JsonRecord = Record<string, unknown>;
type DbClient = SupabaseClient<any, "public", any>;

type TransactionRow = {
  amount?: number | string | null;
  type?: string | null;
  date?: string | null;
  category?: string | null;
  notes?: string | null;
};

type InvoiceRow = {
  number?: string | null;
  status?: string | null;
  total?: number | string | null;
  issue_date?: string | null;
  due_date?: string | null;
};

type ProductRow = {
  name?: string | null;
  sku?: string | null;
  min_stock?: number | string | null;
  price?: number | string | null;
  updated_at?: string | null;
};

type CustomerRow = {
  name?: string | null;
  email?: string | null;
  phone?: string | null;
  last_interaction_at?: string | null;
};

type ChatMessageRow = {
  role?: string | null;
  message?: string | null;
  created_at?: string | null;
};

type GeminiPart = {
  text?: unknown;
};

type GeminiChunk = {
  candidates?: Array<{
    content?: {
      parts?: GeminiPart[];
    };
  }>;
};

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonHeaders(extra: Record<string, string> = {}) {
  return {
    ...corsHeaders,
    "Content-Type": "application/json; charset=utf-8",
    ...extra,
  };
}

function sseHeaders(extra: Record<string, string> = {}) {
  return {
    ...corsHeaders,
    "Content-Type": "text/event-stream; charset=utf-8",
    "Cache-Control": "no-cache, no-transform",
    Connection: "keep-alive",
    ...extra,
  };
}

function safeString(value: unknown, maxLen = 4000) {
  const text = (value ?? "").toString();
  return text.length > maxLen ? text.slice(0, maxLen) : text;
}

function safeNumber(value: unknown) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

function nowIso() {
  return new Date().toISOString();
}

function clampText(text: string, maxLen: number) {
  if (!text) return "";
  return text.length > maxLen ? text.slice(0, maxLen) : text;
}

function errorMessage(error: unknown) {
  if (error instanceof Error) return error.message;
  return String(error);
}

async function readJsonBody(req: Request): Promise<JsonRecord> {
  try {
    const value = await req.json();
    return value && typeof value === "object" && !Array.isArray(value)
      ? (value as JsonRecord)
      : {};
  } catch {
    return {};
  }
}

function createLogger(requestId: string) {
  return (step: string, extra: JsonRecord = {}) => {
    console.log(
      JSON.stringify({
        requestId,
        step,
        at: nowIso(),
        ...extra,
      }),
    );
  };
}

/**
 * Minimal ERP Summary RAG
 * Kullanıcının sorusuna göre küçük ve token-dostu bağlam üretir.
 */
async function buildErpSummaryRag(
  userClient: DbClient,
  businessId: string,
  message: string,
): Promise<JsonRecord> {
  const msg = (message || "").toLowerCase();

  const wantTx = /(gelir|gider|nakit|kasa|harcama|satış|ciro|kar|kâr)/i.test(
    msg,
  );
  const wantInv = /(fatura|tahsil|alacak|ödenmemiş|vade|borç)/i.test(msg);
  const wantStock = /(stok|ürün|kritik|min stok|depo)/i.test(msg);
  const wantCustomer = /(müşteri|cari)/i.test(msg);

  const since90 = new Date(Date.now() - 90 * 86400000).toISOString();

  const { data: tx90, error: tx90Err } = await userClient
    .from("transactions")
    .select("amount,type,date")
    .eq("business_id", businessId)
    .gte("date", since90)
    .limit(800);

  let income90 = 0;
  let expense90 = 0;

  if (!tx90Err) {
    for (const t of (tx90 ?? []) as TransactionRow[]) {
      const amount = safeNumber(t.amount);
      if (t.type === "income") income90 += amount;
      else expense90 += amount;
    }
  }

  const context: JsonRecord = {
    summary_90d: {
      income: income90,
      expense: expense90,
      net: income90 - expense90,
      tx_count: (tx90 ?? []).length,
      note: tx90Err ? "transactions okunamadı (RLS/policy?)" : undefined,
    },
  };

  if (wantTx) {
    const { data: lastTx } = await userClient
      .from("transactions")
      .select("type,amount,category,date,notes")
      .eq("business_id", businessId)
      .order("date", { ascending: false })
      .limit(20);

    context.last_transactions = ((lastTx ?? []) as TransactionRow[]).map((t) => ({
      type: t.type,
      amount: safeNumber(t.amount),
      category: t.category,
      date: t.date,
      notes: safeString(t.notes, 120),
    }));
  }

  if (wantInv) {
    const { data: inv } = await userClient
      .from("invoices")
      .select("number,status,total,issue_date,due_date")
      .eq("business_id", businessId)
      .neq("status", "paid")
      .order("issue_date", { ascending: false })
      .limit(15);

    let unpaidTotal = 0;
    for (const invoice of (inv ?? []) as InvoiceRow[]) {
      unpaidTotal += safeNumber(invoice.total);
    }

    context.unpaid_invoices = {
      count: (inv ?? []).length,
      total: unpaidTotal,
      last: ((inv ?? []) as InvoiceRow[]).slice(0, 8),
    };
  }

  if (wantStock) {
    const { data: products } = await userClient
      .from("products")
      .select("name,sku,min_stock,price,updated_at")
      .eq("business_id", businessId)
      .order("updated_at", { ascending: false })
      .limit(15);

    context.products_sample = ((products ?? []) as ProductRow[]).map((p) => ({
      name: safeString(p.name, 80),
      sku: safeString(p.sku, 40),
      min_stock: safeNumber(p.min_stock),
      price: safeNumber(p.price),
    }));

    context.stock_note =
      "Stok miktarı için inventory_movements üzerinden stok hesaplama veya ayrı stok tablosu gerekebilir.";
  }

  if (wantCustomer) {
    const { data: customers } = await userClient
      .from("customers")
      .select("name,email,phone,last_interaction_at")
      .eq("business_id", businessId)
      .order("last_interaction_at", { ascending: false, nullsFirst: false })
      .limit(12);

    context.customers_sample = ((customers ?? []) as CustomerRow[]).map((c) => ({
      name: safeString(c.name, 80),
      email: safeString(c.email, 80),
      phone: safeString(c.phone, 30),
      last_interaction_at: c.last_interaction_at,
    }));
  }

  return JSON.parse(clampText(JSON.stringify(context), 6000)) as JsonRecord;
}

/**
 * Optional Vector RAG
 * Şimdilik güvenli no-op. RPC yoksa veya embedding yoksa boş döner.
 */
async function tryVectorRag(
  adminClient: DbClient,
  businessId: string,
): Promise<JsonRecord[]> {
  try {
    const { error } = await adminClient.rpc("match_ai_embeddings", {
      business_id: businessId,
      match_count: 5,
    });

    if (error) return [];
    return [];
  } catch {
    return [];
  }
}

async function ensureThread(params: {
  adminClient: DbClient;
  businessId: string;
  userId: string;
  threadId?: string;
  mode: string;
}) {
  const { adminClient, businessId, userId, threadId, mode } = params;

  if (threadId) {
    const { data: existingThread } = await adminClient
      .from("ai_chat_threads")
      .select("id")
      .eq("id", threadId)
      .eq("business_id", businessId)
      .maybeSingle();

    const typedExistingThread = existingThread as { id?: string } | null;
    if (typedExistingThread?.id) {
      return { threadId: typedExistingThread.id, created: false };
    }
  }

  const { data: newThread, error } = await adminClient
    .from("ai_chat_threads")
    .insert({
      business_id: businessId,
      created_by: userId,
      mode,
    })
    .select("id")
    .single();

  const typedNewThread = newThread as { id?: string } | null;

  if (error || !typedNewThread?.id) {
    throw new Error(error?.message ?? "Thread oluşturulamadı");
  }

  return { threadId: typedNewThread.id, created: true };
}

function extractGeminiDelta(obj: GeminiChunk): string {
  const parts = obj.candidates?.[0]?.content?.parts;
  if (!Array.isArray(parts)) return "";

  return parts
    .map((part) => (typeof part.text === "string" ? part.text : ""))
    .join("");
}

function parsePotentialGeminiJsonLines(buffer: string): string[] {
  const trimmed = buffer.trim();
  if (!trimmed) return [];

  const lines = trimmed
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => (line.startsWith("data:") ? line.slice(5).trim() : line))
    .filter((line) => line && line !== "[DONE]");

  if (lines.length > 1) return lines;

  // Bazı Gemini yanıtları JSON array olarak dönebilir.
  if (trimmed.startsWith("[") && trimmed.endsWith("]")) {
    try {
      const arr = JSON.parse(trimmed) as unknown[];
      return arr.map((item) => JSON.stringify(item));
    } catch {
      return lines;
    }
  }

  return lines;
}

async function geminiStreamGenerate(params: {
  base: string;
  model: string;
  key: string;
  systemPrompt: string;
  message: string;
  temperature: number;
  maxOutputTokens: number;
  timeoutMs: number;
  onText: (delta: string) => Promise<void> | void;
  log: (step: string, extra?: JsonRecord) => void;
}) {
  const {
    base,
    model,
    key,
    systemPrompt,
    message,
    temperature,
    maxOutputTokens,
    timeoutMs,
    onText,
    log,
  } = params;

  log("gemini_stream_connect", { model });

  const abortController = new AbortController();
  const timeout = setTimeout(() => abortController.abort(), timeoutMs);

  try {
    const normalizedBase = base.replace(/\/$/, "");
    const url =
      `${normalizedBase}/models/${model}:streamGenerateContent?alt=sse&key=${key}`;

    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      signal: abortController.signal,
      body: JSON.stringify({
        systemInstruction: {
          role: "system",
          parts: [{ text: systemPrompt }],
        },
        contents: [
          {
            role: "user",
            parts: [{ text: message }],
          },
        ],
        generationConfig: {
          temperature,
          maxOutputTokens,
        },
      }),
    });

    log("gemini_http_status", { status: res.status });

    if (!res.ok) {
      const raw = await res.text().catch(() => "");
      if (res.status === 429) {
        throw new Error("RESOURCE_EXHAUSTED");
      }

      throw new Error(`Gemini HTTP ${res.status}: ${raw.slice(0, 1000)}`);
    }

    if (!res.body) {
      throw new Error("Gemini response has no body");
    }

    const reader = res.body.getReader();
    const decoder = new TextDecoder();

    let buffer = "";
    let emittedAny = false;

    while (true) {
      const { value, done } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });

      let newlineIndex: number;
      while ((newlineIndex = buffer.indexOf("\n")) !== -1) {
        const rawLine = buffer.slice(0, newlineIndex);
        buffer = buffer.slice(newlineIndex + 1);

        const clean = rawLine.trim().startsWith("data:")
          ? rawLine.trim().slice(5).trim()
          : rawLine.trim();

        if (!clean || clean === "[DONE]") continue;

        try {
          const obj = JSON.parse(clean) as GeminiChunk;
          const delta = extractGeminiDelta(obj);

          if (delta) {
            emittedAny = true;
            await onText(delta);
          }
        } catch (parseError) {
          log("gemini_stream_parse_retry", {
            error: errorMessage(parseError),
          });
          buffer = `${clean}\n${buffer}`;
          break;
        }
      }
    }

    for (const clean of parsePotentialGeminiJsonLines(buffer)) {
      try {
        const obj = JSON.parse(clean) as GeminiChunk;
        const delta = extractGeminiDelta(obj);
        if (delta) {
          emittedAny = true;
          await onText(delta);
        }
      } catch {
        // Ignore incomplete tail chunks.
      }
    }

    if (!emittedAny) {
      await onText("Yanıt üretilemedi. (Boş çıktı)");
    }
  } catch (error) {
    const messageText = errorMessage(error);
    if (error instanceof DOMException && error.name === "AbortError") {
      throw new Error("Gemini timeout");
    }
    throw new Error(messageText);
  } finally {
    clearTimeout(timeout);
  }
}

function makeSse(
  controller: ReadableStreamDefaultController<Uint8Array>,
  encoder: TextEncoder,
) {
  const send = (payload: JsonRecord) => {
    controller.enqueue(encoder.encode(`data: ${JSON.stringify(payload)}\n\n`));
  };

  return {
    meta: (payload: JsonRecord) => send({ type: "meta", ...payload }),
    chunk: (text: string) => send({ type: "chunk", chunk: text }),
    error: (message: string, extra: JsonRecord = {}) =>
      send({ type: "error", error: message, ...extra }),
    done: (extra: JsonRecord = {}) => send({ type: "done", ...extra }),
  };
}

async function streamWithGeminiFallback(args: {
  base: string;
  key: string;
  systemPrompt: string;
  message: string;
  temperature: number;
  maxOutputTokens: number;
  timeoutMs: number;
  primaryModel: string;
  secondaryModel: string;
  onText: (delta: string) => Promise<void> | void;
  log: (step: string, extra?: JsonRecord) => void;
}) {
  const run = (model: string) =>
    geminiStreamGenerate({
      base: args.base,
      model,
      key: args.key,
      systemPrompt: args.systemPrompt,
      message: args.message,
      temperature: args.temperature,
      maxOutputTokens: args.maxOutputTokens,
      timeoutMs: args.timeoutMs,
      onText: args.onText,
      log: args.log,
    });

  try {
    await run(args.primaryModel);
  } catch (error) {
    const msg = errorMessage(error);
    const isQuota =
      msg.includes("RESOURCE_EXHAUSTED") ||
      msg.toLowerCase().includes("quota") ||
      msg.includes("429");

    args.log("gemini_primary_failed", {
      isQuota,
      error: msg.slice(0, 500),
    });

    if (!isQuota) throw error;

    args.log("gemini_fallback_start", {
      primaryModel: args.primaryModel,
      secondaryModel: args.secondaryModel,
    });

    await run(args.secondaryModel);
  }
}

serve(async (req: Request) => {
  const requestId = crypto.randomUUID();
  const log = createLogger(requestId);

  log("request_start", { method: req.method });

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: jsonHeaders(),
    });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: jsonHeaders(),
      });
    }

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
    const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const SUPABASE_SERVICE_ROLE_KEY =
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
      throw new Error("SUPABASE_URL veya SUPABASE_ANON_KEY eksik");
    }

    if (!SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error("SUPABASE_SERVICE_ROLE_KEY missing");
    }

    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false },
    });

    const {
      data: { user },
      error: userErr,
    } = await userClient.auth.getUser();

    if (userErr || !user?.id) {
      return new Response(JSON.stringify({ error: "Invalid user" }), {
        status: 401,
        headers: jsonHeaders(),
      });
    }

    log("auth_ok", { userId: user.id });

    const body = await readJsonBody(req);
    const businessId = safeString(body.businessId, 80).trim();
    const message = safeString(body.message, 8000).trim();
    const mode = safeString(body.mode ?? "cfo", 20).trim() || "cfo";
    const incomingThreadId = body.threadId
      ? safeString(body.threadId, 80).trim()
      : undefined;

    if (!businessId) {
      return new Response(JSON.stringify({ error: "businessId required" }), {
        status: 400,
        headers: jsonHeaders(),
      });
    }

    if (message.length < 2) {
      return new Response(JSON.stringify({ error: "message required" }), {
        status: 400,
        headers: jsonHeaders(),
      });
    }

    const { data: membership, error: memErr } = await userClient
      .from("user_business_roles")
      .select("role")
      .eq("business_id", businessId)
      .eq("user_id", user.id)
      .maybeSingle();

    const typedMembership = membership as { role?: string | null } | null;

    if (memErr || !typedMembership) {
      return new Response(JSON.stringify({ error: "Forbidden" }), {
        status: 403,
        headers: jsonHeaders(),
      });
    }

    log("membership_ok", {
      businessId,
      role: typedMembership.role ?? "member",
    });

    const { data: biz, error: bizErr } = await userClient
      .from("businesses")
      .select("plan,name,currency")
      .eq("id", businessId)
      .maybeSingle();

    const typedBiz = biz as {
      plan?: string | null;
      name?: string | null;
      currency?: string | null;
    } | null;

    if (bizErr || !typedBiz) {
      return new Response(JSON.stringify({ error: "Business not found" }), {
        status: 404,
        headers: jsonHeaders(),
      });
    }

    log("business_loaded", {
      plan: typedBiz.plan ?? "unknown",
      currency: typedBiz.currency ?? "TRY",
    });

    if (typedBiz.plan === "free") {
      return new Response(JSON.stringify({ error: "Premium feature" }), {
        status: 403,
        headers: jsonHeaders(),
      });
    }

    const { threadId } = await ensureThread({
      adminClient,
      businessId,
      userId: user.id,
      threadId: incomingThreadId,
      mode,
    });

    log("thread_ready", { threadId, mode });

    const monthStart = new Date(
      new Date().getFullYear(),
      new Date().getMonth(),
      1,
    ).toISOString();

    const { data: usageRows } = await adminClient
      .from("ai_usage_logs")
      .select("total_tokens")
      .eq("business_id", businessId)
      .gte("created_at", monthStart);

    const typedUsageRows = (usageRows ?? []) as Array<{
      total_tokens?: number | null;
    }>;

    const usedThisMonth = typedUsageRows.reduce(
      (sum, row) => sum + safeNumber(row.total_tokens),
      0,
    );

    const monthlyCap = 200000;
    const estimatedPromptTokens = Math.ceil(message.length / 4);

    log("quota_check_result", {
      usedThisMonth,
      estimatedPromptTokens,
      cap: monthlyCap,
    });

    if (usedThisMonth + estimatedPromptTokens > monthlyCap) {
      return new Response(JSON.stringify({ error: "quota" }), {
        status: 403,
        headers: jsonHeaders(),
      });
    }

    const { data: history } = await adminClient
      .from("ai_chat_messages")
      .select("role,message,created_at")
      .eq("business_id", businessId)
      .eq("thread_id", threadId)
      .order("created_at", { ascending: false })
      .limit(10);

    const historyLines = ((history ?? []) as ChatMessageRow[])
      .slice()
      .reverse()
      .map((m) =>
        `${m.role === "assistant" ? "Asistan" : "Kullanıcı"}: ${
          safeString(m.message, 800)
        }`
      )
      .join("\n");

    const erpRag = await buildErpSummaryRag(userClient, businessId, message);
    const vectorSnippets = await tryVectorRag(adminClient, businessId);

    const userRole = safeString(typedMembership.role ?? "member", 40);

    const modeHint =
      mode === "risk"
        ? "Risk yönetimi, erken uyarı ve kırılganlık azaltma odaklı yanıt ver."
        : mode === "growth"
        ? "Büyüme, satış, fiyatlama ve kârlılık artırma odaklı yanıt ver."
        : mode === "ops"
        ? "Operasyonel verimlilik, süreç ve maliyet optimizasyonu odaklı yanıt ver."
        : "Finansal disiplin, nakit akışı, kârlılık ve bütçe odaklı yanıt ver.";

    const ragPack: JsonRecord = {
      erp: erpRag,
      vectors: vectorSnippets.length ? vectorSnippets : undefined,
    };

    const ragJson = clampText(JSON.stringify(ragPack), 6500);

    const systemPrompt = `
Sen SmartKOBİ ERP içinde çalışan "İşletme Asistanı" rolündesin.
Yanıt dili: Türkçe. Ton: net, kısa, uygulanabilir. 4-8 madde.

Kullanıcı rolü: ${userRole}
İşletme: ${typedBiz.name ?? "Bilinmiyor"} | Para birimi: ${typedBiz.currency ?? "TRY"}
Mod: ${mode} -> ${modeHint}

Bağlam (RAG):
${ragJson}

Son konuşmalar (thread):
${clampText(historyLines, 2500)}

Kurallar:
- Veriye dayalı konuş. Veri eksikse "varsayım" de ve 1-2 net soru sor.
- Muhasebe/hukuk/vergide kesin hüküm verme; genel öneri yaz.
- Kısa bitir. Gerekirse "Sonraki adım:" diye tek aksiyon ekle.
`.trim();

    const googleBase = Deno.env.get("GOOGLE_API_BASE_URL") ?? "";
    const googleModel = Deno.env.get("GOOGLE_MODEL") ?? "";
    const googleKey = Deno.env.get("GOOGLE_API_KEY") ?? "";

    if (!googleBase || !googleModel || !googleKey) {
      return new Response(JSON.stringify({ error: "Google env eksik" }), {
        status: 500,
        headers: jsonHeaders(),
      });
    }

    try {
      await adminClient.from("ai_chat_messages").insert({
        thread_id: threadId,
        business_id: businessId,
        user_id: user.id,
        role: "user",
        message: clampText(message, 8000),
      });
    } catch (insertError) {
      console.error("user msg insert error:", insertError);
    }

    const encoder = new TextEncoder();
    const startTime = Date.now();

    const stream = new ReadableStream<Uint8Array>({
      start: async (controller) => {
        const sse = makeSse(controller, encoder);
        let assistantFull = "";

        try {
          sse.meta({ threadId, businessId, mode, at: nowIso() });

          log("gemini_call_start", {
            model: googleModel,
            threadId,
          });

          await streamWithGeminiFallback({
            base: googleBase,
            key: googleKey,
            systemPrompt,
            message,
            temperature: 0.35,
            maxOutputTokens: 800,
            timeoutMs: 45000,
            primaryModel: googleModel,
            secondaryModel: "gemini-2.5-flash",
            log,
            onText: (delta) => {
              assistantFull += delta;
              sse.chunk(delta);
            },
          });

          assistantFull = clampText(assistantFull.trim(), 16000);

          log("gemini_call_success", {
            responseLength: assistantFull.length,
            threadId,
          });

          await adminClient.from("ai_chat_messages").insert({
            thread_id: threadId,
            business_id: businessId,
            user_id: user.id,
            role: "assistant",
            message: assistantFull || "Yanıt üretilemedi.",
          });

          const promptText = `${systemPrompt}\n${message}`;
          const promptTokens = Math.ceil(promptText.length / 4);
          const completionTokens = Math.ceil(assistantFull.length / 4);
          const totalTokens = promptTokens + completionTokens;
          const latencyMs = Date.now() - startTime;

          const { error: logErr } = await adminClient
            .from("ai_usage_logs")
            .insert({
              business_id: businessId,
              user_id: user.id,
              thread_id: threadId,
              mode,
              prompt_tokens: promptTokens,
              completion_tokens: completionTokens,
              total_tokens: totalTokens,
              latency_ms: latencyMs,
              provider: "google",
              model: googleModel,
              success: true,
            });

          if (logErr) {
            console.error("ai_usage_logs insert error:", logErr);
          }

          log("request_complete");
          sse.done({ threadId });
          controller.close();
        } catch (streamError) {
          const rawText = errorMessage(streamError);
          let userFriendly = "Yapay Zeka servisine şu anda ulaşılamıyor.";

          await adminClient.from("ai_usage_logs").insert({
            business_id: businessId,
            user_id: user.id,
            thread_id: threadId,
            mode,
            prompt_tokens: 0,
            completion_tokens: 0,
            total_tokens: 0,
            latency_ms: Date.now() - startTime,
            provider: "google",
            model: googleModel,
            success: false,
            error: rawText.slice(0, 500),
          });

          if (
            rawText.includes("RESOURCE_EXHAUSTED") ||
            rawText.toLowerCase().includes("quota")
          ) {
            userFriendly =
              "AI kullanım limitine ulaşıldı. Lütfen biraz sonra tekrar deneyin.";
          }

          log("stream_error", { error: rawText.slice(0, 500) });
          sse.error(userFriendly, { threadId });
          sse.done({ threadId });
          controller.close();
        }
      },
    });

    return new Response(stream, { headers: sseHeaders() });
  } catch (err) {
    const message = errorMessage(err);
    log("request_error", { error: message.slice(0, 500) });

    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: jsonHeaders(),
    });
  }
});
