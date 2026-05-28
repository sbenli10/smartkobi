// deno-lint-ignore no-import-prefix
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

type TransactionType = "income" | "expense" | "";
type OperationType = "income" | "expense" | "product_sale" | "product_purchase";

interface ParsedDraft {
  operation: OperationType;
  transactionType: TransactionType;
  amount: number;
  contact: string;
  category: string;
  title: string;
  productName: string;
  quantity: number | null;
  unit: string;
  unitPrice: number | null;
  totalAmount: number | null;
  stockDelta: number;
  needsProductMatch: boolean;
  needsConfirmation: boolean;
  confidence: number;
  rawText: string;
}

serve(async (req) => {
  const requestId = crypto.randomUUID();
  console.log(`[process-voice-command][${requestId}] request started`, {
    method: req.method,
    origin: req.headers.get("origin"),
  });

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Sadece POST istegi desteklenir." }, 400);
  }

  try {
    const body = await req.json();
    const text = body?.text?.toString().trim();
    console.log(`[process-voice-command][${requestId}] request body`, body);

    if (!text) {
      return jsonResponse({ error: "Metin bos olamaz." }, 400);
    }

    const parsed = parseVoiceCommand(text);
    console.log(`[process-voice-command][${requestId}] success`, parsed);
    return jsonResponse(parsed, 200);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Sesli komut islenemedi.";
    console.error(`[process-voice-command][${requestId}] failure`, {
      message,
      stack: error instanceof Error ? error.stack : undefined,
    });
    return jsonResponse({ error: message }, 400);
  }
});

function jsonResponse(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

function parseVoiceCommand(text: string): ParsedDraft {
  const normalized = normalizeText(text);
  console.log("[process-voice-command] normalized", { text, normalized });

  const quantity = extractQuantity(text);
  const amount = extractMoneyAmount(text);
  const unit = quantity?.unit ?? "adet";
  const productName = extractProductName(text, normalized, quantity?.rawSegment ?? null);

  const isProductSale = includesAny(normalized, [
    "sattim",
    "satildi",
    "satış yaptim",
    "satış yaptım",
  ]) && productName.length > 0;

  const isProductPurchase = includesAny(normalized, [
    "aldim",
    "aldım",
    "stoğa ekle",
    "stoga ekle",
    "depoya girdi",
    "stok eklendi",
  ]) && productName.length > 0;

  if (isProductSale || isProductPurchase) {
    return buildProductDraft({
      text,
      normalized,
      amount,
      quantity: quantity?.value ?? null,
      unit,
      productName,
      isSale: isProductSale,
    });
  }

  return buildFinanceDraft(text, normalized, amount);
}

function buildProductDraft(params: {
  text: string;
  normalized: string;
  amount: number | null;
  quantity: number | null;
  unit: string;
  productName: string;
  isSale: boolean;
}): ParsedDraft {
  const { text, normalized, amount, quantity, unit, productName, isSale } = params;
  const operation: OperationType = isSale ? "product_sale" : "product_purchase";
  const transactionType: TransactionType = isSale
    ? "income"
    : amount != null && amount > 0
    ? "expense"
    : "";
  const stockDelta = quantity == null ? 0 : isSale ? -quantity : quantity;
  const totalAmount = amount;
  const unitPrice = quantity != null && quantity > 0 && amount != null ? amount / quantity : null;
  const category = isSale ? "Satis" : "Stok";
  const title = isSale ? `${productName} satisi` : `${productName} alimi`;
  const contact = extractContact(text, normalized, category, transactionType || "expense");

  return {
    operation,
    transactionType,
    amount: amount ?? 0,
    contact,
    category,
    title,
    productName,
    quantity,
    unit,
    unitPrice,
    totalAmount,
    stockDelta,
    needsProductMatch: true,
    needsConfirmation: true,
    confidence: amount != null || quantity != null ? 0.9 : 0.7,
    rawText: text,
  };
}

function buildFinanceDraft(
  text: string,
  normalized: string,
  amount: number | null,
): ParsedDraft {
  if (amount == null) {
    throw new Error("Tutari bulamadim. Lutfen tutari tekrar soyleyin.");
  }

  const type = detectFinanceType(normalized);
  const category = detectFinanceCategory(normalized, type);
  const contact = extractContact(text, normalized, category, type);
  const title = buildFinanceTitle(type, category, contact, normalized);

  return {
    operation: type === "income" ? "income" : "expense",
    transactionType: type,
    amount,
    contact,
    category,
    title,
    productName: "",
    quantity: null,
    unit: "adet",
    unitPrice: null,
    totalAmount: amount,
    stockDelta: 0,
    needsProductMatch: false,
    needsConfirmation: true,
    confidence: 0.88,
    rawText: text,
  };
}

function normalizeText(text: string): string {
  return text
    .toLocaleLowerCase("tr-TR")
    .replace(/[’']/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function extractMoneyAmount(text: string): number | null {
  const match = text.match(
    /(?:₺\s*)?(\d{1,3}(?:[.,]\d{3})+|\d+(?:[.,]\d+)?)(?:\s*(?:tl|türk lirası|lira)(?:lık|lik|luk|lük)?)?/iu,
  );
  if (!match) {
    return null;
  }
  return normalizeAmountToken(match[1]);
}

function extractQuantity(text: string): { value: number; unit: string; rawSegment: string } | null {
  const match = text.match(
    /(\d+(?:[.,]\d+)?)\s*(adet|paket|koli|kg|kilo|gram|su|süt|kutu|şişe|sise)/iu,
  );
  if (!match) {
    return null;
  }

  const value = normalizeAmountToken(match[1]);
  if (value == null) {
    return null;
  }

  return {
    value,
    unit: normalizeUnit(match[2]),
    rawSegment: match[0],
  };
}

function normalizeUnit(value: string): string {
  const normalized = normalizeText(value);
  if (normalized === "kilo") return "kg";
  if (normalized === "sise") return "sise";
  return normalized;
}

function extractProductName(text: string, normalized: string, quantitySegment: string | null): string {
  const cleaned = text
    .replace(/(?:₺\s*)?\d{1,3}(?:[.,]\d{3})+|\d+(?:[.,]\d+)?\s*(?:tl|türk lirası|lira)(?:lık|lik|luk|lük)?/giu, " ")
    .replace(/\b(bugün|depodan|stoğa|stoga|depoya|kasadan|bakkaldan)\b/giu, " ")
    .replace(/\b(sattım|sattim|satıldı|satildi|aldım|aldim|ekle|girdi)\b/giu, " ")
    .replace(/\s+/g, " ")
    .trim();

  let value = cleaned;
  if (quantitySegment != null && value.toLocaleLowerCase("tr-TR").startsWith(quantitySegment.toLocaleLowerCase("tr-TR"))) {
    value = value.substring(quantitySegment.length).trim();
  }

  value = value
      .replace(/\b(adet|paket|koli|kg|kilo|gram|kutu|şişe|sise)\b/giu, " ")
      .replace(/\s+/g, " ")
      .trim();

  if (value.length === 0 && normalized.includes("market")) {
    return "Market urunu";
  }

  return titleCase(value);
}

function titleCase(value: string): string {
  return value
    .split(" ")
    .filter((part) => part.trim().length > 0)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
    .join(" ");
}

function detectFinanceType(normalized: string): "income" | "expense" {
  const incomeSignals = ["girdi", "gelir", "satış", "satis", "tahsilat", "aldım", "aldim", "para geldi"];
  const expenseSignals = ["çıktı", "cikti", "gider", "ödeme", "odeme", "harcama", "kasadan", "düş", "dus"];
  const hasIncomeSignal = includesAny(normalized, incomeSignals);
  const hasExpenseSignal = includesAny(normalized, expenseSignals);
  if (hasIncomeSignal && !hasExpenseSignal) {
    return "income";
  }
  return "expense";
}

function detectFinanceCategory(normalized: string, type: "income" | "expense"): string {
  if (includesAny(normalized, ["borç yaz", "borc yaz", "yazıver", "yaziver", "kitle", "hesaba yaz", "cari"])) {
    return "Cari";
  }
  if (normalized.includes("yemek")) return "Yemek";
  if (normalized.includes("market")) return "Market";
  if (normalized.includes("kira")) return "Kira";
  if (normalized.includes("fatura")) return "Fatura";
  if (includesAny(normalized, ["satış", "satis"])) return "Satis";
  if (normalized.includes("tahsilat")) return "Tahsilat";
  if (normalized.includes("kasadan")) return "Kasa";
  return type === "income" ? "Gelir" : "Genel Gider";
}

function extractContact(
  original: string,
  normalized: string,
  category: string,
  type: "income" | "expense",
): string {
  if (normalized.includes("kasadan")) {
    return "Kasa";
  }

  const directionalMatch = original.match(
    /([A-ZÇĞİÖŞÜa-zçğıöşü0-9\s.]+?)(?:['’`]?ya|['’`]?ye|['’`]?dan|['’`]?den)\s+(?:\d{1,3}(?:[.,]\d{3})+|\d+(?:[.,]\d+)?)/u,
  );
  if (directionalMatch) {
    const value = cleanContact(directionalMatch[1]);
    if (value) {
      return value;
    }
  }

  const amountIndex = normalized.search(/\d/);
  if (amountIndex > 0) {
    const beforeAmount = cleanContact(original.slice(0, amountIndex));
    if (beforeAmount && !beforeAmount.toLocaleLowerCase("tr-TR").includes("bugün")) {
      return beforeAmount;
    }
  }

  if (category === "Cari") {
    return "Cari Hesap";
  }

  return type === "income" ? "" : "";
}

function cleanContact(value: string): string {
  return value
    .replace(/\b(bugün|yarın|dün|kasadan|depodan|depoya|bakkaldan)\b/giu, " ")
    .replace(/\b(sattım|sattim|satıldı|satildi|aldım|aldim|stoğa|stoga|ekle|girdi)\b/giu, " ")
    .replace(/\s+/g, " ")
    .trim()
    .replace(/[.,;:!?]+$/g, "");
}

function buildFinanceTitle(
  type: TransactionType,
  category: string,
  contact: string,
  normalized: string,
): string {
  if (category === "Cari" && contact.trim().length > 0) {
    return `${contact} borc kaydi`;
  }
  if (type === "income" && normalized.includes("tahsilat")) {
    return contact.length === 0 ? "Tahsilat alindi" : `${contact} tahsilati`;
  }
  if (type === "income" && includesAny(normalized, ["satış", "satis"])) {
    return "Satis geliri";
  }
  if (contact === "Kasa") {
    return category === "Kasa" ? "Kasadan cikis" : `${category} gideri`;
  }
  if (type === "expense" && category !== "Genel Gider") {
    return `${category} gideri`;
  }
  return type === "income" ? "Gelir kaydi" : "Gider kaydi";
}

function normalizeAmountToken(value: string): number | null {
  const trimmed = value.trim();
  const hasDot = trimmed.includes(".");
  const hasComma = trimmed.includes(",");

  let normalized = trimmed;
  if (hasDot && hasComma) {
    normalized = trimmed.replace(/\./g, "").replace(",", ".");
  } else if (hasComma) {
    const parts = trimmed.split(",");
    normalized = parts[1]?.length === 3 ? trimmed.replace(/,/g, "") : trimmed.replace(",", ".");
  } else if (hasDot) {
    const parts = trimmed.split(".");
    normalized = parts[1]?.length === 3 ? trimmed.replace(/\./g, "") : trimmed;
  }

  const parsed = Number.parseFloat(normalized);
  return Number.isFinite(parsed) ? parsed : null;
}

function includesAny(text: string, values: string[]): boolean {
  return values.some((value) => text.includes(value));
}
