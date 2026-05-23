import '../../data/models/cashflow_projection_model.dart';

class CashflowAiService {
  const CashflowAiService();

  Future<String?> buildEdgeReadyPrompt(CashflowProjectionModel projection) async {
    // Placeholder for future Supabase Edge Function integration.
    return 'Projection score: ${projection.cashScore}, risk: ${projection.riskLevel}';
  }
}
