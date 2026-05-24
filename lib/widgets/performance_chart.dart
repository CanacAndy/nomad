import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class PerformanceChart extends StatelessWidget {
  final List<double> weeklyDistances;

  const PerformanceChart({super.key, required this.weeklyDistances});

  @override
  Widget build(BuildContext context) {
    double maxDistance = weeklyDistances.isNotEmpty
        ? weeklyDistances.reduce((a, b) => a > b ? a : b)
        : 0.0;
    if (maxDistance < 5) maxDistance = 5;

    return Container(
      height: 220,
      padding: const EdgeInsets.only(right: 20, left: 10, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            // CORRECTION : Utilisation de AxisTitles pour les axes à masquer
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()} km',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = [
                    'Lun',
                    'Mar',
                    'Mer',
                    'Jeu',
                    'Ven',
                    'Sam',
                    'Dim',
                  ];
                  if (value >= 0 && value < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        days[value.toInt()],
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: maxDistance + 2,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(weeklyDistances.length, (index) {
                return FlSpot(index.toDouble(), weeklyDistances[index]);
              }),
              isCurved:
                  true, // CORRECTION : Plus besoin de curveMode, isCurved gère tout
              color: AppTheme.primaryAccent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryAccent.withValues(alpha: 0.3),
                    AppTheme.primaryAccent.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
