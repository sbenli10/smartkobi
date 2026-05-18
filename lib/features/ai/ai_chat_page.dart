//lib\features\ai\ai_chat_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _supabase = Supabase.instance.client;
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  bool _loading = true;
  bool _isPremium = false;
  bool _sending = false;

  String? _businessId;
  String? _currentThreadId;

  String _mode = "cfo"; // cfo|growth|risk|ops
  final List<_ChatMsg> _messages = [];

  Timer? _scrollTimer;

  static const _supabaseUrl = "https://mgeenfliuqqrbizqndnu.supabase.co";

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    debugPrint("[AI] bootstrap_start");
    setState(() => _loading = true);

    final businessId = await _getBusinessId();
    _businessId = businessId;

    if (businessId == null) {
      setState(() {
        _isPremium = false;
        _loading = false;
      });
      return;
    }

    final business = await _supabase
        .from('businesses')
        .select('plan')
        .eq('id', businessId)
        .maybeSingle();

    final premium = business != null && business['plan'] == 'premium';
    
    setState(() {
      _isPremium = premium;
      _loading = false;
    });

    debugPrint("[AI] premium=$_isPremium business=$_businessId");

    if (!premium) return;

    // ✅ Son thread auto-restore (yoksa create)
    _currentThreadId = await _restoreOrCreateThread(mode: _mode);

    // ✅ Mesajları yükle
    await _loadRecentMessages(limit: 50);
  }

  Future<String?> _getBusinessId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final res = await _supabase
        .from('user_business_roles')
        .select('business_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    return res?['business_id']?.toString();
  }

  Future<String> _restoreOrCreateThread({required String mode}) async {
    final businessId = _businessId;
    final user = _supabase.auth.currentUser;
    if (businessId == null || user == null) {
      throw Exception("businessId veya user yok");
    }

    final last = await _supabase
    .from('ai_chat_threads')
    .select('id,mode,last_message_at,created_at')
    .eq('business_id', businessId)
    .eq('created_by', user.id)
    .eq('mode', mode)
    .order('last_message_at', ascending: false)
    .order('created_at', ascending: false)
    .limit(1)
    .maybeSingle();

if (last != null && last['id'] != null) {
  debugPrint("[AI] restored_thread=${last['id']}");
  return last['id'].toString();
}
    // 2) Yoksa create
    final created = await _supabase
        .from('ai_chat_threads')
        .insert({
          "business_id": businessId,
          "created_by": user.id,
          "mode": mode,
          "last_message_at": DateTime.now().toUtc().toIso8601String(),
        })
        .select('id')
        .single();

        debugPrint("[AI] created_thread=${created['id']}");

    return created['id'].toString();
  }

  Future<void> _loadRecentMessages({int limit = 30}) async {
    final businessId = _businessId;
    final threadId = _currentThreadId;
    if (businessId == null || threadId == null) return;

    final rows = await _supabase
        .from('ai_chat_messages')
        .select('role,message,created_at')
        .eq('thread_id', threadId)
        .order('created_at', ascending: true)
        .limit(limit);

    _messages
      ..clear()
      ..addAll((rows as List).map((r) {
        final role = (r['role'] as String?) ?? 'user';
        return _ChatMsg(
          role: role == 'assistant' ? _Role.assistant : _Role.user,
          text: (r['message'] ?? '').toString(),
        );
      }));

    if (mounted) setState(() {});
    _autoScroll();
  }

  // =============== SEND ===============

  Future<void> _send() async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint("[AI][$requestId] send_start mode=$_mode thread=$_currentThreadId");
    final businessId = _businessId;
    final threadId = _currentThreadId;
    final text = _controller.text.trim();

    if (!_isPremium || businessId == null || threadId == null) return;
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    _messages.add(_ChatMsg(role: _Role.user, text: text));
    final assistantMsg = _ChatMsg(role: _Role.assistant, text: "");
    _messages.add(assistantMsg);

    _controller.clear();
    setState(() {});
    _autoScroll();

    final t0 = DateTime.now();

    try {
      await _retry(
        attempts: 3,
        baseDelayMs: 350,
        fn: () async {
          debugPrint("[AI][$requestId] calling_edge_function");
          await _streamFromEdge(
            functionName: "ai-chat",
            body: {
              "businessId": businessId,
              "message": text,
              "mode": _mode,
              "threadId": _currentThreadId,
            },
            onChunk: (chunk) {
              assistantMsg.text += chunk;
              if (mounted) setState(() {});
              _autoScroll(throttle: true);
            },
            onFullJson: (json) {
              assistantMsg.text = _formatStructuredResponse(json);
              if (mounted) setState(() {});
            },
            onMeta: (metaThreadId) {
              _currentThreadId = metaThreadId;
            },
          );
        },
      );

      final latency = DateTime.now().difference(t0).inMilliseconds;
      debugPrint("[AI][$requestId] completed latency=${latency}ms");
    } catch (e) {
      assistantMsg.text = _mapError(e.toString());
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _retry({
    required int attempts,
    required int baseDelayMs,
    required Future<void> Function() fn,
  }) async {
    int tryNo = 0;
    Object? lastError;

    while (tryNo < attempts) {
      try {
        await fn();
        return;
      } catch (e) {
        debugPrint("[AI] retry attempt=$tryNo error=$e");
        lastError = e;
        tryNo++;
        if (tryNo >= attempts) break;

        final delay = baseDelayMs * (tryNo); // linear backoff
        await Future.delayed(Duration(milliseconds: delay));
      }
    }

    throw lastError ?? Exception("Unknown error");
  }

  // =============== STREAM / JSON FALLBACK ===============

  Future<void> _streamFromEdge({
    required String functionName,
    required Map<String, dynamic> body,
    required void Function(String chunk) onChunk,
    required void Function(Map<String, dynamic> json) onFullJson,
    required void Function(String threadId) onMeta,
  }) async {
    debugPrint("[AI] stream_connect function=$functionName");
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception("Session yok");

    final uri = Uri.parse("$_supabaseUrl/functions/v1/$functionName");

    final req = http.Request("POST", uri);
    req.headers["Content-Type"] = "application/json";
    req.headers["Authorization"] = "Bearer ${session.accessToken}";
    req.body = jsonEncode(body);

    final client = http.Client();
    try {
      final res = await client.send(req);
      debugPrint("[AI] response_status=${res.statusCode}");
      final contentType = (res.headers["content-type"] ?? "").toLowerCase();

      // Status != 200 ise body'yi oku ve hata fırlat
      if (res.statusCode != 200) {
        final bytes = await res.stream.toBytes();
        final txt = utf8.decode(bytes);
        throw Exception(txt);
      }

      // Önce tüm streami text'e çekebilme ihtiyacı:
      // - JSON gelirse tek seferde decode edeceğiz
      // - SSE gelirse satır satır okuyacağız
      if (contentType.contains("application/json")) {
        final bytes = await res.stream.toBytes();
        final txt = utf8.decode(bytes);
        final decoded = jsonDecode(txt);
        if (decoded is Map<String, dynamic>) onFullJson(decoded);
        return;
      }

      // SSE değil ama JSON text dönmüş olabilir → sniff
      // (Bazı function’larda content-type text/plain olabilir)
      if (contentType.contains("text/plain")) {
        final bytes = await res.stream.toBytes();
        final txt = utf8.decode(bytes);
        if (txt.trim().startsWith("{")) {
          final decoded = jsonDecode(txt);
          if (decoded is Map<String, dynamic>) onFullJson(decoded);
          return;
        }
        // text ise chunk olarak bas
        onChunk(txt);
        return;
      }

      // 🔥 BURAYA EKLE
    debugPrint("[AI] sse_stream_started contentType=$contentType");
          
      // ✅ SSE Streaming
      final stream = res.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String buffer = "";

      await for (final line in stream) {
        if (line.trim().isEmpty) {
          if (buffer.startsWith("data:")) {
            final payload = buffer.substring(5).trim();
            if (payload.isNotEmpty) {
              dynamic obj;
            try {
              obj = jsonDecode(payload);
            } catch (e) {
              debugPrint("[AI] json_decode_error=$e");
              continue;
            }

              final type = obj["type"];
              if (type == "meta") {
                final tid = (obj["threadId"] ?? "").toString();

                debugPrint("[AI] meta threadId=$tid");

                if (tid.isNotEmpty) onMeta(tid);
              }else if (type == "chunk") {
                onChunk((obj["chunk"] ?? "").toString());
              } 
              else if (type == "error") {
                debugPrint("[AI] stream_error=${obj["error"]}");
                throw Exception((obj["error"] ?? "Unknown error").toString());
              } 
              else if (type == "done") {
                debugPrint("[AI] stream_done");
                break;
              }
            }
          }
          buffer = "";
        } else {
          buffer += line;
        }
      }
    } finally {
      client.close();
    }
  }

  // =============== FORMAT / UX ===============

  String _formatStructuredResponse(Map<String, dynamic> data) {
    // CFO/Risk/Growth/Ops structured outputlarını genişletebilirsin.
    if (data.containsKey("financialHealthScore")) {
      final score = data["financialHealthScore"];
      final risk = data["risk_level"];
      final actions = (data["actions"] as List? ?? []);

      return [
        "📊 Finansal Sağlık Skoru: $score",
        "⚠ Risk Seviyesi: $risk",
        "",
        "🎯 Öneriler:",
        ...actions.map((e) => "- $e"),
      ].join("\n");
    }

    // Fallback
    return data.toString();
  }

  String _mapError(String raw) {
    final msg = raw.replaceAll("Exception: ", "");

    if (msg.contains("quota")) {
      return "AI kullanım limitine ulaşıldı (Premium aylık limit). Önümüzdeki ay sıfırlanır veya ek paket alabilirsiniz.";
    }
    if (msg.contains("429")) {
      return "Yapay Zeka servisi şu anda yoğun. Lütfen tekrar deneyin.";
    }
    if (msg.toLowerCase().contains("timeout")) {
      return "Yapay Zeka servisi zaman aşımına uğradı. Lütfen tekrar deneyin.";
    }
    if (msg.contains("Premium feature")) {
      return "Bu özellik yalnızca Premium plan kullanıcılarına açıktır.";
    }

    return "Yapay Zeka servisi geçici olarak kullanılamıyor. Lütfen tekrar deneyin.\n($msg)";
  }

  void _autoScroll({bool throttle = false}) {
    if (!_scroll.hasClients) return;

    if (!throttle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
      return;
    }

    _scrollTimer ??= Timer(const Duration(milliseconds: 120), () {
      _scrollTimer = null;
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent + 200);
    });
  }

  // =============== UI ===============

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isPremium) {
      return Scaffold(
        appBar: AppBar(title: const Text("AI Chat")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 56, color: Colors.grey),
              const SizedBox(height: 14),
              const Text(
                "AI Chat Premium Özelliktir",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text("Pro plana geçerek erişebilirsiniz."),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, "/upgrade"),
                child: const Text("Planı Yükselt"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("İşletme Asistanı"),
        actions: [
          _modeChip("CFO", "cfo"),
          _modeChip("Risk", "risk"),
          _modeChip("Growth", "growth"),
          _modeChip("Ops", "ops"),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m.role == _Role.user;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue.withOpacity(0.12)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUser
                            ? Colors.blue.withOpacity(0.25)
                            : Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      m.text.isEmpty && !isUser ? "…" : m.text,
                      style: const TextStyle(fontSize: 14, height: 1.35),
                    ),
                  ),
                );
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _modeChip(String label, String value) {
    final active = _mode == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (v) async {
          if (!v) return;

          // Mode değişti: istersen aynı thread içinde devam et; istersen yeni thread aç.
          // Ben “yeni thread aç” yapıyorum çünkü system prompt değişiyor.
          setState(() => _mode = value);

          if (_isPremium) {
            _currentThreadId = await _restoreOrCreateThread(mode: _mode);
            await _loadRecentMessages(limit: 50);
          }
        },
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: "İşletmenle ilgili sor… (örn: Bu ay giderleri nasıl düşürürüm?)",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              width: 48,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Role { user, assistant }

class _ChatMsg {
  _Role role;
  String text;
  _ChatMsg({required this.role, required this.text});
}