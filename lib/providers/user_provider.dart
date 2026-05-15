import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _userData;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  // Getters pour récupérer facilement les données dans les pages
  Map<String, dynamic>? get userData => _userData;
  String get name => _userData?['name'] ?? "Coureur";
  String get email => _userData?['email'] ?? "";
  double get weeklyGoal => (_userData?['weeklyGoal'] ?? 20.0).toDouble();
  double get weeklyProgress => (_userData?['weeklyProgress'] ?? 0.0).toDouble();
  List<dynamic> get badges => _userData?['badges'] ?? [];

  UserProvider() {
    _startListeningToUser();
  }

  // Écoute Firestore en temps réel et avertit toute l'app dès que ça change
  void _startListeningToUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists) {
              _userData = snapshot.data() as Map<String, dynamic>?;
              notifyListeners(); // 💡 C'est ça qui force TOUTES les pages à se rafraîchir !
            }
          });
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
