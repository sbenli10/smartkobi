import '../../data/models/business_profile_model.dart';

int calculateBusinessProfileCompletion(BusinessProfileModel profile) {
  return profile.calculateCompletion().clamp(0, 100);
}

String getCompletionLabel(int completion) {
  if (completion >= 90) {
    return 'Güçlü Profil';
  }
  if (completion >= 70) {
    return 'Analize Hazır';
  }
  if (completion >= 40) {
    return 'Geliştirilebilir Profil';
  }
  return 'Eksik Profil';
}

String getCompletionDescription(int completion) {
  if (completion >= 90) {
    return 'Profiliniz destek analizi, AI önerileri ve raporlar için güçlü durumda.';
  }
  if (completion >= 70) {
    return 'SmartKOBİ analizleri için temel bilgileriniz büyük ölçüde hazır.';
  }
  if (completion >= 40) {
    return 'Birkaç kritik bilgi daha eklendiğinde öneriler daha isabetli hale gelir.';
  }
  return 'Destek analizi ve AI önerileri için birkaç temel bilgi daha gerekiyor.';
}
