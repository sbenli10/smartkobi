import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/draft_transaction_model.dart';

class VoiceAssistantService {
  VoiceAssistantService({
    SpeechToText? speechToText,
    FlutterTts? flutterTts,
    SupabaseClient? supabaseClient,
  })  : _speechToText = speechToText ?? SpeechToText(),
        _flutterTts = flutterTts ?? FlutterTts(),
        _supabaseClient = supabaseClient ?? Supabase.instance.client;

  final SpeechToText _speechToText;
  final FlutterTts _flutterTts;
  final SupabaseClient _supabaseClient;

  bool _ttsInitialized = false;

  bool get isListening => _speechToText.isListening;

  Future<bool> initializeSpeech() async {
    return _speechToText.initialize(
      onError: _handleSpeechError,
      debugLogging: false,
    );
  }

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        final text = result.recognizedWords.trim();
        if (text.isNotEmpty) {
          onResult(text, result.finalResult);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: 'tr_TR',
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  Future<DraftTransactionModel> processVoiceCommand(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('Ses algılanamadı. Lütfen tekrar deneyin.');
    }

    final response = await _supabaseClient.functions.invoke(
      'process-voice-command',
      body: {'text': trimmed},
    );

    if (response.status != 200) {
      final data = response.data;
      final errorMessage = data is Map<String, dynamic>
          ? data['error']?.toString()
          : null;
      throw Exception(errorMessage ?? 'Sesli komut çözümlenemedi.');
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Sesli komut yanıtı geçersiz.');
    }

    final draft = DraftTransactionModel.fromJson(data);
    if (draft.isFinanceOnly && draft.amount <= 0) {
      throw Exception('Tutarı anlayamadım. Lütfen tekrar söyleyin.');
    }
    if (draft.isProductOperation &&
        draft.productName.trim().isEmpty &&
        (draft.quantity == null || draft.quantity! <= 0) &&
        (draft.totalAmount == null || draft.totalAmount! <= 0)) {
      throw Exception('Ürün bilgisini anlayamadım. Lütfen tekrar söyleyin.');
    }

    return draft;
  }

  Future<void> initializeTts() async {
    if (_ttsInitialized) {
      return;
    }

    await _flutterTts.setLanguage('tr-TR');
    await _flutterTts.setSpeechRate(0.42);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true);
    _ttsInitialized = true;
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await initializeTts();
    await _flutterTts.stop();
    await _flutterTts.speak(trimmed);
  }

  Future<void> dispose() async {
    await stopListening();
    await _flutterTts.stop();
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (error.permanent) return;
  }
}
