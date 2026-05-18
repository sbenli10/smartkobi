//lib\features\ai\ai_service.dart
class AiInsightService {
  String generateInsight({
    required double income,
    required double expense,
  }) {
    final net = income - expense;

    if (net < 0) {
      return "Bu ay giderler gelirlerden yüksek. Gider kategorilerini gözden geçirmeniz önerilir.";
    }

    if (expense > income * 0.7) {
      return "Gider oranınız %70'in üzerinde. Karlılık risk altında olabilir.";
    }

    if (net > income * 0.3) {
      return "Karlılık oranınız sağlıklı görünüyor. Yatırım planı yapılabilir.";
    }

    return "Finansal durum dengeli görünüyor.";
  }
}
