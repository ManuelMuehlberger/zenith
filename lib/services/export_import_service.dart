import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_profile.dart';
import '../models/workout_folder.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_history.dart';
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
    bool includeWorkoutHistory = true,
    bool includeCustomExercises = true,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final userProfile = UserService.instance.currentProfile;
      final workouts = WorkoutService.instance.workouts;
      final workoutFolders = WorkoutService.instance.folders;
      final workoutHistory = await DatabaseService.instance.getWorkoutHistory();
      await ExerciseService.instance.loadExercises();
      final exercises = ExerciseService.instance.exercises;
      final settings = await DatabaseService.instance.getAppSettings();

      List<WorkoutHistory> filteredHistory = workoutHistory;
      if (fromDate != null || toDate != null) {
        filteredHistory = workoutHistory.where((history) {
          final historyDate = history.startTime;
          if (fromDate != null && historyDate.isBefore(fromDate)) return false;
          if (toDate != null && historyDate.isAfter(toDate)) return false;
          return true;
        }).toList();
      }

      // Convert workout history to workout sessions format
      final workoutSessions = _convertHistoryToSessions(filteredHistory);

      // Filter custom exercises (empty list since Exercise model doesn't have isCustom)
      final customExercises = <Exercise>[];

      // Prepare export data
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
              "workoutSessions": workoutSessions.length,
            }
          },
          "exportOptions": <String, dynamic>{
            "includePersonalData": includePersonalData,
            "includeWorkoutHistory": includeWorkoutHistory,
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
          "workoutSessions": includeWorkoutHistory ? workoutSessions : [],
          "customExercises": includeCustomExercises ? customExercises.map((exercise) => _exerciseToExportFormat(exercise)).toList() : [],
          "preferences": _settingsToPreferences(settings),
        }
      };

      // Calculate checksum
      final dataString = jsonEncode(exportData["data"]);
      final checksum = sha256.convert(utf8.encode(dataString)).toString();
      (exportData["metadata"] as Map<String, dynamic>)["dataIntegrity"]["checksum"] = checksum;

      // Save to file
      return await _saveExportFile(exportData);
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Import data from file
  Future<bool> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return false; // User cancelled picker
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final importData = jsonDecode(content) as Map<String, dynamic>;

      // Validate format
      if (!_validateImportData(importData)) {
        throw Exception('Invalid data format. Please select a valid backup file.');
      }

      // Verify checksum
      final metadata = importData["metadata"] as Map<String, dynamic>;
      final data = importData["data"] as Map<String, dynamic>;
      final expectedChecksum = metadata["dataIntegrity"]["checksum"] as String;
      final actualChecksum = sha256.convert(utf8.encode(jsonEncode(data))).toString();
      
      if (expectedChecksum != actualChecksum) {
        throw Exception('Data integrity check failed. The file may be corrupted.');
      }

      // Import data
      await _importUserData(data);
      
      return true;
    } catch (e) {
      rethrow; // Rethrow to be caught in UI and display specific error
    }
  }

  /// Save export data to file and share
  Future<String> _saveExportFile(Map<String, dynamic> exportData) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'workout_tracker_backup_$timestamp.json';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(jsonEncode(exportData));
    
    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Workout Tracker Data Export - $fileName',
    );
    
    return file.path;
  }

  /// Convert WorkoutHistory to WorkoutSession format
  List<Map<String, dynamic>> _convertHistoryToSessions(List<WorkoutHistory> history) {
    return history.map((h) => <String, dynamic>{
      "id": h.id,
      "workoutId": h.workoutId,
      "workoutSnapshot": <String, dynamic>{
        "id": h.workoutId,
        "name": h.workoutName,
        "exercises": h.exercises.map((e) => e.toMap()).toList(),
      },
      "startTime": h.startTime.toUtc().toIso8601String(),
      "endTime": h.endTime.toUtc().toIso8601String(),
      "isCompleted": true,
      "notes": h.notes,
      "mood": h.mood,
      "exercises": h.exercises.map((e) => <String, dynamic>{
        "id": e.exerciseId,
        "workoutExerciseId": e.exerciseId,
        "sets": e.sets.map((s) => <String, dynamic>{
          "id": "${e.exerciseId}_${e.sets.indexOf(s)}",
          "reps": s.reps,
          "weight": s.weight,
          "isCompleted": s.completed,
          "completedAt": s.completed ? h.endTime.toUtc().toIso8601String() : null,
        }).toList(),
      }).toList(),
    }).toList();
  }

  /// Convert Workout to export format
  Map<String, dynamic> _workoutToExportFormat(Workout workout) {
    return <String, dynamic>{
      "id": workout.id,
      "name": workout.name,
      "folderId": workout.folderId,
      "createdAt": workout.createdAt.toUtc().toIso8601String(),
      "updatedAt": workout.updatedAt.toUtc().toIso8601String(),
      "iconCodePoint": workout.iconCodePoint,
      "colorValue": workout.colorValue,
      "exercises": workout.exercises.map((e) => <String, dynamic>{
        "id": e.id,
        "exercise": _exerciseToExportFormat(e.exercise),
        "sets": e.sets.map((s) => <String, dynamic>{
          "id": s.id,
          "reps": s.reps,
          "weight": s.weight,
          "isCompleted": s.isCompleted,
          "restTime": null,
          "notes": null,
        }).toList(),
        "notes": e.notes,
      }).toList(),
    };
  }

  /// Convert Exercise to export format
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

  /// Convert app settings to preferences format
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

  /// Validate import data structure
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
          dataSection["workouts"] == null ||
          dataSection["workoutSessions"] == null) {
        return false;
      }
      return true;
    } catch (e) {
      return false; // Any parsing error means invalid structure
    }
  }

  /// Import user data
  Future<void> _importUserData(Map<String, dynamic> data) async {
    final userService = UserService.instance;
    final workoutService = WorkoutService.instance;
    final String importedFileUnits = (data["userProfile"] as Map<String,dynamic>)["units"] as String? ?? "metric";

    final dbService = DatabaseService.instance;

    // Import user profile
    if (data["userProfile"] != null) {
      final profile = UserProfile.fromMap(data["userProfile"] as Map<String, dynamic>);
      await userService.saveUserProfile(profile);
    }

    await workoutService.loadData(); // Ensure local data is loaded before merging

    // Import workout folders
    if (data["workoutFolders"] != null) {
      final folders = (data["workoutFolders"] as List)
          .map((f) => WorkoutFolder.fromMap(f as Map<String, dynamic>))
          .toList();
      for (final folder in folders) {
        // Check if folder exists by name to avoid duplicates, or update if necessary
        final existingFolder = workoutService.folders.firstWhere((ef) => ef.name == folder.name, orElse: () => folder);
        if(existingFolder.id == folder.id) { // new folder
             await workoutService.createFolder(folder.name);
        } else { // existing folder, potentially update
            // currently no updatable properties for folder other than name, which is the key
        }
      }
    }
    
    // Import workouts
    if (data["workouts"] != null) {
      final workoutsData = (data["workouts"]as List);
      for (final workoutMap in workoutsData) {
        await _importWorkout(workoutMap as Map<String, dynamic>, importedFileUnits);
      }
    }

    // Import workout history (sessions)
    if (data["workoutSessions"] != null) {
      final sessionsData = (data["workoutSessions"] as List);
      for (final sessionMap in sessionsData) {
        await _importWorkoutSession(sessionMap as Map<String, dynamic>, importedFileUnits);
      }
    }

    // Import preferences
    if (data["preferences"] != null) {
      final preferences = data["preferences"] as Map<String, dynamic>;
      final settings = _preferencesToSettings(preferences);
      await dbService.saveAppSettings(settings);
    }
  }

  /// Import individual workout
  Future<void> _importWorkout(Map<String, dynamic> workoutData, String importedFileUnits) async {
    // Create a deep copy of workoutData to modify weights before parsing
    final modifiableWorkoutData = jsonDecode(jsonEncode(workoutData)) as Map<String, dynamic>;

    if (modifiableWorkoutData['exercises'] is List) {
      for (var exMap_any in (modifiableWorkoutData['exercises'] as List)) {
        if (exMap_any is Map<String, dynamic>) {
          final exMap = exMap_any;
          if (exMap['sets'] is List) {
            for (var sMap_any in (exMap['sets'] as List)) {
              if (sMap_any is Map<String, dynamic>) {
                final sMap = sMap_any;
                if (sMap['weight'] != null) {
                  final rawWeight = (sMap['weight'] as num).toDouble();
                  if (importedFileUnits == "imperial") {
                    sMap['weight'] = rawWeight * 0.45359237;
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
      // Update existing workout
      await workoutService.updateWorkout(existingWorkout.copyWith(
        name: workout.name,
        folderId: workout.folderId,
        iconCodePoint: workout.iconCodePoint,
        colorValue: workout.colorValue,
        exercises: workout.exercises, // these exercises now have weights in KG
        updatedAt: DateTime.now(),
        createdAt: workout.createdAt,
      ));
    } else {
      workoutService.workouts.add(workout.copyWith(updatedAt: DateTime.now()));
      await workoutService.saveData();
    }
  }

  /// Import workout session as workout history
  Future<void> _importWorkoutSession(Map<String, dynamic> sessionData, String importedFileUnits) async {
    final workoutSnapshot = sessionData["workoutSnapshot"] as Map<String, dynamic>;
    final snapshotExercises = (workoutSnapshot["exercises"] as List? ?? []);
    
    final sessionExercises = (sessionData["exercises"] as List? ?? [])
        .map((e) {
          final exerciseMap = e as Map<String, dynamic>;
          final exerciseId = exerciseMap["id"] as String? ?? ""; // This is the slug
          
          String exerciseName = "Imported Exercise"; // fallback
          try {
            final snapshotExerciseMap = snapshotExercises.firstWhere(
              (snapEx) => (snapEx as Map<String, dynamic>)["exerciseId"] == exerciseId,
              orElse: () => null, 
            ) as Map<String, dynamic>?;

            if (snapshotExerciseMap != null) {
              exerciseName = snapshotExerciseMap["exerciseName"] as String? ?? "Imported Exercise";
            }
          } catch (e) {
            // Optional: log error e for debugging
          }
          
          final sets = (exerciseMap["sets"] as List? ?? [])
              .map((s) {
                final setMap = s as Map<String, dynamic>;
                final rawWeight = (setMap["weight"] as num? ?? 0.0).toDouble();
                double weightToStore = rawWeight;
                if (importedFileUnits == "imperial") {
                  weightToStore = rawWeight * 0.45359237; // lbs to kg
                }
                return SetHistory(
                  reps: setMap["reps"] as int? ?? 0,
                  weight: weightToStore, // Store in kg
                  completed: setMap["isCompleted"] as bool? ?? false,
                );
              })
              .toList();
          
          return WorkoutExerciseHistory(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            sets: sets,
          );
        })
        .toList();

    // Calculate total volume (sum of weight * reps for all completed sets)
    // set.weight is already in KG at this point due to earlier conversion in this method.
    final totalVolume = sessionExercises.fold(0.0, (sum, exercise) =>
        sum + exercise.sets.where((set) => set.completed).fold(0.0, (setSum, set) =>
            setSum + (set.weight * set.reps)));

    final history = WorkoutHistory(
      id: sessionData["id"] as String,
      workoutId: sessionData["workoutId"] as String,
      workoutName: workoutSnapshot["name"] as String? ?? "Imported Workout",
      startTime: DateTime.parse(sessionData["startTime"] as String),
      endTime: DateTime.parse(sessionData["endTime"] as String),
      exercises: sessionExercises,
      notes: sessionData["notes"] as String? ?? "",
      mood: sessionData["mood"] as int? ?? 3, // Default mood
      // Recalculate these based on imported data
      totalSets: sessionExercises.fold(0, (sum, e) => sum + e.sets.where((s) => s.completed).length),
      totalWeight: totalVolume, // Store total volume ( KG * reps) here
      iconCodePoint: workoutSnapshot["iconCodePoint"] as int? ?? 0xe1a3, // Default icon
      colorValue: workoutSnapshot["colorValue"] as int? ?? 0xFF2196F3, // Default color
    );

    await DatabaseService.instance.saveWorkoutHistory(history);
  }

  /// Convert preferences to app settings
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
