import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/measure.dart';
import '../models/workout.dart';
import '../state/fit_state.dart';

/// Summary inspection of a JSON export before importing.
class DataInspectionResult {
  const DataInspectionResult({
    required this.isValid,
    this.sessionCount = 0,
    this.bodyweightCount = 0,
    this.measureCount = 0,
    this.routineCount = 0,
    this.earliestDate,
    this.latestDate,
    this.errorMessage,
    this.parsedData,
  });

  final bool isValid;
  final int sessionCount;
  final int bodyweightCount;
  final int measureCount;
  final int routineCount;
  final DateTime? earliestDate;
  final DateTime? latestDate;
  final String? errorMessage;
  final Map<String, dynamic>? parsedData;
}

/// Service to handle exporting and importing user workout history
/// and progress data as portable JSON files to ensure privacy and data ownership.
class DataPortabilityService {
  DataPortabilityService._();
  static final DataPortabilityService instance = DataPortabilityService._();

  static const String kSchemaVersion = 'gymmane-workout-export-v1';

  /// Generate a clean, structured JSON string of workout history and progress data.
  String generateExportJson({bool formatted = true}) {
    final data = {
      'schema': kSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'GymMane',
      'units': fit.units,
      'summary': {
        'totalSessions': fit.sessions.length,
        'totalBodyweightLogs': fit.bodyweight.length,
        'totalBodyMeasures': fit.measures.length,
        'totalRoutines': fit.routines.length,
      },
      'workoutHistory': fit.sessions.map((s) => s.toJson()).toList(),
      'progressData': {
        'bodyweight': fit.bodyweight.map((b) => b.toJson()).toList(),
        'bodyMeasures': fit.measures.map((m) => m.toJson()).toList(),
      },
      'routines': fit.routines.map((r) => r.toJson()).toList(),
      'profile': fit.profile.toJson(),
    };

    if (formatted) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    }
    return jsonEncode(data);
  }

  /// Export workout history and progress data directly to a `.json` file and share it.
  Future<File?> exportToJsonFile() async {
    try {
      final jsonString = generateExportJson(formatted: true);
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().split('T').first;
      final file = File('${dir.path}/gymmane-workout-history-$stamp.json');
      await file.writeAsString(jsonString, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'GymMane Workout History & Progress ($stamp)',
        ),
      );
      return file;
    } catch (e) {
      debugPrint('Export to JSON file error: $e');
      return null;
    }
  }

  /// Copy the complete JSON export string to system clipboard.
  Future<void> copyJsonToClipboard() async {
    final jsonString = generateExportJson(formatted: true);
    await Clipboard.setData(ClipboardData(text: jsonString));
  }

  /// Inspect a raw JSON string to preview contents and validate structure.
  DataInspectionResult inspectJson(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return const DataInspectionResult(
        isValid: false,
        errorMessage: 'JSON content is empty.',
      );
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return const DataInspectionResult(
          isValid: false,
          errorMessage: 'Invalid format: Root must be a JSON object.',
        );
      }

      // Check for workout history
      List<dynamic> sessionsRaw = [];
      if (decoded.containsKey('workoutHistory') && decoded['workoutHistory'] is List) {
        sessionsRaw = decoded['workoutHistory'] as List<dynamic>;
      } else if (decoded.containsKey('sessions') && decoded['sessions'] is List) {
        sessionsRaw = decoded['sessions'] as List<dynamic>;
      }

      // Check for bodyweight
      List<dynamic> weightRaw = [];
      if (decoded['progressData'] is Map && decoded['progressData']['bodyweight'] is List) {
        weightRaw = decoded['progressData']['bodyweight'] as List<dynamic>;
      } else if (decoded['bodyweight'] is List) {
        weightRaw = decoded['bodyweight'] as List<dynamic>;
      }

      // Check for body measures
      List<dynamic> measuresRaw = [];
      if (decoded['progressData'] is Map && decoded['progressData']['bodyMeasures'] is List) {
        measuresRaw = decoded['progressData']['bodyMeasures'] as List<dynamic>;
      } else if (decoded['measures'] is List) {
        measuresRaw = decoded['measures'] as List<dynamic>;
      }

      // Check for routines
      List<dynamic> routinesRaw = [];
      if (decoded['routines'] is List) {
        routinesRaw = decoded['routines'] as List<dynamic>;
      }

      // Determine date ranges
      DateTime? earliest;
      DateTime? latest;
      for (final s in sessionsRaw) {
        if (s is Map && s['d'] is String) {
          final dt = DateTime.tryParse(s['d'] as String);
          if (dt != null) {
            if (earliest == null || dt.isBefore(earliest)) earliest = dt;
            if (latest == null || dt.isAfter(latest)) latest = dt;
          }
        }
      }

      return DataInspectionResult(
        isValid: true,
        sessionCount: sessionsRaw.length,
        bodyweightCount: weightRaw.length,
        measureCount: measuresRaw.length,
        routineCount: routinesRaw.length,
        earliestDate: earliest,
        latestDate: latest,
        parsedData: decoded,
      );
    } catch (e) {
      return DataInspectionResult(
        isValid: false,
        errorMessage: 'Malformed JSON: $e',
      );
    }
  }

  /// Pick a JSON file from device storage.
  Future<String?> pickJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;

      final file = result.files.single;
      if (file.bytes != null) {
        return utf8.decode(file.bytes!, allowMalformed: true);
      }
      if (file.path != null) {
        return await File(file.path!).readAsString();
      }
      return null;
    } catch (e) {
      debugPrint('Error picking JSON file: $e');
      return null;
    }
  }

  /// Import workout history and progress data into GymMane.
  /// If [merge] is true, adds new non-duplicate records. If false, replaces records.
  ({bool success, int sessionsAdded, int weightsAdded, int measuresAdded, int routinesAdded, String? error})
      importJsonData(String rawJson, {bool merge = true}) {
    final inspection = inspectJson(rawJson);
    if (!inspection.isValid || inspection.parsedData == null) {
      return (
        success: false,
        sessionsAdded: 0,
        weightsAdded: 0,
        measuresAdded: 0,
        routinesAdded: 0,
        error: inspection.errorMessage ?? 'Invalid JSON content',
      );
    }

    final data = inspection.parsedData!;
    var sessionsAdded = 0;
    var weightsAdded = 0;
    var measuresAdded = 0;
    var routinesAdded = 0;

    try {
      // 1. Process Workout Sessions
      List<dynamic> sessionsList = [];
      if (data.containsKey('workoutHistory') && data['workoutHistory'] is List) {
        sessionsList = data['workoutHistory'] as List<dynamic>;
      } else if (data.containsKey('sessions') && data['sessions'] is List) {
        sessionsList = data['sessions'] as List<dynamic>;
      }

      if (!merge) {
        fit.sessions.clear();
      }

      final existingSessionKeys = fit.sessions
          .map((s) => '${s.date.toIso8601String().split("T").first}_${s.exercises.length}')
          .toSet();

      for (final item in sessionsList) {
        if (item is! Map) continue;
        try {
          final s = LoggedSession.fromJson(item.cast<String, dynamic>());
          final key = '${s.date.toIso8601String().split("T").first}_${s.exercises.length}';
          if (!merge || !existingSessionKeys.contains(key)) {
            fit.sessions.add(s);
            existingSessionKeys.add(key);
            sessionsAdded++;
          }
        } catch (_) {}
      }

      // 2. Process Bodyweight Entries
      List<dynamic> weightList = [];
      if (data['progressData'] is Map && data['progressData']['bodyweight'] is List) {
        weightList = data['progressData']['bodyweight'] as List<dynamic>;
      } else if (data['bodyweight'] is List) {
        weightList = data['bodyweight'] as List<dynamic>;
      }

      if (!merge) {
        fit.bodyweight.clear();
      }

      final existingWeightKeys = fit.bodyweight
          .map((w) => '${w.date.year}-${w.date.month}-${w.date.day}')
          .toSet();

      for (final item in weightList) {
        if (item is! Map) continue;
        try {
          final bw = BodyweightEntry.fromJson(item.cast<String, dynamic>());
          final dayKey = '${bw.date.year}-${bw.date.month}-${bw.date.day}';
          if (!merge || !existingWeightKeys.contains(dayKey)) {
            fit.bodyweight.add(bw);
            existingWeightKeys.add(dayKey);
            weightsAdded++;
          }
        } catch (_) {}
      }
      fit.bodyweight.sort((a, b) => a.date.compareTo(b.date));
      if (fit.bodyweight.isNotEmpty) {
        fit.profile.weightKg = fit.bodyweight.last.kg;
      }

      // 3. Process Body Measures
      List<dynamic> measuresList = [];
      if (data['progressData'] is Map && data['progressData']['bodyMeasures'] is List) {
        measuresList = data['progressData']['bodyMeasures'] as List<dynamic>;
      } else if (data['measures'] is List) {
        measuresList = data['measures'] as List<dynamic>;
      }

      if (!merge) {
        fit.measures.clear();
      }

      final existingMeasureKeys = fit.measures
          .map((m) => '${m.date.year}-${m.date.month}-${m.date.day}_${m.key}')
          .toSet();

      for (final item in measuresList) {
        if (item is! Map) continue;
        try {
          final m = BodyMeasure.fromJson(item.cast<String, dynamic>());
          final key = '${m.date.year}-${m.date.month}-${m.date.day}_${m.key}';
          if (!merge || !existingMeasureKeys.contains(key)) {
            fit.measures.add(m);
            existingMeasureKeys.add(key);
            measuresAdded++;
          }
        } catch (_) {}
      }

      // 4. Process Routines
      if (data['routines'] is List) {
        final routinesList = data['routines'] as List<dynamic>;
        final existingRoutineNames = fit.routines.map((r) => r.name.trim().toLowerCase()).toSet();

        for (final item in routinesList) {
          if (item is! Map) continue;
          try {
            final r = Routine.fromJson(item.cast<String, dynamic>());
            if (!merge || !existingRoutineNames.contains(r.name.trim().toLowerCase())) {
              fit.routines.add(r);
              existingRoutineNames.add(r.name.trim().toLowerCase());
              routinesAdded++;
            }
          } catch (_) {}
        }
      }

      // 5. Units if provided
      if (data['units'] is String && const ['kg', 'lb'].contains(data['units'])) {
        fit.units = data['units'] as String;
      }

      fit.persistNow();
      fit.notifyListeners();

      return (
        success: true,
        sessionsAdded: sessionsAdded,
        weightsAdded: weightsAdded,
        measuresAdded: measuresAdded,
        routinesAdded: routinesAdded,
        error: null,
      );
    } catch (e) {
      debugPrint('Error importing JSON data: $e');
      return (
        success: false,
        sessionsAdded: sessionsAdded,
        weightsAdded: weightsAdded,
        measuresAdded: measuresAdded,
        routinesAdded: routinesAdded,
        error: e.toString(),
      );
    }
  }
}
