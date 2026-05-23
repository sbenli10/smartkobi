class CashflowSnapshotModel {
  const CashflowSnapshotModel({
    required this.id,
    required this.userId,
    this.businessId,
    required this.snapshotDate,
    required this.openingBalance,
    required this.expectedInflow30d,
    required this.expectedOutflow30d,
    required this.netCash30d,
    required this.expectedInflow60d,
    required this.expectedOutflow60d,
    required this.netCash60d,
    required this.cashScore,
    required this.riskLevel,
    this.aiSummary,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? businessId;
  final DateTime snapshotDate;
  final double openingBalance;
  final double expectedInflow30d;
  final double expectedOutflow30d;
  final double netCash30d;
  final double expectedInflow60d;
  final double expectedOutflow60d;
  final double netCash60d;
  final int cashScore;
  final String riskLevel;
  final String? aiSummary;
  final DateTime createdAt;

  CashflowSnapshotModel copyWith({
    String? id,
    String? userId,
    String? businessId,
    DateTime? snapshotDate,
    double? openingBalance,
    double? expectedInflow30d,
    double? expectedOutflow30d,
    double? netCash30d,
    double? expectedInflow60d,
    double? expectedOutflow60d,
    double? netCash60d,
    int? cashScore,
    String? riskLevel,
    String? aiSummary,
    DateTime? createdAt,
    bool clearBusinessId = false,
    bool clearAiSummary = false,
  }) {
    return CashflowSnapshotModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: clearBusinessId ? null : businessId ?? this.businessId,
      snapshotDate: snapshotDate ?? this.snapshotDate,
      openingBalance: openingBalance ?? this.openingBalance,
      expectedInflow30d: expectedInflow30d ?? this.expectedInflow30d,
      expectedOutflow30d: expectedOutflow30d ?? this.expectedOutflow30d,
      netCash30d: netCash30d ?? this.netCash30d,
      expectedInflow60d: expectedInflow60d ?? this.expectedInflow60d,
      expectedOutflow60d: expectedOutflow60d ?? this.expectedOutflow60d,
      netCash60d: netCash60d ?? this.netCash60d,
      cashScore: cashScore ?? this.cashScore,
      riskLevel: riskLevel ?? this.riskLevel,
      aiSummary: clearAiSummary ? null : aiSummary ?? this.aiSummary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory CashflowSnapshotModel.fromJson(Map<String, dynamic> json) {
    return CashflowSnapshotModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String?,
      snapshotDate:
          DateTime.tryParse(json['snapshot_date']?.toString() ?? '') ?? DateTime.now(),
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0,
      expectedInflow30d: (json['expected_inflow_30d'] as num?)?.toDouble() ?? 0,
      expectedOutflow30d:
          (json['expected_outflow_30d'] as num?)?.toDouble() ?? 0,
      netCash30d: (json['net_cash_30d'] as num?)?.toDouble() ?? 0,
      expectedInflow60d: (json['expected_inflow_60d'] as num?)?.toDouble() ?? 0,
      expectedOutflow60d:
          (json['expected_outflow_60d'] as num?)?.toDouble() ?? 0,
      netCash60d: (json['net_cash_60d'] as num?)?.toDouble() ?? 0,
      cashScore: (json['cash_score'] as num?)?.toInt() ?? 50,
      riskLevel: (json['risk_level'] ?? 'medium') as String,
      aiSummary: json['ai_summary'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_id': businessId,
      'snapshot_date': snapshotDate.toIso8601String().split('T').first,
      'opening_balance': openingBalance,
      'expected_inflow_30d': expectedInflow30d,
      'expected_outflow_30d': expectedOutflow30d,
      'net_cash_30d': netCash30d,
      'expected_inflow_60d': expectedInflow60d,
      'expected_outflow_60d': expectedOutflow60d,
      'net_cash_60d': netCash60d,
      'cash_score': cashScore,
      'risk_level': riskLevel,
      'ai_summary': aiSummary,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
