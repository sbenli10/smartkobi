// TODO: Bu Edge Function sonraki sürümde günlük otomatik hatırlatma üretimi için kullanılacak.
// Not:
// - Gerçek üretim mantığı şu anda Flutter tarafında NotificationsRepository üzerinden manuel çalışıyor.
// - Cron ile günlük 09:00 çalıştırıldığında duplicate önleme için metadata.rule_key ve metadata.generated_date kullanılmalı.
// - Service context veya güvenli backend doğrulaması olmadan toplu kullanıcı taraması yapılmamalı.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(() => {
  return new Response(
    JSON.stringify({
      ok: false,
      message:
        "Akıllı hatırlatma Edge Function altyapısı henüz etkin değil. İlk sürümde hatırlatmalar uygulama içinden üretilir.",
    }),
    {
      status: 501,
      headers: { "Content-Type": "application/json" },
    },
  );
});
