import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../widgets/bmi_card.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'badges_page.dart'; // 👈 Importation de la page des trophées

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  int _totalWorkouts = 0;
  double _totalDistance = 0.0;
  StreamSubscription<QuerySnapshot>? _statsSubscription;

  @override
  void initState() {
    super.initState();
    _listenToGlobalStats();
  }

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

  ImageProvider _getAvatarImage(String? base64String) {
    if (base64String != null && base64String.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        debugPrint("❌ Erreur décodage Base64 : $e");
      }
    }
    return NetworkImage('https://i.pravatar.cc/150?u=${user?.uid}');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          String? photoBase64;
          Map<String, dynamic>? userData;

          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            if (userData != null) {
              photoBase64 = userData['photoBase64'];
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryAccent.withValues(alpha: 0.9),
                            AppTheme.secondaryAccent.withValues(alpha: 0.6),
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
                            backgroundImage: _getAvatarImage(photoBase64),
                            backgroundColor: AppTheme.cardColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                Text(
                  userProvider.name,
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
                              '$_totalWorkouts',
                              Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              Icons.speed_rounded,
                              'Distance totale',
                              '${_totalDistance.toStringAsFixed(1)} km',
                              AppTheme.primaryAccent,
                            ),
                          ),
                        ],
                      ),

                      if (userData != null) ...[
                        () {
                          final rawWeight =
                              userData?['weight'] ?? userData?['poids'] ?? 0.0;
                          final rawHeight =
                              userData?['height'] ?? userData?['taille'] ?? 0.0;

                          final double weight = (rawWeight as num).toDouble();
                          final double height = (rawHeight as num).toDouble();

                          if (weight > 0 && height > 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 32),
                                const Text(
                                  'Analyse de Santé',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                BmiCard(weightKg: weight, heightCm: height),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }(),
                      ],

                      const SizedBox(height: 32),
                      const Text(
                        'Paramètres',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🏆 AJOUT : Option de menu pour accéder aux Badges
                      _buildMenuOption(
                        Icons.emoji_events_rounded,
                        'Mes Trophées & Badges',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BadgesPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

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

                      const SizedBox(height: 24),
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
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Colors.redAccent,
                              ),
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
          );
        },
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

  // 🛠️ Stylisation uniforme des options cliquables sous forme de tuiles sombres
  Widget _buildMenuOption(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(icon, color: AppTheme.primaryAccent, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
