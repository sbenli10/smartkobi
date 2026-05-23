import 'package:flutter/material.dart';

class AppColors {
  // Yeni Açık Tema (SaaS) Renkleri
  static const Color primaryNavy = Color(0xFF0B1F3A); // Güven veren ana lacivert
  static const Color primaryNavySoft = Color(0xFFEAF0F7);
  static const Color accentGold = Color(0xFFC89B3C); // Vurgu için altın rengi
  static const Color accentGoldSoft = Color(0xFFFFF7E6);

  static const Color scaffoldBackground = Color(0xFFF7F8FA); // Kırık beyaz arka plan
  static const Color surface = Color(0xFFFFFFFF); // Beyaz kart zemini
  static const Color surfaceAlt = Color(0xFFF1F5F9); // Form alanları ve alt kartlar için açık gri
  static const Color border = Color(0xFFE2E8F0); // İnce ve zarif kenarlık rengi

  static const Color textPrimary = Color(0xFF0F172A); // Koyu metin
  static const Color textSecondary = Color(0xFF475569); // Gri metin
  static const Color textMuted = Color(0xFF94A3B8); // Pasif metin

  // Durum Renkleri
  static const Color success = Color(0xFF10B981); // Güvenli, tamamlandı (Yeşil)
  static const Color warning = Color(0xFFF59E0B); // Dikkat (Amber)
  static const Color danger = Color(0xFFEF4444); // Kritik, hata (Kırmızı)
  static const Color info = Color(0xFF3B82F6); // Bilgi (Mavi)

  // --- GERİYE DÖNÜK UYUMLULUK (Eski ekranların patlamaması için) ---
  static const Color navy950 = primaryNavy; 
  static const Color navy900 = scaffoldBackground; 
  static const Color navy800 = surfaceAlt;
  static const Color navy700 = primaryNavySoft;
  static const Color gold500 = primaryNavy; // Laciverti ana buton rengi yapmak için gold'u ezdik
  static const Color gold400 = accentGold; 
}