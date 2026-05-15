import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Récupération de l'utilisateur actuel
  final User? user = FirebaseAuth.instance.currentUser;
  String userName = "Chargement...";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fonction pour récupérer le nom dans Firestore
  Future<void> _fetchUserData() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          userName = doc.data()!['name'] ?? "Utilisateur";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

            // --- VRAIES INFOS UTILISATEUR ---
            Text(
              userName, // Vrai nom venant de Firestore
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ??
                  'Email non disponible', // Vrai email de Firebase Auth
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),

            // Statistics Grid (Ici, tu pourras brancher tes vrais calculs plus tard)
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
                          '0',
                          Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          Icons.speed_rounded,
                          'Distance',
                          '0 km',
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

                  // --- BOUTON DÉCONNEXION RÉEL ---
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      // Grâce à ton AuthWrapper dans main.dart, l'app reviendra au Login toute seule.
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

  // Tes widgets de construction (StatCard et MenuOption) restent les mêmes...
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
