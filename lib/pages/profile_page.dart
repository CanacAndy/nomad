import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Variables pour les statistiques globales calculées en temps réel
  int _totalWorkouts = 0;
  double _totalDistance = 0.0;
  StreamSubscription<QuerySnapshot>? _statsSubscription;

  @override
  void initState() {
    super.initState();
    _listenToGlobalStats();
  }

  // Écoute TOUTES les courses de l'utilisateur pour sommer les statistiques globales
  void _listenToGlobalStats() {
    if (user == null) return;

    _statsSubscription = FirebaseFirestore.instance
        .collection('workouts')
        .where('userId', isEqualTo: user!.uid)
        .snapshots()
        .listen((snapshot) {
          int count = snapshot.docs.length;
          double distanceCumulee = 0.0;

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final distance = data['distanceKm'];
            if (distance != null) {
              distanceCumulee += (distance as num).toDouble();
            }
          }

          if (mounted) {
            setState(() {
              _totalWorkouts = count;
              _totalDistance = distanceCumulee;
            });
          }
        });
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 💡 On récupère instantanément les données du Provider sans faire de requêtes manuelles !
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Custom Header (Gradient + Avatar)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryAccent.withOpacity(0.9),
                        AppTheme.secondaryAccent.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mon Profil',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Colors.black87,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfilePage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: AppTheme.darkBackground,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          user?.photoURL ??
                              'https://i.pravatar.cc/150?u=${user?.uid}',
                        ),
                        backgroundColor: AppTheme.cardColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // --- VRAIES INFOS UTILISATEUR VIA PROVIDER ---
            Text(
              userProvider.name, // Nom réactif et mis à jour instantanément
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              userProvider.email.isNotEmpty
                  ? userProvider.email
                  : (user?.email ?? 'Email non disponible'),
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),

            // Statistics Grid (Branché sur de vraies valeurs !)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques Globales',
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
                        child: _buildStatCard(
                          Icons.directions_run_rounded,
                          'Courses',
                          '$_totalWorkouts', // Vrai nombre cumulé
                          Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          Icons.speed_rounded,
                          'Distance total',
                          '${_totalDistance.toStringAsFixed(1)} km', // Vrais kilomètres cumulés
                          AppTheme.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Menu Options
                  const Text(
                    'Paramètres',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuOption(
                    Icons.person_outline_rounded,
                    'Modifier le profil',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                    },
                  ),

                  // --- BOUTON DÉCONNEXION ---
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();

                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.logout_rounded, color: Colors.redAccent),
                          SizedBox(width: 16),
                          Text(
                            'Se déconnecter',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
    );
  }
}
