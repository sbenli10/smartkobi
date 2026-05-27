import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/ai_conversation_model.dart';
import '../../data/models/ai_message_model.dart';
import '../../data/models/business_context_summary_model.dart';
import '../../data/repositories/ai_advisor_repository.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final AiAdvisorRepository _repository = AiAdvisorRepository();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: 'TL', decimalDigits: 2);

  final List<String> _quickQuestions = const [
    'Bu ay işletmemin durumu nasıl?',
    'Nakit akışım riskli mi?',
    'Kimden tahsilat yapmalıyım?',
    'Hangi ürünler kritik stokta?',
    'En çok hangi giderim artmış?',
    'Bu harcamayı yapabilir miyim?',
    'Kârımı artırmak için ne yapmalıyım?',
    'KOSGEB/desteklere uygun muyum?',
  ];

  BusinessContextSummaryModel _contextSummary = BusinessContextSummaryModel.empty();
  List<AiMessageModel> _messages = [];
  AiConversationModel? _activeConversation;
  bool _loading = true;
  bool _sending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _repository.buildContextSummary();
      final conversations = await _repository.fetchConversations();
      AiConversationModel? activeConversation;
      List<AiMessageModel> messages = [];

      if (conversations.isNotEmpty) {
        activeConversation = conversations.first;
        messages = await _repository.fetchMessages(activeConversation.id);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _contextSummary = summary;
        _activeConversation = activeConversation;
        _messages = messages;
        _loading = false;
      });

      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _startNewConversation() async {
    setState(() {
      _activeConversation = null;
      _messages = [];
      _messageController.clear();
    });
  }

  Future<void> _sendQuestion([String? quickQuestion]) async {
    final question = (quickQuestion ?? _messageController.text).trim();
    if (question.isEmpty || _sending) {
      return;
    }

    setState(() => _sending = true);
    if (quickQuestion == null) {
      _messageController.clear();
    }

    try {
      final topic = _detectTopic(question);
      await _repository.askAdvisor(
        question: question,
        conversationId: _activeConversation?.id,
        topic: topic,
      );

      final conversations = await _repository.fetchConversations();
      final activeConversation = conversations.isNotEmpty ? conversations.first : null;
      final messages = activeConversation == null
          ? <AiMessageModel>[]
          : await _repository.fetchMessages(activeConversation.id);
      final summary = await _repository.buildContextSummary();

      if (!mounted) {
        return;
      }

      setState(() {
        _contextSummary = summary;
        _activeConversation = activeConversation;
        _messages = messages;
        _sending = false;
      });

      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _sending = false);
      _showSnackBar(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.warning : AppColors.success,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'SmartKOBİ Danışman',
      subtitle:
          'İşletme verilerinize göre finans, cari, stok ve nakit önerileri alın.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _loadData,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: _sending ? null : _startNewConversation,
          tooltip: 'Yeni görüşme',
          icon: const Icon(Icons.add_comment_outlined),
        ),
      ],
      child: _loading
          ? const Center(child: Text('SmartKOBİ analiz ediyor...'))
          : _errorMessage != null
              ? _AdvisorErrorState(
                  message: _errorMessage!,
                  onRetry: _loadData,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 980;
                    final summaryPanel = _SummaryPanel(
                      summary: _contextSummary,
                      currency: _currency,
                      quickQuestions: _quickQuestions,
                      onQuickQuestionTap: (question) => _sendQuestion(question),
                    );
                    final chatPanel = _ChatPanel(
                      conversationTitle:
                          _activeConversation?.title ?? 'Yeni danışman görüşmesi',
                      messages: _messages,
                      sending: _sending,
                      controller: _messageController,
                      scrollController: _scrollController,
                      onSend: () => _sendQuestion(),
                      onQuickQuestionTap: (question) => _sendQuestion(question),
                    );

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 340,
                            child: SingleChildScrollView(child: summaryPanel),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: chatPanel),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              summaryPanel,
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 560,
                                child: chatPanel,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.summary,
    required this.currency,
    required this.quickQuestions,
    required this.onQuickQuestionTap,
  });

  final BusinessContextSummaryModel summary;
  final NumberFormat currency;
  final List<String> quickQuestions;
  final Future<void> Function(String question) onQuickQuestionTap;

  @override
  Widget build(BuildContext context) {
    final hasData = summary.hasFinancialData ||
        summary.pendingReceivables > 0 ||
        summary.criticalStockCount > 0 ||
        summary.expectedCashInflow30d > 0 ||
        summary.expectedCashOutflow30d > 0;

    return Column(
      children: [
        SmartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.gold500.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: AppColors.gold500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'SmartKOBİ Danışman',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Verilere göre öneri üretir',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _TagPill(label: 'Ön Analiz', color: AppColors.info),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'SmartKOBİ Danışman; finans, nakit akışı, cari, stok, satış, destekler ve işletme kararları için yanıt verir.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.turquoiseSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'SmartKOBİ önerileri ön analiz niteliğindedir. Finansal, hukuki ve vergisel kararlar için uzman görüşü alınmalıdır.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SmartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'İşletme Context Özeti',
                subtitle: 'Danışman bu özet veriler üzerinden kısa yorum üretir.',
              ),
              const SizedBox(height: 14),
              if (!hasData)
                const Text(
                  'Henüz yeterli veri yok. Kayıt ekledikçe danışman daha net öneriler sunar.',
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricMiniCard(
                      label: 'Bu Ay Gelir',
                      value: currency.format(summary.monthlyIncome),
                      color: AppColors.success,
                    ),
                    _MetricMiniCard(
                      label: 'Bu Ay Gider',
                      value: currency.format(summary.monthlyExpense),
                      color: AppColors.danger,
                    ),
                    _MetricMiniCard(
                      label: 'Nakit Skoru',
                      value: '${summary.cashScore}/100',
                      color: _riskColor(summary.overallRiskLevel),
                    ),
                    _MetricMiniCard(
                      label: 'Geciken Tahsilat',
                      value: currency.format(summary.overdueReceivables),
                      color: AppColors.warning,
                    ),
                    _MetricMiniCard(
                      label: 'Kritik Stok',
                      value: summary.criticalStockCount.toString(),
                      color: AppColors.info,
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SmartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Hazır Sorular',
                subtitle: 'Tek dokunuşla aksiyon odaklı özet isteyin.',
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickQuestions
                    .map(
                      (question) => InkWell(
                        onTap: () => onQuickQuestionTap(question),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Text(question),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.conversationTitle,
    required this.messages,
    required this.sending,
    required this.controller,
    required this.scrollController,
    required this.onSend,
    required this.onQuickQuestionTap,
  });

  final String conversationTitle;
  final List<AiMessageModel> messages;
  final bool sending;
  final TextEditingController controller;
  final ScrollController scrollController;
  final Future<void> Function() onSend;
  final Future<void> Function(String question) onQuickQuestionTap;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: SectionHeader(
                    title: conversationTitle,
                    subtitle: 'Kısa, net ve veri odaklı öneriler alın.',
                  ),
                ),
                if (messages.isNotEmpty)
                  _TagPill(
                    label: '${messages.length} mesaj',
                    color: AppColors.gold500,
                  ),
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? _EmptyChatState(onQuestionTap: onQuickQuestionTap)
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const _TypingIndicator();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MessageBubble(message: messages[index]),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: const InputDecoration(
                      hintText: 'İşletmenizle ilgili sorunuzu yazın...',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: ElevatedButton(
                    onPressed: sending ? null : () => onSend(),
                    child: sending
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
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AiMessageModel message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubbleColor = isUser ? AppColors.gold500.withValues(alpha: 0.14) : AppColors.surfaceAlt;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final textColor = isUser ? AppColors.textPrimary : AppColors.textPrimary;
    final riskLevel = message.metadata['riskLevel']?.toString();
    final relatedModule = message.metadata['relatedModule']?.toString();
    final usedFallback = message.metadata['usedFallback'] == true;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUser
                  ? AppColors.gold500.withValues(alpha: 0.20)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isUser)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (riskLevel != null)
                      _TagPill(
                        label: _riskLabel(riskLevel),
                        color: _riskColor(riskLevel),
                      ),
                    if (relatedModule != null)
                      _TagPill(
                        label: _moduleLabel(relatedModule),
                        color: AppColors.info,
                      ),
                    if (usedFallback)
                      const _TagPill(
                        label: 'Kural Bazlı',
                        color: AppColors.warning,
                      ),
                  ],
                ),
              if (!isUser) const SizedBox(height: 10),
              Text(
                message.content,
                style: TextStyle(color: textColor, height: 1.45),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('dd.MM HH:mm').format(message.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('SmartKOBİ analiz ediyor...'),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.onQuestionTap});

  final Future<void> Function(String question) onQuestionTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 44, color: AppColors.gold500),
            const SizedBox(height: 12),
            Text(
              'Henüz mesaj yok. İşletmenizle ilgili bir soru sorarak başlayın.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ActionChip(
                  label: const Text('Bu ay işletmemin durumu nasıl?'),
                  onPressed: () => onQuestionTap('Bu ay işletmemin durumu nasıl?'),
                ),
                ActionChip(
                  label: const Text('Nakit akışım riskli mi?'),
                  onPressed: () => onQuestionTap('Nakit akışım riskli mi?'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvisorErrorState extends StatelessWidget {
  const _AdvisorErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SmartCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: AppColors.warning),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricMiniCard extends StatelessWidget {
  const _MetricMiniCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _detectTopic(String question) {
  final value = question.toLowerCase();
  if (value.contains('nakit') ||
      value.contains('ödeme') ||
      value.contains('tahsilat') ||
      value.contains('harcama') ||
      value.contains('para')) {
    return 'cashflow';
  }
  if (value.contains('müşteri') || value.contains('cari') || value.contains('alacak')) {
    return 'customers';
  }
  if (value.contains('stok') || value.contains('ürün') || value.contains('barkod')) {
    return 'inventory';
  }
  if (value.contains('gelir') ||
      value.contains('gider') ||
      value.contains('kâr') ||
      value.contains('kar') ||
      value.contains('zarar') ||
      value.contains('finans')) {
    return 'finance';
  }
  if (value.contains('destek') ||
      value.contains('kosgeb') ||
      value.contains('teşvik') ||
      value.contains('tübitak')) {
    return 'support';
  }
  return 'general';
}

String _riskLabel(String level) {
  switch (level) {
    case 'critical':
      return 'Kritik';
    case 'high':
      return 'Riskli';
    case 'medium':
      return 'Dikkat';
    default:
      return 'Güvenli';
  }
}

Color _riskColor(String level) {
  switch (level) {
    case 'critical':
      return AppColors.danger;
    case 'high':
      return AppColors.warning;
    case 'medium':
      return AppColors.info;
    default:
      return AppColors.success;
  }
}

String _moduleLabel(String module) {
  switch (module) {
    case 'cashflow':
      return 'Nakit';
    case 'customers':
      return 'Cari';
    case 'inventory':
      return 'Stok';
    case 'finance':
      return 'Finans';
    case 'support':
      return 'Destek';
    default:
      return 'Genel';
  }
}
