import 'package:flutter/material.dart';
import 'package:nomad/pages/stats_page.dart';
import 'package:nomad/theme/app_theme.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'history_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Les 3 pages qui correspondent parfaitement aux 3 icônes du bas
  final List<Widget> _pages = [
    const HomePage(),
    const HistoryPage(),
    const StatsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.black,
        selectedItemColor: AppTheme.primaryAccent, // Ta couleur Vert/Jaune fluo
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed, // Évite les décalages visuels
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run_rounded),
            label: 'Course',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Statistiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
