import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:meta/meta.dart';
import '../models/user_data.dart';
import '../models/workout_folder.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import 'dao/user_dao.dart';
import 'dao/weight_entry_dao.dart';
import 'dao/workout_dao.dart';
import 'dao/workout_folder_dao.dart';
import 'dao/workout_exercise_dao.dart';
import 'dao/workout_set_dao.dart';
import 'dao/exercise_dao.dart';
import 'dao/muscle_group_dao.dart';

class ExportImportService {
  static ExportImportService? _instance;

  final UserDao _userDao;
  final WeightEntryDao _weightEntryDao;
  final WorkoutDao _workoutDao;
  final WorkoutFolderDao _workoutFolderDao;
  final WorkoutExerciseDao _workoutExerciseDao;
  final WorkoutSetDao _workoutSetDao;
  final ExerciseDao _exerciseDao;
  final MuscleGroupDao _muscleGroupDao;

  @visibleForTesting
  ExportImportService.internal(
    this._userDao,
    this._weightEntryDao,
    this._workoutDao,
    this._workoutFolderDao,
    this._workoutExerciseDao,
    this._workoutSetDao,
    this._exerciseDao,
    this._muscleGroupDao,
  );

  static ExportImportService get instance {
    _instance ??= ExportImportService.internal(
        UserDao(),
        WeightEntryDao(),
        WorkoutDao(),
        WorkoutFolderDao(),
        WorkoutExerciseDao(),
        WorkoutSetDao(),
        ExerciseDao(),
        MuscleGroupDao(),
      );
    return _instance!;
  }

  @visibleForTesting
  static void setTestInstance(ExportImportService testInstance) {
    _instance = testInstance;
  }

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
      // Load data using DAOs
      final users = await _userDao.getAll();
      final userProfile = users.isNotEmpty ? users.first : null;
      
      // Load weight history for the user
      List<WeightEntry> weightHistory = [];
      if (userProfile != null) {
        weightHistory = await _weightEntryDao.getWeightEntriesByUserId(userProfile.id);
      }
      
      // Update user profile with weight history
      final userWithHistory = userProfile?.copyWith(weightHistory: weightHistory);
      
      final workoutFolders = await _workoutFolderDao.getAllWorkoutFoldersOrdered();
      final workouts = await _workoutDao.getTemplateWorkouts();
      
      // Load exercises and sets for each workout
      final List<Workout> workoutsWithExercises = [];
      for (final workout in workouts) {
        final workoutExercises = await _workoutExerciseDao.getWorkoutExercisesByWorkoutId(workout.id);
        
        // Load sets for each exercise
        final List<WorkoutExercise> exercisesWithSets = [];
        for (final workoutExercise in workoutExercises) {
          final sets = await _workoutSetDao.getWorkoutSetsByWorkoutExerciseId(workoutExercise.id);
          final exerciseWithSets = workoutExercise.copyWith(sets: sets);
          exercisesWithSets.add(exerciseWithSets);
        }
        
        // Update workout with exercises and sets
        final workoutWithExercises = workout.copyWith(exercises: exercisesWithSets);
        workoutsWithExercises.add(workoutWithExercises);
      }
      
      final workoutHistory = await _workoutDao.getCompletedWorkouts();
      
      // Load exercises and sets for each history workout
      final List<Workout> historyWithExercises = [];
      for (final workout in workoutHistory) {
        final workoutExercises = await _workoutExerciseDao.getWorkoutExercisesByWorkoutId(workout.id);
        
        // Load sets for each exercise
        final List<WorkoutExercise> exercisesWithSets = [];
        for (final workoutExercise in workoutExercises) {
          final sets = await _workoutSetDao.getWorkoutSetsByWorkoutExerciseId(workoutExercise.id);
          final exerciseWithSets = workoutExercise.copyWith(sets: sets);
          exercisesWithSets.add(exerciseWithSets);
        }
        
        // Update workout with exercises and sets
        final workoutWithExercises = workout.copyWith(exercises: exercisesWithSets);
        historyWithExercises.add(workoutWithExercises);
      }
      
      final exercises = await _exerciseDao.getAllExercises();
      
      // For now, we'll use a simple map for settings
      final settings = <String, dynamic>{
        'theme': userWithHistory?.theme ?? 'dark',
        'units': userWithHistory?.units.name ?? 'metric',
      };

      List<Workout> filteredHistory = historyWithExercises;
      if (fromDate != null || toDate != null) {
        filteredHistory = historyWithExercises.where((workout) {
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
              "userProfile": userWithHistory != null ? 1 : 0,
              "workoutFolders": workoutFolders.length,
              "workouts": workoutsWithExercises.length,
              "exercises": exercises.length,
              "workout_sessions": workoutSessions.length,
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
          "userProfile": includePersonalData ? userWithHistory?.toMap() : null,
          "workoutFolders": workoutFolders.map((folder) => folder.toMap()).toList(),
          "workouts": workoutsWithExercises.map((workout) => _workoutToExportFormat(workout)).toList(),
          "exercises": exercises.map((exercise) => _exerciseToExportFormat(exercise)).toList(),
          "workout_sessions": includeWorkouts ? workoutSessions : [],
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
      "primaryMuscleGroup": exercise.primaryMuscleGroup.name,
      "secondaryMuscleGroups": exercise.secondaryMuscleGroups.map((e) => e.name).toList(),
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
    final String importedFileUnits = (data["userProfile"] as Map<String,dynamic>?)?["units"] as String? ?? "metric";

    if (data["userProfile"] != null) {
      final profile = UserData.fromMap(data["userProfile"] as Map<String, dynamic>);
      // Check if user already exists
      final existingUser = await _userDao.getUserDataById(profile.id);
      
      if (existingUser != null) {
        // Update existing user
        await _userDao.updateUserData(profile);
      } else {
        // Create new user
        await _userDao.insert(profile);
      }
      
      // Save weight history entries
      for (final weightEntry in profile.weightHistory) {
        try {
          await _weightEntryDao.addWeightEntryForUser(profile.id, weightEntry);
        } catch (e) {
          // If entry already exists, update it
          await _weightEntryDao.updateWeightEntry(profile.id, weightEntry);
        }
      }
    }

    if (data["workoutFolders"] != null) {
      final folders = (data["workoutFolders"] as List)
          .map((f) => WorkoutFolder.fromMap(f as Map<String, dynamic>))
          .toList();
      for (final folder in folders) {
        // Check if folder already exists
        try {
          await _workoutFolderDao.insert(folder);
        } catch (e) {
          // If folder already exists, update it
          await _workoutFolderDao.updateWorkoutFolder(folder);
        }
      }
    }
    
    if (data["workouts"] != null) {
      final workoutsData = (data["workouts"] as List);
      for (final workoutMap in workoutsData) {
        await _importWorkout(workoutMap as Map<String, dynamic>, importedFileUnits);
      }
    }

    if (data["workout_sessions"] != null) {
      final sessionsData = (data["workout_sessions"] as List);
      for (final sessionMap in sessionsData) {
        await _importWorkoutSession(sessionMap as Map<String, dynamic>, importedFileUnits);
      }
    }

    // Note: We're not importing preferences directly as settings are now part of UserData
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
    
    // Check if workout already exists
    final existingWorkout = await _workoutDao.getWorkoutById(workout.id);

    if (existingWorkout != null) {
      await _workoutDao.updateWorkout(workout);
    } else {
      await _workoutDao.insert(workout);
    }
    
    // Import exercises and sets for this workout
    for (final exercise in workout.exercises) {
      try {
        await _workoutExerciseDao.insert(exercise);
      } catch (e) {
        // If exercise already exists, update it
        await _workoutExerciseDao.updateWorkoutExercise(exercise);
      }
      
      // Import sets for this exercise
      for (final set in exercise.sets) {
        try {
          await _workoutSetDao.insert(set);
        } catch (e) {
          // If set already exists, update it
          await _workoutSetDao.updateWorkoutSet(set);
        }
      }
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

    // Save workout using DAO
    await _workoutDao.insert(workout);
    
    // Save exercises and sets using DAOs
    for (final exercise in importedExercises) {
      await _workoutExerciseDao.insert(exercise);
      
      // Save sets for this exercise
      for (final set in exercise.sets) {
        await _workoutSetDao.insert(set);
      }
    }
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
