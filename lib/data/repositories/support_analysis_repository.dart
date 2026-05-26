import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/support/support_analysis_engine.dart';
import '../models/business_profile_model.dart';
import '../models/support_analysis_result_model.dart';
import '../models/support_checklist_item_model.dart';
import '../models/support_opportunity_model.dart';
import 'business_profile_repository.dart';

class SupportAnalysisRepository {
  SupportAnalysisRepository({
    SupabaseClient? client,
    BusinessProfileRepository? businessProfileRepository,
  })  : _client = client ?? Supabase.instance.client,
        _businessProfileRepository =
            businessProfileRepository ?? BusinessProfileRepository(client: client);

  final SupabaseClient _client;
  final BusinessProfileRepository _businessProfileRepository;

  Future<SupportAnalysisResultModel?> fetchLatestAnalysis() async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('support_analysis_results')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) {
        return null;
      }
      return SupportAnalysisResultModel.fromJson(data);
    } on PostgrestException catch (error) {
      if (_isSupportTablesMissing(error)) {
        return null;
      }
      throw Exception('Destek analizi alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Destek analizi alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<List<SupportAnalysisResultModel>> fetchAnalysisHistory() async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('support_analysis_results')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((row) => SupportAnalysisResultModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (_isSupportTablesMissing(error)) {
        return const [];
      }
      throw Exception('Destek analizi geçmişi alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Destek analizi geçmişi alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<SupportAnalysisResultModel> runSupportAnalysis() async {
    final user = _requireUser();
    try {
      final profile = await _businessProfileRepository.fetchMyBusinessProfile();
      final draft = analyzeSupportEligibility(profile);

      final resultPayload = {
        'user_id': user.id,
        'business_profile_id': _resolveBusinessProfileId(profile),
        'analysis_title': draft.analysisTitle,
        'overall_score': draft.overallScore,
        'overall_status': draft.overallStatus,
        'kosgeb_score': draft.kosgebScore,
        'tubitak_score': draft.tubitakScore,
        'export_support_score': draft.exportSupportScore,
        'certification_support_score': draft.certificationSupportScore,
        'digitalization_support_score': draft.digitalizationSupportScore,
        'financing_support_score': draft.financingSupportScore,
        'missing_profile_fields': draft.missingProfileFields,
        'missing_documents': draft.missingDocuments,
        'recommended_actions': draft.recommendedActions,
        'risk_notes': draft.riskNotes,
        'opportunity_notes': draft.opportunityNotes,
        'summary': draft.summary,
      };

      final inserted = await _client
          .from('support_analysis_results')
          .insert(resultPayload)
          .select()
          .single();
      final result = SupportAnalysisResultModel.fromJson(inserted);

      if (draft.opportunities.isNotEmpty) {
        await _client.from('support_opportunities').insert(
              draft.opportunities
                  .map(
                    (item) => {
                      'user_id': user.id,
                      'analysis_result_id': result.id,
                      'business_profile_id': _resolveBusinessProfileId(profile),
                      'support_type': item.supportType,
                      'title': item.title,
                      'description': item.description,
                      'eligibility_score': item.eligibilityScore,
                      'eligibility_status': item.eligibilityStatus,
                      'missing_requirements': item.missingRequirements,
                      'next_steps': item.nextSteps,
                      'priority': item.priority,
                    },
                  )
                  .toList(),
            );
      }

      if (draft.checklist.isNotEmpty) {
        await _client.from('support_checklist_items').insert(
              draft.checklist
                  .map(
                    (item) => {
                      'user_id': user.id,
                      'analysis_result_id': result.id,
                      'title': item.title,
                      'description': item.description,
                      'category': item.category,
                      'status': item.status,
                      'priority': item.priority,
                      'due_date': item.dueDate?.toIso8601String().split('T').first,
                    },
                  )
                  .toList(),
            );
      }

      return result;
    } on PostgrestException catch (error) {
      if (_isSupportTablesMissing(error)) {
        throw Exception(
          'Destek analizi altyapısı henüz hazır değil. Lütfen veritabanı migration dosyalarını uygulayın.',
        );
      }
      throw Exception('Destek analizi kaydedilemedi. ${error.message}');
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }
      throw Exception('Destek analizi hazırlanamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<List<SupportOpportunityModel>> fetchOpportunities(String analysisResultId) async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('support_opportunities')
          .select()
          .eq('user_id', user.id)
          .eq('analysis_result_id', analysisResultId)
          .order('eligibility_score', ascending: false);
      return (data as List<dynamic>)
          .map((row) => SupportOpportunityModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (_isSupportTablesMissing(error)) {
        return const [];
      }
      throw Exception('Destek fırsatları alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Destek fırsatları alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<List<SupportChecklistItemModel>> fetchChecklistItems(String analysisResultId) async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('support_checklist_items')
          .select()
          .eq('user_id', user.id)
          .eq('analysis_result_id', analysisResultId)
          .order('priority', ascending: false)
          .order('created_at');
      return (data as List<dynamic>)
          .map((row) => SupportChecklistItemModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (_isSupportTablesMissing(error)) {
        return const [];
      }
      throw Exception('Hazırlık kontrol listesi alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Hazırlık kontrol listesi alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<SupportChecklistItemModel> updateChecklistItemStatus(String id, String status) async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('support_checklist_items')
          .update({'status': status})
          .eq('id', id)
          .eq('user_id', user.id)
          .select()
          .single();
      return SupportChecklistItemModel.fromJson(data);
    } on PostgrestException catch (error) {
      throw Exception('Kontrol listesi güncellenemedi. ${error.message}');
    } catch (_) {
      throw Exception('Kontrol listesi güncellenemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<void> deleteAnalysis(String id) async {
    final user = _requireUser();
    try {
      await _client
          .from('support_analysis_results')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } on PostgrestException catch (error) {
      throw Exception('Destek analizi silinemedi. ${error.message}');
    } catch (_) {
      throw Exception('Destek analizi silinemedi. Lütfen tekrar deneyin.');
    }
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return user;
  }

  bool _isSupportTablesMissing(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST205' ||
        message.contains('support_analysis_results') ||
        message.contains('support_opportunities') ||
        message.contains('support_checklist_items');
  }

  String? _resolveBusinessProfileId(BusinessProfileModel? profile) {
    if (profile == null) {
      return null;
    }
    return profile.id.trim().isEmpty ? null : profile.id;
  }
}
