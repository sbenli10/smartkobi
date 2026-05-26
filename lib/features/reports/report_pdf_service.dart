import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/business_report_model.dart';
import '../../data/models/report_section_model.dart';

class ReportPdfService {
  ReportPdfService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const bucketName = 'business-reports';

  static const _fontRegularAsset = 'lib/auth/public/fonts/Inter_18pt-Regular.ttf';
  static const _fontBoldAsset = 'lib/auth/public/fonts/Inter_24pt-Bold.ttf';
  static const _logoCandidates = <String>[
    'assets/images/isgvizyon_logo.png',
    'assets/logo/isgvizyon_logo.png',
    'assets/logo/smartkobi_logo.png',
    'assets/images/smartkobi_logo.png',
    'web/icons/Icon-192.png',
    'web/favicon.png',
  ];

  final SupabaseClient _client;

  Future<Uint8List> buildPdf(
    BusinessReportModel report,
    List<ReportSectionModel> sections,
  ) async {
    final fontBundle = await _loadPdfFonts();
    final logoBytes = await _loadLogoBytes();
    final pages = await _ReportCanvasRenderer(
      report: report,
      sections: sections,
      fontBundle: fontBundle,
      logoBytes: logoBytes,
    ).render();

    if (pages.isEmpty) {
      throw Exception('PDF oluşturulamadı. Rapor sayfası hazırlanamadı.');
    }

    return _BinaryPdfBuilder().build(pages);
  }

  Future<String> savePdfToStorage({
    required String userId,
    required String reportId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$userId/$reportId/$fileName';
    await _client.storage.from(bucketName).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );
    return path;
  }

  String buildPdfFileName(BusinessReportModel report) {
    final date = report.generatedAt ?? report.createdAt;
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final localizedTitle = _slugifyReportTitle(report.reportTypeLabel);
    return 'SmartKOBI_${localizedTitle}_$yyyy-$mm-$dd.pdf';
  }

  Future<_PdfFontBundle> _loadPdfFonts() async {
    try {
      await rootBundle.load(_fontRegularAsset);
      await rootBundle.load(_fontBoldAsset);
      return const _PdfFontBundle(
        regularFamily: 'Inter',
        boldFamily: 'Inter',
        isFallback: false,
      );
    } catch (_) {
      return const _PdfFontBundle(
        regularFamily: null,
        boldFamily: null,
        isFallback: true,
      );
    }
  }

  Future<Uint8List?> _loadLogoBytes() async {
    for (final asset in _logoCandidates) {
      try {
        final data = await rootBundle.load(asset);
        return data.buffer.asUint8List();
      } catch (_) {}
    }
    return null;
  }

  String _slugifyReportTitle(String value) {
    final normalized = value
        .replaceAll('İ', 'I')
        .replaceAll('ı', 'i')
        .replaceAll('Ş', 'S')
        .replaceAll('ş', 's')
        .replaceAll('Ğ', 'G')
        .replaceAll('ğ', 'g')
        .replaceAll('Ü', 'U')
        .replaceAll('ü', 'u')
        .replaceAll('Ö', 'O')
        .replaceAll('ö', 'o')
        .replaceAll('Ç', 'C')
        .replaceAll('ç', 'c')
        .replaceAll('Â', 'A')
        .replaceAll('â', 'a')
        .replaceAll('Ê', 'E')
        .replaceAll('ê', 'e')
        .replaceAll('Î', 'I')
        .replaceAll('î', 'i')
        .replaceAll('Ô', 'O')
        .replaceAll('ô', 'o')
        .replaceAll('Û', 'U')
        .replaceAll('û', 'u');

    return normalized
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

class _PdfFontBundle {
  const _PdfFontBundle({
    required this.regularFamily,
    required this.boldFamily,
    required this.isFallback,
  });

  final String? regularFamily;
  final String? boldFamily;
  final bool isFallback;
}

class _RenderedPdfPage {
  const _RenderedPdfPage({
    required this.width,
    required this.height,
    required this.rgbBytes,
  });

  final int width;
  final int height;
  final Uint8List rgbBytes;
}

class _ReportCanvasRenderer {
  _ReportCanvasRenderer({
    required this.report,
    required this.sections,
    required this.fontBundle,
    required this.logoBytes,
  });

  static const double pageWidth = 1000;
  static const double pageHeight = 1414;
  static const double left = 72;
  static const double right = 72;
  static const double top = 64;
  static const double bottom = 74;
  static const double footerHeight = 28;
  static const double contentWidth = pageWidth - left - right;

  final BusinessReportModel report;
  final List<ReportSectionModel> sections;
  final _PdfFontBundle fontBundle;
  final Uint8List? logoBytes;

  late final String _businessName = _resolveBusinessName();
  late final String _generatedDate =
      _formatDate(report.generatedAt ?? report.createdAt);
  late final Map<String, String> _metrics = _parseMetrics(report.reportData['metrikler']);
  late final List<_CanvasPage> _pages = <_CanvasPage>[];
  _CanvasPage? _currentPage;

  Future<List<_RenderedPdfPage>> render() async {
    _startPage();
    await _buildHeader();
    _buildTitleBlock();
    _buildDisclaimerBox();
    _buildExecutiveSummary();
    _buildMetricGrid();

    for (final section in sections) {
      _buildSection(
        title: section.title,
        body: localizeTechnicalTerms(section.content ?? 'Bu bölüm için içerik bulunamadı.'),
      );
    }

    _buildRiskList();
    _buildActionList();
    _buildFooterNote();

    final rendered = <_RenderedPdfPage>[];
    for (var i = 0; i < _pages.length; i++) {
      final page = _pages[i];
      _paintFooter(page, i + 1);
      rendered.add(await page.toRenderedPage());
    }
    return rendered;
  }

  Future<void> _buildHeader() async {
    final page = _current;
    final canvas = page.canvas;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, contentWidth, 84),
        const Radius.circular(22),
      ),
      Paint()..color = const Color(0xFFF7F9FC),
    );

    if (logoBytes != null) {
      try {
        final logo = await _decodeImage(logoBytes!);
        final logoRect = Rect.fromLTWH(left + 18, top + 14, 56, 56);
        paintImage(
          canvas: canvas,
          rect: logoRect,
          image: logo,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        );
      } catch (_) {
        _drawText(
          page,
          'SmartKOBİ',
          Offset(left + 18, top + 24),
          style: _style(20, bold: true, color: const Color(0xFF112E67)),
          maxWidth: 280,
        );
      }
    } else {
      _drawText(
        page,
        'SmartKOBİ',
        Offset(left + 18, top + 24),
        style: _style(20, bold: true, color: const Color(0xFF112E67)),
        maxWidth: 280,
      );
    }

    _drawText(
      page,
      report.reportTypeLabel,
      Offset(pageWidth - right - 290, top + 18),
      style: _style(
        18,
        bold: true,
        color: const Color(0xFF112E67),
      ),
      maxWidth: 290,
    );
    _drawText(
      page,
      'Oluşturulma tarihi: $_generatedDate',
      Offset(pageWidth - right - 290, top + 46),
      style: _style(12, color: const Color(0xFF5A6477)),
      maxWidth: 290,
    );

    page.y = top + 108;
  }

  void _buildTitleBlock() {
    _ensureSpace(170);
    final page = _current;

    _drawText(
      page,
      report.title,
      Offset(left, page.y),
      style: _style(28, bold: true, color: const Color(0xFF0E2A5C)),
      maxWidth: contentWidth,
    );
    page.y += 46;

    final items = <String>[
      'İşletme: $_businessName',
      'Dönem: ${report.formattedPeriod}',
      'Hazırlayan: SmartKOBİ Karar Destek Sistemi',
    ];

    for (final item in items) {
      final height = _drawText(
        page,
        item,
        Offset(left, page.y),
        style: _style(14, color: const Color(0xFF344054)),
        maxWidth: contentWidth,
      );
      page.y += height + 8;
    }

    page.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, page.y + 8, 160, 4),
        const Radius.circular(999),
      ),
      Paint()..color = const Color(0xFFD4A53A),
    );
    page.y += 28;
  }

  void _buildDisclaimerBox() {
    const boxHeight = 68.0;
    _ensureSpace(boxHeight + 18);
    final page = _current;

    page.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, page.y, contentWidth, boxHeight),
        const Radius.circular(16),
      ),
      Paint()..color = const Color(0xFFFFF6E5),
    );
    _drawText(
      page,
      'Bu rapor ön analiz ve karar destek amacıyla hazırlanmıştır. '
      'Kesin muhasebe, vergi, hukuk veya resmî başvuru kararı yerine geçmez.',
      Offset(left + 18, page.y + 16),
      style: _style(13, color: const Color(0xFF6B4E16)),
      maxWidth: contentWidth - 36,
    );
    page.y += boxHeight + 22;
  }

  void _buildExecutiveSummary() {
    final text = localizeTechnicalTerms(
      (report.summary ?? '').trim().isNotEmpty
          ? report.summary!
          : 'Yönetici özeti henüz oluşturulamadı. Daha güçlü bir değerlendirme için işletme verilerinizi tamamlayın.',
    );
    _buildSection(
      title: 'Yönetici Özeti',
      body: text,
      backgroundColor: const Color(0xFFF8FAFC),
      borderColor: const Color(0xFFE2E8F0),
    );
  }

  void _buildMetricGrid() {
    if (_metrics.isEmpty) {
      return;
    }

    _ensureSpace(54);
    final page = _current;
    _drawText(
      page,
      'Temel Göstergeler',
      Offset(left, page.y),
      style: _style(20, bold: true, color: const Color(0xFF0E2A5C)),
      maxWidth: contentWidth,
    );
    page.y += 34;

    final items = _metrics.entries.take(6).toList();
    const gap = 16.0;
    final cardWidth = (contentWidth - gap) / 2;
    const cardHeight = 96.0;

    for (var i = 0; i < items.length; i += 2) {
      _ensureSpace(cardHeight + 14);
      final rowItems = items.skip(i).take(2).toList();
      for (var j = 0; j < rowItems.length; j++) {
        final entry = rowItems[j];
        final dx = left + ((cardWidth + gap) * j);
        _buildMetricCard(
          page,
          Rect.fromLTWH(dx, page.y, cardWidth, cardHeight),
          entry.key,
          entry.value,
        );
      }
      page.y += cardHeight + 14;
    }

    page.y += 8;
  }

  void _buildMetricCard(
    _CanvasPage page,
    Rect rect,
    String title,
    String value,
  ) {
    page.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()..color = const Color(0xFFF8FAFC),
    );
    page.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFE2E8F0),
    );
    page.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, 6, rect.height),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFFD4A53A),
    );

    _drawText(
      page,
      localizeTechnicalTerms(title),
      Offset(rect.left + 22, rect.top + 18),
      style: _style(12, bold: true, color: const Color(0xFF5A6477)),
      maxWidth: rect.width - 44,
    );
    _drawText(
      page,
      localizeTechnicalTerms(value),
      Offset(rect.left + 22, rect.top + 42),
      style: _style(20, bold: true, color: const Color(0xFF0E2A5C)),
      maxWidth: rect.width - 44,
    );
  }

  void _buildSection({
    required String title,
    required String body,
    Color backgroundColor = Colors.white,
    Color borderColor = const Color(0xFFE5E7EB),
  }) {
    final paragraphs = body
        .split('\n')
        .map((line) => localizeTechnicalTerms(line.trim()))
        .where((line) => line.isNotEmpty)
        .toList();

    final estimatedHeight = 54 + (paragraphs.length * 34);
    _ensureSpace(math.max(estimatedHeight.toDouble(), 116));

    final page = _current;
    final startY = page.y;
    var currentY = startY + 18;

    _drawText(
      page,
      localizeTechnicalTerms(title),
      Offset(left + 18, currentY),
      style: _style(18, bold: true, color: const Color(0xFF0E2A5C)),
      maxWidth: contentWidth - 36,
    );
    currentY += 34;

    for (final paragraph in paragraphs) {
      final height = _drawText(
        page,
        paragraph,
        Offset(left + 18, currentY),
        style: _style(13.5, color: const Color(0xFF344054), height: 1.45),
        maxWidth: contentWidth - 36,
      );
      currentY += height + 10;
    }

    final rect = Rect.fromLTWH(left, startY, contentWidth, currentY - startY + 12);
    page.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()..color = backgroundColor,
    );
    page.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = borderColor,
    );
    page.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, startY, 6, rect.height),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFF112E67),
    );

    _redrawSectionContent(title, paragraphs, startY);
    page.y = rect.bottom + 18;
  }

  void _redrawSectionContent(
    String title,
    List<String> paragraphs,
    double startY,
  ) {
    final page = _current;
    var currentY = startY + 18;
    _drawText(
      page,
      localizeTechnicalTerms(title),
      Offset(left + 18, currentY),
      style: _style(18, bold: true, color: const Color(0xFF0E2A5C)),
      maxWidth: contentWidth - 36,
    );
    currentY += 34;
    for (final paragraph in paragraphs) {
      final height = _drawText(
        page,
        paragraph,
        Offset(left + 18, currentY),
        style: _style(13.5, color: const Color(0xFF344054), height: 1.45),
        maxWidth: contentWidth - 36,
      );
      currentY += height + 10;
    }
  }

  void _buildRiskList() {
    _buildBulletList(
      title: 'Öne Çıkan Riskler',
      items: report.risks,
      emptyMessage: 'Belirgin bir risk kaydı bulunmuyor. Veriler güncellendikçe rapor yeniden alınabilir.',
      tone: _SectionTone.risk,
    );
  }

  void _buildActionList() {
    _buildBulletList(
      title: 'Önerilen Aksiyonlar',
      items: report.recommendedActions,
      emptyMessage: 'Önerilen aksiyon bulunmuyor. Daha kapsamlı çıktı için ilgili modül kayıtları artırılabilir.',
      tone: _SectionTone.action,
    );
  }

  void _buildBulletList({
    required String title,
    required List<String> items,
    required String emptyMessage,
    required _SectionTone tone,
  }) {
    final safeItems = items.isEmpty ? [emptyMessage] : items.map(localizeTechnicalTerms).toList();
    final estimatedHeight = 80 + (safeItems.length * 36);
    _ensureSpace(estimatedHeight.toDouble());
    final page = _current;
    final startY = page.y;

    _drawText(
      page,
      title,
      Offset(left + 18, startY + 18),
      style: _style(18, bold: true, color: tone.titleColor),
      maxWidth: contentWidth - 36,
    );

    var currentY = startY + 54;
    final pageRef = _current;
    for (final item in safeItems) {
      final height = _drawText(
        pageRef,
        item,
        Offset(left + 40, currentY),
        style: _style(13.5, color: const Color(0xFF344054), height: 1.45),
        maxWidth: contentWidth - 76,
      );
      currentY += height + 12;
    }

    pageRef.y = currentY + 8;
    final rect = Rect.fromLTWH(left, startY, contentWidth, pageRef.y - startY);
    pageRef.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()..color = tone.backgroundColor,
    );
    pageRef.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = tone.borderColor,
    );

    _drawText(
      pageRef,
      title,
      Offset(left + 18, startY + 18),
      style: _style(18, bold: true, color: tone.titleColor),
      maxWidth: contentWidth - 36,
    );

    currentY = startY + 54;
    for (final item in safeItems) {
      pageRef.canvas.drawCircle(
        Offset(left + 26, currentY + 10),
        5,
        Paint()..color = tone.bulletColor,
      );
      final height = _drawText(
        pageRef,
        item,
        Offset(left + 40, currentY),
        style: _style(13.5, color: const Color(0xFF344054), height: 1.45),
        maxWidth: contentWidth - 76,
      );
      currentY += height + 12;
    }
    pageRef.y = rect.bottom + 18;
  }

  void _buildFooterNote() {
    _buildSection(
      title: 'Sonraki Adım',
      body: localizeTechnicalTerms(
        report.opportunities.isNotEmpty
            ? report.opportunities.take(2).join(' ')
            : 'Raporu ilgili modüllerle birlikte değerlendirin. Finans, Cari, Stok, Nakit AI, Destek Analizi ve Belgelerim ekranlarındaki kayıtlar güncellendikçe daha güçlü çıktılar elde edilir.',
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      borderColor: const Color(0xFFE2E8F0),
    );
  }

  void _paintFooter(_CanvasPage page, int pageNumber) {
    final footerY = pageHeight - bottom + 10;
    page.canvas.drawLine(
      Offset(left, footerY - 18),
      Offset(pageWidth - right, footerY - 18),
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..strokeWidth = 1,
    );

    _drawText(
      page,
      'SmartKOBİ',
      Offset(left, footerY),
      style: _style(11, bold: true, color: const Color(0xFF0E2A5C)),
      maxWidth: 220,
    );
    _drawText(
      page,
      'Ön analiz raporudur.',
      Offset(left + 250, footerY),
      style: _style(11, color: const Color(0xFF667085)),
      maxWidth: 150,
    );
    _drawText(
      page,
      'Sayfa $pageNumber • $_generatedDate',
      Offset(pageWidth - right - 180, footerY),
      style: _style(11, color: const Color(0xFF667085)),
      maxWidth: 180,
    );
  }

  String _resolveBusinessName() {
    final rawProfile = report.reportData['isletme_profili'];
    final profileMap = rawProfile is Map ? Map<String, dynamic>.from(rawProfile) : const <String, dynamic>{};
    final name = report.reportData['isletme_adi']?.toString() ??
        profileMap['isletme_adi']?.toString() ??
        'SmartKOBİ Kullanıcısı';
    return localizeTechnicalTerms(name);
  }

  Map<String, String> _parseMetrics(dynamic raw) {
    if (raw is! Map) {
      return const <String, String>{};
    }

    final result = <String, String>{};
    for (final entry in raw.entries) {
      result[_metricLabel(entry.key.toString())] = _formatMetricValue(entry.value);
    }
    return result;
  }

  String _metricLabel(String key) {
    switch (key) {
      case 'aylik_gelir':
        return 'Aylık gelir';
      case 'aylik_gider':
        return 'Aylık gider';
      case 'net_kar_zarar':
        return 'Net kâr / zarar';
      case 'bekleyen_tahsilat':
        return 'Bekleyen tahsilatlar';
      case 'vadesi_gecmis_tahsilat':
        return 'Vadesi geçmiş tahsilatlar';
      case 'nakit_skoru':
        return 'Nakit skoru';
      case 'net_nakit_30_gun':
        return '30 günlük net nakit durumu';
      case 'kritik_stok_sayisi':
        return 'Kritik stoktaki ürün sayısı';
      case 'stokta_olmayan_sayisi':
        return 'Stokta olmayan ürün sayısı';
      case 'eksik_belge_sayisi':
        return 'Eksik belge';
      case 'destek_skoru':
        return 'Destek skoru';
      case 'profil_tamamlama':
        return 'Profil tamamlanma oranı';
      case 'risk_duzeyi':
        return 'Risk düzeyi';
      default:
        return localizeTechnicalTerms(key.replaceAll('_', ' '));
    }
  }

  String _formatMetricValue(dynamic value) {
    if (value is num) {
      if (value % 1 == 0) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(2);
    }
    return localizeTechnicalTerms(value?.toString() ?? '-');
  }

  TextStyle _style(
    double size, {
    bool bold = false,
    Color color = Colors.black,
    double height = 1.2,
  }) {
    return TextStyle(
      fontFamily: bold ? fontBundle.boldFamily ?? fontBundle.regularFamily : fontBundle.regularFamily,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      fontSize: size,
      height: height,
      color: color,
    );
  }

  double _drawText(
    _CanvasPage page,
    String text,
    Offset offset, {
    required TextStyle style,
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: null,
    )..layout(maxWidth: maxWidth);
    painter.paint(page.canvas, offset);
    return painter.size.height;
  }

  bool _hasSpace(double height) {
    return _current.y + height <= pageHeight - bottom - footerHeight;
  }

  void _ensureSpace(double height) {
    if (!_hasSpace(height)) {
      _startPage();
    }
  }

  void _startPage() {
    final page = _CanvasPage(
      width: pageWidth.toInt(),
      height: pageHeight.toInt(),
    );
    page.canvas.drawRect(
      Rect.fromLTWH(0, 0, pageWidth, pageHeight),
      Paint()..color = Colors.white,
    );
    page.y = top + 108;
    _pages.add(page);
    _currentPage = page;

    if (_pages.length > 1) {
      _drawText(
        page,
        report.reportTypeLabel,
        Offset(left, top + 4),
        style: _style(16, bold: true, color: const Color(0xFF0E2A5C)),
        maxWidth: 320,
      );
      _drawText(
        page,
        _businessName,
        Offset(left, top + 28),
        style: _style(12, color: const Color(0xFF667085)),
        maxWidth: 320,
      );
      page.canvas.drawLine(
        Offset(left, top + 68),
        Offset(pageWidth - right, top + 68),
        Paint()
          ..color = const Color(0xFFE5E7EB)
          ..strokeWidth = 1,
      );
      page.y = top + 86;
    }
  }

  _CanvasPage get _current => _currentPage!;

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day.$month.$year';
  }
}

enum _SectionTone {
  risk(
    backgroundColor: Color(0xFFFFF7ED),
    borderColor: Color(0xFFFED7AA),
    titleColor: Color(0xFF9A3412),
    bulletColor: Color(0xFFEA580C),
  ),
  action(
    backgroundColor: Color(0xFFF5F9FF),
    borderColor: Color(0xFFD8E5FF),
    titleColor: Color(0xFF112E67),
    bulletColor: Color(0xFFD4A53A),
  );

  const _SectionTone({
    required this.backgroundColor,
    required this.borderColor,
    required this.titleColor,
    required this.bulletColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;
  final Color bulletColor;
}

class _CanvasPage {
  _CanvasPage({
    required this.width,
    required this.height,
  })  : recorder = ui.PictureRecorder(),
        y = 0;

  final int width;
  final int height;
  final ui.PictureRecorder recorder;
  late final Canvas canvas = Canvas(recorder);
  double y;

  Future<_RenderedPdfPage> toRenderedPage() async {
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw Exception('PDF sayfası görsele dönüştürülemedi.');
    }
    final rgba = byteData.buffer.asUint8List();
    final rgb = Uint8List(width * height * 3);
    var rgbIndex = 0;
    for (var i = 0; i < rgba.length; i += 4) {
      rgb[rgbIndex++] = rgba[i];
      rgb[rgbIndex++] = rgba[i + 1];
      rgb[rgbIndex++] = rgba[i + 2];
    }
    return _RenderedPdfPage(width: width, height: height, rgbBytes: rgb);
  }
}

class _BinaryPdfBuilder {
  Uint8List build(List<_RenderedPdfPage> pages) {
    final objects = <_PdfObject>[];
    final pageRefs = <int>[];
    var nextId = 1;

    for (final page in pages) {
      final imageId = nextId++;
      final contentId = nextId++;
      final pageId = nextId++;
      pageRefs.add(pageId);

      objects.add(
        _PdfObject.binary(
          id: imageId,
          header:
              '<< /Type /XObject /Subtype /Image /Width ${page.width} /Height ${page.height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Length ${page.rgbBytes.length} >>',
          streamBytes: page.rgbBytes,
        ),
      );

      final content = 'q\n595 0 0 842 0 0 cm\n/Im$pageId Do\nQ\n';
      objects.add(
        _PdfObject.text(
          contentId,
          '<< /Length ${content.codeUnits.length} >>\nstream\n$content\nendstream',
        ),
      );

      objects.add(
        _PdfObject.text(
          pageId,
          '<< /Type /Page /Parent ${nextId + (pages.length - pageRefs.length)} 0 R /MediaBox [0 0 595 842] /Resources << /XObject << /Im$pageId $imageId 0 R >> >> /Contents $contentId 0 R >>',
        ),
      );
    }

    final pagesId = nextId++;
    final catalogId = nextId++;

    for (final object in objects) {
      if (object.id != pageRefs.last) {
        continue;
      }
    }

    final fixedObjects = objects.map((object) {
      if (!pageRefs.contains(object.id)) {
        return object;
      }
      final contentId = object.id - 1;
      final imageId = object.id - 2;
      return _PdfObject.text(
        object.id,
        '<< /Type /Page /Parent $pagesId 0 R /MediaBox [0 0 595 842] /Resources << /XObject << /Im${object.id} $imageId 0 R >> >> /Contents $contentId 0 R >>',
      );
    }).toList();

    fixedObjects.add(
      _PdfObject.text(
        pagesId,
        '<< /Type /Pages /Count ${pageRefs.length} /Kids [${pageRefs.map((id) => '$id 0 R').join(' ')}] >>',
      ),
    );
    fixedObjects.add(
      _PdfObject.text(catalogId, '<< /Type /Catalog /Pages $pagesId 0 R >>'),
    );

    final builder = BytesBuilder();
    final offsets = <int>[0];
    _writeAscii(builder, '%PDF-1.4\n');

    for (final object in fixedObjects) {
      offsets.add(builder.length);
      _writeAscii(builder, '${object.id} 0 obj\n');
      if (object.streamBytes != null) {
        _writeAscii(builder, '${object.header}\nstream\n');
        builder.add(object.streamBytes!);
        _writeAscii(builder, '\nendstream\nendobj\n');
      } else {
        _writeAscii(builder, '${object.text!}\nendobj\n');
      }
    }

    final xrefOffset = builder.length;
    _writeAscii(builder, 'xref\n0 ${catalogId + 1}\n');
    _writeAscii(builder, '0000000000 65535 f \n');
    for (var i = 1; i <= catalogId; i++) {
      final offset = offsets[i];
      _writeAscii(builder, '${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    _writeAscii(
      builder,
      'trailer\n<< /Size ${catalogId + 1} /Root $catalogId 0 R >>\nstartxref\n$xrefOffset\n%%EOF',
    );
    return builder.toBytes();
  }

  void _writeAscii(BytesBuilder builder, String value) {
    builder.add(Uint8List.fromList(value.codeUnits));
  }
}

class _PdfObject {
  const _PdfObject._({
    required this.id,
    this.text,
    this.header,
    this.streamBytes,
  });

  factory _PdfObject.text(int id, String text) {
    return _PdfObject._(id: id, text: text);
  }

  factory _PdfObject.binary({
    required int id,
    required String header,
    required Uint8List streamBytes,
  }) {
    return _PdfObject._(
      id: id,
      header: header,
      streamBytes: streamBytes,
    );
  }

  final int id;
  final String? text;
  final String? header;
  final Uint8List? streamBytes;
}

String localizeTechnicalTerms(String text) {
  return text
      .replaceAll('pending_receivables', 'bekleyen tahsilatlar')
      .replaceAll('overdue_receivables', 'vadesi geçmiş tahsilatlar')
      .replaceAll('cash_score', 'nakit skoru')
      .replaceAll('net_cash_30d', '30 günlük net nakit durumu')
      .replaceAll('critical_stock_count', 'kritik stoktaki ürün sayısı')
      .replaceAll('out_of_stock_count', 'stokta olmayan ürün sayısı')
      .replaceAll('report_type', 'rapor türü')
      .replaceAll('support_type', 'destek türü')
      .replaceAll('eligibility_score', 'uygunluk skoru')
      .replaceAll('profile_completion', 'profil tamamlanma oranı');
}
