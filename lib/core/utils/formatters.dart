import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  static final NumberFormat _integerFormat = NumberFormat.decimalPattern('tr_TR');

  static final NumberFormat _decimalFormat = NumberFormat('#,##0.##', 'tr_TR');

  static final NumberFormat _fixedTwoDecimalFormat = NumberFormat('#,##0.00', 'tr_TR');

  static final NumberFormat _percentFormat = NumberFormat('#,##0.0', 'tr_TR');

  /// Para birimlerini Türk Lirası formatında gösterir.
  ///
  /// Örnek:
  /// - 750        -> ₺750,00
  /// - 750000     -> ₺750.000,00
  /// - null / NaN -> ₺0,00
  static String formatCurrency(num? value) {
    final safeValue = _safeNumber(value);
    return _currencyFormat.format(safeValue);
  }

  /// Stok miktarlarını akıllı formatlar.
  ///
  /// Tam sayıysa ondalık göstermez:
  /// - 1000 -> 1.000
  ///
  /// Ondalık varsa en fazla 2 hane gösterir:
  /// - 12.5 -> 12,5
  /// - 12.25 -> 12,25
  ///
  /// Birim geçerliyse sonuna ekler:
  /// - 1000, unit: adet -> 1.000 adet
  /// - 12.5, unit: kg   -> 12,5 kg
  ///
  /// Birim tamamen sayıysa göstermez:
  /// - 1000, unit: 1000 -> 1.000
  static String formatQuantity(num? value, {String? unit}) {
    final safeValue = _safeNumber(value);
    final formattedValue = _formatSmartNumber(safeValue);
    final safeUnit = normalizeUnit(unit);

    if (safeUnit == null) {
      return formattedValue;
    }

    return '$formattedValue $safeUnit';
  }

  /// Miktarı her zaman 2 ondalıkla göstermek gereken özel durumlar için.
  ///
  /// Normal stok gösteriminde bunu değil, formatQuantity kullan.
  static String formatQuantityFixed(num? value, {String? unit}) {
    final safeValue = _safeNumber(value);
    final formattedValue = _fixedTwoDecimalFormat.format(safeValue);
    final safeUnit = normalizeUnit(unit);

    if (safeUnit == null) {
      return formattedValue;
    }

    return '$formattedValue $safeUnit';
  }

  /// Genel sayı formatı.
  ///
  /// Tam sayıysa:
  /// - 1000 -> 1.000
  ///
  /// Ondalıklıysa:
  /// - 1250.5 -> 1.250,5
  static String formatNumber(num? value) {
    return _formatSmartNumber(_safeNumber(value));
  }

  /// Yüzdelik değerleri gösterir.
  ///
  /// Örnek:
  /// - 33.333 -> %33,3
  /// - null   -> %0,0
  static String formatPercent(num? value) {
    final safeValue = _safeNumber(value);
    return '%${_percentFormat.format(safeValue)}';
  }

  /// Tarihleri standart Türkçe tarih formatında gösterir.
  ///
  /// Örnek:
  /// - 24.05.2026
  static String formatDateTr(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  /// Saat formatı.
  ///
  /// Örnek:
  /// - 14:35
  static String formatTimeTr(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('HH:mm').format(date);
  }

  /// Tarih + saat formatı.
  ///
  /// Örnek:
  /// - 24.05.2026 14:35
  static String formatDateTimeTr(DateTime? date) {
    if (date == null) return '-';
    return '${formatDateTr(date)} ${formatTimeTr(date)}';
  }

  /// Dosya boyutu gösterimi.
  ///
  /// Örnek:
  /// - 900 -> 900 B
  /// - 1200 -> 1,2 KB
  /// - 2500000 -> 2,38 MB
  static String formatFileSize(num? bytes) {
    final safeBytes = _safeNumber(bytes);

    if (safeBytes <= 0) return '0 B';
    if (safeBytes < 1024) return '${_integerFormat.format(safeBytes)} B';

    final kb = safeBytes / 1024;
    if (kb < 1024) return '${_decimalFormat.format(kb)} KB';

    final mb = kb / 1024;
    if (mb < 1024) return '${_decimalFormat.format(mb)} MB';

    final gb = mb / 1024;
    return '${_decimalFormat.format(gb)} GB';
  }

  /// Para veya sayı inputlarını güvenli double değere çevirir.
  ///
  /// Kabul eder:
  /// - 1000
  /// - 1000.50
  /// - 1000,50
  /// - 1.000,50
  /// - ₺1.000,50
  static double parseDecimal(String? value, {double fallback = 0}) {
    final normalized = normalizeDecimalInput(value);

    if (normalized == null) {
      return fallback;
    }

    return double.tryParse(normalized) ?? fallback;
  }

  /// Kullanıcı inputunu double.parse için güvenli hale getirir.
  ///
  /// Türkçe para/sayı formatını destekler:
  /// - 1.000,50 -> 1000.50
  /// - 1000,50 -> 1000.50
  /// - 1000.50 -> 1000.50
  static String? normalizeDecimalInput(String? value) {
    if (value == null) return null;

    var text = value.trim();

    if (text.isEmpty) return null;

    text = text
        .replaceAll('₺', '')
        .replaceAll('TL', '')
        .replaceAll('tl', '')
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^0-9,.\-]'), '');

    if (text.isEmpty || text == '-' || text == ',' || text == '.') {
      return null;
    }

    final hasComma = text.contains(',');
    final hasDot = text.contains('.');

    if (hasComma && hasDot) {
      final lastComma = text.lastIndexOf(',');
      final lastDot = text.lastIndexOf('.');

      if (lastComma > lastDot) {
        // Türkçe format: 1.250,50
        text = text.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // İngilizce format: 1,250.50
        text = text.replaceAll(',', '');
      }
    } else if (hasComma) {
      // 1250,50
      text = text.replaceAll(',', '.');
    }

    return text;
  }

  /// Birim değerini güvenli hale getirir.
  ///
  /// Tamamen sayısal unit değerlerini yok sayar.
  /// Örnek:
  /// - "adet" -> "adet"
  /// - " kg " -> "kg"
  /// - "1000" -> null
  /// - "" -> null
  static String? normalizeUnit(String? unit) {
    if (unit == null) return null;

    final trimmed = unit.trim();

    if (trimmed.isEmpty) return null;

    final normalized = trimmed.toLowerCase();

    // Yanlışlıkla birim alanına stok miktarı yazıldıysa göstermeyelim.
    final numericOnly = RegExp(r'^[0-9]+([,.][0-9]+)?$');
    if (numericOnly.hasMatch(normalized)) {
      return null;
    }

    // Çok uzun metinleri birim gibi göstermeyelim.
    if (normalized.length > 20) {
      return null;
    }

    return normalized;
  }

  /// Birim alanı için form validasyonu.
  ///
  /// Yeni ürün / ürün düzenleme formlarında kullanılabilir.
  static String? validateUnit(String? value) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return 'Birim zorunlu';
    }

    final numericOnly = RegExp(r'^[0-9]+([,.][0-9]+)?$');

    if (numericOnly.hasMatch(trimmed)) {
      return 'Birim adet, kg, koli gibi bir ifade olmalı';
    }

    if (trimmed.length > 20) {
      return 'Birim çok uzun olmamalı';
    }

    return null;
  }

  /// Dosya adı / export adı üretirken Türkçe karakterleri sadeleştirir.
  static String slugifyFileName(String value) {
    var text = value.trim();

    if (text.isEmpty) return 'smartkobi';

    const replacements = {
      'ç': 'c',
      'Ç': 'C',
      'ğ': 'g',
      'Ğ': 'G',
      'ı': 'i',
      'I': 'I',
      'İ': 'I',
      'ö': 'o',
      'Ö': 'O',
      'ş': 's',
      'Ş': 'S',
      'ü': 'u',
      'Ü': 'U',
    };

    replacements.forEach((from, to) {
      text = text.replaceAll(from, to);
    });

    text = text
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return text.isEmpty ? 'smartkobi' : text;
  }

  static num _safeNumber(num? value) {
    if (value == null) return 0;
    if (value.isNaN) return 0;
    if (value.isInfinite) return 0;
    return value;
  }

  static String _formatSmartNumber(num value) {
    final safeValue = _safeNumber(value);

    if (_isWholeNumber(safeValue)) {
      return _integerFormat.format(safeValue.round());
    }

    return _decimalFormat.format(safeValue);
  }

  static bool _isWholeNumber(num value) {
    final safeValue = _safeNumber(value);
    return safeValue % 1 == 0;
  }
}