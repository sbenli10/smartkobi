// deno-lint-ignore no-import-prefix
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// deno-lint-ignore no-import-prefix
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) throw new Error("Unauthorized");

    const { scanId } = await req.json();
    if (!scanId) throw new Error("scanId is required");

    // 1. Kaydı Çek ve Processing Yap
    const { data: scanRecord, error: scanErr } = await supabaseClient
      .from('receipt_scans').select('*').eq('id', scanId).eq('user_id', user.id).single();
    
    if (scanErr || !scanRecord) throw new Error("Scan record not found");
    await supabaseClient.from('receipt_scans').update({ scan_status: 'processing' }).eq('id', scanId);

    // 2. Dosyayı indir ve Base64 yap
    const { data: fileData, error: fileErr } = await supabaseClient.storage
      .from('business-documents').download(scanRecord.file_path);
    if (fileErr || !fileData) throw new Error("Could not download file");
    
    const arrayBuffer = await fileData.arrayBuffer();
    const base64Image = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)));

    // 3. Gemini API Çağrısı
    const apiKey = Deno.env.get('GOOGLE_API_KEY');
    const prompt = `Sen Türkçe fiş, fatura, perakende satış fişi, yakıt fişi ve toptancı faturalarından temel muhasebe bilgilerini çıkaran bir asistansın. Sadece aşağıdaki JSON formatında veri dön. Markdown blokları kullanma.
    {
      "vendorName": "Satıcı Adı veya null",
      "taxNumber": "Vergi/TC no veya null",
      "documentNumber": "Fatura/Fiş no veya null",
      "documentDate": "YYYY-MM-DD veya null",
      "totalAmount": 150.50 (sayı veya null),
      "taxAmount": 22.95 (sayı veya null),
      "netAmount": 127.55 (sayı veya null),
      "currency": "TRY",
      "suggestedCategory": "Yemek, Yakıt, Ofis, Tedarik, Kira, Personel, Pazarlama, Ulaşım, Genel Gider, Diğer seçeneklerinden biri",
      "suggestedDescription": "Kısa bir açıklama",
      "confidenceScore": 0 ile 100 arası sayı,
      "warnings": ["Tarih okunamadı" gibi uyarılar veya boş liste]
    }`;

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;
    const aiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          parts: [
            { text: prompt },
            { inline_data: { mime_type: scanRecord.file_mime_type || 'image/jpeg', data: base64Image } }
          ]
        }]
      })
    });

    const aiData = await aiResponse.json();
    
    // TİP HATASI BURADA DÜZELTİLDİ: Açıkça Record<string, any> olarak tanımlandı
    let resultJson: Record<string, any> = {};
    let rawText = '';
    
    try {
      rawText = aiData.candidates[0].content.parts[0].text;
      const cleanJson = rawText.replace(/```json/g, '').replace(/```/g, '').trim();
      resultJson = JSON.parse(cleanJson);
    } catch (_e) { // LINT HATASI BURADA DÜZELTİLDİ: e yerine _e kullanıldı
      resultJson = { warnings: ["Belge otomatik okunamadı. Lütfen alanları elle kontrol edin."], confidenceScore: 10 };
    }

    // 4. Veritabanını Güncelle
    await supabaseClient.from('receipt_scans').update({
      scan_status: 'completed',
      extracted_vendor_name: resultJson.vendorName || null,
      extracted_document_date: resultJson.documentDate || null,
      extracted_total_amount: resultJson.totalAmount || null,
      extracted_tax_amount: resultJson.taxAmount || null,
      extracted_net_amount: resultJson.netAmount || null,
      suggested_category: resultJson.suggestedCategory || 'Genel Gider',
      confidence_score: resultJson.confidenceScore || 0,
      ai_result: resultJson,
      raw_ocr_text: rawText
    }).eq('id', scanId);

    return new Response(JSON.stringify(resultJson), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  } catch (error) {
    // UNKNOWN ERROR HATASI BURADA DÜZELTİLDİ
    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: errorMessage }), { status: 400, headers: corsHeaders });
  }
});