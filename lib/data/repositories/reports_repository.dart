import 'dart:typed_data';

import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/reports/report_generation_engine.dart';
import '../../features/reports/report_pdf_service.dart';
import '../models/business_report_model.dart';
import '../models/report_export_log_model.dart';
import '../models/report_section_model.dart';
import '../services/report_data_service.dart';

class ReportsRepository {
  ReportsRepository({
    SupabaseClient? client,
    ReportDataService? reportDataService,
    ReportPdfService? reportPdfService,
  })  : _client = client ?? Supabase.instance.client,
        _reportDataService = reportDataService ?? ReportDataService(client: client),
        _reportPdfService = reportPdfService ?? ReportPdfService(client: client);

  final SupabaseClient _client;
  final ReportDataService _reportDataService;
  final ReportPdfService _reportPdfService;

  Future<List<BusinessReportModel>> fetchReports() async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('business_reports')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((row) => BusinessReportModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (_isReportsTablesMissing(error)) {
        return const [];
      }
      throw Exception('Raporlar alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Raporlar alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<BusinessReportModel?> getReportById(String id) async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('business_reports')
          .select()
          .eq('id', id)
          .eq('user_id', user.id)
          .maybeSingle();
      return data == null ? null : BusinessReportModel.fromJson(data);
    } on PostgrestException catch (error) {
      if (_isReportsTablesMissing(error)) {
        return null;
      }
      throw Exception('Rapor alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Rapor alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<List<ReportSectionModel>> fetchReportSections(String reportId) async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('report_sections')
          .select()
          .eq('report_id', reportId)
          .eq('user_id', user.id)
          .order('sort_order');
      return (data as List<dynamic>)
          .map((row) => ReportSectionModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (_isReportsTablesMissing(error)) {
        return const [];
      }
      throw Exception('Rapor bölümleri alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Rapor bölümleri alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<BusinessReportModel> generateReport({
    required String reportType,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final user = _requireUser();
    try {
      final summary = await _reportDataService.buildReportSummary(
        start: periodStart,
        end: periodEnd,
      );
      final moduleData = await _buildModuleData(
        reportType: reportType,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      final draft = generateReportDraft(
        reportType: reportType,
        summary: summary,
        moduleData: moduleData,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      final profileData = moduleData['businessProfile'];
      final report = BusinessReportModel(
        id: '',
        userId: user.id,
        businessProfileId: profileData is Map<String, dynamic>
            ? profileData['id']?.toString()
            : null,
        businessId: null,
        reportType: reportType,
        title: draft.title,
        periodLabel: draft.periodLabel,
        periodStart: periodStart,
        periodEnd: periodEnd,
        status: 'ready',
        summary: draft.summary,
        keyFindings: draft.keyFindings,
        risks: draft.risks,
        opportunities: draft.opportunities,
        recommendedActions: draft.recommendedActions,
        reportData: {
          ...draft.reportData,
          'isletme_adi': profileData is Map<String, dynamic>
              ? profileData['isletme_adi']
              : null,
          'olusturma_notu': 'Bu rapor ön analiz ve karar destek amacıyla hazırlanmıştır.',
        },
        generatedAt: DateTime.now(),
        pdfFilePath: null,
        pdfFileName: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final sections = draft.sections
          .map(
            (item) => ReportSectionModel(
              id: '',
              userId: user.id,
              reportId: '',
              sectionKey: item.sectionKey,
              title: item.title,
              content: item.content,
              sortOrder: item.sortOrder,
              sectionData: item.sectionData,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
          .toList();

      return saveReport(report, sections);
    } on AuthException {
      rethrow;
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Rapor oluşturulamadı. Lütfen verilerinizi kontrol edip tekrar deneyin.');
    }
  }

  Future<BusinessReportModel> saveReport(
    BusinessReportModel report,
    List<ReportSectionModel> sections,
  ) async {
    final user = _requireUser();
    try {
      final payload = report.copyWith(userId: user.id, updatedAt: DateTime.now()).toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');

      final inserted = await _client.from('business_reports').insert(payload).select().single();
      final savedReport = BusinessReportModel.fromJson(inserted);

      if (sections.isNotEmpty) {
        final sectionPayload = sections
            .map(
              (item) => item
                  .copyWith(
                    userId: user.id,
                    reportId: savedReport.id,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  )
                  .toJson()
                ..remove('id')
                ..remove('created_at')
                ..remove('updated_at'),
            )
            .toList();
        await _client.from('report_sections').insert(sectionPayload);
      }

      return savedReport;
    } on PostgrestException catch (error) {
      if (_isReportsTablesMissing(error)) {
        throw Exception(
          'Rapor altyapısı henüz hazır değil. Lütfen veritabanı migration dosyalarını uygulayın.',
        );
      }
      throw Exception('Rapor kaydedilemedi. ${error.message}');
    } catch (_) {
      throw Exception('Rapor kaydedilemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<BusinessReportModel> updateReport(BusinessReportModel report) async {
    final user = _requireUser();
    try {
      final payload = report.copyWith(updatedAt: DateTime.now()).toJson()
        ..remove('created_at')
        ..remove('updated_at');
      final data = await _client
          .from('business_reports')
          .update(payload)
          .eq('id', report.id)
          .eq('user_id', user.id)
          .select()
          .single();
      return BusinessReportModel.fromJson(data);
    } on PostgrestException catch (error) {
      throw Exception('Rapor güncellenemedi. ${error.message}');
    } catch (_) {
      throw Exception('Rapor güncellenemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<void> deleteReport(String id) async {
    final user = _requireUser();
    try {
      final report = await getReportById(id);
      if (report?.pdfFilePath != null && report!.pdfFilePath!.trim().isNotEmpty) {
        await _safeRemoveStorageFile(report.pdfFilePath!);
      }
      await _client.from('business_reports').delete().eq('id', id).eq('user_id', user.id);
    } on PostgrestException catch (error) {
      throw Exception('Rapor silinemedi. ${error.message}');
    } catch (_) {
      throw Exception('Rapor silinemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<void> archiveReport(String id) async {
    final report = await getReportById(id);
    if (report == null) {
      return;
    }
    await updateReport(report.copyWith(status: 'archived'));
  }

  Future<Uint8List> buildReportPdf(
    BusinessReportModel report,
    List<ReportSectionModel> sections,
  ) {
    return _reportPdfService.buildPdf(report, sections);
  }

  Future<BusinessReportModel> exportReportToPdf(String reportId) async {
    final user = _requireUser();
    final report = await getReportById(reportId);
    if (report == null) {
      throw Exception('Rapor bulunamadı.');
    }
    try {
      final sections = await fetchReportSections(reportId);
      final pdfBytes = await buildReportPdf(report, sections);
      final fileName = _reportPdfService.buildPdfFileName(report);
      final path = await _reportPdfService.savePdfToStorage(
        userId: user.id,
        reportId: report.id,
        fileName: fileName,
        bytes: pdfBytes,
      );
      final updated = await updateReport(
        report.copyWith(
          pdfFilePath: path,
          pdfFileName: fileName,
          generatedAt: DateTime.now(),
          status: 'ready',
        ),
      );
      await logReportExport(
        reportId: report.id,
        exportType: 'pdf',
        filePath: path,
        status: 'success',
      );
      return updated;
    } on StorageException catch (error) {
      await logReportExport(
        reportId: report.id,
        exportType: 'pdf',
        filePath: null,
        status: 'failed',
        errorMessage: error.message,
      );
      throw Exception('PDF oluşturuldu ancak depoya kaydedilemedi. ${error.message}');
    } catch (error) {
      await logReportExport(
        reportId: report.id,
        exportType: 'pdf',
        filePath: null,
        status: 'failed',
        errorMessage: error.toString(),
      );
      throw Exception('PDF oluşturulamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<void> logReportExport({
    required String? reportId,
    required String exportType,
    required String? filePath,
    required String status,
    String? errorMessage,
  }) async {
    final user = _requireUser();
    try {
      await _client.from('report_export_logs').insert({
        'user_id': user.id,
        'report_id': reportId,
        'export_type': exportType,
        'file_path': filePath,
        'status': status,
        'error_message': errorMessage,
      });
    } on PostgrestException catch (error) {
      if (_isReportsTablesMissing(error)) {
        return;
      }
      rethrow;
    } catch (_) {}
  }

  Future<List<ReportExportLogModel>> fetchExportLogs(String reportId) async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('report_export_logs')
          .select()
          .eq('user_id', user.id)
          .eq('report_id', reportId)
          .order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((row) => ReportExportLogModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (_isReportsTablesMissing(error)) {
        return const [];
      }
      throw Exception('Rapor geçmişi alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Rapor geçmişi alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<String> createPdfDownloadUrl(String filePath) {
    return _client.storage.from(ReportPdfService.bucketName).createSignedUrl(filePath, 60);
  }

  Future<Map<String, dynamic>> _buildModuleData({
    required String reportType,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final businessProfile =
        await _reportDataService.buildBusinessProfileData(start: periodStart, end: periodEnd);
    final financial =
        await _reportDataService.buildFinancialData(start: periodStart, end: periodEnd);
    final cashflow =
        await _reportDataService.buildCashflowData(start: periodStart, end: periodEnd);
    final customerRisk =
        await _reportDataService.buildCustomerRiskData(start: periodStart, end: periodEnd);
    final inventoryRisk =
        await _reportDataService.buildInventoryRiskData(start: periodStart, end: periodEnd);
    final support =
        await _reportDataService.buildSupportData(start: periodStart, end: periodEnd);
    final documents =
        await _reportDataService.buildDocumentData(start: periodStart, end: periodEnd);

    return {
      'reportType': reportType,
      'businessProfile': businessProfile,
      'financial': financial,
      'cashflow': cashflow,
      'customerRisk': customerRisk,
      'inventoryRisk': inventoryRisk,
      'support': support,
      'documents': documents,
    };
  }

  Future<void> _safeRemoveStorageFile(String path) async {
    try {
      await _client.storage.from(ReportPdfService.bucketName).remove([path]);
    } catch (_) {}
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return user;
  }

  bool _isReportsTablesMissing(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST205' ||
        message.contains('business_reports') ||
        message.contains('report_sections') ||
        message.contains('report_export_logs');
  }
}
