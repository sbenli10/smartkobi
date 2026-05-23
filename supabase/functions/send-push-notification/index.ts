// TODO: Bu Edge Function, Firebase Cloud Messaging kurulumu tamamlandığında device_tokens tablosundaki aktif cihazlara bildirim gönderecek.
// Beklenen env değişkenleri:
// - FIREBASE_PROJECT_ID
// - FIREBASE_CLIENT_EMAIL
// - FIREBASE_PRIVATE_KEY
// Bu gizli bilgiler Flutter içine eklenmemeli; yalnızca Supabase ortam değişkenlerinde tutulmalı.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(() => {
  return new Response(
    JSON.stringify({
      ok: false,
      message:
        "Push notification altyapısı henüz etkin değil. Firebase Cloud Messaging kurulumu tamamlandığında bu fonksiyon kullanılacak.",
    }),
    {
      status: 501,
      headers: { "Content-Type": "application/json" },
    },
  );
});
