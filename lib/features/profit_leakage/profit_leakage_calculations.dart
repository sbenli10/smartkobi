class ProfitLeakageCalculations {
  static String normalizeItemName(String value) {
    String normalized = value.toLowerCase().trim();
    normalized = normalized.replaceAll(RegExp(r'[ıi]'), 'i')
        .replaceAll(RegExp(r'[şs]'), 's')
        .replaceAll(RegExp(r'[ğg]'), 'g')
        .replaceAll(RegExp(r'[üu]'), 'u')
        .replaceAll(RegExp(r'[öo]'), 'o')
        .replaceAll(RegExp(r'[çc]'), 'c');
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    // Birim standartlaştırma
    normalized = normalized.replaceAll(RegExp(r'\b(kg|kilo|kilogram)\b'), 'kg');
    normalized = normalized.replaceAll(RegExp(r'\b(lt|litre)\b'), 'lt');
    normalized = normalized.replaceAll(RegExp(r'\b(ad|adet)\b'), 'adet');
    return normalized.trim();
  }

  static double? calculateUnitPrice(double? total, double? qty, double? explicitUnit) {
    if (explicitUnit != null && explicitUnit > 0) return explicitUnit;
    if (total != null && qty != null && qty > 0) return total / qty;
    return null;
  }

  static String determineSeverity(double increaseRate) {
    if (increaseRate < 10) return 'low';
    if (increaseRate < 20) return 'medium';
    if (increaseRate < 35) return 'high';
    return 'critical';
  }
}