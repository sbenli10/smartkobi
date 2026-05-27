import 'package:flutter/material.dart';
import '../../common/widgets/page_scaffold.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/supplier_price_alert_model.dart';
import '../../data/repositories/profit_leakage_repository.dart';

class ProfitLeakagePage extends StatefulWidget {
  const ProfitLeakagePage({super.key});

  @override
  State<ProfitLeakagePage> createState() => _ProfitLeakagePageState();
}

class _ProfitLeakagePageState extends State<ProfitLeakagePage> {
  final _repository = ProfitLeakageRepository();
  bool _isLoading = true;
  List<SupplierPriceAlertModel> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await _repository.fetchOpenAlerts();
      setState(() => _alerts = alerts);
    } catch (_) {} finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _dismissAlert(String id) async {
    await _repository.updateAlertStatus(id, 'dismissed');
    _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Tedarikçi Fiyat Radarı',
      subtitle: 'Alış fiyatlarındaki artışları takip edin, kâr marjınızı koruyun.',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.primaryNavy),
          onPressed: _loadAlerts,
        )
      ],
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _alerts.isEmpty 
          ? _buildEmptyState()
          : ListView.separated(
              itemCount: _alerts.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return _buildAlertCard(alert);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.price_check, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Şu an maliyet artışı uyarısı yok', 
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Fiş/Fatura okutarak veya manuel alış girerek en az iki veri oluşturduğunuzda sistem kâr sızıntılarını otomatik tespit eder.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(SupplierPriceAlertModel alert) {
    final isCritical = alert.severity == 'critical' || alert.severity == 'high';
    final color = isCritical ? AppColors.danger : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(alert.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('%${alert.increaseRate?.toStringAsFixed(1)} Artış', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(alert.message, style: const TextStyle(color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('💡 ${alert.suggestedAction ?? ""}', style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => _dismissAlert(alert.id),
              child: const Text('Anladım, Kapat'),
            ),
          )
        ],
      ),
    );
  }
}