// supabase/functions/send-reset-email/index.ts
// deno-lint-ignore-file

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Resend } from "npm:resend";

serve(async (req) => {
  try {
    const { email } = await req.json();

    if (!email || typeof email !== "string") {
      return new Response(
        JSON.stringify({ success: true }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // 🔹 Reset link üret
    // 🔐 Reset link üret
    const { data } = await supabase.auth.admin.generateLink({
      type: "recovery",
      email,
      options: {
        redirectTo: "https://smartkobi.app/reset-password",
      },
    });

    const resetLink = data?.properties?.action_link;
    // 🔹 Resend ile mail gönder
    const resend = new Resend(Deno.env.get("RESEND_API_KEY"));
    if (resetLink) {
    await resend.emails.send({
    from: "SmartKOBİ <noreply@denetron.me>",
    to: email,
    subject: "SmartKOBİ | Şifre Sıfırlama Talebi",
    html: `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Şifre Sıfırlama</title>
    </head>
    <body style="margin:0;padding:0;background-color:#f4f6fb;font-family:Arial,Helvetica,sans-serif;">
      
      <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 0;">
        <tr>
          <td align="center">
            
            <table width="600" cellpadding="0" cellspacing="0" 
              style="background:#ffffff;border-radius:12px;padding:40px;box-shadow:0 10px 30px rgba(0,0,0,0.08);">
              
              <!-- Logo / Header -->
              <tr>
                <td align="center" style="padding-bottom:25px;">
                  <h1 style="margin:0;color:#1E3A8A;font-size:24px;">
                    SmartKOBİ
                  </h1>
                  <p style="margin:5px 0 0 0;color:#6b7280;font-size:14px;">
                    İşletmenizi güvenle yönetin
                  </p>
                </td>
              </tr>

              <!-- Title -->
              <tr>
                <td>
                  <h2 style="margin:0 0 15px 0;color:#111827;font-size:20px;">
                    Şifre Sıfırlama Talebi
                  </h2>
                  <p style="margin:0 0 20px 0;color:#4b5563;font-size:15px;line-height:1.6;">
                    Hesabınız için bir şifre sıfırlama talebi aldık. 
                    Aşağıdaki butona tıklayarak yeni bir şifre oluşturabilirsiniz.
                  </p>
                </td>
              </tr>

              <!-- Button -->
              <tr>
                <td align="center" style="padding:25px 0;">
                  <a href="${resetLink}" 
                    style="background:linear-gradient(90deg,#2563EB,#4F46E5);
                            color:#ffffff;
                            text-decoration:none;
                            padding:14px 28px;
                            border-radius:8px;
                            font-weight:bold;
                            font-size:15px;
                            display:inline-block;">
                    Şifremi Sıfırla
                  </a>
                </td>
              </tr>

              <!-- Expiry Info -->
              <tr>
                <td>
                  <p style="margin:0 0 15px 0;color:#6b7280;font-size:13px;line-height:1.6;">
                    ⚠️ Bu bağlantı güvenlik nedeniyle belirli bir süre sonra geçersiz olacaktır.
                  </p>
                  <p style="margin:0;color:#6b7280;font-size:13px;line-height:1.6;">
                    Eğer bu işlemi siz başlatmadıysanız, bu e-postayı görmezden gelebilirsiniz.
                    Hesabınız güvendedir.
                  </p>
                </td>
              </tr>

              <!-- Divider -->
              <tr>
                <td style="padding:30px 0;">
                  <hr style="border:none;border-top:1px solid #e5e7eb;" />
                </td>
              </tr>

              <!-- Footer -->
              <tr>
                <td align="center">
                  <p style="margin:0;color:#9ca3af;font-size:12px;">
                    © ${new Date().getFullYear()} SmartKOBİ
                  </p>
                  <p style="margin:5px 0 0 0;color:#9ca3af;font-size:12px;">
                    Bu e-posta otomatik olarak gönderilmiştir.
                  </p>
                </td>
              </tr>

            </table>
            
          </td>
        </tr>
      </table>

    </body>
    </html>
    `,
  });
}
    // Her durumda success dön (güvenlik için)
    return new Response(
      JSON.stringify({ success: true }),
      { headers: { "Content-Type": "application/json" } }
    );

  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500 }
    );
  }
});