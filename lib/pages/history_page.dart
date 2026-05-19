import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/workout.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // 🧮 Calcule l'allure moyenne au kilomètre (format standard : MM'SS")
  String _calculatePace(double distanceKm, int totalSeconds) {
    if (distanceKm <= 0 || totalSeconds <= 0) return "-'--\"";
    final totalMinutes = totalSeconds / 60;
    final paceDecimal = totalMinutes / distanceKm;
    final paceMinutes = paceDecimal.floor();
    final paceSeconds = ((paceDecimal - paceMinutes) * 60).round();
    return "$paceMinutes'${paceSeconds.toString().padLeft(2, '0')}\"";
  }

  // 🕒 Formate une durée globale proprement (gère les heures)
  String _formatTotalDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    }
    return "${minutes}m ${seconds}s";
  }

  // ⏱ Formate la durée d'une seule course (MM:SS ou HH:MM:SS)
  String _formatSingleDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: Text(
            "Veuillez vous connecter",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Mon Historique',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workouts')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_run_rounded,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Aucune course enregistrée.\nBouge de là et va courir ! 🏃‍♂️",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          List<DocumentSnapshot> workoutDocs = snapshot.data!.docs;
          List<Workout> workouts = workoutDocs
              .map((doc) => Workout.fromFirestore(doc))
              .toList();

          List<Map<String, dynamic>> pairedWorkouts = [];
          for (int i = 0; i < workouts.length; i++) {
            pairedWorkouts.add({
              'workout': workouts[i],
              'docId': workoutDocs[i].id,
            });
          }
          pairedWorkouts.sort(
            (a, b) => (b['workout'] as Workout).date.compareTo(
              (a['workout'] as Workout).date,
            ),
          );

          double totalKm = 0;
          int totalCalories = 0;
          int totalSeconds = 0;

          for (var item in pairedWorkouts) {
            final w = item['workout'] as Workout;
            totalKm += w.distanceKm;
            totalCalories += w.calories;
            totalSeconds += w.durationSeconds;
          }

          return Column(
            children: [
              // 📊 DASHBOARD GLOBAL
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        "${totalKm.toStringAsFixed(1)} km",
                        "Distance",
                        Icons.speed_rounded,
                        AppTheme.secondaryAccent,
                      ),
                      _buildStatItem(
                        "$totalCalories kcal",
                        "Calories",
                        Icons.local_fire_department_rounded,
                        Colors.orangeAccent,
                      ),
                      _buildStatItem(
                        _formatTotalDuration(totalSeconds),
                        "Temps total",
                        Icons.timer_rounded,
                        AppTheme.primaryAccent,
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Activités récentes",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // 🏃‍♂️ LISTE SMART & INTUITIVE
              Expanded(
                child: ListView.builder(
                  itemCount: pairedWorkouts.length,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 20,
                  ),
                  itemBuilder: (context, index) {
                    final item = pairedWorkouts[index];
                    final workout = item['workout'] as Workout;
                    final docId = item['docId'] as String;

                    final dateFormated = DateFormat(
                      'dd MMMM yyyy à HH:mm',
                      'fr_FR',
                    ).format(workout.date);
                    final bool isGoalAchieved =
                        (workout.durationSeconds / 60) >=
                        workout.targetTimeMinutes;

                    return Dismissible(
                      key: Key(docId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.redAccent.withValues(alpha: 0.2),
                              Colors.redAccent.withValues(alpha: 0.8),
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.centerRight,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Supprimer",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.delete_forever_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              "Supprimer cette course ?",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: const Text(
                              "Cette action effacera définitivement l'activité de ton historique.",
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text(
                                  "Annuler",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text(
                                  "Supprimer",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        FirebaseFirestore.instance
                            .collection('workouts')
                            .doc(docId)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Course supprimée")),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                              splashColor: AppTheme.primaryAccent.withValues(
                                alpha: 0.05,
                              ),
                              highlightColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              iconColor: AppTheme.primaryAccent,
                              collapsedIconColor: Colors.white60,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryAccent.withValues(
                                    alpha: 0.08,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.directions_run_rounded,
                                  color: AppTheme.primaryAccent,
                                  size: 26,
                                ),
                              ),
                              title: Text(
                                "${workout.distanceKm.toStringAsFixed(2)} km",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                dateFormated,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatSingleDuration(
                                          workout.durationSeconds,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${workout.calories} kcal",
                                        style: const TextStyle(
                                          color: Colors.orangeAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 8,
                                  ),
                                  color: Colors.white.withValues(alpha: 0.015),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildExpandedStatDetail(
                                        icon: Icons.speed_rounded,
                                        label: "Allure Moy.",
                                        value: _calculatePace(
                                          workout.distanceKm,
                                          workout.durationSeconds,
                                        ),
                                        iconColor: AppTheme.secondaryAccent,
                                      ),
                                      _buildExpandedStatDetail(
                                        icon: isGoalAchieved
                                            ? Icons.check_circle_rounded
                                            : Icons.flag_outlined,
                                        label: "Objectif",
                                        value:
                                            "${workout.targetTimeMinutes} min",
                                        iconColor: isGoalAchieved
                                            ? Colors.greenAccent
                                            : AppTheme.primaryAccent,
                                      ),
                                      _buildExpandedStatDetail(
                                        icon: Icons.bolt_rounded,
                                        label: "Intensité",
                                        value:
                                            "${(workout.calories / (workout.durationSeconds / 60 == 0 ? 1 : workout.durationSeconds / 60)).toStringAsFixed(1)} c/m",
                                        iconColor: Colors.orangeAccent,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildExpandedStatDetail({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
