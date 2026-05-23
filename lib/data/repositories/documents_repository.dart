import 'dart:math';
import 'dart:typed_data';

import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/documents/document_calculations.dart';
import '../models/business_document_model.dart';
import '../models/business_profile_model.dart';
import '../models/document_requirement_model.dart';
import '../models/support_analysis_result_model.dart';
import 'business_profile_repository.dart';
import 'support_analysis_repository.dart';

class DocumentsRepository {
  DocumentsRepository({
    SupabaseClient? client,
    BusinessProfileRepository? businessProfileRepository,
    SupportAnalysisRepository? supportAnalysisRepository,
  })  : _client = client ?? Supabase.instance.client,
        _businessProfileRepository =
            businessProfileRepository ?? BusinessProfileRepository(client: client),
        _supportAnalysisRepository =
            supportAnalysisRepository ?? SupportAnalysisRepository(client: client);

  static const bucketName = 'business-documents';

  final SupabaseClient _client;
  final BusinessProfileRepository _businessProfileRepository;
  final SupportAnalysisRepository _supportAnalysisRepository;

  Future<List<BusinessDocumentModel>> fetchDocuments() async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('business_documents')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((row) => BusinessDocumentModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (_isDocumentsTablesMissing(error)) {
        return const [];
      }
      throw Exception('Belgeler alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Belgeler alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<BusinessDocumentModel?> getDocumentById(String id) async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('business_documents')
          .select()
          .eq('id', id)
          .eq('user_id', user.id)
          .maybeSingle();
      return data == null ? null : BusinessDocumentModel.fromJson(data);
    } on PostgrestException catch (error) {
      if (_isDocumentsTablesMissing(error)) {
        return null;
      }
      throw Exception('Belge alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Belge alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<BusinessDocumentModel> addDocument(BusinessDocumentModel document) async {
    final user = _requireUser();
    try {
      final profile = await _businessProfileRepository.fetchMyBusinessProfile();
      final payload = document
          .copyWith(
            userId: user.id,
            businessProfileId: _resolveBusinessProfileId(profile),
            status: _deriveStatus(document),
            updatedAt: DateTime.now(),
          )
          .toJson()
        ..remove('created_at')
        ..remove('updated_at');
      if ((payload['id']?.toString().isEmpty ?? true)) {
        payload.remove('id');
      }

      final data = await _client.from('business_documents').insert(payload).select().single();
      return BusinessDocumentModel.fromJson(data);
    } on PostgrestException catch (error) {
      throw Exception('Belge kaydedilemedi. ${error.message}');
    } catch (_) {
      throw Exception('Belge kaydedilemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<BusinessDocumentModel> updateDocument(BusinessDocumentModel document) async {
    final user = _requireUser();
    try {
      final payload = document
          .copyWith(
            userId: user.id,
            status: _deriveStatus(document),
            updatedAt: DateTime.now(),
          )
          .toJson()
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _client
          .from('business_documents')
          .update(payload)
          .eq('id', document.id)
          .eq('user_id', user.id)
          .select()
          .single();
      return BusinessDocumentModel.fromJson(data);
    } on PostgrestException catch (error) {
      throw Exception('Belge güncellenemedi. ${error.message}');
    } catch (_) {
      throw Exception('Belge güncellenemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<void> deleteDocument(String id) async {
    final document = await getDocumentById(id);
    if (document == null) {
      return;
    }
    await deleteDocumentFile(document);
  }

  Future<List<BusinessDocumentModel>> fetchDocumentsByType(String documentType) async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('business_documents')
          .select()
          .eq('user_id', user.id)
          .eq('document_type', documentType)
          .order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((row) => BusinessDocumentModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (_isDocumentsTablesMissing(error)) {
        return const [];
      }
      throw Exception('Belge listesi alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Belge listesi alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<List<BusinessDocumentModel>> fetchExpiredDocuments() async {
    final documents = await fetchDocuments();
    return documents.where((document) => document.isExpired).toList();
  }

  Future<List<BusinessDocumentModel>> fetchWillExpireDocuments() async {
    final documents = await fetchDocuments();
    return documents.where((document) => document.willExpireSoon).toList();
  }

  Future<BusinessDocumentModel> uploadDocumentFile({
    required String title,
    required String documentType,
    required String category,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? issuer,
    String? referenceNumber,
    String? notes,
    List<String> tags = const [],
  }) async {
    final user = _requireUser();
    final profile = await _businessProfileRepository.fetchMyBusinessProfile();
    final now = DateTime.now();
    final documentId = const Uuid().v4();
    final safeFileName = buildSafeFileName(fileName);
    final path = '${user.id}/$documentId/$safeFileName';

    try {
      await _client.storage.from(bucketName).uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: mimeType.isEmpty ? 'application/octet-stream' : mimeType,
              upsert: true,
            ),
          );

      final document = BusinessDocumentModel(
        id: documentId,
        userId: user.id,
        businessProfileId: _resolveBusinessProfileId(profile),
        businessId: null,
        title: title,
        documentType: documentType,
        category: category,
        fileName: safeFileName,
        filePath: path,
        fileMimeType: mimeType,
        fileSizeBytes: fileBytes.lengthInBytes,
        status: _deriveStatus(
          BusinessDocumentModel.empty().copyWith(
            expiryDate: expiryDate,
            issueDate: issueDate,
            status: 'uploaded',
          ),
        ),
        issueDate: issueDate,
        expiryDate: expiryDate,
        issuer: issuer,
        referenceNumber: referenceNumber,
        notes: notes,
        tags: tags,
        sourceModule: 'manual',
        createdAt: now,
        updatedAt: now,
      );

      return await addDocument(document);
    } on StorageException catch (error) {
      throw Exception('Belge dosyası yüklenemedi. ${error.message}');
    } on PostgrestException catch (error) {
      await _safeRemoveStorageFile(path);
      throw Exception('Belge kaydı oluşturulamadı. ${error.message}');
    } catch (_) {
      await _safeRemoveStorageFile(path);
      throw Exception('Belge yüklenemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<void> deleteDocumentFile(BusinessDocumentModel document) async {
    final user = _requireUser();
    try {
      if (document.filePath != null && document.filePath!.trim().isNotEmpty) {
        await _client.storage.from(bucketName).remove([document.filePath!.trim()]);
      }
    } catch (_) {
      // Storage dosyası silinemese de metadata temizliği devam edebilir.
    }

    try {
      if (document.id.isNotEmpty) {
        await _client
            .from('business_documents')
            .delete()
            .eq('id', document.id)
            .eq('user_id', user.id);
      }
    } on PostgrestException catch (error) {
      throw Exception('Belge silinemedi. ${error.message}');
    } catch (_) {
      throw Exception('Belge silinemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<List<DocumentRequirementModel>> fetchRequirements() async {
    final user = _requireUser();
    try {
      await _syncGeneratedRequirements(user.id);
      final data = await _client
          .from('document_requirements')
          .select()
          .eq('user_id', user.id)
          .order('priority', ascending: false)
          .order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((row) => DocumentRequirementModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (_isDocumentsTablesMissing(error)) {
        return const [];
      }
      throw Exception('Belge ihtiyaçları alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Belge ihtiyaçları alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<List<DocumentRequirementModel>> fetchMissingRequirements() async {
    final requirements = await fetchRequirements();
    return requirements.where((item) => item.isMissing).toList();
  }

  Future<DocumentRequirementModel> addRequirement(DocumentRequirementModel requirement) async {
    final user = _requireUser();
    final profile = await _businessProfileRepository.fetchMyBusinessProfile();
    try {
      final payload = requirement
          .copyWith(
            userId: user.id,
            businessProfileId: _resolveBusinessProfileId(profile),
            updatedAt: DateTime.now(),
          )
          .toJson()
        ..remove('created_at')
        ..remove('updated_at');
      if ((payload['id']?.toString().isEmpty ?? true)) {
        payload.remove('id');
      }

      final data = await _client.from('document_requirements').insert(payload).select().single();
      return DocumentRequirementModel.fromJson(data);
    } on PostgrestException catch (error) {
      throw Exception('Belge ihtiyacı eklenemedi. ${error.message}');
    } catch (_) {
      throw Exception('Belge ihtiyacı eklenemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<DocumentRequirementModel> updateRequirement(DocumentRequirementModel requirement) async {
    final user = _requireUser();
    try {
      final payload = requirement.copyWith(updatedAt: DateTime.now()).toJson()
        ..remove('created_at')
        ..remove('updated_at');
      final data = await _client
          .from('document_requirements')
          .update(payload)
          .eq('id', requirement.id)
          .eq('user_id', user.id)
          .select()
          .single();
      return DocumentRequirementModel.fromJson(data);
    } on PostgrestException catch (error) {
      throw Exception('Belge ihtiyacı güncellenemedi. ${error.message}');
    } catch (_) {
      throw Exception('Belge ihtiyacı güncellenemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<DocumentRequirementModel> linkRequirementToDocument({
    required String requirementId,
    required String documentId,
  }) async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('document_requirements')
          .update({
            'linked_document_id': documentId,
            'status': 'uploaded',
          })
          .eq('id', requirementId)
          .eq('user_id', user.id)
          .select()
          .single();
      return DocumentRequirementModel.fromJson(data);
    } on PostgrestException catch (error) {
      throw Exception('Belge ihtiyacı ilişkilendirilemedi. ${error.message}');
    } catch (_) {
      throw Exception('Belge ihtiyacı ilişkilendirilemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<DocumentSummary> buildDocumentSummary() async {
    final documents = await fetchDocuments();
    final requirements = await fetchRequirements();
    final uploadedDocuments = countUploadedDocuments(documents);
    final missingRequirements = countMissingRequirements(requirements);
    final expiredDocuments = countExpiredDocuments(documents);
    final willExpireDocuments = countWillExpireDocuments(documents);
    final highPriorityMissing = countHighPriorityMissing(requirements);
    final supportReadyScore = calculateSupportReadinessScore(
      documents: documents,
      requirements: requirements,
    );

    return DocumentSummary(
      totalDocuments: documents.length,
      missingRequirements: missingRequirements,
      expiredDocuments: expiredDocuments,
      willExpireDocuments: willExpireDocuments,
      uploadedDocuments: uploadedDocuments,
      highPriorityMissing: highPriorityMissing,
      supportReadyScore: supportReadyScore,
      insight: generateDocumentAiInsight(
        documents: documents,
        requirements: requirements,
      ),
    );
  }

  Future<void> _syncGeneratedRequirements(String userId) async {
    final profile = await _businessProfileRepository.fetchMyBusinessProfile();
    SupportAnalysisResultModel? analysis;
    try {
      analysis = await _supportAnalysisRepository.fetchLatestAnalysis();
    } catch (_) {
      analysis = null;
    }

    List<dynamic> rows;
    try {
      rows = await _client
          .from('document_requirements')
          .select(
            'id, required_document_type, support_analysis_result_id, source_module, title',
          )
          .eq('user_id', userId);
    } on PostgrestException catch (error) {
      if (_isDocumentsTablesMissing(error)) {
        return;
      }
      rethrow;
    }

    final existingKeys = (rows)
        .map((row) => row as Map<String, dynamic>)
        .map(
          (row) => _requirementKey(
            row['required_document_type']?.toString() ?? '',
            row['support_analysis_result_id']?.toString(),
            row['source_module']?.toString(),
          ),
        )
        .toSet();

    final drafts = <DocumentRequirementModel>[
      ...generateDefaultRequirementsForProfile(profile),
      ...generateRequirementsFromSupportAnalysis(analysis),
    ];

    if (drafts.isEmpty) {
      return;
    }

    final profileId = _resolveBusinessProfileId(profile);
    final analysisId = analysis?.id;
    final inserts = <Map<String, dynamic>>[];

    for (final draft in drafts) {
      final key = _requirementKey(
        draft.requiredDocumentType,
        draft.sourceModule == 'support_analysis' ? analysisId : null,
        draft.sourceModule,
      );
      if (existingKeys.contains(key)) {
        continue;
      }
      existingKeys.add(key);
      inserts.add(
        draft
            .copyWith(
              userId: userId,
              businessProfileId: profileId,
              supportAnalysisResultId:
                  draft.sourceModule == 'support_analysis' ? analysisId : null,
            )
            .toJson()
          ..remove('created_at')
          ..remove('updated_at')
          ..remove('id'),
      );
    }

    if (inserts.isEmpty) {
      return;
    }

    await _client.from('document_requirements').insert(inserts);
  }

  Future<void> _safeRemoveStorageFile(String path) async {
    try {
      await _client.storage.from(bucketName).remove([path]);
    } catch (_) {}
  }

  String _deriveStatus(BusinessDocumentModel document) {
    if (document.expiryDate == null) {
      return document.status;
    }
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    if (document.expiryDate!.isBefore(date)) {
      return 'expired';
    }
    if (!document.expiryDate!.isAfter(date.add(const Duration(days: 30)))) {
      return 'will_expire';
    }
    return document.status == 'missing' ? 'uploaded' : document.status;
  }

  String _requirementKey(String type, String? analysisId, String? sourceModule) {
    return '$type|${analysisId ?? ''}|${sourceModule ?? ''}';
  }

  String? _resolveBusinessProfileId(BusinessProfileModel? profile) {
    if (profile == null) {
      return null;
    }
    final id = profile.id.trim();
    return id.isEmpty ? null : id;
  }

  bool _isDocumentsTablesMissing(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST205' ||
        message.contains('business_documents') ||
        message.contains('document_requirements');
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return user;
  }
}

class DocumentSummary {
  const DocumentSummary({
    required this.totalDocuments,
    required this.missingRequirements,
    required this.expiredDocuments,
    required this.willExpireDocuments,
    required this.uploadedDocuments,
    required this.highPriorityMissing,
    required this.supportReadyScore,
    required this.insight,
  });

  final int totalDocuments;
  final int missingRequirements;
  final int expiredDocuments;
  final int willExpireDocuments;
  final int uploadedDocuments;
  final int highPriorityMissing;
  final int supportReadyScore;
  final String insight;
}

class Uuid {
  const Uuid();

  String v4() => _randomUuid();
}

String _randomUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final values = bytes.map(hex).join();
  return '${values.substring(0, 8)}-'
      '${values.substring(8, 12)}-'
      '${values.substring(12, 16)}-'
      '${values.substring(16, 20)}-'
      '${values.substring(20, 32)}';
}

String buildSafeFileName(String fileName) {
  final trimmed = fileName.trim().isEmpty ? 'belge' : fileName.trim();
  final normalized = trimmed
      .replaceAll('ç', 'c')
      .replaceAll('Ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('Ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('Ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('Ş', 's')
      .replaceAll('ü', 'u')
      .replaceAll('Ü', 'u')
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return normalized.replaceAll('..', '.').replaceAll('/', '_').replaceAll('\\', '_');
}
