import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  bool _isLoading = false;

  Future<void> _register() async {
    // 1. Validation locale
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty) {
      _showError("Veuillez remplir le nom, l'email et le mot de passe");
      return;
    }

    setState(() => _isLoading = true);
    print("🚀 Tentative d'inscription...");

    try {
      // 2. Création Auth - On n'assigne pas de variable ici pour éviter le bug de cast Pigeon
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. Récupération manuelle de l'utilisateur connecté
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        print("✅ Utilisateur Auth détecté : ${user.uid}");

        // 4. Enregistrement Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()) ?? 0,
          'weight': double.tryParse(_weightController.text.trim()) ?? 0.0,
          'height': double.tryParse(_heightController.text.trim()) ?? 0.0,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print("🔥 Firestore mis à jour avec succès !");

        if (mounted) {
          Navigator.of(context).pop(); // Retour à l'écran précédent
        }
      } else {
        throw Exception(
          "L'utilisateur n'a pas pu être récupéré après création.",
        );
      }
    } on FirebaseAuthException catch (e) {
      print("❌ Erreur Auth: ${e.code}");
      _showError(_translateError(e.code));
    } catch (e) {
      // Si l'erreur Pigeon survient quand même, on vérifie si l'Auth a quand même réussi
      final userFallback = FirebaseAuth.instance.currentUser;
      if (userFallback != null) {
        print(
          "⚠️ Erreur de cast détectée mais utilisateur connecté. Forçage Firestore...",
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userFallback.uid)
            .set({
              'uid': userFallback.uid,
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'age': int.tryParse(_ageController.text.trim()) ?? 0,
              'weight': double.tryParse(_weightController.text.trim()) ?? 0.0,
              'height': double.tryParse(_heightController.text.trim()) ?? 0.0,
              'createdAt': FieldValue.serverTimestamp(),
            });
        if (mounted) Navigator.of(context).pop();
      } else {
        print("❌ Erreur critique : $e");
        _showError("Erreur : $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _translateError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return "Cet email est déjà utilisé.";
      case 'invalid-email':
        return "Format d'email invalide.";
      case 'weak-password':
        return "Mot de passe trop court (6 caractères min).";
      default:
        return "Erreur lors de l'inscription.";
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Créer un compte',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              _buildInput(_nameController, 'Nom complet', Icons.person_outline),
              const SizedBox(height: 16),
              _buildInput(
                _emailController,
                'Email',
                Icons.email_outlined,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildInput(
                _passwordController,
                'Mot de passe',
                Icons.lock_outline,
                obscure: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      _ageController,
                      'Âge',
                      Icons.cake,
                      type: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInput(
                      _weightController,
                      'Kg',
                      Icons.fitness_center,
                      type: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInput(
                      _heightController,
                      'Cm',
                      Icons.height,
                      type: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'S\'INSCRIRE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscure = false,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
