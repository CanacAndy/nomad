import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nomad/pages/auth_wrapper.dart'; // Ta nouvelle page de sécurité
import 'package:nomad/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const NomadApp());
}

class NomadApp extends StatelessWidget {
  const NomadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nomad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Le wrapper décide si on montre Login ou Home
      home: AuthWrapper(),
    );
  }
}
