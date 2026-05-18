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

  // Variables pour les rouleaux de sélection (Taille & Poids)
  int _selectedHeight = 170; // Valeur par défaut (en cm)
  int _selectedWeight = 70; // Valeur par défaut (en kg)

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
          _goalController.text = (data['weeklyGoal'] ?? '20').toString();

          // Récupération sécurisée de la taille et du poids depuis Firestore
          if (data['height'] != null)
            _selectedHeight = (data['height'] as num).toInt();
          if (data['weight'] != null)
            _selectedWeight = (data['weight'] as num).toInt();
        }
      }
    } catch (e) {
      print("❌ Erreur lors du chargement du profil : $e");
    } finally {
      if (mounted) {
        setState(() => _isInitLoading = false);
      }
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
        await FirebaseFirestore.instance.collection('users').doc(_uid).update({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'weeklyGoal': int.tryParse(_goalController.text.trim()) ?? 20,
          'height':
              _selectedHeight, // Sauvegarde de la taille choisie au rouleau
          'weight': _selectedWeight, // Sauvegarde du poids choisi au rouleau
        });

        _showSnackBar("Profil mis à jour avec succès !");

        if (mounted) Navigator.pop(context);
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

  // Fonction pour afficher le rouleau de sélection (BottomSheet fluide)
  void _showScrollPicker({
    required String title,
    required int minValue,
    required int maxValue,
    required int initialValue,
    required String unit,
    required Function(int) onValueSelected,
  }) {
    int localPickedValue = initialValue;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: 320,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          onValueSelected(localPickedValue);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Valider",
                          style: TextStyle(
                            color: AppTheme.primaryAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Barre de sélection centrale en arrière-plan
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryAccent.withOpacity(0.3),
                            ),
                          ),
                        ),
                        // Rouleau de défilement (Scroll Wheel natif de Flutter)
                        ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
                          controller: FixedExtentScrollController(
                            initialItem: initialValue - minValue,
                          ),
                          onSelectedItemChanged: (index) {
                            localPickedValue = minValue + index;
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: (maxValue - minValue) + 1,
                            builder: (context, index) {
                              final value = minValue + index;
                              return Center(
                                child: Text(
                                  "$value $unit",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Modifier le profil',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                  // Photo de profil
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
                  const SizedBox(height: 24),

                  // 📊 SECTION DES ROULEAUX (Taille & Poids)
                  Row(
                    children: [
                      // Rouleau Taille
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showScrollPicker(
                            title: "Choisir ta taille",
                            minValue: 100,
                            maxValue: 250,
                            initialValue: _selectedHeight,
                            unit: "cm",
                            onValueSelected: (val) =>
                                setState(() => _selectedHeight = val),
                          ),
                          child: _buildPickerDisplay(
                            "Taille",
                            "$_selectedHeight cm",
                            Icons.straighten_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Rouleau Poids
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showScrollPicker(
                            title: "Choisir ton poids",
                            minValue: 30,
                            maxValue: 200,
                            initialValue: _selectedWeight,
                            unit: "kg",
                            onValueSelected: (val) =>
                                setState(() => _selectedWeight = val),
                          ),
                          child: _buildPickerDisplay(
                            "Poids",
                            "$_selectedWeight kg",
                            Icons.fitness_center_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Bouton Enregistrer
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

  // Petit widget personnalisé pour afficher le bouton d'ouverture des rouleaux Taille/Poids
  Widget _buildPickerDisplay(String label, String value, IconData icon) {
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryAccent, size: 22),
              const SizedBox(width: 12),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
