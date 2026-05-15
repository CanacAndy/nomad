import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Workout {
  final String? id;
  final String userId;
  final DateTime date;
  final int durationSeconds;
  final double distanceKm;
  final int calories;
  final int targetTimeMinutes;
  final List<LatLng> routePoints;

  Workout({
    this.id,
    required this.userId,
    required this.date,
    required this.durationSeconds,
    required this.distanceKm,
    required this.calories,
    required this.targetTimeMinutes,
    required this.routePoints,
  });

  // Convertit un objet Workout en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'durationSeconds': durationSeconds,
      'distanceKm': distanceKm,
      'calories': calories,
      'targetTimeMinutes': targetTimeMinutes,
      // Sauvegarde des coordonnées GPS sous forme de liste de maps
      'routePoints': routePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
    };
  }

  // Crée un objet Workout à partir d'un document Firestore
  factory Workout.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Récupération et reconstruction des points GPS
    final List<dynamic> pointsData = data['routePoints'] ?? [];
    List<LatLng> points = pointsData.map((p) {
      return LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble());
    }).toList();

    return Workout(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      durationSeconds: data['durationSeconds'] ?? 0,
      distanceKm: (data['distanceKm'] as num).toDouble(),
      calories: data['calories'] ?? 0,
      targetTimeMinutes: data['targetTimeMinutes'] ?? 0,
      routePoints: points,
    );
  }
}
