import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../models/workout.dart';
import 'run_tracking_page.dart';
import 'history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _selectedTime = 30; // minutes
  String _selectedTerrain = 'Route';

  final List<String> _terrains = ['Route', 'Nature', 'Mixte'];

  double get _estimatedDistance => (_selectedTime / 60) * 10; // Approx 10km/h

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = FirebaseAuth.instance.currentUser;

    final String userName = userProvider.name;
    final double weeklyGoal = userProvider.weeklyGoal;
    final double weeklyProgress = userProvider.weeklyProgress;

    // Calcul du pourcentage pour l'anneau de progression
    double progressPercentage = weeklyGoal > 0
        ? (weeklyProgress / weeklyGoal)
        : 0.0;
    if (progressPercentage > 1.0) progressPercentage = 1.0;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Nomad',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête : Bonjour dynamique
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.cardColor,
                  child: Icon(Icons.person, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour $userName,',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 16),
                    ),
                    Text(
                      'Prêt à dépasser vos limites ?',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Suivi d'objectif Hebdomadaire dynamique
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Objectif de la semaine',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${weeklyProgress.toStringAsFixed(1)} / ${weeklyGoal.toInt()} km',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progressPercentage * 100).toInt()}% complété',
                        style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 70,
                        width: 70,
                        child: CircularProgressIndicator(
                          value: progressPercentage,
                          backgroundColor: Colors.white10,
                          color: AppTheme.primaryAccent,
                          strokeWidth: 7,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Icon(
                        Icons.directions_run_rounded,
                        color: progressPercentage >= 1.0
                            ? AppTheme.secondaryAccent
                            : Colors.white,
                        size: 26,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 🔄 SECTION DYNAMIQUE CORRIGÉE (Plus besoin d'index Firebase composite !)
            if (user != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('workouts')
                    .where('userId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryAccent,
                        ),
                      ),
                    );
                  }

                  // Correction : On vérifie si on a des données locales après filtrage
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Center(
                        child: Text(
                          "Aucune course enregistrée. C'est le moment de s'y mettre ! 🚀",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  // 💡 ASTUCE : On convertit les documents et on trie côté client (évite le bug d'index)
                  List<Workout> workouts = snapshot.data!.docs
                      .map((doc) => Workout.fromFirestore(doc))
                      .toList();

                  // Tri de la plus récente à la plus ancienne
                  workouts.sort((a, b) => b.date.compareTo(a.date));

                  final lastWorkout = workouts.first;

                  final String dateFormatted = DateFormat(
                    'dd MMM yyyy',
                    'fr_FR',
                  ).format(lastWorkout.date);
                  final String durationFormatted =
                      "${(lastWorkout.durationSeconds / 60).floor()} min";

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.cardColor,
                            AppTheme.cardColor.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              color: AppTheme.primaryAccent,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dernière course',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$dateFormatted • $durationFormatted • ${lastWorkout.distanceKm.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),

            // Section Générer un tracé
            Text(
              'Générer un tracé',
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 24),

            // Sélecteur de terrain
            Text('Terrain', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: _terrains.map((terrain) {
                final isSelected = _selectedTerrain == terrain;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTerrain = terrain),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryAccent
                            : AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryAccent
                              : Colors.white10,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          terrain,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Sélecteur de temps
            Text(
              'Durée de la course',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${_selectedTime.toInt()}',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'min',
                        style: TextStyle(
                          fontSize: 20,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Distance estimée : ~${_estimatedDistance.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: AppTheme.secondaryAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryAccent,
                      inactiveTrackColor: Colors.white10,
                      thumbColor: AppTheme.primaryAccent,
                      overlayColor: AppTheme.primaryAccent.withOpacity(0.2),
                      trackHeight: 12,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 14,
                      ),
                    ),
                    child: Slider(
                      value: _selectedTime,
                      min: 10,
                      max: 120,
                      divisions: 22,
                      onChanged: (value) =>
                          setState(() => _selectedTime = value),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '10 min',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '120 min',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Bouton Démarrer
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RunTrackingPage(
                      targetTimeMinutes: _selectedTime.toInt(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.black,
                elevation: 10,
                shadowColor: AppTheme.primaryAccent.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Démarrer la course',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, size: 24),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
