import 'package:flutter/material.dart';

class WorkoutBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const WorkoutBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Liste globale de tous les badges de l'application
const List<WorkoutBadge> appBadges = [
  WorkoutBadge(
    id: 'first_run',
    title: 'Premier Pas',
    description: 'Enregistrer ta toute première course.',
    icon: Icons.directions_run_rounded,
    color: Colors.greenAccent,
  ),
  WorkoutBadge(
    id: 'five_k',
    title: 'Le Cap des 5K',
    description: 'Parcourir au moins 5 km en une seule course.',
    icon: Icons.bolt_rounded,
    color: Colors.cyanAccent,
  ),
  WorkoutBadge(
    id: 'ten_k',
    title: 'Dix de Der',
    description: 'Parcourir au moins 10 km en une seule course.',
    icon: Icons.workspace_premium_rounded,
    color: Colors.orangeAccent,
  ),
  WorkoutBadge(
    id: 'regular_3',
    title: 'Habitué',
    description: 'Courir au moins 3 fois dans la même semaine.',
    icon: Icons.calendar_month_rounded,
    color: Colors.purpleAccent,
  ),
  WorkoutBadge(
    id: 'distance_50',
    title: 'Demi-Centenaire',
    description: 'Cumuler un total de 50 km parcourus.',
    icon: Icons.emoji_events_rounded,
    color: Colors.amber,
  ),
];
