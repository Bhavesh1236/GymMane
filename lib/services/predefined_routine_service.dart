import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout.dart';
import '../state/fit_state.dart';
import 'plan_share.dart';

/// Single exercise within a pre-defined workout routine.
class PredefinedRoutineItem {
  const PredefinedRoutineItem({
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.restSeconds = 90,
    this.notes = '',
    this.sec,
    this.weightKg,
  });

  final String name;
  final int sets;
  final int? reps;
  final int restSeconds;
  final String notes;
  final int? sec;
  final double? weightKg;

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        if (reps != null) 'reps': reps,
        'restSeconds': restSeconds,
        if (notes.isNotEmpty) 'notes': notes,
        if (sec != null) 'sec': sec,
        if (weightKg != null) 'weightKg': weightKg,
      };

  factory PredefinedRoutineItem.fromJson(Map<String, dynamic> json) =>
      PredefinedRoutineItem(
        name: json['name'] as String? ?? 'Exercise',
        sets: (json['sets'] as num?)?.toInt() ?? 3,
        reps: (json['reps'] as num?)?.toInt(),
        restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 90,
        notes: json['notes'] as String? ?? '',
        sec: (json['sec'] as num?)?.toInt(),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
      );

  PlanItem toPlanItem() => PlanItem(
        name,
        sets,
        reps: reps,
        restSec: restSeconds,
        weightKg: weightKg,
        mode: sec != null ? 'timed' : '',
      );
}

/// A complete pre-defined workout routine that users can browse and import.
class PredefinedRoutine {
  const PredefinedRoutine({
    required this.id,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.description,
    required this.estimatedMinutes,
    required this.targetMuscles,
    required this.equipment,
    required this.exercises,
    this.defaultGroup = 'Pre-defined',
    this.suggestedWeekday,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String category; // 'Strength', 'Hypertrophy', 'Full Body', 'Home', 'HIIT', 'Targeted'
  final String difficulty; // 'Beginner', 'Intermediate', 'Advanced'
  final String description;
  final int estimatedMinutes;
  final List<String> targetMuscles;
  final List<String> equipment;
  final List<PredefinedRoutineItem> exercises;
  final String defaultGroup;
  final int? suggestedWeekday; // 1 = Monday, 7 = Sunday
  final bool isCustom;

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'difficulty': difficulty,
        'description': description,
        'estimatedMinutes': estimatedMinutes,
        'targetMuscles': targetMuscles,
        'equipment': equipment,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'defaultGroup': defaultGroup,
        if (suggestedWeekday != null) 'suggestedWeekday': suggestedWeekday,
        'isCustom': isCustom,
      };

  factory PredefinedRoutine.fromJson(Map<String, dynamic> json) =>
      PredefinedRoutine(
        id: json['id'] as String? ?? 'routine_${DateTime.now().millisecondsSinceEpoch}',
        name: json['name'] as String? ?? 'Routine',
        category: json['category'] as String? ?? 'Strength',
        difficulty: json['difficulty'] as String? ?? 'Intermediate',
        description: json['description'] as String? ?? '',
        estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 45,
        targetMuscles: (json['targetMuscles'] as List<dynamic>?)?.cast<String>() ?? [],
        equipment: (json['equipment'] as List<dynamic>?)?.cast<String>() ?? [],
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map((e) => PredefinedRoutineItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        defaultGroup: json['defaultGroup'] as String? ?? 'Pre-defined',
        suggestedWeekday: (json['suggestedWeekday'] as num?)?.toInt(),
        isCustom: json['isCustom'] as bool? ?? false,
      );

  PlanRoutine toPlanRoutine({String? groupOverride, int? dayOverride}) =>
      PlanRoutine(
        name,
        exercises.map((e) => e.toPlanItem()).toList(),
        group: groupOverride ?? defaultGroup,
        days: [
          if (dayOverride != null) dayOverride else if (suggestedWeekday != null) suggestedWeekday!,
        ],
      );
}

/// A multi-day program consisting of multiple pre-defined routines.
class PredefinedProgram {
  const PredefinedProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.daysPerWeek,
    required this.routines,
  });

  final String id;
  final String name;
  final String description;
  final String level;
  final int daysPerWeek;
  final List<PredefinedRoutine> routines;
}

/// Service to store, manage, and import pre-defined workout routines
/// into the user's personal fitness tracker.
class PredefinedRoutineService extends ChangeNotifier {
  PredefinedRoutineService._();
  static final PredefinedRoutineService instance = PredefinedRoutineService._();

  static const _customRoutinesKey = 'gymmane_custom_predefined_routines_v1';
  static const _bookmarkedIdsKey = 'gymmane_bookmarked_routines_v1';

  final List<PredefinedRoutine> _customRoutines = [];
  final Set<String> _bookmarkedIds = {};
  bool _initialized = false;

  /// Initialize the service by loading custom saved routines and bookmarks.
  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final customJson = prefs.getString(_customRoutinesKey);
      if (customJson != null && customJson.isNotEmpty) {
        final decoded = jsonDecode(customJson) as List<dynamic>;
        _customRoutines.clear();
        for (final item in decoded) {
          _customRoutines.add(PredefinedRoutine.fromJson(item as Map<String, dynamic>));
        }
      }

      final bookmarks = prefs.getStringList(_bookmarkedIdsKey);
      if (bookmarks != null) {
        _bookmarkedIds.addAll(bookmarks);
      }
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('PredefinedRoutineService init error: $e');
    }
  }

  /// All available pre-defined routines (built-in + custom created).
  List<PredefinedRoutine> get allRoutines => [
        ..._builtInRoutines,
        ..._customRoutines,
      ];

  /// All multi-day pre-defined workout programs.
  List<PredefinedProgram> get allPrograms => _builtInPrograms;

  /// Available categories for filtering.
  List<String> get categories => const [
        'All',
        'Strength',
        'Hypertrophy',
        'Full Body',
        'Home',
        'HIIT',
        'Targeted',
      ];

  /// Get routines filtered by category and difficulty.
  List<PredefinedRoutine> getRoutines({
    String category = 'All',
    String difficulty = 'All',
    String searchQuery = '',
  }) {
    return allRoutines.where((r) {
      if (category != 'All' && r.category.toLowerCase() != category.toLowerCase()) {
        return false;
      }
      if (difficulty != 'All' && r.difficulty.toLowerCase() != difficulty.toLowerCase()) {
        return false;
      }
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchesName = r.name.toLowerCase().contains(q);
        final matchesDesc = r.description.toLowerCase().contains(q);
        final matchesMuscle = r.targetMuscles.any((m) => m.toLowerCase().contains(q));
        final matchesExercise = r.exercises.any((e) => e.name.toLowerCase().contains(q));
        if (!matchesName && !matchesDesc && !matchesMuscle && !matchesExercise) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Checks if a routine is bookmarked by the user.
  bool isBookmarked(String routineId) => _bookmarkedIds.contains(routineId);

  /// Toggle bookmark status for a routine.
  Future<void> toggleBookmark(String routineId) async {
    if (_bookmarkedIds.contains(routineId)) {
      _bookmarkedIds.remove(routineId);
    } else {
      _bookmarkedIds.add(routineId);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_bookmarkedIdsKey, _bookmarkedIds.toList());
    } catch (_) {}
  }

  /// Check whether a routine from the pre-defined catalog is already imported
  /// in the user's personal routines.
  bool isImportedInTracker(PredefinedRoutine routine) {
    return fit.routines.any((r) =>
        r.name.trim().toLowerCase() == routine.name.trim().toLowerCase() ||
        (r.exerciseIds.length == routine.exercises.length &&
            r.group == routine.defaultGroup));
  }

  /// Import a pre-defined routine into the user's personal routines tracker.
  /// Returns the imported Routine object.
  Routine? importRoutineToTracker(
    PredefinedRoutine routine, {
    String? customGroupName,
    int? weekdaySchedule,
    int? scaleSets,
  }) {
    final group = customGroupName ?? routine.defaultGroup;
    final planRoutine = PlanRoutine(
      routine.name,
      routine.exercises.map((e) {
        return PlanItem(
          e.name,
          scaleSets ?? e.sets,
          reps: e.reps,
          restSec: e.restSeconds,
          weightKg: e.weightKg,
          mode: e.sec != null ? 'timed' : '',
        );
      }).toList(),
      group: group,
      days: [if (weekdaySchedule != null) weekdaySchedule],
    );

    final result = fit.applyPlan([planRoutine], schedule: weekdaySchedule != null);
    if (result.added > 0 || result.routines > 0) {
      // Find the imported routine
      final imported = fit.routines.reversed.firstWhere(
        (r) => r.name.toLowerCase() == routine.name.toLowerCase() && r.group == group,
        orElse: () => fit.routines.last,
      );
      notifyListeners();
      return imported;
    }
    return null;
  }

  /// Import an entire multi-day program into personal routines.
  /// Automatically sets routine groups and optional weekly schedule.
  int importProgramToTracker(
    PredefinedProgram program, {
    bool schedule = true,
  }) {
    final plans = program.routines.map((r) {
      return r.toPlanRoutine(
        groupOverride: program.name,
        dayOverride: r.suggestedWeekday,
      );
    }).toList();

    final result = fit.applyPlan(plans, schedule: schedule);
    notifyListeners();
    return result.routines;
  }

  /// Save a new custom pre-defined routine into storage.
  Future<void> saveCustomRoutine(PredefinedRoutine routine) async {
    final custom = PredefinedRoutine(
      id: routine.id.isEmpty ? 'custom_${DateTime.now().millisecondsSinceEpoch}' : routine.id,
      name: routine.name,
      category: routine.category,
      difficulty: routine.difficulty,
      description: routine.description,
      estimatedMinutes: routine.estimatedMinutes,
      targetMuscles: routine.targetMuscles,
      equipment: routine.equipment,
      exercises: routine.exercises,
      defaultGroup: routine.defaultGroup,
      suggestedWeekday: routine.suggestedWeekday,
      isCustom: true,
    );

    final idx = _customRoutines.indexWhere((r) => r.id == custom.id);
    if (idx >= 0) {
      _customRoutines[idx] = custom;
    } else {
      _customRoutines.add(custom);
    }

    notifyListeners();
    await _persistCustomRoutines();
  }

  /// Delete a custom saved pre-defined routine.
  Future<void> deleteCustomRoutine(String routineId) async {
    _customRoutines.removeWhere((r) => r.id == routineId);
    _bookmarkedIds.remove(routineId);
    notifyListeners();
    await _persistCustomRoutines();
  }

  /// Export a pre-defined routine as a JSON string for sharing or backup.
  String exportRoutineAsJson(PredefinedRoutine routine) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(routine.toJson());
  }

  /// Import a routine from raw JSON string and save it to custom catalog.
  Future<PredefinedRoutine?> importRoutineFromJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString.trim()) as Map<String, dynamic>;
      final routine = PredefinedRoutine.fromJson(decoded);
      await saveCustomRoutine(routine);
      return routine;
    } catch (e) {
      debugPrint('Failed to import routine from JSON: $e');
      return null;
    }
  }

  Future<void> _persistCustomRoutines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_customRoutines.map((r) => r.toJson()).toList());
      await prefs.setString(_customRoutinesKey, encoded);
    } catch (_) {}
  }

  // =========================================================================
  // Built-in Curated Workout Routines Library
  // =========================================================================
  static final List<PredefinedRoutine> _builtInRoutines = [
    // 1. Push Day Hypertrophy
    const PredefinedRoutine(
      id: 'push_hypertrophy',
      name: 'Push Day (Chest, Shoulders, Triceps)',
      category: 'Hypertrophy',
      difficulty: 'Intermediate',
      description:
          'High-volume chest, anterior deltoid, and triceps workout focused on progressive overload and maximum muscle tension.',
      estimatedMinutes: 55,
      targetMuscles: ['Chest', 'Shoulders', 'Triceps'],
      equipment: ['Barbell', 'Dumbbells', 'Cables', 'Bench'],
      defaultGroup: 'PPL Split',
      suggestedWeekday: 1,
      exercises: [
        PredefinedRoutineItem(name: 'Barbell Bench Press', sets: 4, reps: 8, restSeconds: 120, notes: 'Heavy compound base'),
        PredefinedRoutineItem(name: 'Incline Dumbbell Press', sets: 3, reps: 10, restSeconds: 90, notes: 'Upper chest focus'),
        PredefinedRoutineItem(name: 'Overhead Press', sets: 3, reps: 8, restSeconds: 90, notes: 'Strict shoulder power'),
        PredefinedRoutineItem(name: 'Lateral Raise', sets: 4, reps: 12, restSeconds: 60, notes: 'Side delt isolation'),
        PredefinedRoutineItem(name: 'Triceps Pushdown', sets: 3, reps: 12, restSeconds: 60, notes: 'Full triceps lockout'),
        PredefinedRoutineItem(name: 'Cable Fly', sets: 3, reps: 12, restSeconds: 60, notes: 'Deep chest stretch'),
      ],
    ),

    // 2. Pull Day Hypertrophy
    const PredefinedRoutine(
      id: 'pull_hypertrophy',
      name: 'Pull Day (Back, Biceps, Rear Delts)',
      category: 'Hypertrophy',
      difficulty: 'Intermediate',
      description:
          'Complete back thickness and width routine with targeted lat engagement, rear delt posture correction, and peak bicep curls.',
      estimatedMinutes: 55,
      targetMuscles: ['Back', 'Biceps', 'Rear Delts'],
      equipment: ['Barbell', 'Dumbbells', 'Pull-up Bar', 'Cables'],
      defaultGroup: 'PPL Split',
      suggestedWeekday: 3,
      exercises: [
        PredefinedRoutineItem(name: 'Deadlift', sets: 3, reps: 5, restSeconds: 150, notes: 'Posterior chain builder'),
        PredefinedRoutineItem(name: 'Pull Up', sets: 4, reps: 8, restSeconds: 90, notes: 'Full lat stretch and contraction'),
        PredefinedRoutineItem(name: 'Barbell Row', sets: 4, reps: 8, restSeconds: 90, notes: 'Torso at 45 degrees, pull to navel'),
        PredefinedRoutineItem(name: 'Lat Pulldown', sets: 3, reps: 10, restSeconds: 75, notes: 'Controlled eccentric'),
        PredefinedRoutineItem(name: 'Face Pull', sets: 4, reps: 15, restSeconds: 60, notes: 'External shoulder rotation'),
        PredefinedRoutineItem(name: 'Barbell Curl', sets: 3, reps: 10, restSeconds: 60, notes: 'Strict bicep isolation'),
      ],
    ),

    // 3. Leg Day Power & Quads
    const PredefinedRoutine(
      id: 'leg_power',
      name: 'Leg Day (Quads, Hamstrings, Calves)',
      category: 'Strength',
      difficulty: 'Intermediate',
      description:
          'Comprehensive lower body session hitting quads, hamstrings, glutes, and calves with heavy barbell squats and hamstring extensions.',
      estimatedMinutes: 60,
      targetMuscles: ['Quads', 'Hamstrings', 'Glutes', 'Calves'],
      equipment: ['Barbell', 'Squat Rack', 'Leg Press', 'Machines'],
      defaultGroup: 'PPL Split',
      suggestedWeekday: 5,
      exercises: [
        PredefinedRoutineItem(name: 'Barbell Squat', sets: 4, reps: 8, restSeconds: 150, notes: 'Depth below parallel'),
        PredefinedRoutineItem(name: 'Romanian Deadlift', sets: 3, reps: 10, restSeconds: 90, notes: 'Hinge at hips, stretch hamstrings'),
        PredefinedRoutineItem(name: 'Leg Press', sets: 3, reps: 12, restSeconds: 90, notes: 'Foot placement shoulder-width'),
        PredefinedRoutineItem(name: 'Leg Curl', sets: 3, reps: 12, restSeconds: 60, notes: 'Squeeze hamstrings at contraction'),
        PredefinedRoutineItem(name: 'Standing Calf Raise', sets: 4, reps: 15, restSeconds: 60, notes: '2 second pause at bottom stretch'),
      ],
    ),

    // 4. Upper Body Power & Hypertrophy
    const PredefinedRoutine(
      id: 'upper_power',
      name: 'Upper Body Power & Mass',
      category: 'Strength',
      difficulty: 'Intermediate',
      description:
          'Heavy compound pressing and pulling routine designed for upper torso thickness, explosive pushing strength, and muscular balance.',
      estimatedMinutes: 50,
      targetMuscles: ['Chest', 'Back', 'Shoulders', 'Arms'],
      equipment: ['Barbell', 'Dumbbells', 'Bench', 'Cables'],
      defaultGroup: 'Upper Lower Split',
      suggestedWeekday: 1,
      exercises: [
        PredefinedRoutineItem(name: 'Barbell Bench Press', sets: 4, reps: 6, restSeconds: 120, notes: 'Powerlifting arch and drive'),
        PredefinedRoutineItem(name: 'Barbell Row', sets: 4, reps: 6, restSeconds: 120, notes: 'Overhand grip, strict form'),
        PredefinedRoutineItem(name: 'Overhead Press', sets: 3, reps: 8, restSeconds: 90, notes: 'Lockout overhead'),
        PredefinedRoutineItem(name: 'Lat Pulldown', sets: 3, reps: 10, restSeconds: 75, notes: 'Wide grip pull to chest'),
        PredefinedRoutineItem(name: 'Hammer Curl', sets: 3, reps: 10, restSeconds: 60, notes: 'Brachialis and forearm thickness'),
        PredefinedRoutineItem(name: 'Triceps Dip', sets: 3, reps: 10, restSeconds: 60, notes: 'Chest or bodyweight dips'),
      ],
    ),

    // 5. Lower Body Strength & Core
    const PredefinedRoutine(
      id: 'lower_strength',
      name: 'Lower Body Strength & Core',
      category: 'Strength',
      difficulty: 'Intermediate',
      description:
          'Foundation leg day combining heavy squats with hinge work and high-intensity abdominal stabilization.',
      estimatedMinutes: 50,
      targetMuscles: ['Quads', 'Hamstrings', 'Glutes', 'Core'],
      equipment: ['Barbell', 'Squat Rack', 'Leg Extension', 'Mat'],
      defaultGroup: 'Upper Lower Split',
      suggestedWeekday: 2,
      exercises: [
        PredefinedRoutineItem(name: 'Barbell Squat', sets: 4, reps: 6, restSeconds: 150, notes: 'Solid brace and upright chest'),
        PredefinedRoutineItem(name: 'Romanian Deadlift', sets: 3, reps: 8, restSeconds: 90, notes: 'Keep bar close to shins'),
        PredefinedRoutineItem(name: 'Leg Extension', sets: 3, reps: 12, restSeconds: 60, notes: 'Quad peak contraction'),
        PredefinedRoutineItem(name: 'Leg Curl', sets: 3, reps: 12, restSeconds: 60, notes: 'Slow negative descent'),
        PredefinedRoutineItem(name: 'Standing Calf Raise', sets: 4, reps: 12, restSeconds: 60, notes: 'Full dorsiflexion'),
        PredefinedRoutineItem(name: 'Plank', sets: 3, reps: 1, sec: 60, restSeconds: 60, notes: 'Hollow body hold'),
      ],
    ),

    // 6. Full Body 3-Day Foundation
    const PredefinedRoutine(
      id: 'fullbody_foundation',
      name: 'Full Body 3-Day Foundation',
      category: 'Full Body',
      difficulty: 'Beginner',
      description:
          'The ultimate beginner-to-intermediate full body workout. Hits all major muscle groups in under 45 minutes with time-tested compound lifts.',
      estimatedMinutes: 45,
      targetMuscles: ['Chest', 'Back', 'Quads', 'Shoulders', 'Core'],
      equipment: ['Barbell', 'Squat Rack', 'Bench'],
      defaultGroup: 'Foundations',
      suggestedWeekday: 1,
      exercises: [
        PredefinedRoutineItem(name: 'Barbell Squat', sets: 3, reps: 8, restSeconds: 90, notes: 'Focus on form consistency'),
        PredefinedRoutineItem(name: 'Barbell Bench Press', sets: 3, reps: 8, restSeconds: 90, notes: 'Tuck elbows at 45 degrees'),
        PredefinedRoutineItem(name: 'Barbell Row', sets: 3, reps: 8, restSeconds: 90, notes: 'Controlled pull to abdomen'),
        PredefinedRoutineItem(name: 'Overhead Press', sets: 3, reps: 8, restSeconds: 75, notes: 'Keep glutes and core tight'),
        PredefinedRoutineItem(name: 'Romanian Deadlift', sets: 3, reps: 8, restSeconds: 90, notes: 'Hamstring stretch'),
        PredefinedRoutineItem(name: 'Plank', sets: 3, reps: 1, sec: 45, restSeconds: 60, notes: 'Core stability brace'),
      ],
    ),

    // 7. StrongLifts 5x5 Workout A
    const PredefinedRoutine(
      id: 'stronglifts_a',
      name: 'StrongLifts 5×5 (Workout A)',
      category: 'Strength',
      difficulty: 'Beginner',
      description:
          'Classic 5x5 linear progression program for raw strength and density. Squat, bench press, and row with maximum focus on progressive resistance.',
      estimatedMinutes: 45,
      targetMuscles: ['Quads', 'Chest', 'Back', 'Core'],
      equipment: ['Barbell', 'Squat Rack', 'Bench'],
      defaultGroup: 'StrongLifts 5x5',
      suggestedWeekday: 1,
      exercises: [
        PredefinedRoutineItem(name: 'Barbell Squat', sets: 5, reps: 5, restSeconds: 180, notes: 'Heavy 5 reps across all sets'),
        PredefinedRoutineItem(name: 'Barbell Bench Press', sets: 5, reps: 5, restSeconds: 180, notes: 'Pause slightly at chest touch'),
        PredefinedRoutineItem(name: 'Barbell Row', sets: 5, reps: 5, restSeconds: 120, notes: 'Pendlay or bent-over row from floor'),
      ],
    ),

    // 8. StrongLifts 5x5 Workout B
    const PredefinedRoutine(
      id: 'stronglifts_b',
      name: 'StrongLifts 5×5 (Workout B)',
      category: 'Strength',
      difficulty: 'Beginner',
      description:
          'Workout B of the classic 5x5 protocol. Heavy squats, strict overhead military press, and maximal deadlift.',
      estimatedMinutes: 45,
      targetMuscles: ['Quads', 'Shoulders', 'Lower Back', 'Hamstrings'],
      equipment: ['Barbell', 'Squat Rack'],
      defaultGroup: 'StrongLifts 5x5',
      suggestedWeekday: 3,
      exercises: [
        PredefinedRoutineItem(name: 'Barbell Squat', sets: 5, reps: 5, restSeconds: 180, notes: '5x5 working sets'),
        PredefinedRoutineItem(name: 'Overhead Press', sets: 5, reps: 5, restSeconds: 180, notes: 'Strict overhead standing press'),
        PredefinedRoutineItem(name: 'Deadlift', sets: 1, reps: 5, restSeconds: 180, notes: '1 heavy working top set of 5'),
      ],
    ),

    // 9. Dumbbell Home Muscle Builder
    const PredefinedRoutine(
      id: 'dumbbell_home',
      name: 'Dumbbell-Only Home Muscle Builder',
      category: 'Home',
      difficulty: 'Beginner',
      description:
          'Requires only a pair of dumbbells. Complete full-body hypertrophy stimulus for home workouts without needing gym machines.',
      estimatedMinutes: 40,
      targetMuscles: ['Chest', 'Quads', 'Back', 'Shoulders', 'Arms'],
      equipment: ['Dumbbells', 'Mat'],
      defaultGroup: 'Home Workouts',
      suggestedWeekday: 2,
      exercises: [
        PredefinedRoutineItem(name: 'Incline Dumbbell Press', sets: 4, reps: 10, restSeconds: 75, notes: 'Floor press or bench press'),
        PredefinedRoutineItem(name: 'Bodyweight Squat', sets: 4, reps: 12, restSeconds: 75, notes: 'Hold dumbbell at chest (Goblet Squat)'),
        PredefinedRoutineItem(name: 'Seated Cable Row', sets: 4, reps: 10, restSeconds: 60, notes: 'Bent over dumbbell row'),
        PredefinedRoutineItem(name: 'Dumbbell Standing Overhead Press', sets: 3, reps: 10, restSeconds: 60, notes: 'Strict shoulder press'),
        PredefinedRoutineItem(name: 'Hammer Curl', sets: 3, reps: 12, restSeconds: 60, notes: 'Alternate arms or together'),
        PredefinedRoutineItem(name: 'Push Up', sets: 3, reps: 15, restSeconds: 60, notes: 'Standard chest push up'),
      ],
    ),

    // 10. Bodyweight Calisthenics Progression
    const PredefinedRoutine(
      id: 'bodyweight_calisthenics',
      name: 'Bodyweight Calisthenics Progression',
      category: 'Home',
      difficulty: 'Intermediate',
      description:
          'Master relative body strength with zero weights. Uses pull-ups, push-ups, dips, and core levers for athletic functional fitness.',
      estimatedMinutes: 40,
      targetMuscles: ['Chest', 'Back', 'Arms', 'Core', 'Quads'],
      equipment: ['Pull-up Bar', 'Dip Bars'],
      defaultGroup: 'Calisthenics',
      suggestedWeekday: 2,
      exercises: [
        PredefinedRoutineItem(name: 'Pull Up', sets: 4, reps: 8, restSeconds: 90, notes: 'Chest to bar, full extension'),
        PredefinedRoutineItem(name: 'Push Up', sets: 4, reps: 15, restSeconds: 60, notes: 'Keep body in straight plank line'),
        PredefinedRoutineItem(name: 'Triceps Dip', sets: 3, reps: 10, restSeconds: 75, notes: 'Controlled 90 degree elbow bend'),
        PredefinedRoutineItem(name: 'Bodyweight Squat', sets: 4, reps: 20, restSeconds: 60, notes: 'Explosive ascent'),
        PredefinedRoutineItem(name: 'Hanging Leg Raise', sets: 3, reps: 12, restSeconds: 60, notes: 'Toes to bar or knee tucks'),
        PredefinedRoutineItem(name: 'Plank', sets: 3, reps: 1, sec: 60, restSeconds: 60, notes: 'Hold firm core tension'),
      ],
    ),

    // 11. HIIT & Core Conditioning Circuit
    const PredefinedRoutine(
      id: 'hiit_core_circuit',
      name: 'HIIT & Core Conditioning Circuit',
      category: 'HIIT',
      difficulty: 'Intermediate',
      description:
          'High intensity metabolic conditioning and core shred. Accelerates calorie burn and builds endurance between weight training days.',
      estimatedMinutes: 30,
      targetMuscles: ['Cardio', 'Core', 'Full Body'],
      equipment: ['Mat', 'Jump Rope'],
      defaultGroup: 'Conditioning',
      suggestedWeekday: 6,
      exercises: [
        PredefinedRoutineItem(name: 'Push Up', sets: 4, reps: 15, restSeconds: 45, notes: 'Speed tempo'),
        PredefinedRoutineItem(name: 'Bodyweight Squat', sets: 4, reps: 20, restSeconds: 45, notes: 'Continuous rhythm'),
        PredefinedRoutineItem(name: 'Lunge', sets: 3, reps: 12, restSeconds: 45, notes: 'Walking or jumping lunges'),
        PredefinedRoutineItem(name: 'Hanging Leg Raise', sets: 3, reps: 15, restSeconds: 45, notes: 'Core crunch compression'),
        PredefinedRoutineItem(name: 'Plank', sets: 3, reps: 1, sec: 60, restSeconds: 45, notes: 'Side plank or standard plank'),
      ],
    ),

    // 12. Arm Annihilator & Shoulders
    const PredefinedRoutine(
      id: 'arm_annihilator',
      name: 'Arm & Shoulder Sculpt (Pump Day)',
      category: 'Targeted',
      difficulty: 'Intermediate',
      description:
          'Dedicated arm and shoulder hypertrophy session focusing on biceps, triceps long & lateral heads, and deltoid caps.',
      estimatedMinutes: 45,
      targetMuscles: ['Biceps', 'Triceps', 'Shoulders'],
      equipment: ['Barbell', 'Dumbbells', 'Cables'],
      defaultGroup: 'Specialization',
      suggestedWeekday: 6,
      exercises: [
        PredefinedRoutineItem(name: 'Overhead Press', sets: 4, reps: 8, restSeconds: 90, notes: 'Shoulder mass builder'),
        PredefinedRoutineItem(name: 'Barbell Curl', sets: 4, reps: 10, restSeconds: 60, notes: 'Strict form, no swinging'),
        PredefinedRoutineItem(name: 'Skull Crushers', sets: 4, reps: 10, restSeconds: 60, notes: 'Elbows tucked, deep stretch'),
        PredefinedRoutineItem(name: 'Lateral Raise', sets: 4, reps: 12, restSeconds: 45, notes: 'Side delt burn'),
        PredefinedRoutineItem(name: 'Hammer Curl', sets: 3, reps: 12, restSeconds: 45, notes: 'Cross-body or straight'),
        PredefinedRoutineItem(name: 'Triceps Pushdown', sets: 3, reps: 15, restSeconds: 45, notes: 'Drop set on last set'),
      ],
    ),

    // 13. Glute & Hamstring Focus
    const PredefinedRoutine(
      id: 'glute_hamstring_focus',
      name: 'Glute & Hamstring Specialization',
      category: 'Targeted',
      difficulty: 'Intermediate',
      description:
          'Specialized posterior chain workout targeting glute hypertrophy, hamstring flexibility and strength, and hip drive.',
      estimatedMinutes: 50,
      targetMuscles: ['Glutes', 'Hamstrings', 'Lower Back'],
      equipment: ['Barbell', 'Bench', 'Dumbbells', 'Machines'],
      defaultGroup: 'Specialization',
      suggestedWeekday: 4,
      exercises: [
        PredefinedRoutineItem(name: 'Romanian Deadlift', sets: 4, reps: 8, restSeconds: 90, notes: 'Hinge back deeply'),
        PredefinedRoutineItem(name: 'Barbell Squat', sets: 4, reps: 10, restSeconds: 90, notes: 'Sumo or wide stance'),
        PredefinedRoutineItem(name: 'Leg Press', sets: 3, reps: 12, restSeconds: 75, notes: 'High foot placement for glutes'),
        PredefinedRoutineItem(name: 'Leg Curl', sets: 3, reps: 12, restSeconds: 60, notes: 'Hamstring isolation'),
        PredefinedRoutineItem(name: 'Lunge', sets: 3, reps: 12, restSeconds: 60, notes: 'Deep step forward'),
      ],
    ),

    // 14. 20-Minute Express Torso
    const PredefinedRoutine(
      id: 'express_torso',
      name: '20-Minute Express Torso Blast',
      category: 'Targeted',
      difficulty: 'Beginner',
      description:
          'Short on time? A super-efficient 20-minute workout that delivers maximum stimulus to chest, back, and shoulders with zero wasted minutes.',
      estimatedMinutes: 20,
      targetMuscles: ['Chest', 'Back', 'Shoulders'],
      equipment: ['Dumbbells', 'Bench'],
      defaultGroup: 'Express Workouts',
      suggestedWeekday: 4,
      exercises: [
        PredefinedRoutineItem(name: 'Barbell Bench Press', sets: 3, reps: 10, restSeconds: 60, notes: 'Superset ready'),
        PredefinedRoutineItem(name: 'Barbell Row', sets: 3, reps: 10, restSeconds: 60, notes: 'Explosive drive'),
        PredefinedRoutineItem(name: 'Overhead Press', sets: 3, reps: 10, restSeconds: 60, notes: 'Immediate press'),
        PredefinedRoutineItem(name: 'Lat Pulldown', sets: 3, reps: 10, restSeconds: 60, notes: 'Full pump finisher'),
      ],
    ),
  ];

  // =========================================================================
  // Built-in Multi-Day Programs
  // =========================================================================
  static final List<PredefinedProgram> _builtInPrograms = [
    PredefinedProgram(
      id: 'program_ppl',
      name: 'Push Pull Legs (PPL)',
      description:
          'The gold standard 3 to 6-day bodybuilding split. Alternates push muscles, pull muscles, and lower body for optimal hypertrophy and recovery.',
      level: 'Intermediate',
      daysPerWeek: 3,
      routines: [
        _builtInRoutines.firstWhere((r) => r.id == 'push_hypertrophy'),
        _builtInRoutines.firstWhere((r) => r.id == 'pull_hypertrophy'),
        _builtInRoutines.firstWhere((r) => r.id == 'leg_power'),
      ],
    ),
    PredefinedProgram(
      id: 'program_upper_lower',
      name: 'Upper / Lower 4-Day Split',
      description:
          'Balanced 4-day per week schedule allowing every muscle group to be trained twice a week with adequate rest for joint recovery and strength gains.',
      level: 'Intermediate',
      daysPerWeek: 4,
      routines: [
        _builtInRoutines.firstWhere((r) => r.id == 'upper_power'),
        _builtInRoutines.firstWhere((r) => r.id == 'lower_strength'),
      ],
    ),
    PredefinedProgram(
      id: 'program_fullbody_3day',
      name: '3-Day Full Body Classic',
      description:
          'Perfect for beginners and busy lifters. 3 comprehensive workouts per week (Monday, Wednesday, Friday) hitting every major movement pattern.',
      level: 'Beginner',
      daysPerWeek: 3,
      routines: [
        _builtInRoutines.firstWhere((r) => r.id == 'fullbody_foundation'),
      ],
    ),
    PredefinedProgram(
      id: 'program_stronglifts',
      name: 'StrongLifts 5×5 Strength Protocol',
      description:
          'The world-renowned 5x5 compound strength routine. Alternate Workout A and Workout B 3 times a week to build serious baseline power.',
      level: 'Beginner to Intermediate',
      daysPerWeek: 3,
      routines: [
        _builtInRoutines.firstWhere((r) => r.id == 'stronglifts_a'),
        _builtInRoutines.firstWhere((r) => r.id == 'stronglifts_b'),
      ],
    ),
    PredefinedProgram(
      id: 'program_home_bodyweight',
      name: 'Minimalist Home & Bodyweight Split',
      description:
          'No gym membership required. Alternate dumbbell training and calisthenics progressions to stay lean and strong anywhere.',
      level: 'All Levels',
      daysPerWeek: 3,
      routines: [
        _builtInRoutines.firstWhere((r) => r.id == 'dumbbell_home'),
        _builtInRoutines.firstWhere((r) => r.id == 'bodyweight_calisthenics'),
        _builtInRoutines.firstWhere((r) => r.id == 'hiit_core_circuit'),
      ],
    ),
  ];
}
