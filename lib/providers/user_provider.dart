import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _userData;
  double _weeklyProgressCalculated =
      0.0; // Contiendra le total des km de la semaine

  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<QuerySnapshot>? _workoutsSubscription;

  // Getters pour récupérer facilement les données dans les pages
  Map<String, dynamic>? get userData => _userData;
  String get name => _userData?['name'] ?? "Coureur";
  String get email => _userData?['email'] ?? "";
  double get weeklyGoal => (_userData?['weeklyGoal'] ?? 20.0).toDouble();
  List<dynamic> get badges => _userData?['badges'] ?? [];

  // 💡 Le progrès est maintenant calculé dynamiquement en temps réel
  double get weeklyProgress => _weeklyProgressCalculated;

  UserProvider() {
    _startListeningToUser();
    _startListeningToWeeklyWorkouts();
  }

  // Écoute les infos de profil de l'utilisateur
  void _startListeningToUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists) {
              _userData = snapshot.data();
              notifyListeners();
            }
          });
    }
  }

  // 📊 Écoute les courses de l'utilisateur pour calculer le score de la semaine en cours
  void _startListeningToWeeklyWorkouts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // On trouve la date du lundi de la semaine actuelle à 00h00
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );

    _workoutsSubscription = FirebaseFirestore.instance
        .collection('workouts')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
          double totalKmThisWeek = 0.0;

          for (var doc in snapshot.docs) {
            final data = doc.data();

            // Sécurité sur la date
            if (data['date'] != null) {
              final DateTime workoutDate = (data['date'] as Timestamp).toDate();

              // Si la course a eu lieu cette semaine (depuis lundi 00h00)
              if (workoutDate.isAfter(startOfWeek)) {
                final distance = data['distanceKm'];
                if (distance != null) {
                  totalKmThisWeek += (distance as num).toDouble();
                }
              }
            }
          }

          // On met à jour la variable et on prévient l'interface
          _weeklyProgressCalculated = totalKmThisWeek;
          notifyListeners(); // 💡 Force la jauge de la HomePage à se mettre à jour instantanément !
        });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _workoutsSubscription?.cancel();
    super.dispose();
  }
}
