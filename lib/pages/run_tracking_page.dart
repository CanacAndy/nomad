import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
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
  bool _isRunning = false;
  Timer? _timer;

  int _userWeight = 70;
  final MapController _mapController = MapController();

  // Liste de points sécurisée (on commence vide)
  final List<LatLng> _routePoints = [];
  LatLng _currentLocation = const LatLng(48.8566, 2.3522); // Paris par défaut

  double _realDistanceKm = 0.0;
  StreamSubscription<Position>? _gpsSubscription;
  bool _isLoadingGps = true;

  @override
  void initState() {
    super.initState();
    _loadUserWeight();
    _initGpsTracking();
  }

  Future<void> _initGpsTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Obtenir la position précise au démarrage
    Position pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _routePoints.add(_currentLocation);
        _isLoadingGps = false;
        _isRunning = true;
      });
      _mapController.move(_currentLocation, 16.5);
      _startTimer();
    }

    // Écoute du flux GPS
    _gpsSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position position) {
          if (!_isRunning || !mounted) return;

          LatLng newPoint = LatLng(position.latitude, position.longitude);
          setState(() {
            double distance = Geolocator.distanceBetween(
              _currentLocation.latitude,
              _currentLocation.longitude,
              newPoint.latitude,
              newPoint.longitude,
            );
            _realDistanceKm += distance / 1000;
            _currentLocation = newPoint;
            _routePoints.add(newPoint);
          });
          _mapController.move(_currentLocation, _mapController.camera.zoom);
        });
  }

  Future<void> _loadUserWeight() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      final data = doc.data();
      setState(() {
        _userWeight = (data?['weight'] ?? data?['poids'] ?? 70).toInt();
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isRunning && mounted) setState(() => _secondsElapsed++);
    });
  }

  void _stopRun() {
    setState(() => _isRunning = false);
    if (_secondsElapsed < 5) {
      // Sécurité si stop immédiat
      _timer?.cancel();
      _gpsSubscription?.cancel();
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Course terminée !",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Bravo ! Tu as fait ${_realDistanceKm.toStringAsFixed(2)} km.\nSauvegarder ?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Annuler",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveWorkout();
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWorkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Sauvegarde de la course
    final workout = Workout(
      userId: user.uid,
      date: DateTime.now(),
      durationSeconds: _secondsElapsed,
      distanceKm: _realDistanceKm,
      calories: (_realDistanceKm * _userWeight * 1.036).round(),
      targetTimeMinutes: widget.targetTimeMinutes,
      routePoints: _routePoints,
    );

    await FirebaseFirestore.instance
        .collection('workouts')
        .add(workout.toMap());

    // 2. LOGIQUE DES BADGES (Trophées)
    await _checkAndUnlockBadges(user.uid);

    if (mounted) Navigator.pop(context);
  }

  // Moteur de vérification des Trophées
  Future<void> _checkAndUnlockBadges(String uid) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final workouts = await FirebaseFirestore.instance
        .collection('workouts')
        .where('userId', isEqualTo: uid)
        .get();

    List<String> unlocked = [];
    double totalKm = 0;
    for (var doc in workouts.docs) {
      totalKm += (doc.data()['distanceKm'] ?? 0.0);
    }

    if (workouts.docs.isNotEmpty) unlocked.add('first_run');
    if (_realDistanceKm >= 5.0) unlocked.add('five_k');
    if (_realDistanceKm >= 10.0) unlocked.add('ten_k');
    if (totalKm >= 50.0) unlocked.add('distance_50');

    await userDoc.update({'unlockedBadges': FieldValue.arrayUnion(unlocked)});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gpsSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 6,
                    color: AppTheme.primaryAccent,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Dashboard (Glassmorphism)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.black54,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statIcon(
                            Icons.local_fire_department,
                            "${(_realDistanceKm * _userWeight * 1.036).round()}",
                            "kcal",
                          ),
                          _statIcon(
                            Icons.straighten,
                            _realDistanceKm.toStringAsFixed(2),
                            "km",
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: widget.targetTimeMinutes > 0
                                  ? (_secondsElapsed /
                                        (widget.targetTimeMinutes * 60))
                                  : 0,
                              strokeWidth: 8,
                              strokeCap: StrokeCap
                                  .round, // 👈 CORRIGÉ : Remplace borderRadius
                              color: AppTheme.primaryAccent,
                              backgroundColor: Colors.white10,
                            ),
                          ),
                          Text(
                            _formattedTime,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton(
                            backgroundColor: Colors.redAccent,
                            onPressed: _stopRun,
                            child: const Icon(Icons.stop),
                          ),
                          const SizedBox(width: 20),
                          FloatingActionButton(
                            backgroundColor: AppTheme.primaryAccent,
                            onPressed: () =>
                                setState(() => _isRunning = !_isRunning),
                            child: Icon(
                              _isRunning ? Icons.pause : Icons.play_arrow,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoadingGps)
            Container(
              color: Colors.black87,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _statIcon(IconData icon, String val, String unit) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryAccent),
        Text(
          "$val $unit",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
