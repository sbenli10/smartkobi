import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class CashflowPage extends StatefulWidget {
  const CashflowPage({super.key});

  @override
  State<CashflowPage> createState() => _CashflowPageState();
}

class _CashflowPageState extends State<CashflowPage> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  bool _isPremium = false;

  double currentCash = 0;
  double predictedCash = 0;

  /// 0-100 (yüksek = daha riskli)
  double riskScore = 0;

  /// Edge function risk_level: low/medium/high
  String riskLevel = "low";

  String aiAnalysis = "";

  /// 30 günlük trend noktaları
  List<FlSpot> forecastSpots = const [];

  late RealtimeChannel _txChannel;

  @override
  void initState() {
    super.initState();
    _initRealtime();
    _loadData();
  }

  void _initRealtime() {
    _txChannel = _supabase.channel('cashflow-transactions')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'transactions',
       callback: (_) {
        Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted && _isPremium) {
            _loadData();
            }
        });
        },
      )
      ..subscribe();
  }

  @override
  void dispose() {
    _supabase.removeChannel(_txChannel);
    super.dispose();
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

    return res?['business_id'];
  }

Future<void> _loadData() async {
  if (!mounted) return;
  setState(() => _loading = true);

  try {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _isPremium = false;
        _loading = false;
      });
      return;
    }

    /// USER DEBUG
    debugPrint("Logged user id: ${user.id}");
    debugPrint("Logged user email: ${user.email}");

    /// BUSINESS ID
    final roles = await _supabase
        .from('user_business_roles')
        .select('business_id')
        .eq('user_id', user.id);

    if (roles.isEmpty) {
      debugPrint("No business role found.");
      setState(() {
        _isPremium = false;
        _loading = false;
      });
      return;
    }

    final businessId = roles.first['business_id'] as String;
    debugPrint("Business ID: $businessId");

    /// PLAN CHECK
    final businessRes = await _supabase
        .from('businesses')
        .select('plan')
        .eq('id', businessId)
        .maybeSingle();

    if (businessRes == null) {
      debugPrint("Business not found.");
      setState(() {
        _isPremium = false;
        _loading = false;
      });
      return;
    }

    final plan = businessRes['plan'] as String? ?? 'free';
    debugPrint("Business plan from DB: $plan");

    if (plan == 'free') {
      setState(() {
        _isPremium = false;
        _loading = false;
      });
      return;
    }

    /// SON 6 AY TRANSACTION
    final sixMonthsAgo =
        DateTime.now().subtract(const Duration(days: 180)).toIso8601String();

    final tx = await _supabase
        .from('transactions')
        .select('amount,type')
        .eq('business_id', businessId)
        .gte('created_at', sixMonthsAgo);

    double income = 0;
    double expense = 0;

    for (final t in tx) {
      final amt = (t['amount'] as num?)?.toDouble() ?? 0;
      if (t['type'] == 'income') {
        income += amt;
      } else {
        expense += amt;
      }
    }

    final computedCurrentCash = income - expense;

    /// EDGE FUNCTION
    final response = await _supabase.functions.invoke(
      'cashflow-forecast',
      body: {'businessId': businessId},
    );

    if (response.status != 200) {
      debugPrint("Forecast HTTP error: ${response.status}");
      setState(() {
        _isPremium = true;
        currentCash = computedCurrentCash;
        _loading = false;
      });
      return;
    }

    final data = response.data as Map<String, dynamic>?;

    if (data == null) {
      debugPrint("Forecast returned null data.");
      setState(() {
        _isPremium = true;
        currentCash = computedCurrentCash;
        _loading = false;
      });
      return;
    }

    final forecast30 =
        (data['forecast30'] as num?)?.toDouble() ?? 0;

    final level =
        (data['risk'] as String?)?.toLowerCase() ?? "low";

    final analysis =
        data['analysis']?.toString() ?? "";

    double newRiskScore;
    switch (level) {
      case "high":
        newRiskScore = 80;
        break;
      case "medium":
        newRiskScore = 50;
        break;
      default:
        newRiskScore = 20;
    }

    /// TREND
    final series = data['series'];
    List<FlSpot> spots;

    if (series is List && series.isNotEmpty) {
      spots = List.generate(series.length, (i) {
        final y = (series[i] as num?)?.toDouble() ?? 0;
        return FlSpot(i.toDouble(), y);
      });
    } else {
      const days = 30;
      spots = List.generate(days + 1, (i) {
        final t = i / days;
        final y =
            computedCurrentCash +
            (forecast30 - computedCurrentCash) * t;
        return FlSpot(i.toDouble(), y);
      });
    }

    if (!mounted) return;

    setState(() {
      _isPremium = true;
      _loading = false;

      currentCash = computedCurrentCash;
      predictedCash = forecast30;

      riskLevel = level;
      riskScore = newRiskScore;

      aiAnalysis = analysis;
      forecastSpots = spots;
    });

  } catch (e) {
    debugPrint("Cashflow load error: $e");
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
}


  Color _riskColor() {
    if (riskScore > 70) return Colors.red;
    if (riskScore > 40) return Colors.orange;
    return Colors.green;
  }

  String _riskLabel() {
    if (riskLevel == "high") return "Yüksek Risk";
    if (riskLevel == "medium") return "Orta Risk";
    return "Düşük Risk";
  }

  String _riskDescription() {
    if (riskLevel == "high") {
      return "Önümüzdeki 30 günde nakit dalgalanması yüksek. Tahsilat hızını artırın, zorunlu olmayan giderleri erteleyin ve stok alımlarını kontrollü yapın.";
    }
    if (riskLevel == "medium") {
      return "Nakit akışı yönetilebilir ancak dikkat gerektiriyor. Tahsilat takibini sıklaştırın ve kısa vadeli gider planı çıkarın.";
    }
    return "Nakit görünümü iyi. Planlı büyüme ve maliyet optimizasyonu için uygun bir dönem.";
  }

  /// Risk tersinden: 100 - riskScore
  int get cashConfidenceScore =>
      (100 - riskScore).clamp(0, 100).round();

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final riskColor = _riskColor();

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : !_isPremium
                ? _buildLockedView()
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildGradientHeader(),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// KPI Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _kpiCard(
                                      title: "Mevcut Nakit",
                                      value: currency.format(currentCash),
                                      icon: Icons.account_balance_wallet_outlined,
                                      accent: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _kpiCard(
                                      title: "30 Gün Tahmini",
                                      value: currency.format(predictedCash),
                                      icon: Icons.insights_outlined,
                                      accent: riskColor,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              /// Risk + Badge
                              Row(
                                children: [
                                  Text(
                                    "Risk Seviyesi",
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(width: 10),
                                  _riskBadge(),
                                ],
                              ),
                              const SizedBox(height: 10),

                              LinearProgressIndicator(
                                value: riskScore / 100,
                                backgroundColor: Colors.grey.shade300,
                                color: riskColor,
                                minHeight: 10,
                              ),

                              const SizedBox(height: 14),

                              /// Risk açıklaması kutusu
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: riskColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: riskColor.withOpacity(0.25),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline, color: riskColor),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _riskDescription(),
                                        style: const TextStyle(fontSize: 14, height: 1.35),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              /// Nakit Güven Skoru
                              Text(
                                "Nakit Güven Skoru",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),

                              _confidenceGauge(),

                              const SizedBox(height: 18),

                              /// 30 günlük trend grafik
                              Text(
                                "30 Günlük Tahmin Trendi",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),

                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SizedBox(
                                  height: 240,
                                  child: LineChart(
                                    LineChartData(
                                      gridData: FlGridData(show: false),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        topTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        rightTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 28,
                                            interval: 10,
                                            getTitlesWidget: (value, meta) {
                                              // 0,10,20,30
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: Text(
                                                  "${value.toInt()}g",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black.withOpacity(0.6),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: forecastSpots.isEmpty
                                              ? [
                                                  FlSpot(0, currentCash),
                                                  FlSpot(30, predictedCash),
                                                ]
                                              : forecastSpots,
                                          isCurved: true,
                                          barWidth: 3,
                                          color: riskColor,
                                          dotData: FlDotData(show: false),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: riskColor.withOpacity(0.12),
                                          ),
                                        ),
                                      ],
                                      minX: 0,
                                      maxX: forecastSpots.isNotEmpty ? forecastSpots.last.x : 30,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              /// AI Analiz kartı
                              Text(
                                "AI CFO Analiz",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),

                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  aiAnalysis.isEmpty ? "AI analiz bulunamadı." : aiAnalysis,
                                  style: const TextStyle(fontSize: 14, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade700,
            Colors.purple.shade600,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.maybePop(context),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nakit Tahmin Motoru",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "AI CFO paketi • Premium",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Text(
              "PREMIUM",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskBadge() {
    final color = _riskColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        _riskLabel(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _confidenceGauge() {
    final confidence = cashConfidenceScore; // 0..100
    Color color;
    if (confidence >= 70) {
      color = Colors.green;
    } else if (confidence >= 40) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 52,
            width: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: confidence / 100,
                  strokeWidth: 6,
                  color: color,
                  backgroundColor: Colors.grey.shade200,
                ),
                Text(
                  "$confidence",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              confidence >= 70
                  ? "Güven yüksek. Nakit planı stabil."
                  : confidence >= 40
                      ? "Orta güven. Tahsilat ve gider disiplinine dikkat."
                      : "Düşük güven. Kısa vadede nakit sıkışıklığı riski var.",
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 60, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Nakit Tahmin Motoru\nAI CFO Premium Özelliğidir",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Premium satış sayfasına yönlendir
              },
              child: const Text("Premium'a Geç"),
            )
          ],
        ),
      ),
    );
  }
}
