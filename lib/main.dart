import 'package:flutter/material.dart';
import 'package:nomad/pages/login_page.dart';
import 'package:nomad/theme/app_theme.dart';

void main() {
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
      home: const LoginPage(),
    );
  }
}
