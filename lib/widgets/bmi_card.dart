import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BmiCard extends StatelessWidget {
  final double weightKg;
  final double heightCm;

  const BmiCard({super.key, required this.weightKg, required this.heightCm});

  // 🧮 Calcul de l'IMC
  double get _bmi {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    final heightMeters = heightCm / 100;
    return weightKg / (heightMeters * heightMeters);
  }

  // 🎨 Récupération des infos de catégorie (Texte, Couleur, Pourcentage de la jauge)
  Map<String, dynamic> _getBmiStatus() {
    final score = _bmi;
    if (score <= 0) {
      return {'label': 'Inconnu', 'color': Colors.grey, 'percent': 0.0};
    } else if (score < 18.5) {
      return {
        'label': 'Insuffisance pondérale',
        'color': Colors.blueAccent,
        'percent': 0.25,
      };
    } else if (score < 25.0) {
      return {
        'label': 'Corpulence normale 🎯',
        'color': Colors.greenAccent,
        'percent': 0.5,
      };
    } else if (score < 30.0) {
      return {
        'label': 'Surpoids',
        'color': Colors.orangeAccent,
        'percent': 0.75,
      };
    } else {
      return {'label': 'Obésité', 'color': Colors.redAccent, 'percent': 1.0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final bmiValue = _bmi;
    final status = _getBmiStatus();
    final Color statusColor = status['color'];
    final String statusLabel = status['label'];
    final double progressPercent = status['percent'];

    if (bmiValue == 0.0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête sécurisé contre l'overflow (bande jaune et noire)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Icon(
                      Icons.favorite_rounded,
                      color: Colors.pinkAccent,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Indice de Masse Corporelle",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Score IMC et poids/taille
          Row(
            crossAxisAlignment: CrossAxisAlignment.end, // Corrigé !
            children: [
              Text(
                bmiValue.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900, // Corrigé !
                  letterSpacing: -1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6, bottom: 8),
                child: Text(
                  "IMC",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                "${weightKg.toStringAsFixed(0)} kg / ${heightCm.toStringAsFixed(0)} cm",
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 📊 Jauge linéaire animée
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    height: 8,
                    width: constraints.maxWidth * progressPercent,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.3),
                          statusColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
