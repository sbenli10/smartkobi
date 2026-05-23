class CashflowScenarioModel {
  const CashflowScenarioModel({
    required this.id,
    required this.userId,
    this.businessId,
    required this.title,
    required this.scenarioType,
    required this.amount,
    required this.scenarioDate,
    required this.riskLevel,
    this.resultSummary,
    this.recommendation,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? businessId;
  final String title;
  final String scenarioType;
  final double amount;
  final DateTime scenarioDate;
  final String riskLevel;
  final String? resultSummary;
  final String? recommendation;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLowRisk => riskLevel == 'low';
  bool get isMediumRisk => riskLevel == 'medium';
  bool get isHighRisk => riskLevel == 'high';
  bool get isCriticalRisk => riskLevel == 'critical';

  CashflowScenarioModel copyWith({
    String? id,
    String? userId,
    String? businessId,
    String? title,
    String? scenarioType,
    double? amount,
    DateTime? scenarioDate,
    String? riskLevel,
    String? resultSummary,
    String? recommendation,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearBusinessId = false,
    bool clearResultSummary = false,
    bool clearRecommendation = false,
  }) {
    return CashflowScenarioModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: clearBusinessId ? null : businessId ?? this.businessId,
      title: title ?? this.title,
      scenarioType: scenarioType ?? this.scenarioType,
      amount: amount ?? this.amount,
      scenarioDate: scenarioDate ?? this.scenarioDate,
      riskLevel: riskLevel ?? this.riskLevel,
      resultSummary:
          clearResultSummary ? null : resultSummary ?? this.resultSummary,
      recommendation:
          clearRecommendation ? null : recommendation ?? this.recommendation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CashflowScenarioModel.fromJson(Map<String, dynamic> json) {
    return CashflowScenarioModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String?,
      title: (json['title'] ?? '') as String,
      scenarioType: (json['scenario_type'] ?? 'expense_check') as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      scenarioDate:
          DateTime.tryParse(json['scenario_date']?.toString() ?? '') ?? DateTime.now(),
      riskLevel: (json['risk_level'] ?? 'medium') as String,
      resultSummary: json['result_summary'] as String?,
      recommendation: json['recommendation'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_id': businessId,
      'title': title,
      'scenario_type': scenarioType,
      'amount': amount,
      'scenario_date': scenarioDate.toIso8601String().split('T').first,
      'risk_level': riskLevel,
      'result_summary': resultSummary,
      'recommendation': recommendation,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
