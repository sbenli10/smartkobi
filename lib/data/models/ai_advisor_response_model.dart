class AiAdvisorResponseModel {
  const AiAdvisorResponseModel({
    required this.answer,
    required this.riskLevel,
    required this.suggestedActions,
    required this.relatedModule,
    required this.usedFallback,
    required this.createdAt,
  });

  final String answer;
  final String riskLevel;
  final List<String> suggestedActions;
  final String relatedModule;
  final bool usedFallback;
  final DateTime createdAt;
}
