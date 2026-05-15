import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/workout.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

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
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 💡 CORRECTION : Plus de orderBy ici pour éviter le blocage d'index Firestore
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
            return const Center(
              child: Text(
                "Aucune course enregistrée.\nBouge de là et va courir ! 🏃‍♂️",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            );
          }

          // Convertit les documents Firestore en liste de Workout
          List<Workout> workouts = snapshot.data!.docs
              .map((doc) => Workout.fromFirestore(doc))
              .toList();

          // 💡 TRUC EN PLUS : On trie les courses de la plus récente à la plus ancienne directement en Dart
          workouts.sort((a, b) => b.date.compareTo(a.date));

          // Calcul des statistiques globales
          double totalKm = 0;
          int totalCalories = 0;
          int totalSeconds = 0;

          for (var w in workouts) {
            totalKm += w.distanceKm;
            totalCalories += w.calories;
            totalSeconds += w.durationSeconds;
          }

          final totalDurationStr =
              "${(totalSeconds / 60).floor()}m ${totalSeconds % 60}s";

          return Column(
            children: [
              // 📊 SECTION STATISTIQUES (Dashboard Premium)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                        totalDurationStr,
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

              // 🏃‍♂️ LISTE DES COURSES
              Expanded(
                child: ListView.builder(
                  itemCount: workouts.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    final dateFormated = DateFormat(
                      'dd MMMM yyyy à HH:mm',
                      'fr_FR',
                    ).format(workout.date);
                    final durationStr =
                        "${(workout.durationSeconds / 60).floor()}:${(workout.durationSeconds % 60).toString().padLeft(2, '0')}";

                    return Card(
                      color: Colors.white.withOpacity(0.03),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_run_rounded,
                            color: AppTheme.primaryAccent,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          "${workout.distanceKm.toStringAsFixed(2)} km",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              dateFormated,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              durationStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${workout.calories} kcal",
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
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
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
