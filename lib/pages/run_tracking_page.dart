import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/workout.dart';

class RunTrackingPage extends StatefulWidget {
  final int targetTimeMinutes;

  const RunTrackingPage({super.key, required this.targetTimeMinutes});

  @override
  State<RunTrackingPage> createState() => _RunTrackingPageState();
}

class _RunTrackingPageState extends State<RunTrackingPage> {
  int _secondsElapsed = 0;
  bool _isRunning = true;
  Timer? _timer;

  // Poids de l'utilisateur (récupéré depuis Firestore)
  int _userWeight = 70; // Valeur par défaut si non trouvé

  // Contrôleur pour animer et centrer la carte sur la position de l'utilisateur
  final MapController _mapController = MapController();

  // Simulation du tracé initial
  final List<LatLng> _routePoints = [
    const LatLng(48.8566, 2.3522),
    const LatLng(48.8570, 2.3530),
    const LatLng(48.8575, 2.3540),
  ];

  LatLng _currentLocation = const LatLng(48.8566, 2.3522);

  @override
  void initState() {
    super.initState();
    _loadUserWeight();
    _startTimer();
  }

  // Charger le poids de l'utilisateur depuis Firestore
  Future<void> _loadUserWeight() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['weight'] != null) {
            setState(() {
              _userWeight = (data['weight'] as num).toInt();
            });
          }
        }
      }
    } catch (e) {
      print("❌ Erreur lors de la récupération du poids pour les calories : $e");
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning && mounted) {
        setState(() {
          _secondsElapsed++;
          // Simulation d'un déplacement continu (légèrement accéléré pour la démo)
          _currentLocation = LatLng(
            _currentLocation.latitude + 0.00004,
            _currentLocation.longitude + 0.00004,
          );
          _routePoints.add(_currentLocation);

          // Déplace la caméra de la carte pour suivre le curseur
          _mapController.move(_currentLocation, _mapController.camera.zoom);
        });
      }
    });
  }

  void _toggleRun() {
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _stopRun() {
    // On met en pause le timer immédiatement dès qu'on interagit avec l'arrêt
    setState(() {
      _isRunning = false;
    });

    // Si l'utilisateur clique sur stop alors qu'il n'a pas commencé, on quitte directement
    if (_secondsElapsed == 0) {
      _timer?.cancel();
      Navigator.pop(context);
      return;
    }

    // Pop-up stylé de fin de course pour proposer l'enregistrement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Course terminée !",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Bravo ! Tu as parcouru ${_distanceKm.toStringAsFixed(2)} km en $_formattedTime.\nSouhaites-tu enregistrer cette activité ?",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _timer?.cancel();
                Navigator.pop(dialogContext); // Ferme la pop-up
                Navigator.pop(
                  context,
                ); // Quitte l'écran de course sans sauvegarder
              },
              child: const Text(
                "Ignorer",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext); // Ferme la pop-up d'abord
                _timer?.cancel(); // Coupe définitivement le timer
                await _saveWorkoutToFirestore(); // Lance la sauvegarde Firestore
              },
              child: const Text(
                "Enregistrer",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveWorkoutToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Affiche un écran de chargement pendant l'envoi des données
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryAccent),
      ),
    );

    try {
      // Instanciation de notre modèle Workout avec les données scientifiques réelles
      final workout = Workout(
        userId: user.uid,
        date: DateTime.now(),
        durationSeconds: _secondsElapsed,
        distanceKm: _distanceKm,
        calories:
            _calories, // Calories calculées scientifiquement selon son poids
        targetTimeMinutes: widget.targetTimeMinutes,
        routePoints: _routePoints,
      );

      // Ajout du document dans la collection "workouts" de Firestore
      await FirebaseFirestore.instance
          .collection('workouts')
          .add(workout.toMap());

      print("✅ Course enregistrée avec succès dans Firestore !");
    } catch (e) {
      print("❌ Erreur lors de la sauvegarde de la course : $e");
    }

    // Sortie propre et sécurisée des écrans (Vérification mounted obligatoire !)
    if (mounted) {
      Navigator.pop(context); // Ferme le loader (CircularProgressIndicator)
      Navigator.pop(context); // Retourne à l'écran d'accueil
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_secondsElapsed / 60).floor().toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _distanceKm {
    return (_secondsElapsed * 2.7) / 1000;
  }

  // 🧮 CALCUL SCIENTIFIQUE DES CALORIES EN FONCTION DU POIDS
  int get _calories {
    if (_distanceKm == 0) return 0;
    // Formule : Distance (km) * Poids (kg) * 1.036
    return (_distanceKm * _userWeight * 1.036).round();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Bloque le retour arrière physique natif d'Android
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _stopRun(); // Déclenche notre logique d'arrêt propre
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white),
            ),
            onPressed: _stopRun,
          ),
        ),
        body: Stack(
          children: [
            // Fond de carte style Waze / Mapbox Light
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(48.8566, 2.3522),
                initialZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 8.0,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.navigation,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Bannière supérieure d'objectif
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10),
                    ],
                  ),
                  child: Text(
                    'Objectif : ${widget.targetTimeMinutes} min',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Tableau de bord inférieur Premium (Effet Flou Glassmorphism)
            Positioned(
              bottom: 32,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Rangée des métriques (Calories & Kilomètres)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MetricItem(
                              icon: Icons.local_fire_department_rounded,
                              value: '$_calories',
                              unit: 'kcal',
                              color: Colors.orangeAccent,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white24,
                            ),
                            _MetricItem(
                              icon: Icons.speed_rounded,
                              value: _distanceKm.toStringAsFixed(2),
                              unit: 'km',
                              color: AppTheme.secondaryAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Chronomètre circulaire central
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: CircularProgressIndicator(
                                value: widget.targetTimeMinutes > 0
                                    ? (_secondsElapsed /
                                              (widget.targetTimeMinutes * 60))
                                          .clamp(0.0, 1.0)
                                    : 0.0,
                                strokeWidth: 8,
                                backgroundColor: Colors.white10,
                                color: AppTheme.primaryAccent,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formattedTime,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${widget.targetTimeMinutes} min obj.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Boutons de contrôle (Pause / Play / Stop)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ControlButton(
                              icon: Icons.stop_rounded,
                              color: Colors.white10,
                              iconColor: Colors.redAccent,
                              onPressed: _stopRun,
                              size: 64,
                            ),
                            const SizedBox(width: 32),
                            _ControlButton(
                              icon: _isRunning
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: AppTheme.primaryAccent,
                              onPressed: _toggleRun,
                              size: 80,
                              iconColor: Colors.black,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color color;

  const _MetricItem({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onPressed;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.iconColor = Colors.white,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
  }
}
