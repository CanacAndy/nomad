import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 💡 INDISPENSABLE POUR LA SÉCURITÉ
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'package:nomad/providers/user_provider.dart';
import 'package:nomad/pages/main_navigation.dart';
import 'package:nomad/pages/login_page.dart'; // 💡 Import de ta page de connexion (adapte le chemin)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('fr_FR', null);
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialisé avec succès !");
  } catch (e) {
    print("❌ Erreur d'initialisation : $e");
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nomad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      // 💡 SÉCURISATION ICI : On utilise un StreamBuilder à la racine
      home: const AuthGate(),
    );
  }
}

// 🔐 LE COMPOSANT BARRIÈRE DE SÉCURITÉ
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance
          .authStateChanges(), // Écoute l'état de connexion
      builder: (context, snapshot) {
        // Pendant le chargement initial de l'état de connexion
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            ),
          );
        }

        // 🟢 Si le snapshot a des données, l'utilisateur est connecté
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigation();
        }

        // 🔴 Sinon, l'utilisateur n'est pas connecté -> Direction la page de Login
        return const LoginPage();
      },
    );
  }
}
