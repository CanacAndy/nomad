import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _goalController = TextEditingController();

  bool _isInitLoading = true;
  bool _isSaving = false;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 1. Charger les données actuelles depuis Firestore
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _uid = user.uid;
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          // Si tu as un champ 'weeklyGoal' dans Firestore, sinon valeur par défaut '20'
          _goalController.text = (data['weeklyGoal'] ?? '20').toString();
        }
      }
    } catch (e) {
      print("❌ Erreur lors du chargement du profil : $e");
    } finally {
      setState(() => _isInitLoading = false);
    }
  }

  // 2. Sauvegarder les modifications dans Firestore
  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      _showSnackBar(
        "Le nom et l'email ne peuvent pas être vides",
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_uid != null) {
        // Enregistrement des nouvelles données
        await FirebaseFirestore.instance.collection('users').doc(_uid).update({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'weeklyGoal': int.tryParse(_goalController.text.trim()) ?? 20,
        });

        _showSnackBar("Profil mis à jour avec succès !");
        if (mounted) Navigator.pop(context); // Retour à la page précédente
      }
    } catch (e) {
      print("❌ Erreur lors de la sauvegarde : $e");
      _showSnackBar(
        "Impossible d'enregistrer les modifications",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Modifier le profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isInitLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Photo de profil avec l'icône appareil photo
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?img=11',
                            ),
                            backgroundColor: AppTheme.cardColor,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.secondaryAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Formulaire dynamique relié aux contrôleurs
                  _buildTextField(
                    'Nom complet',
                    _nameController,
                    Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    'Email',
                    _emailController,
                    Icons.email_outlined,
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    'Objectif hebdomadaire (km)',
                    _goalController,
                    Icons.flag_outlined,
                    type: TextInputType.number,
                  ),
                  const SizedBox(height: 48),

                  // Bouton Enregistrer / Loading
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 60),
                      backgroundColor: AppTheme.primaryAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Enregistrer les modifications',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primaryAccent),
          ),
        ),
      ],
    );
  }
}
