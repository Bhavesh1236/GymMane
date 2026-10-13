import 'package:flutter/material.dart';

import '../models/exercise.dart';
import 'app_colors.dart';

class MuscleCategory {
  final String id;
  final String label;
  final Color primary;
  final Color secondary;

  const MuscleCategory({
    required this.id,
    required this.label,
    required this.primary,
    required this.secondary,
  });

  LinearGradient get gradient => LinearGradient(
        colors: [primary, secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient badgeGradient() => LinearGradient(
        colors: [
          primary.withValues(alpha: 0.20),
          secondary.withValues(alpha: 0.12),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient cardGradient(GymColors gc, {bool isDark = true}) => LinearGradient(
        colors: isDark
            ? [
                gc.bgRaised,
                Color.lerp(gc.bgRaised, primary, 0.08)!,
                Color.lerp(gc.bgRaised2, secondary, 0.06)!,
              ]
            : [
                gc.bgRaised,
                Color.lerp(gc.bgRaised, primary, 0.05)!,
                Color.lerp(gc.bgRaised2, secondary, 0.03)!,
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

const List<MuscleCategory> kMuscleCategories = [
  MuscleCategory(
    id: 'chest',
    label: 'Chest',
    primary: Color(0xFFFF5252),
    secondary: Color(0xFFFF7A00),
  ),
  MuscleCategory(
    id: 'back',
    label: 'Back',
    primary: Color(0xFF00B4D8),
    secondary: Color(0xFF0077B6),
  ),
  MuscleCategory(
    id: 'legs',
    label: 'Legs',
    primary: Color(0xFF10B981),
    secondary: Color(0xFF059669),
  ),
  MuscleCategory(
    id: 'shoulders',
    label: 'Shoulders',
    primary: Color(0xFFA855F7),
    secondary: Color(0xFF7C3AED),
  ),
  MuscleCategory(
    id: 'arms',
    label: 'Arms',
    primary: Color(0xFFF59E0B),
    secondary: Color(0xFFEA580C),
  ),
  MuscleCategory(
    id: 'core',
    label: 'Core',
    primary: Color(0xFFEC4899),
    secondary: Color(0xFFBE185D),
  ),
];

MuscleCategory musclePaletteFor(String muscleId) {
  final group = muscleGroup(muscleId).toLowerCase();
  for (final cat in kMuscleCategories) {
    if (cat.id == muscleId.toLowerCase() || cat.id == group) {
      return cat;
    }
  }
  return const MuscleCategory(
    id: 'other',
    label: 'Fitness',
    primary: Color(0xFF00F0FF),
    secondary: Color(0xFF00B4D8),
  );
}
