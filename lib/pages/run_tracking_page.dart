import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

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

  // Simulate movement path
  final List<LatLng> _routePoints = [
    const LatLng(48.8566, 2.3522),
    const LatLng(48.8570, 2.3530),
    const LatLng(48.8575, 2.3540),
  ];

  LatLng _currentLocation = const LatLng(48.8566, 2.3522);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning) {
        setState(() {
          _secondsElapsed++;
          // Simulate slight movement
          _currentLocation = LatLng(
            _currentLocation.latitude + 0.00001,
            _currentLocation.longitude + 0.00001,
          );
          _routePoints.add(_currentLocation);
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
    _timer?.cancel();
    Navigator.pop(context); // Return to home
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_secondsElapsed / 60).floor().toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _distanceKm {
    // Simulate distance (e.g. 10km/h = ~2.7m/s)
    return (_secondsElapsed * 2.7) / 1000;
  }

  int get _calories {
    // Simulate calories (e.g. 10 calories per minute)
    return (_secondsElapsed / 60 * 10).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          // Waze-style map background
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(48.8566, 2.3522),
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                // CartoDB Voyager has a bright, clean style somewhat reminiscent of Waze
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              PolylineLayer(
                polylines: [
                  Polyline<Object>(
                    points: _routePoints,
                    strokeWidth: 8.0,
                    color: Colors.blueAccent, // Waze bold blue route
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

          // Top Info Banner (Target Time)
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

          // Premium Bottom Dashboard (Glassmorphism effect)
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
                      // Top Row: Metrics
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

                      // Central Circular Timer
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: CircularProgressIndicator(
                              value:
                                  (_secondsElapsed /
                                          (widget.targetTimeMinutes * 60))
                                      .clamp(0.0, 1.0),
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
                                style: TextStyle(
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

                      // Bottom Row: Controls
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
