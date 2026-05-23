import { serve } from "std/http/server.ts";
import { createClient } from "@supabase/supabase-js";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type ScopeDecision = "inScope" | "outOfScope" | "ambiguous";
type ScopeTopic =
  | "general"
  | "finance"
  | "cashflow"
  | "customers"
  | "inventory"
  | "support";

type ScopeResult = {
  decision: ScopeDecision;
  topic: ScopeTopic;
  reason: string;
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  console.log("[ai-business-advisor] jsonResponse hazirlaniyor", {
    status,
    bodyKeys: Object.keys(body),
  });

  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=utf-8",
    },
  });
}

function normalizeQuestion(question: string) {
  return question
    .toLowerCase()
    .trim()
    .replaceAll("ç", "c")
    .replaceAll("ğ", "g")
    .replaceAll("ı", "i")
    .replaceAll("ö", "o")
    .replaceAll("ş", "s")
    .replaceAll("ü", "u")
    .replace(/[^\w\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function containsAny(normalized: string, values: string[]) {
  return values.some((value) => normalized.includes(value));
}

function classifyQuestionScope(question: string): ScopeResult {
  const normalized = normalizeQuestion(question);

  const strongCustomer = [
    "kimden tahsilat yapmaliyim",
    "hangi musteriden tahsilat istemeliyim",
    "tahsilat onceligim kim olmali",
    "geciken tahsilatlarim var mi",
    "kim bana borclu",
    "cari risklerim neler",
    "hangi musteri riskli",
    "tahsilat",
    "alacak",
    "borc",
    "cari",
    "musteri",
    "geciken odeme",
    "geciken tahsilat",
    "borclu",
    "odeme hatirlatma",
  ];

  const strongCashflow = [
    "nakit",
    "nakit akisi",
    "odeme yapabilir miyim",
    "beni zorlar mi",
    "harcama",
    "makine",
    "ekipman",
    "yatirim",
    "kredi",
    "finansman",
  ];

  const strongInventory = [
    "stok",
    "urun",
    "kritik stok",
    "tedarik",
    "barkod",
    "siparis",
  ];

  const strongSupport = [
    "kosgeb",
    "destek",
    "tesvik",
    "tubitak",
    "eximbank",
    "hibe",
    "nace",
    "belge",
    "kapasite raporu",
    "ihracat",
  ];

  const strongFinance = [
    "gelir",
    "gider",
    "kar",
    "zarar",
    "ciro",
    "maliyet",
    "fiyat",
    "zam",
    "iskonto",
    "vergi",
    "rapor",
    "isletme",
    "kobi",
  ];

  const strongBusinessKeywords = [
    ...strongCustomer,
    ...strongCashflow,
    ...strongInventory,
    ...strongSupport,
    ...strongFinance,
    "satis",
    "fatura",
    "b2b",
  ];

  if (containsAny(normalized, strongCustomer)) {
    return {
      decision: "inScope",
      topic: "customers",
      reason: "Cari, musteri veya tahsilat sorusu.",
    };
  }

  if (containsAny(normalized, strongCashflow)) {
    return {
      decision: "inScope",
      topic: "cashflow",
      reason: "Nakit akisi, harcama veya yatirim karari sorusu.",
    };
  }

  if (containsAny(normalized, strongInventory)) {
    return {
      decision: "inScope",
      topic: "inventory",
      reason: "Stok, urun veya tedarik sorusu.",
    };
  }

  if (containsAny(normalized, strongSupport)) {
    return {
      decision: "inScope",
      topic: "support",
      reason: "Destek, tesvik veya basvuru hazirligi sorusu.",
    };
  }

  if (containsAny(normalized, strongFinance)) {
    return {
      decision: "inScope",
      topic: "finance",
      reason: "Finans, gelir-gider, maliyet veya karlilik sorusu.",
    };
  }

  if (containsAny(normalized, strongBusinessKeywords)) {
    return {
      decision: "inScope",
      topic: detectScopeTopic(normalized),
      reason: "Guclu isletme anahtar kelimeleri bulundu.",
    };
  }

  const outOfScopeTerms = [
    "sevgili",
    "iliski",
    "flort",
    "arkadas",
    "aile",
    "yemek",
    "tarif",
    "tatil",
    "film",
    "dizi",
    "mac",
    "futbol",
    "magazin",
    "siyasi",
    "parti",
    "hastalik",
    "ilac",
    "tedavi",
    "saglik",
    "siir",
    "hikaye",
    "oyun",
    "odev",
  ];

  if (containsAny(normalized, outOfScopeTerms)) {
    return {
      decision: "outOfScope",
      topic: "general",
      reason: "Soru isletme yonetimi disi bir alana ait.",
    };
  }

  const ambiguousTerms = ["telefon", "araba", "bilgisayar", "laptop", "eleman"];

  if (containsAny(normalized, ambiguousTerms)) {
    return {
      decision: "ambiguous",
      topic: "general",
      reason: "Soru isletme baglami olmadan yorumlanabilir.",
    };
  }

  return {
    decision: "outOfScope",
    topic: "general",
    reason: "Soru SmartKOBI kapsamindaki modullere baglanmiyor.",
  };
}

function detectScopeTopic(normalized: string): ScopeTopic {
  if (
    containsAny(normalized, [
      "tahsilat",
      "alacak",
      "cari",
      "musteri",
      "geciken odeme",
      "borclu",
    ])
  ) {
    return "customers";
  }
  if (
    containsAny(normalized, [
      "nakit",
      "nakit akisi",
      "harcama",
      "makine",
      "ekipman",
      "yatirim",
      "kredi",
    ])
  ) {
    return "cashflow";
  }
  if (containsAny(normalized, ["stok", "urun", "kritik stok", "tedarik", "siparis"])) {
    return "inventory";
  }
  if (
    containsAny(normalized, [
      "kosgeb",
      "destek",
      "tesvik",
      "tubitak",
      "eximbank",
      "hibe",
      "nace",
      "belge",
      "kapasite raporu",
    ])
  ) {
    return "support";
  }
  return "finance";
}

function sanitizeModule(value: unknown) {
  const module = (value ?? "").toString().toLowerCase();
  if (
    ["finance", "cashflow", "customers", "inventory", "support", "general"]
      .includes(module)
  ) {
    return module;
  }
  return "general";
}

function localizeTechnicalTerms(text: string): string {
  const replacements: Array<[RegExp, string]> = [
    [/"?pending_receivables"?|'?pending_receivables'?/gi, "bekleyen tahsilatlar"],
    [/"?overdue_receivables"?|'?overdue_receivables'?/gi, "vadesi gecmis tahsilatlar"],
    [/"?net_cash_30d"?|'?net_cash_30d'?/gi, "30 gunluk net nakit durumu"],
    [/"?cash_score"?|'?cash_score'?/gi, "nakit skoru"],
    [/"?critical_stock_count"?|'?critical_stock_count'?/gi, "kritik stoktaki urun sayisi"],
    [/"?out_of_stock_count"?|'?out_of_stock_count'?/gi, "stokta olmayan urun sayisi"],
    [/"?low_margin_product_count"?|'?low_margin_product_count'?/gi, "dusuk kar marjli urun sayisi"],
    [/"?monthly_income"?|'?monthly_income'?/gi, "aylik gelir"],
    [/"?monthly_expense"?|'?monthly_expense'?/gi, "aylik gider"],
    [/"?net_profit"?|'?net_profit'?/gi, "net kar/zarar"],
    [/"?customer_risk_count"?|'?customer_risk_count'?/gi, "riskli musteri sayisi"],
    [/"?expected_cash_inflow_30d"?|'?expected_cash_inflow_30d'?/gi, "30 gunluk beklenen tahsilat"],
    [/"?expected_cash_outflow_30d"?|'?expected_cash_outflow_30d'?/gi, "30 gunluk beklenen odeme"],
    [/"?business_context"?|'?business_context'?/gi, "isletme ozeti"],
    [/"?context"?|'?context'?/gi, "isletme ozeti"],
    [/"?snapshot"?|'?snapshot'?/gi, "ozet kayit"],
    [/"?field"?|'?field'?/gi, "alan"],
    [/"?fallback"?|'?fallback'?/gi, "on analiz"],
  ];

  let localized = text;
  for (const [pattern, replacement] of replacements) {
    localized = localized.replaceAll(pattern, replacement);
  }

  return localized
    .replaceAll(/\s+/g, " ")
    .replaceAll(/\s+([,.:;])/g, "$1")
    .trim();
}

function sanitizeGeminiText(rawText: string): string {
  const cleaned = rawText
    .trim()
    .replace(/```json/gi, "")
    .replace(/```text/gi, "")
    .replace(/```/g, "")
    .trim();

  const answerMatch = cleaned.match(/"answer"\s*:\s*"([^"]*)/i);
  if (answerMatch && answerMatch[1]?.trim().length) {
    return answerMatch[1].trim();
  }

  const looksBrokenJson =
    cleaned.startsWith("{") &&
    cleaned.includes('"answer"') &&
    !cleaned.includes('"}') &&
    !cleaned.includes('",');

  if (looksBrokenJson) {
    return "";
  }

  if (cleaned.length < 12) {
    return "";
  }

  return cleaned;
}

function buildDeterministicFallbackAnswer(
  topic: string,
  _question: string,
  _context: Record<string, unknown>,
): string {
  switch (sanitizeModule(topic)) {
    case "customers":
      return "Tahsilat önceliği için önce vadesi geçmiş ve bakiyesi yüksek müşterileri kontrol edin. Geciken tahsilatlar nakit akışınızı doğrudan etkiler. Cari ekranında riskli müşterileri filtreleyip ödeme hatırlatması göndermeniz önerilir.";
    case "cashflow":
      return "Nakit kararını vermeden önce 30 günlük beklenen tahsilat ve ödeme dengesini kontrol edin. Nakit skoru düşükse yeni harcamayı ertelemek veya tahsilatları öne çekmek daha güvenli olabilir.";
    case "inventory":
      return "Stok kararında kritik stok seviyesine yaklaşan ve kâr marjı düşük ürünleri önceliklendirin. Tedarik planını satış hızı ve minimum stok seviyesine göre güncellemeniz önerilir.";
    case "finance":
      return "Finansal karar için gelir, gider ve net kâr dengesini birlikte değerlendirin. Gider oranı yükseliyorsa yeni harcamadan önce maliyet kalemlerini gözden geçirmeniz önerilir.";
    case "support":
      return "Destek uygunluğu için sektör, NACE kodu, çalışan sayısı, ciro, yatırım ihtiyacı ve belge durumunun tamamlanması gerekir. Destek Analizi ekranından ön uygunluk kontrolü yapabilirsiniz.";
    default:
      return "Bu konuda işletme verilerinize göre ön değerlendirme yapabilirim. Finans, cari, stok veya nakit akışı bilgilerinizi güncellediğinizde öneriler daha net hale gelir.";
  }
}

function asNumber(value: unknown) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

function inferRiskLevelFromContextAndTopic(
  context: Record<string, unknown>,
  topic: string,
  _question: string,
) {
  const module = sanitizeModule(topic);
  const overdueReceivables = asNumber(context.overdue_receivables ?? context.overdueReceivables);
  const customerRiskCount = asNumber(context.customer_risk_count ?? context.customerRiskCount);
  const cashScore = asNumber(context.cash_score ?? context.cashScore);
  const netCash30d = asNumber(context.net_cash_30d ?? context.netCash30d);
  const criticalStockCount =
    asNumber(context.critical_stock_count ?? context.criticalStockCount);
  const outOfStockCount = asNumber(context.out_of_stock_count ?? context.outOfStockCount);

  switch (module) {
    case "customers":
      if (overdueReceivables > 0 || customerRiskCount > 0) {
        return overdueReceivables > 0 && customerRiskCount > 0 ? "high" : "medium";
      }
      return "medium";
    case "cashflow":
      if (cashScore < 40 || netCash30d < 0) {
        return cashScore < 25 ? "critical" : "high";
      }
      return cashScore < 70 ? "medium" : "low";
    case "inventory":
      if (outOfStockCount > 0) {
        return "high";
      }
      if (criticalStockCount > 0) {
        return "medium";
      }
      return "low";
    default:
      return "medium";
  }
}

function buildSuggestedActions(
  topic: string,
  _context: Record<string, unknown>,
  _question: string,
) {
  switch (sanitizeModule(topic)) {
    case "customers":
      return [
        "Cari ekranında geciken tahsilatları kontrol edin.",
        "Bakiyesi yüksek müşterilere ödeme hatırlatması gönderin.",
        "Tahsilat tarihlerini güncelleyin.",
      ];
    case "cashflow":
      return [
        "Nakit AI ekranında 30 günlük tahmini kontrol edin.",
        "Yeni harcama öncesi beklenen tahsilatları netleştirin.",
        "Geciken tahsilatları önceliklendirin.",
      ];
    case "inventory":
      return [
        "Kritik stoktaki ürünleri kontrol edin.",
        "Minimum stok seviyelerini güncelleyin.",
        "Düşük kâr marjlı ürünlerde fiyatı gözden geçirin.",
      ];
    case "finance":
      return [
        "Gelir-gider kayıtlarını güncelleyin.",
        "En yüksek gider kategorilerini inceleyin.",
        "Net kâr ve gider/gelir oranını takip edin.",
      ];
    case "support":
      return [
        "Destek Analizi ekranında işletme bilgilerini tamamlayın.",
        "NACE kodu, çalışan sayısı ve ciro bilgisini girin.",
        "Eksik belgeleri Belgeler ekranından kontrol edin.",
      ];
    default:
      return [
        "Finans, cari, stok ve nakit verilerinizi güncel tutun.",
        "Danışman önerilerini ilgili modüllerde doğrulayın.",
      ];
  }
}

function buildOutOfScopeJson() {
  return {
    answer:
      "Ben SmartKOBİ Danışmanıyım. Finans, nakit akışı, cari, stok, destekler, satış, maliyet ve işletme kararları konusunda yardımcı olabilirim. Bu konu SmartKOBİ kapsamı dışında kalıyor. İsterseniz işletmenizle ilgili bir soru sorabilirsiniz.",
    riskLevel: "low",
    suggestedActions: [
      "Nakit akışım riskli mi?",
      "Bu ay yeni harcama yapabilir miyim?",
      "Hangi müşteriden tahsilat yapmalıyım?",
      "Hangi ürünler kritik stokta?",
    ],
    relatedModule: "general",
  };
}

function buildAmbiguousJson() {
  return {
    answer:
      "Bu soruyu işletmenizle ilgili olarak mı değerlendirmemi istersiniz? Eğer maliyet, satış, nakit akışı veya yatırım açısından soruyorsanız detay vererek tekrar yazabilirsiniz.",
    riskLevel: "low",
    suggestedActions: [
      "İşletme için bu harcamayı yapabilir miyim?",
      "Bu alım nakit akışımı zorlar mı?",
      "Satış ve maliyet açısından değerlendirir misin?",
    ],
    relatedModule: "general",
  };
}

serve(async (req) => {
  console.log("[ai-business-advisor] request geldi", {
    method: req.method,
    url: req.url,
  });

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    console.log("[ai-business-advisor] Authorization header kontrol edildi", {
      hasAuthHeader: Boolean(authHeader),
    });

    if (!authHeader) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: authHeader },
        },
      },
    );

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    console.log("[ai-business-advisor] Kullanici dogrulama tamamlandi", {
      hasUser: Boolean(user),
      userId: user?.id,
      hasUserError: Boolean(userError),
      userErrorMessage: userError?.message,
    });

    if (userError || !user) {
      return jsonResponse({ error: "Invalid user" }, 401);
    }

    const body = await req.json().catch(() => ({}));
    const question = body?.question?.toString().trim() ?? "";
    const topic = body?.topic?.toString().trim() || "general";
    const context = typeof body?.context === "object" && body.context !== null
      ? body.context as Record<string, unknown>
      : {};
    const conversationHistory = Array.isArray(body?.conversationHistory)
      ? body.conversationHistory.slice(-8)
      : [];

    console.log("[ai-business-advisor] Body alanlari hazirlandi", {
      questionLength: question.length,
      topic,
      contextKeys: Object.keys(context ?? {}),
      conversationHistoryLength: conversationHistory.length,
    });

    if (!question) {
      return jsonResponse({ error: "question zorunlu" }, 400);
    }

    const scope = classifyQuestionScope(question);
    console.log("[ai-business-advisor] Scope guard sonucu", {
      decision: scope.decision,
      topic: scope.topic,
      reason: scope.reason,
    });

    if (scope.decision === "outOfScope") {
      return jsonResponse(buildOutOfScopeJson());
    }

    if (scope.decision === "ambiguous") {
      return jsonResponse(buildAmbiguousJson());
    }

    const googleApiKey = Deno.env.get("GOOGLE_API_KEY");
    if (!googleApiKey) {
      return jsonResponse(
        { error: "AI yapılandırması eksik. GOOGLE_API_KEY bulunamadı." },
        500,
      );
    }

    const googleModel = Deno.env.get("GOOGLE_MODEL") || "gemini-2.5-flash";
    const googleBaseUrl =
      Deno.env.get("GOOGLE_API_BASE_URL") ||
      "https://generativelanguage.googleapis.com/v1beta";
    const _serviceAccountBase64 = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON_BASE64");

    const _legacySystemPrompt = `
Sen SmartKOBİ'nin KOBİ işletme danışmanısın.
Sadece işletme, finans, nakit akışı, cari, stok, destek, satış, maliyet, fiyatlandırma ve büyüme kararları hakkında cevap ver.
Cevap kısa, Türkçe, net ve aksiyon odaklı olsun.
Kesin finansal, hukuki veya vergi kararı verme; ön analiz sun.
Cevabı düz metin olarak ver.
Markdown tablo kullanma.
Gereksiz uzun giriş yapma.
Maksimum 5 kısa satır veya 1 kısa paragraf artı 2-3 aksiyon önerisi seviyesinde kal.
Sen genel sohbet botu değilsin.
`.trim();

    const systemPrompt = `
Sen SmartKOBI'nin KOBI isletme danismanisin.
Sadece isletme, finans, nakit akisi, cari, stok, destek, satis, maliyet, fiyatlandirma ve buyume kararlari hakkinda cevap ver.
Cevap kisa, Turkce, net ve aksiyon odakli olsun.
Kesin finansal, hukuki veya vergi karari verme; on analiz sun.
Cevabi duz metin olarak ver.
Markdown tablo kullanma.
Gereksiz uzun giris yapma.
Maksimum 5 kisa satir veya 1 kisa paragraf arti 2-3 aksiyon onerisi seviyesinde kal.
Sen genel sohbet botu degilsin.
Kullaniciya teknik JSON alan adlarini, veritabani kolon isimlerini veya Ingilizce field name ifadelerini asla gosterme.
Ornegin pending_receivables, overdue_receivables, cash_score, net_cash_30d gibi alan adlarini cevapta yazma.
Bunlari Turkce ve dogal dille acikla: bekleyen tahsilatlar, vadesi gecmis tahsilatlar, nakit skoru, 30 gunluk net nakit durumu gibi.
Cevap tamamen Turkce olmali. Gerekmedikce Ingilizce kelime kullanma.
JSON key isimleri sadece API response icinde kalabilir; kullaniciya gosterilen metinde field, context, snapshot, pending_receivables, overdue_receivables gibi ifadeler yer almamali.
`.trim();

    const prompt = `
Rol:
${systemPrompt}

Konu:
${scope.topic}

İşletme Özet Context:
${JSON.stringify(context)}

Son Görüşme Mesajları:
${JSON.stringify(conversationHistory)}

Kullanıcı Sorusu:
${question}

Örnek cevap formatı:
Durum: ...
Risk: ...
Neden: ...
Önerilen aksiyon: ...
Sonraki adım: ...
`.trim();

    const aiResponse = await fetch(
      `${googleBaseUrl}/models/${googleModel}:generateContent?key=${googleApiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.2,
            maxOutputTokens: 900,
          },
        }),
      },
    );

    console.log("[ai-business-advisor] Gemini status", {
      ok: aiResponse.ok,
      status: aiResponse.status,
      statusText: aiResponse.statusText,
    });

    let rawText = "";
    if (aiResponse.ok) {
      const data = await aiResponse.json();
      rawText = data?.candidates?.[0]?.content?.parts?.[0]?.text?.toString() ?? "";
    } else {
      const errorText = await aiResponse.text();
      console.log("[ai-business-advisor] Gemini hata detayi", {
        errorTextPreview: errorText.slice(0, 300),
      });
    }

    console.log("[ai-business-advisor] rawText durumu", {
      rawTextLength: rawText.length,
      rawTextPreview: rawText.slice(0, 300),
    });

    const sanitizedAnswer = sanitizeGeminiText(rawText);
    console.log("[ai-business-advisor] sanitize sonucu", {
      sanitizedLength: sanitizedAnswer.length,
      sanitizedPreview: sanitizedAnswer.slice(0, 300),
    });

    const advisorAnswer = sanitizedAnswer.length > 0
      ? sanitizedAnswer
      : buildDeterministicFallbackAnswer(scope.topic, question, context);

    const responseBody = {
      answer: advisorAnswer,
      riskLevel: inferRiskLevelFromContextAndTopic(context, scope.topic, question),
      suggestedActions: buildSuggestedActions(scope.topic, context, question),
      relatedModule: sanitizeModule(scope.topic),
    };

    console.log("[ai-business-advisor] response envelope hazir", {
      relatedModule: responseBody.relatedModule,
      riskLevel: responseBody.riskLevel,
      answerLength: responseBody.answer.length,
      suggestedActionsCount: responseBody.suggestedActions.length,
    });

    return jsonResponse(responseBody);
  } catch (error) {
    console.error("[ai-business-advisor] Beklenmeyen hata yakalandi", {
      errorName: error instanceof Error ? error.name : "UnknownError",
      errorMessage: error instanceof Error ? error.message : String(error),
    });

    return jsonResponse(
      {
        error: "AI yaniti uretilemedi.",
        details: error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }
});
