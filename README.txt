SmartKOBI UYGULAMA REHBERI
==========================

Bu belge, SmartKOBI uygulamasinin modullerini, temel isleyisini ve kullanim amaclarini
aciklamak icin hazirlanmistir. Metin teknik olmayan bir isletme kullanicisinin da
anlayabilecegi sekilde, uygulamanin operasyon mantigini anlatir.


1. UYGULAMANIN GENEL AMACI
--------------------------

SmartKOBI; kucuk ve orta olcekli isletmelerin gunluk yonetim ihtiyaclarini tek yerde
toplamak icin tasarlanmis bir dijital isletme yonetim uygulamasidir.

Uygulamanin temel hedefleri:

- gelir ve gider takibini duzenlemek
- musteri/cari hesaplarini yonetmek
- stok ve urun durumunu izlemek
- nakit akis riskini onceden gormek
- isletme profiline gore destek ve tesvik potansiyelini analiz etmek
- AI destekli ozet ve oneri uretmek

SmartKOBI kesin muhasebe, hukuki veya resmi basvuru karari vermez.
Uygulama; on analiz, operasyon takibi ve karar destegi saglar.


2. TEMEL CALISMA MANTIGI
------------------------

Uygulama Supabase altyapisi uzerinde calisir.
Her kullanici sadece kendi verilerini gorur.
Bu guvenlik, kullanici oturumu ve RLS (row level security) kurallari ile saglanir.

Uygulamanin genel veri akisi soyledir:

1. Kullanici giris yapar.
2. Kullanici kendi isletmesine ait verileri ekler.
3. Moduller bu verileri okur ve kendi ekranlarinda gosterir.
4. AI destekli moduller ham veriyi degil, ozetlenmis baglam verisini yorumlar.
5. Kullanici yeni veri girdikce analizler daha dogru hale gelir.


3. GIRIS VE KULLANICI YAPISI
----------------------------

Giris / Kayit:
- Kullanici e-posta ve sifre ile kayit olabilir.
- Kayit sirasinda temel isletme adi alinabilir.
- Giris sonrasinda ayrintili profil isletme profili ekraninda tamamlanir.

Guvenlik:
- Flutter tarafinda sadece kullanicinin aktif oturumu kullanilir.
- Service role key veya gizli API anahtari uygulama icine konulmaz.
- Her tablo kullanici bazli goruntuleme ve degistirme kurallari ile korunur.


4. HOMESHELL / ANA UYGULAMA KABUGU
----------------------------------

HomeShell, uygulamanin ana navigasyon katmanidir.

Geniş ekran:
- solda sidebar kullanilir
- menuler gruplu sekilde gosterilir
- aktif modul altin vurgu ile belirginlestirilir

Mobil:
- altta 5 sekmeli navigasyon kullanilir
- Ana Sayfa, Finans, Cari, Stok ve Diger bolumu vardir
- Diger alanindan kalan modullere erisim saglanir

Amaç:
- kullanici hangi modülde oldugunu net gorebilsin
- menuler kalabaliklasmadan duzenli kalsin
- mobil kullanim rahat olsun


5. ANA SAYFA / DASHBOARD
------------------------

Dashboard, isletmenin genel saglik ekranidir.

Gosterdigi ana alanlar:
- bugunku ciro
- aylik gelir
- aylik gider
- net kar
- tahsil edilecek tutar
- odenecek tutar
- kritik stok
- nakit akisi skoru

Ek olarak:
- isletme profili tamamlama durumu
- destek analizi karti
- AI onerileri
- hizli islem dugmeleri

Kullanim amaci:
- kullanici tum isletme ozetini tek bakista gorsun
- oncelikli riski veya eksigi hemen fark etsin


6. ISLETME PROFILI / KOBI KIMLIK KARTI
--------------------------------------

Bu modul, uygulamanin merkezi isletme kimlik kaynagidir.

Burada toplanan bilgiler:
- isletme adi
- resmi unvan
- vergi bilgileri
- isletme turu
- sektor
- NACE kodu
- sehir / ilce
- kurulus yili
- calisan sayisi
- ciro araligi
- aylik gider araligi
- uretim / ihracat / e-ticaret bilgisi
- makine, dijitallesme, sertifika ve finansman ihtiyaclari
- hedef yatirim tutari
- ana urun / hizmet bilgisi
- hedef pazarlar
- sertifikalar

Bu modül neden onemli?
- Destek Analizi bu bilgileri kullanir
- AI Danisman daha isabetli yorum uretir
- Nakit ve buyume kararlarinda baglamsal destek saglar

Profil tamamlama:
- sistem profilin yuzde kac tamamlandigini hesaplar
- dusuk oranlarda kullaniciya eksik alanlar gosterilir


7. FINANS MODULU
----------------

Finans modulu gelir-gider kayitlari icin kullanilir.

Temel fonksiyonlar:
- gelir ekleme
- gider ekleme
- islem tipi secme
- tarih ve aciklama ile kayit tutma
- kayitlari listeleme

Finans modulu su alanlarda etkilidir:
- Dashboard finans ozetleri
- aylik kar/zarar gorunumu
- AI Danisman finans yorumu
- Business context ozetleri


8. CARI / MUSTERI YONETIMI
--------------------------

Cari modulu, musteri bazli tahsilat ve hesap takibi icin tasarlanmistir.

Neler yapilir:
- yeni musteri eklenir
- musteri detay bilgileri tutulur
- acilis bakiyesi girilebilir
- cari hareket eklenebilir
- alacak, tahsilat, borc ve duzeltme kaydi tutulur
- musteri bazli bakiye yeniden hesaplanir
- geciken tahsilat gorulebilir

Ekran davranislari:
- toplam musteri sayisi
- toplam alacak
- geciken tahsilat
- yuksek riskli cari hesaplar
- arama ve filtreleme

AI/kural bazli destek:
- risk etiketi (dusuk / orta / yuksek)
- tahsilat onceligi yorumu
- WhatsApp ve e-posta hatirlatma metni olusturma


9. STOK / URUN YONETIMI
-----------------------

Stok modulu, urunlerin miktarini, fiyatlarini ve stok hareketlerini takip eder.

Temel ozellikler:
- urun ekleme
- SKU ve barkod bilgisi tutma
- kategori ve birim takibi
- alis ve satis fiyati kaydi
- minimum stok seviyesi belirleme
- stok giris / cikis / iade / duzeltme hareketleri ekleme
- kar marji hesaplama
- kritik stok uyarisi

Ozet veriler:
- toplam urun
- toplam stok degeri
- stokta olmayan urunler
- kritik stoktaki urunler
- ortalama kar marji

Ek ozellik:
- barkod tarama altyapisi
- kritik stok ve dusuk marj filtresi


10. KPI MODULU
--------------

KPI modulu, temel performans gostergelerini daha odakli gormek icin kullanilir.

Kullanici burada:
- ciro
- kar
- gider
- stok ve operasyon etkisi
- trend bazli performans
gibi basliklari daha analitik bir ekranda takip eder.

Bu modul, Dashboard’un daha odakli KPI gorunumu gibi dusunulebilir.


11. NAKIT AI / NAKIT AKISI TAHMINI
----------------------------------

Bu modul, kisa ve orta vadeli nakit durumunu yorumlar.

Temel amaci:
- 30 gunluk nakit tahmini
- 60 gunluk nakit tahmini
- beklenen tahsilatlar
- beklenen odemeler
- geciken tahsilat etkisi
- nakit skoru

Kullanici burada:
- yeni nakit kaydi ekleyebilir
- beklenen tahsilat / odeme planlayabilir
- “Bu harcamayi yapabilir miyim?” analizi calistirabilir

Kural bazli analizler:
- net nakit negatif mi?
- geciken tahsilat baskisi var mi?
- yaklasan odemeler fazla mi?
- nakit skoru ne seviyede?

Bu modul, kararin dogrudan kendisini vermez.
Yeni harcama onceki tahminleri nasil etkiler, onu gosterir.


12. AI DANISMAN
---------------

AI Danisman, genel sohbet botu degildir.
Bu modul sadece isletme yonetimi kapsaminda yardimci olur.

Odaklandigi konular:
- finans
- cari
- stok
- nakit akisi
- destek / tesvik
- satis, fiyatlandirma ve buyume kararlari

Calisma mantigi:
1. Kullanici soru sorar.
2. Sistem once sorunun kapsama uygun olup olmadigini kontrol eder.
3. Isletme verilerinden baglam ozeti olusturulur.
4. Uygunsa Edge Function uzerinden AI cevabi denenir.
5. AI yoksa veya cevap alinamazsa kural bazli fallback cevap uretilir.

Scope guard:
- kapsam disi sorulari reddeder
- belirsiz sorularda kullanicidan isletme baglami ister
- gereksiz AI maliyetini azaltir

Beklenen kullanim sorulari:
- Nakit akisim riskli mi?
- Kimden tahsilat yapmaliyim?
- Hangi urunler kritik stokta?
- Bu ay isletmemin durumu nasil?
- KOSGEB destegine uygun muyum?


13. AI ANALIZLER
----------------

AI Analizler modulu, AI Danisman’dan farkli olarak daha genel analiz ekranidir.

Bu alan:
- veri ozetleri
- otomatik yorumlar
- analiz destekli bakis acilari
sunmak icin kullanilir.

AI Danisman daha sohbet bazli;
AI Analizler ise ekran bazli yorum ve analiz odaklidir.


14. DESTEK ANALIZI
------------------

Destek Analizi modulu, isletme profiline gore on uygunluk tahmini yapar.

Kapsadigi basliklar:
- KOSGEB
- TUBITAK / Ar-Ge
- Ticaret Bakanligi ihracat destekleri
- belgelendirme destekleri
- dijitallesme destekleri
- finansman / Eximbank potansiyeli

Analiz mantigi:
- kesin uygunluk demez
- yuksek / orta / dusuk potansiyel dili kullanir
- eksik profil alanlarini listeler
- eksik belge onerir
- sonraki adimlari cikarir

Urettigi alanlar:
- genel uygunluk skoru
- destek basligina gore alt skorlar
- firsat kartlari
- checklist / hazirlik listesi
- ozet yorum

Bu modül özellikle su sorulara yardimci olur:
- Hangi destek bana daha uygun olabilir?
- Basvuru oncesi hangi bilgi eksik?
- Hangi belgeyi tamamlamam gerekiyor?


15. BELGELER MODULU
-------------------

Belgeler modulu, destek ve isletme sureclerinde gerekebilecek belgeleri takip etmek icin
kullanilmak uzere konumlanmistir.

Ornek belge alanlari:
- vergi levhasi
- faaliyet belgesi
- KOBI beyannamesi
- imza sirkuleri
- kapasite raporu
- proforma fatura
- teknik dokumanlar
- ISO / TSE / CE gibi sertifikalar

Destek Analizi modulu, eksik belge listelerini bu alanla uyumlu calisacak sekilde üretir.


16. RAPORLAR MODULU
-------------------

Raporlar modulu, kayitlardan daha derli toplu cikti almak icin kullanilir.

Olası kullanim amaclari:
- finansal ozet
- performans raporu
- isletme durumuna dair yonetici bakisi
- operasyonel veri ozetleri

Bu modul, Dashboard’dan daha cok cikti/raporlama odaklidir.


17. AYARLAR
-----------

Ayarlar modulu uygulama icindeki genel tercihlerin ve profil baglantilarinin yonetimi icin
kullanilir.

Buradan:
- isletme profiline ulasilabilir
- genel uygulama ayarlari acilabilir
- ileride genisletilecek hesap/tercih ekranlari yonetilebilir


18. MODULLER ARASI BAGLANTI
---------------------------

SmartKOBI modulleri birbirinden bagimsiz degil, birbirini besleyen bir yapiyla calisir:

- Isletme Profili
  -> Destek Analizi
  -> AI Danisman
  -> Dashboard profil karti

- Finans
  -> Dashboard gelir/gider ozeti
  -> AI Danisman finans yorumu
  -> Business context summary

- Cari
  -> tahsilat riski
  -> Nakit AI
  -> AI Danisman musteri/tahsilat yorumu

- Stok
  -> kritik stok sayisi
  -> Dashboard stok kartlari
  -> AI Danisman stok yorumu

- Nakit AI
  -> cash score
  -> 30/60 gun tahmini
  -> AI Danisman nakit yorumu

- Destek Analizi
  -> uygunluk skorlar
  -> AI Danisman destek cevabi


19. AI CEVAPLARINDA KULLANILAN MANTIK
-------------------------------------

AI tarafinda ham tablo isimleri kullaniciya gosterilmez.
Teknik alan adlari Turkcelestirilir.

Ornek:
- pending_receivables -> bekleyen tahsilatlar
- overdue_receivables -> vadesi gecmis tahsilatlar
- cash_score -> nakit skoru
- critical_stock_count -> kritik stoktaki urun sayisi

Amaç:
- kullanicinin teknik terimlerle degil, isletme diliyle bilgi almasi


20. DESTEKLEYICI KURAL MOTORLARI
--------------------------------

Uygulamada birden fazla yerde AI benzeri ama kural bazli karar motoru kullanilir:

- cari risk seviyesi hesaplama
- stok risk ve kritik seviye tespiti
- nakit skoru hesaplama
- destek uygunluk skorlari
- AI Danisman fallback cevap motoru

Bu sayede:
- API cevap vermese bile temel analiz devam eder
- uygulama bos ekrana dusmez
- kullanici yine yonlendirici cevap alir


21. VERI TAMAMLANDIKCA GELISEN ANALIZ
-------------------------------------

SmartKOBI'de analiz kalitesi veri kalitesine baglidir.

En iyi sonuc icin kullanicinin asagidaki alanlari duzenli guncellemesi gerekir:

- gelir ve gider kayitlari
- musteri ve tahsilat bilgileri
- stok ve urun bilgileri
- nakit kayitlari
- isletme profili
- destek icin gerekli alanlar ve belgeler

Veri eksikse:
- analiz daha sinirli olur
- uygulama bunu kullaniciya acikca soyler
- “kesin sonuc” vermez


22. TEKNIK NOTLAR
-----------------

Uygulama mimarisi genel olarak su katmanlarla calisir:

- Supabase SQL migration katmani
- Dart model katmani
- repository/service katmani
- helper/calculation motorleri
- UI sayfalari
- AI / fallback entegrasyonlari

Guvenlik notlari:
- service role key Flutter icinde tutulmaz
- AI anahtarlari sadece server-side / Edge Function tarafinda kullanilir
- kullanici sadece kendi verisini gorur


23. ONERILEN ILK KULLANIM SIRASI
--------------------------------

Uygulamayi ilk kez kullanacak bir isletme icin onerilen siralama:

1. Giris yapin
2. Isletme Profili ekranini doldurun
3. Finans modülünde ilk gelir-gider kayitlarini girin
4. Cari modülünde musteri ve tahsilat kayitlarini olusturun
5. Stok modülünde urunleri ve stok seviyelerini ekleyin
6. Nakit AI ekraninda beklenen tahsilat/odeme kayitlari olusturun
7. Destek Analizi ekraninda ilk analiz calistirin
8. AI Danisman ile ozet sorular sorun


24. ORNEK KULLANIM SORULARI
---------------------------

AI Danisman icin ornek sorular:

- Bu ay isletmemin durumu nasil?
- Nakit akisim riskli mi?
- Kimden tahsilat yapmaliyim?
- Hangi urunler kritik stokta?
- Karim neden dusuyor olabilir?
- KOSGEB destegine uygun olabilir miyim?
- Yatirim oncesi hangi eksiklerimi tamamlamam gerekir?


25. SONUC
---------

SmartKOBI; isletme sahibinin farkli ekranlar arasinda kaybolmadan,
tek bir uygulama icinde:

- kayit tutmasini,
- risk gormesini,
- oncelik belirlemesini,
- destek potansiyelini anlamasini,
- AI destekli ozetler almasini
hedefler.

Uygulama bir “karar destek ve operasyon takip merkezi” gibi dusunulmelidir.

