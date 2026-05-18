import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/monthly_summary_model.dart';

class IncomeExpenseChart extends StatelessWidget {
  final List<MonthlySummaryModel> data;

  const IncomeExpenseChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text("Grafik verisi yok")),
      );
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),
          barGroups: data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.income,
                  width: 8,
                  color: Colors.green,
                ),
                BarChartRodData(
                  toY: item.expense,
                  width: 8,
                  color: Colors.red,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
