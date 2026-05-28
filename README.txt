Yüklediğin dosya yapısını ve uygulamanın içerdiği modülleri kapsamlı bir şekilde analiz ettim. SmartKOBİ, küçük esnaf ve KOBİ'ler için geliştirilmiş, yapay zeka destekli, uçtan uca bir işletme yönetimi uygulaması.

Projenin mimarisine, barındırdığı özelliklere ve modern "Feature-first" klasör yapısına uygun olarak hazırladığım kapsamlı `README.md` (veya `README.txt`) dosyasını aşağıda bulabilirsin. Bu dosyayı projenin kök dizinine ekleyebilirsin.

---

# SmartKOBİ - Dijital İş Ortağınız

SmartKOBİ, küçük esnaf, mikro işletmeler ve KOBİ'ler için geliştirilmiş; karmaşık muhasebe programlarına kıyasla son derece sade, proaktif ve yapay zeka destekli bir işletme yönetimi (SaaS) mobil uygulamasıdır. İşletmelerin gelir-gider, stok, cari ve nakit akışı takibini tek bir yerden yapmasını sağlarken, aynı zamanda akıllı uyarılarla "karar destek mekanizması" olarak çalışır.

## 🚀 Öne Çıkan Özellikler

SmartKOBİ sadece bir "kayıt defteri" değil, aynı zamanda işletmenizin finansal sağlığını koruyan akıllı bir asistandır:

* **Günlük Komuta Merkezi (Dashboard):** İşletme sahibine o gün odaklanması gereken en önemli 3-4 eylemi (ör. tahsilat yap, stok yenile) gösteren, sadeleştirilmiş ana ekran.
* **Kâr Sızıntısı Analizi (Fiyat Radarı):** Tedarikçilerden alınan ürünlerin fiyat artışlarını geçmiş verilerle karşılaştırıp kâr marjı düşüşlerine karşı esnafı uyaran modül.
* **Yapay Zeka (AI) Danışman:** İşletmenin verilerine dayanarak nakit akışı tahminleri yapan, "Kârım neden düştü?" veya "Bu ay sonu KDV ne kadar çıkar?" gibi sorulara cevap veren sohbet asistanı.
* **Fiş ve Fatura Tarayıcı (OCR):** Kamerayla çekilen fiş ve faturaları okuyarak içerisindeki satır kalemlerini (ürün, fiyat, KDV) otomatik olarak gider ve alış kayıtlarına işleyen akıllı tarayıcı.
* **Kibar Tahsilat Asistanı:** Vadesi geçmiş veya yaklaşan alacaklar için WhatsApp üzerinden müşterinin risk/ilişki durumuna göre otomatik, nazik tahsilat mesajları oluşturma.
* **Stok ve Barkod Yönetimi:** Barkod/QR kod okuyucu entegrasyonu ile hızlı stok girişi-çıkışı yapma ve kritik stok seviyesi takibi.
* **Destek ve Teşvik Analizi:** İşletmenin profiline (NACE kodu vb.) göre uygun KOSGEB, Ticaret Bakanlığı teşvik ve desteklerini eşleştirme.
* **Dinamik Raporlama:** İşletme verilerinin anlık durumunu PDF formatında dışa aktarabilme.
* **Güvenli ve Modern Kimlik Doğrulama (Auth):** "Midnight Fintech" konseptiyle tasarlanmış, şifreli ve güvenli bulut tabanlı kullanıcı oturum yönetimi.

## 🛠 Teknoloji Yığını

Uygulama, modern çapraz platform ve bulut teknolojileri kullanılarak ölçeklenebilir bir yapıda inşa edilmiştir:

* **Frontend:** Flutter (Cross-platform: iOS, Android, Web, macOS, Windows, Linux)
* **Backend & Veritabanı:** Supabase (PostgreSQL)
* **Kimlik Doğrulama:** Supabase Auth
* **Sunucu Taraflı Mantık:** Supabase Edge Functions (Deno / TypeScript)
* **Yapay Zeka (OCR ve LLM):** Gemini API / Supabase AI entegrasyonları
* **Dosya Depolama:** Supabase Storage (Fiş taramaları ve PDF raporlar için)

## 📁 Proje Mimarisi (Feature-First)

Uygulama, endüstri standardı olan "Feature-First" (Özelliğe Göre Gruplandırma) mimarisini kullanmaktadır:

* `lib/auth/` - Oturum açma, kayıt olma ve şifre sıfırlama ekranları.
* `lib/common/` - Proje genelinde kullanılan ortak bileşenler (kartlar, scaffold, vb.).
* `lib/core/` - Uygulama teması, renk paleti (AppColors) ve formatlayıcılar.
* `lib/data/` - Veri modelleri, Supabase API istekleri (Repositories) ve iş servisleri.
* `lib/features/` - Ana uygulama modülleri:
* `/ai` - AI Danışman ve chat arayüzleri.
* `/business_profile` - İşletme profil bilgileri.
* `/cashflow` - Nakit akışı tahminlemeleri.
* `/customers` - Müşteri ve cari takibi.
* `/dashboard` - Ana komuta merkezi ve widget'ları.
* `/documents` - Belge yükleme ve takibi.
* `/inventory` - Ürün, stok ve barkod tarayıcı.
* `/notifications` - Akıllı bildirim merkezi.
* `/profit_leakage` - Fiyat radarı ve kâr sızıntısı analizi.
* `/receipt_scanner` - Kamera ve OCR ile fiş/fatura tarama.
* `/reports` - Rapor oluşturma ve PDF dışa aktarma.
* `/support` - Devlet destekleri uygunluk analizi.
* `/transactions` - Gelir, gider ve finans hareketleri.



## ⚙️ Kurulum ve Çalıştırma

Projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımları izleyin:

### Ön Koşullar

* Flutter SDK (Stabil sürüm)
* Dart SDK
* Supabase CLI (Edge Functions ve lokal testler için)

### Adımlar

1. **Depoyu Klonlayın:**
Kodu lokal bilgisayarınıza indirin.
2. **Bağımlılıkları Yükleyin:**
```bash

```



flutter pub get

```
    
3.  **Supabase Bağlantısını Ayarlayın:**
    `lib/main.dart` veya `.env` dosyanız içerisindeki Supabase `URL` ve `Anon Key` bilgilerinizi güncelleyin. Supabase tarafında veritabanı tablolarının (`supabase/migrations/` altındaki SQL dosyaları) oluşturulduğundan emin olun.

4.  **Uygulamayı Çalıştırın:**
    ```bash
flutter run

```

## 🔒 Güvenlik (Row Level Security)

Tüm veritabanı tabloları (`transactions`, `purchase_invoice_items`, `supplier_price_alerts` vb.) Supabase üzerinde **Row Level Security (RLS)** ile korunmaktadır. Her KOBİ kullanıcısı yalnızca kendi oluşturduğu (kendi `user_id`'si ile eşleşen) verileri görüntüleyebilir ve değiştirebilir.