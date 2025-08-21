import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart'; // Added for generating IDs if needed during import
import '../models/user_data.dart';
import '../models/workout_folder.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import 'database_service.dart';
import 'user_service.dart';
import 'workout_service.dart';
import 'exercise_service.dart';

class ExportImportService {
  static final ExportImportService _instance = ExportImportService._internal();
  factory ExportImportService() => _instance;
  ExportImportService._internal();
  
  static ExportImportService get instance => _instance;

  static const String _fileVersion = "1.0.0";
  static const String _appVersion = "1.0.0";
  
  Future<String?> exportData({
    bool includePersonalData = true,
    bool includeWorkouts = true,
    bool includeCustomExercises = true,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final userProfile = UserService.instance.currentProfile;
      final workouts = WorkoutService.instance.workouts;
      final workoutFolders = WorkoutService.instance.folders;
      final workoutHistory = await DatabaseService.instance.getWorkouts();
      await ExerciseService.instance.loadExercises();
      final exercises = ExerciseService.instance.exercises;
      final settings = await DatabaseService.instance.getAppSettings();

      List<Workout> filteredHistory = workoutHistory;
      if (fromDate != null || toDate != null) {
        filteredHistory = workoutHistory.where((workout) {
          final historyDate = workout.startedAt;
          if (historyDate == null) return false;
          if (fromDate != null && historyDate.isBefore(fromDate)) return false;
          if (toDate != null && historyDate.isAfter(toDate)) return false;
          return true;
        }).toList();
      }

      final workoutSessions = _convertHistoryToSessions(filteredHistory);
      final customExercisesList = <Exercise>[]; // Placeholder

      final exportData = <String, dynamic>{
        "metadata": <String, dynamic>{
          "version": _fileVersion,
          "format": "json",
          "exportDate": DateTime.now().toUtc().toIso8601String(),
          "appVersion": _appVersion,
          "deviceInfo": <String, dynamic>{
            "platform": Platform.isIOS ? "ios" : "android",
            "osVersion": Platform.operatingSystemVersion,
            "appBuild": _appVersion,
          },
          "dataIntegrity": <String, dynamic>{
            "checksum": "",
            "recordCount": <String, dynamic>{
              "userProfile": userProfile != null ? 1 : 0,
              "workoutFolders": workoutFolders.length,
              "workouts": workouts.length,
              "exercises": exercises.length, 
              "workouts": workoutSessions.length,
            }
          },
          "exportOptions": <String, dynamic>{
            "includePersonalData": includePersonalData,
            "includeWorkouts": includeWorkouts,
            "includeCustomExercises": includeCustomExercises,
            "dateRange": <String, dynamic>{
              "from": fromDate?.toUtc().toIso8601String(),
              "to": toDate?.toUtc().toIso8601String(),
            }
          }
        },
        "data": <String, dynamic>{
          "userProfile": includePersonalData ? userProfile?.toMap() : null,
          "workoutFolders": workoutFolders.map((folder) => folder.toMap()).toList(),
          "workouts": workouts.map((workout) => _workoutToExportFormat(workout)).toList(),
          "exercises": exercises.map((exercise) => _exerciseToExportFormat(exercise)).toList(),
          "workouts": includeWorkouts ? workoutSessions : [],
          "customExercises": includeCustomExercises ? customExercisesList.map((exercise) => _exerciseToExportFormat(exercise)).toList() : [],
          "preferences": _settingsToPreferences(settings),
        }
      };

      final dataString = jsonEncode(exportData["data"]);
      final checksum = sha256.convert(utf8.encode(dataString)).toString();
      (exportData["metadata"] as Map<String, dynamic>)["dataIntegrity"]["checksum"] = checksum;

      return await _saveExportFile(exportData);
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  Future<bool> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return false;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final importData = jsonDecode(content) as Map<String, dynamic>;

      if (!_validateImportData(importData)) {
        throw Exception('Invalid data format. Please select a valid backup file.');
      }

      final metadata = importData["metadata"] as Map<String, dynamic>;
      final data = importData["data"] as Map<String, dynamic>;
      final expectedChecksum = metadata["dataIntegrity"]["checksum"] as String;
      final actualChecksum = sha256.convert(utf8.encode(jsonEncode(data))).toString();
      
      if (expectedChecksum != actualChecksum) {
        throw Exception('Data integrity check failed. The file may be corrupted.');
      }

      await _importUserData(data);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _saveExportFile(Map<String, dynamic> exportData) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'workout_tracker_backup_$timestamp.json';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonEncode(exportData));
    await Share.shareXFiles([XFile(file.path)], subject: 'Workout Tracker Data Export - $fileName');
    return file.path;
  }

  List<Map<String, dynamic>> _convertHistoryToSessions(List<Workout> history) {
    return history.where((h) => h.status == WorkoutStatus.completed).map((h) {
      // h.exercises are List<WorkoutExercise>
      // Their toMap() is for DB representation. We need to map them to the export format.
      List<Map<String,dynamic>> exportedExercises = h.exercises.map((we) { // we is WorkoutExercise
        return {
          "exerciseId": we.exerciseSlug, 
          "exerciseName": we.exerciseDetail?.name ?? we.exerciseSlug,
          "notes": we.notes,
          "orderIndex": we.orderIndex,
          "sets": we.sets.map((s) { // s is WorkoutSet
            return {
              "id": s.id, // Exporting WorkoutSet ID
              "reps": s.actualReps,
              "weight": s.actualWeight,
              "completed": s.isCompleted,
              "type": null, // WorkoutSet doesn't have a type field
              "notes": null, // WorkoutSet doesn't have a notes field
              "durationSeconds": null, // WorkoutSet doesn't have a durationSeconds field
              "restTimeAchievedSeconds": null, // WorkoutSet doesn't have a restTimeAchievedSeconds field
              "weightUnit": null, // WorkoutSet doesn't have a weightUnit field
            };
          }).toList(),
        };
      }).toList();

      return <String, dynamic>{
        "id": h.id,
        "workoutId": h.templateId, // This is workout template ID
        "workoutSnapshot": <String, dynamic>{
          "id": h.templateId, 
          "name": h.name,
          "exercises": exportedExercises, // Use the mapped exercises
        },
        "startTime": h.startedAt?.toUtc().toIso8601String(),
        "endTime": h.completedAt?.toUtc().toIso8601String(),
        "isCompleted": h.completedAt != null,
        "notes": h.notes,
        "mood": null, // Workout doesn't have a mood field
        "exercises": exportedExercises, // Use the same mapped exercises for the main exercises list
      };
    }).toList();
  }

  Map<String, dynamic> _workoutToExportFormat(Workout workout) {
    return <String, dynamic>{
      "id": workout.id,
      "name": workout.name,
      "description": workout.description,
      "folderId": workout.folderId,
      "notes": workout.notes,
      "lastUsed": workout.lastUsed,
      "orderIndex": workout.orderIndex,
      "iconCodePoint": workout.iconCodePoint,
      "colorValue": workout.colorValue,
      "exercises": workout.exercises.map((e) {
        final Map<String, dynamic> exerciseData = e.exerciseDetail != null
            ? _exerciseToExportFormat(e.exerciseDetail!)
            : {'slug': e.exerciseSlug, 'name': 'Unknown Exercise (Detail not loaded)'};
        return <String, dynamic>{
          "id": e.id,
          "exerciseSlug": e.exerciseSlug,
          "exercise": exerciseData,
          "sets": e.sets.map((s) {
            return <String, dynamic>{
              "id": s.id,
              "setIndex": s.setIndex,
              "targetReps": s.targetReps,
              "targetWeight": s.targetWeight,
              "targetRestSeconds": s.targetRestSeconds,
              "actualReps": s.actualReps,
              "actualWeight": s.actualWeight,
              "isCompleted": s.isCompleted,
            };
          }).toList(),
          "notes": e.notes,
        };
      }).toList(),
    };
  }

  Map<String, dynamic> _exerciseToExportFormat(Exercise exercise) {
    return <String, dynamic>{
      "slug": exercise.slug,
      "name": exercise.name,
      "primaryMuscleGroup": exercise.primaryMuscleGroup,
      "secondaryMuscleGroups": exercise.secondaryMuscleGroups,
      "instructions": exercise.instructions,
      "image": exercise.image,
      "animation": exercise.animation,
    };
  }

  Map<String, dynamic> _settingsToPreferences(Map<String, dynamic> settings) {
    return <String, dynamic>{
      "theme": settings["theme"] ?? "dark",
      "defaultRestTime": settings["defaultRestTime"] ?? 90,
      "autoStartTimer": settings["autoStartTimer"] ?? true,
      "soundEnabled": settings["soundEnabled"] ?? true,
      "vibrationEnabled": settings["vibrationEnabled"] ?? true,
      "reminderSettings": <String, dynamic>{
        "enabled": settings["remindersEnabled"] ?? false,
        "days": settings["reminderDays"] ?? ["monday", "tuesday", "wednesday", "thursday", "friday"],
        "time": settings["reminderTime"] ?? "18:00",
      }
    };
  }

  bool _validateImportData(Map<String, dynamic> data) {
    try {
      final metadata = data["metadata"] as Map<String, dynamic>?;
      final dataSection = data["data"] as Map<String, dynamic>?;
      if (metadata == null ||
          metadata["version"] == null || 
          metadata["format"] != "json" ||
          metadata["exportDate"] == null ||
          metadata["dataIntegrity"] == null ||
          (metadata["dataIntegrity"] as Map<String, dynamic>)["checksum"] == null) {
        return false;
      }
      if (dataSection == null ||
          dataSection["workouts"] == null) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _importUserData(Map<String, dynamic> data) async {
    final userService = UserService.instance;
    final workoutService = WorkoutService.instance;
    final String importedFileUnits = (data["userProfile"] as Map<String,dynamic>?)?["units"] as String? ?? "metric";
    final dbService = DatabaseService.instance;

    if (data["userProfile"] != null) {
      final profile = UserData.fromMap(data["userProfile"] as Map<String, dynamic>);
      await userService.saveUserProfile(profile);
    }

    await workoutService.loadData(); 

    if (data["workoutFolders"] != null) {
      final folders = (data["workoutFolders"] as List)
          .map((f) => WorkoutFolder.fromMap(f as Map<String, dynamic>))
          .toList();
      for (final folder in folders) {
        final existingFolder = workoutService.folders.firstWhere((ef) => ef.name == folder.name, orElse: () => folder);
        if(existingFolder.id == folder.id) { 
             await workoutService.createFolder(folder.name);
        }
      }
    }
    
    if (data["workouts"] != null) {
      final workoutsData = (data["workouts"]as List);
      for (final workoutMap in workoutsData) {
        await _importWorkout(workoutMap as Map<String, dynamic>, importedFileUnits);
      }
    }

    if (data["workouts"] != null) {
      final sessionsData = (data["workouts"] as List);
      for (final sessionMap in sessionsData) {
        await _importWorkoutSession(sessionMap as Map<String, dynamic>, importedFileUnits);
      }
    }

    if (data["preferences"] != null) {
      final preferences = data["preferences"] as Map<String, dynamic>;
      final settings = _preferencesToSettings(preferences);
      await dbService.saveAppSettings(settings);
    }
  }

  Future<void> _importWorkout(Map<String, dynamic> workoutData, String importedFileUnits) async {
    final modifiableWorkoutData = jsonDecode(jsonEncode(workoutData)) as Map<String, dynamic>;

    if (modifiableWorkoutData['exercises'] is List) {
      for (var exMap_any in (modifiableWorkoutData['exercises'] as List)) {
        if (exMap_any is Map<String, dynamic>) {
          final exMap = exMap_any;
          if (exMap['sets'] is List) {
            for (var sMap_any in (exMap['sets'] as List)) {
              if (sMap_any is Map<String, dynamic>) {
                final sMap = sMap_any;
                // For template import, weight is targetWeight
                if (sMap['targetWeight'] != null) { 
                  final rawWeight = (sMap['targetWeight'] as num).toDouble();
                  if (importedFileUnits == "imperial") {
                    sMap['targetWeight'] = rawWeight * 0.45359237;
                  }
                }
              }
            }
          }
        }
      }
    }

    final workout = Workout.fromMap(modifiableWorkoutData);
    final workoutService = WorkoutService.instance;
    final existingWorkout = workoutService.workouts.cast<Workout?>().firstWhere((w) => w?.id == workout.id, orElse: () => null);

    if (existingWorkout != null) {
      await workoutService.updateWorkout(existingWorkout.copyWith(
        name: workout.name,
        description: workout.description,
        folderId: workout.folderId,
        iconCodePoint: workout.iconCodePoint,
        colorValue: workout.colorValue,
        notes: workout.notes,
        lastUsed: workout.lastUsed,
        orderIndex: workout.orderIndex,
        exercises: workout.exercises,
      ));
    } else {
      workoutService.workouts.add(workout);
      await workoutService.saveData();
    }
  }

  Future<void> _importWorkoutSession(Map<String, dynamic> sessionData, String importedFileUnits) async {
    final String workoutId = sessionData["id"] as String? ?? const Uuid().v4();
    final workoutSnapshot = sessionData["workoutSnapshot"] as Map<String, dynamic>;
    final snapshotExercises = (workoutSnapshot["exercises"] as List? ?? []);
    
    final List<WorkoutExercise> importedExercises = (sessionData["exercises"] as List? ?? [])
        .map((exerciseMap) {
      final List<WorkoutSet> importedSets = (exerciseMap["sets"] as List? ?? [])
          .map((setMap) {
        return WorkoutSet.fromMap(setMap);
      }).toList();
      return WorkoutExercise.fromMap(exerciseMap).copyWith(sets: importedSets);
    }).toList();

    final workout = Workout(
      id: workoutId,
      name: workoutSnapshot["name"] as String? ?? "Imported Workout",
      startedAt: sessionData["startTime"] != null ? DateTime.parse(sessionData["startTime"] as String) : null,
      completedAt: sessionData["endTime"] != null ? DateTime.parse(sessionData["endTime"] as String) : null,
      exercises: importedExercises,
      notes: sessionData["notes"] as String? ?? "",
      iconCodePoint: workoutSnapshot["iconCodePoint"] as int?,
      colorValue: workoutSnapshot["colorValue"] as int?,
      status: WorkoutStatus.completed,
      templateId: sessionData["workoutId"] as String?,
    );

    await DatabaseService.instance.saveWorkout(workout);
  }

  Map<String, dynamic> _preferencesToSettings(Map<String, dynamic> preferences) {
    return <String, dynamic>{
      "theme": preferences["theme"] ?? "dark",
      "defaultRestTime": preferences["defaultRestTime"] ?? 90,
      "autoStartTimer": preferences["autoStartTimer"] ?? true,
      "soundEnabled": preferences["soundEnabled"] ?? true,
      "vibrationEnabled": preferences["vibrationEnabled"] ?? true,
      "remindersEnabled": (preferences["reminderSettings"] as Map<String,dynamic>)["enabled"] ?? false,
      "reminderDays": (preferences["reminderSettings"] as Map<String,dynamic>)["days"] ?? ["monday", "tuesday", "wednesday", "thursday", "friday"],
      "reminderTime": (preferences["reminderSettings"] as Map<String,dynamic>)["time"] ?? "18:00",
    };
  }
}
