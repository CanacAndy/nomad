import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/performance_chart.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Normalise et répartit les distances sur les 7 jours de la semaine en cours
  List<double> _processWeeklyData(List<QueryDocumentSnapshot> docs) {
    List<double> weekDaysDistances = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    final now = DateTime.now();
    final currentWeekMonday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(
      currentWeekMonday.year,
      currentWeekMonday.month,
      currentWeekMonday.day,
    );

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? timestamp = data['date'];
      final num? distance = data['distanceKm'];

      if (timestamp != null && distance != null) {
        final dateWorkout = timestamp.toDate();
        if (dateWorkout.isAfter(startOfWeek)) {
          int dayIndex = dateWorkout.weekday - 1;
          if (dayIndex >= 0 && dayIndex < 7) {
            weekDaysDistances[dayIndex] += distance.toDouble();
          }
        }
      }
    }

    // Normalisation : On arrondit chaque jour à 1 chiffre après la virgule
    return weekDaysDistances
        .map((val) => double.parse(val.toStringAsFixed(1)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Mes Statistiques',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workouts')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryAccent),
            );
          }

          int totalWorkouts = 0;
          double totalDistance = 0.0;
          double maxDistance = 0.0;
          List<double> weeklyStats = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final docs = snapshot.data!.docs;
            totalWorkouts = docs.length;
            weeklyStats = _processWeeklyData(docs);

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final num? distance = data['distanceKm'];
              if (distance != null) {
                double distDouble = distance.toDouble();
                totalDistance += distDouble;
                if (distDouble > maxDistance) {
                  maxDistance = distDouble;
                }
              }
            }
          }

          // Calcul de la moyenne par entraînement (Normalisé)
          double averageDistance = totalWorkouts > 0
              ? (totalDistance / totalWorkouts)
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏆 SECTION 1 : VUE D'ENSEMBLE
                const Text(
                  'Cumuls & Moyennes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildBigStatCard(
                        "Distance Totale",
                        "${totalDistance.toStringAsFixed(1)} km",
                        "Tout historique confondu",
                        Icons.stacked_line_chart_rounded,
                        AppTheme.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildBigStatCard(
                        "Distance Moyenne",
                        "${averageDistance.toStringAsFixed(1)} km",
                        "Par séance de course",
                        Icons.analytics_rounded,
                        Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFullWidthStatCard(
                  "Record Personnel",
                  "${maxDistance.toStringAsFixed(1)} km",
                  "Ta plus longue distance parcourue en une seule fois !",
                  Icons.emoji_events_rounded,
                  Colors.amber,
                ),
                const SizedBox(height: 32),

                // 📈 SECTION 2 : GRAPHIOUE LINÉAIRE (Semaine complète)
                const Text(
                  'Évolution cette semaine (km)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                PerformanceChart(weeklyDistances: weeklyStats),
                const SizedBox(height: 32),

                // 📊 SECTION 3 : LE VOLUME EN BARRES
                const Text(
                  'Volume quotidien',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBarChart(weeklyStats),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget de carte statistique carrée optimisée
  Widget _buildBigStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // Carte large pour mettre en valeur le record personnel
  Widget _buildFullWidthStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Graphique en barres avec échelle Y normalisée en "km"
  Widget _buildBarChart(List<double> weeklyDistances) {
    double maxVal = weeklyDistances.reduce((a, b) => a > b ? a : b);
    double roundedMaxY = ((maxVal + 2) / 5).ceil() * 5.0;
    if (roundedMaxY < 5) roundedMaxY = 5;

    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 20, bottom: 10, right: 16, left: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize:
                    40, // Augmenté un peu pour laisser la place au texte "km"
                interval: roundedMaxY / 2,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()} km', // 👈 Unité corrigée ici de "k" à "km"
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
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      days[value.toInt()],
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          maxY: roundedMaxY,
          barGroups: List.generate(weeklyDistances.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: weeklyDistances[index],
                  color: AppTheme.secondaryAccent,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  // Correction de la propriété ici : backDrawInfo au lieu de backDrawRodData
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: roundedMaxY,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
