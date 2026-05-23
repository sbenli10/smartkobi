import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/ai/advisor_fallback_engine.dart';
import '../../features/ai/advisor_scope_guard.dart';
import '../models/ai_advisor_response_model.dart';
import '../models/ai_conversation_model.dart';
import '../models/ai_message_model.dart';
import '../models/business_context_summary_model.dart';
import '../services/business_context_service.dart';

class AiAdvisorRepository {
  AiAdvisorRepository({
    SupabaseClient? client,
    BusinessContextService? contextService,
  })  : _client = client ?? Supabase.instance.client,
        _contextService =
            contextService ?? BusinessContextService(client: client ?? Supabase.instance.client);

  final SupabaseClient _client;
  final BusinessContextService _contextService;

  Future<AiConversationModel> createConversation({
    String? title,
    String topic = 'general',
  }) async {
    try {
      final user = _requireUser();
      final now = DateTime.now();
      final payload = {
        'user_id': user.id,
        'title': title?.trim().isNotEmpty == true
            ? title!.trim()
            : 'Yeni Danışman Görüşmesi',
        'topic': topic,
        'last_message_at': now.toIso8601String(),
      };
      final data = await _client.from('ai_conversations').insert(payload).select().single();
      return AiConversationModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Danışman görüşmesi oluşturulamadı. ${e.message}');
    } catch (_) {
      throw Exception('Danışman görüşmesi oluşturulurken bir sorun oluştu.');
    }
  }

  Future<List<AiConversationModel>> fetchConversations() async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('ai_conversations')
          .select()
          .eq('user_id', user.id)
          .order('last_message_at', ascending: false)
          .order('updated_at', ascending: false);
      return (data as List<dynamic>)
          .map((item) => AiConversationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Görüşmeler alınamadı. ${e.message}');
    } catch (_) {
      throw Exception('Görüşmeler alınırken bir sorun oluştu.');
    }
  }

  Future<List<AiMessageModel>> fetchMessages(String conversationId) async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('ai_messages')
          .select()
          .eq('user_id', user.id)
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      return (data as List<dynamic>)
          .map((item) => AiMessageModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Mesajlar alınamadı. ${e.message}');
    } catch (_) {
      throw Exception('Mesajlar alınırken bir sorun oluştu.');
    }
  }

  Future<AiMessageModel> addMessage(AiMessageModel message) async {
    try {
      final user = _requireUser();
      final payload = message.copyWith(userId: user.id).toJson()
        ..remove('id')
        ..remove('created_at');
      final data = await _client.from('ai_messages').insert(payload).select().single();
      return AiMessageModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Mesaj kaydedilemedi. ${e.message}');
    } catch (_) {
      throw Exception('Mesaj kaydı sırasında bir sorun oluştu.');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      final user = _requireUser();
      await _client
          .from('ai_conversations')
          .delete()
          .eq('id', conversationId)
          .eq('user_id', user.id);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Görüşme silinemedi. ${e.message}');
    } catch (_) {
      throw Exception('Görüşme silinirken bir sorun oluştu.');
    }
  }

  Future<AiAdvisorResponseModel> askAdvisor({
    required String question,
    String? conversationId,
    String topic = 'general',
  }) async {
    final user = _requireUser();
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) {
      throw Exception('Lütfen bir soru yazın.');
    }

    final scope = classifyAdvisorQuestion(trimmedQuestion);
    final scopedModule = advisorTopicToModule(scope.topic);

    var conversation = conversationId == null
        ? await createConversation(
            title: _buildConversationTitle(trimmedQuestion),
            topic: scopedModule,
          )
        : await _ensureConversation(conversationId);

    await addMessage(
      AiMessageModel(
        id: '',
        userId: user.id,
        conversationId: conversation.id,
        businessId: conversation.businessId,
        role: 'user',
        content: trimmedQuestion,
        messageType: 'text',
        metadata: {
          'scopeDecision': scope.decision.name,
          'scopeTopic': scope.topic.name,
          'scopeConfidence': scope.confidence,
          'scopeReason': scope.reason,
        },
        createdAt: DateTime.now(),
      ),
    );

    if (scope.decision == AdvisorScopeDecision.outOfScope) {
      final response = buildOutOfScopeResponse(trimmedQuestion);
      await _saveAssistantReply(
        userId: user.id,
        conversation: conversation,
        question: trimmedQuestion,
        topic: 'general',
        response: response,
        usedFallback: true,
      );
      return response;
    }

    if (scope.decision == AdvisorScopeDecision.ambiguous) {
      final response = buildAmbiguousResponse(trimmedQuestion);
      await _saveAssistantReply(
        userId: user.id,
        conversation: conversation,
        question: trimmedQuestion,
        topic: 'general',
        response: response,
        usedFallback: true,
      );
      return response;
    }

    final context = await _contextService.buildContextSummary();
    final history = await fetchMessages(conversation.id);
    final recentHistory = history
        .where((message) => message.role != 'system')
        .toList()
        .reversed
        .take(8)
        .toList()
        .reversed
        .map(
          (message) => {
            'role': message.role,
            'content': message.content,
          },
        )
        .toList();

    var usedFallback = false;
    AiAdvisorResponseModel response;

    try {
      final result = await _client.functions.invoke(
        'ai-business-advisor',
        body: {
          'question': trimmedQuestion,
          'topic': scopedModule,
          'context': context.toJson(),
          'conversationHistory': recentHistory,
        },
      );

      final rawData = result.data;
      final data = rawData is Map<String, dynamic>
          ? rawData
          : rawData is Map
              ? Map<String, dynamic>.from(rawData)
              : null;

      if (data == null || (data['answer']?.toString().trim().isEmpty ?? true)) {
        throw Exception('AI yanıtı boş döndü.');
      }

      response = AiAdvisorResponseModel(
        answer: data['answer']?.toString() ?? '',
        riskLevel: data['riskLevel']?.toString() ?? 'medium',
        suggestedActions: (data['suggestedActions'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
        relatedModule: data['relatedModule']?.toString() ?? scopedModule,
        usedFallback: false,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      usedFallback = true;
      response = generateFallbackAdvisorResponse(
        question: trimmedQuestion,
        context: context,
      );
    }

    await _saveAssistantReply(
      userId: user.id,
      conversation: conversation,
      question: trimmedQuestion,
      topic: scopedModule,
      response: response,
      usedFallback: usedFallback || response.usedFallback,
    );

    return response;
  }

  Future<BusinessContextSummaryModel> buildContextSummary() {
    return _contextService.buildContextSummary();
  }

  Future<void> _saveAssistantReply({
    required String userId,
    required AiConversationModel conversation,
    required String question,
    required String topic,
    required AiAdvisorResponseModel response,
    required bool usedFallback,
  }) async {
    await addMessage(
      AiMessageModel(
        id: '',
        userId: userId,
        conversationId: conversation.id,
        businessId: conversation.businessId,
        role: 'assistant',
        content: response.answer,
        messageType: _resolveAssistantMessageType(response),
        metadata: {
          'riskLevel': response.riskLevel,
          'relatedModule': response.relatedModule,
          'suggestedActions': response.suggestedActions,
          'usedFallback': usedFallback,
        },
        createdAt: DateTime.now(),
      ),
    );

    await _client
        .from('ai_conversations')
        .update({
          'last_message_preview': response.answer.length > 140
              ? '${response.answer.substring(0, 140)}...'
              : response.answer,
          'last_message_at': DateTime.now().toIso8601String(),
          'topic': topic,
          'title': conversation.title == 'Yeni Danışman Görüşmesi'
              ? _buildConversationTitle(question)
              : conversation.title,
        })
        .eq('id', conversation.id)
        .eq('user_id', userId);
  }

  Future<AiConversationModel> _ensureConversation(String conversationId) async {
    final user = _requireUser();
    final data = await _client
        .from('ai_conversations')
        .select()
        .eq('id', conversationId)
        .eq('user_id', user.id)
        .maybeSingle();
    if (data == null) {
      throw Exception('Danışman görüşmesi bulunamadı.');
    }
    return AiConversationModel.fromJson(data);
  }

  String _buildConversationTitle(String question) {
    final trimmed = question.trim();
    if (trimmed.length <= 48) {
      return trimmed;
    }
    return '${trimmed.substring(0, 48)}...';
  }

  String _resolveAssistantMessageType(AiAdvisorResponseModel response) {
    if (response.riskLevel == 'high' || response.riskLevel == 'critical') {
      return 'warning';
    }
    if (response.suggestedActions.isNotEmpty) {
      return 'action';
    }
    return 'insight';
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return user;
  }
}
