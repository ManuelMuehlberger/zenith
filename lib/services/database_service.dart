import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';
import 'workout_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  static DatabaseService get instance => _instance;

  static const String _workoutHistoryKey = 'workouts';
  static const String _activeWorkoutKey = 'active_workout';
  static const String _settingsKey = 'app_settings';

  // Workout Management
  Future<List<Workout>> getWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutsJson = prefs.getStringList(_workoutHistoryKey) ?? [];
      
      return workoutsJson
          .map((json) => Workout.fromMap(jsonDecode(json)))
          .toList()
        ..sort((a, b) => (b.startedAt ?? DateTime.now()).compareTo(a.startedAt ?? DateTime.now()));
    } catch (e) {
      return [];
    }
  }

  Future<void> saveWorkout(Workout workout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutsJson = prefs.getStringList(_workoutHistoryKey) ?? [];
      
      // Check if workout already exists
      final existingIndex = workoutsJson.indexWhere((json) {
        final workoutMap = jsonDecode(json);
        return workoutMap['id'] == workout.id;
      });
      
      if (existingIndex != -1) {
        // Update existing workout
        workoutsJson[existingIndex] = jsonEncode(workout.toMap());
      } else {
        // Add new workout
        workoutsJson.add(jsonEncode(workout.toMap()));
      }
      
      await prefs.setStringList(_workoutHistoryKey, workoutsJson);
    } catch (e) {
    }
  }


  Future<void> deleteWorkout(String workoutId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutsJson = prefs.getStringList(_workoutHistoryKey) ?? [];
      
      final updatedWorkoutsJson = workoutsJson.where((json) {
        final workoutMap = jsonDecode(json);
        return workoutMap['id'] != workoutId;
      }).toList();
      
      await prefs.setStringList(_workoutHistoryKey, updatedWorkoutsJson);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Workout>> getWorkoutsForDate(DateTime date) async {
    final allWorkouts = await getWorkouts();
    final targetDate = DateTime(date.year, date.month, date.day);
    
    return allWorkouts.where((workout) {
      final workoutDate = DateTime(
        workout.startedAt?.year ?? 0,
        workout.startedAt?.month ?? 0,
        workout.startedAt?.day ?? 0,
      );
      return workoutDate == targetDate;
    }).toList();
  }

  Future<List<DateTime>> getDatesWithWorkouts() async {
    final allHistory = await getWorkouts();
    final dates = <DateTime>{};
    
    for (final workout in allHistory) {
      if (workout.startedAt != null) {
        dates.add(DateTime(
          workout.startedAt!.year,
          workout.startedAt!.month,
          workout.startedAt!.day,
        ));
      }
    }
    
    return dates.toList()..sort();
  }

  // Active Workout State Management
  Future<void> saveActiveWorkoutState(Map<String, dynamic> workoutState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeWorkoutKey, jsonEncode(workoutState));
    } catch (e) {
    }
  }

  Future<Map<String, dynamic>?> getActiveWorkoutState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_activeWorkoutKey);
      
      if (stateJson != null) {
        return jsonDecode(stateJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearActiveWorkoutState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeWorkoutKey);
    } catch (e) {
    }
  }

  // App Settings Management
  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        return jsonDecode(settingsJson);
      }
      
      // Return default settings
      return {
        'units': 'metric', // 'metric' or 'imperial'
        'theme': 'dark',
      };
    } catch (e) {
      return {
        'units': 'metric',
        'theme': 'dark',
      };
    }
  }

  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(settings));
    } catch (e) {
    }
  }

  Future<Workout?> getLastWorkoutForExercise(String exerciseSlug) async {
    try {
      final allWorkouts = await getWorkouts(); // Already sorted by most recent first
      for (final workout in allWorkouts) {
        // Ensure exercises are loaded for workout if they are fetched lazily in the future.
        // For now, assuming workout.exercises is populated by Workout.fromMap
        for (final exerciseInWorkout in workout.exercises) { 
          if (exerciseInWorkout.exerciseSlug == exerciseSlug) { // Changed from exerciseId
            return workout; // Return the first (most recent) workout containing this exercise
          }
        }
      }
      return null; // No workout found for this exercise
    } catch (e) {
      return null;
    }
  }

  // Data Export/Import
  Future<String> exportWorkoutData() async {
    try {
      final workouts = await getWorkouts();
      final settings = await getAppSettings();
      
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'workouts': workouts.map((w) => w.toMap()).toList(),
        'settings': settings,
      };
      
      return jsonEncode(exportData);
    } catch (e) {
      return '';
    }
  }

  Future<bool> importWorkoutData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData);
      
      if (data['workouts'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final workoutsList = (data['workouts'] as List)
            .map((w) => jsonEncode(w))
            .toList();
        
        await prefs.setStringList(_workoutHistoryKey, workoutsList);
      }
      
      if (data['settings'] != null) {
        await saveAppSettings(data['settings']);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_workoutHistoryKey);
      await prefs.remove(_activeWorkoutKey);
      await prefs.remove(_settingsKey);
    } catch (e) {
    }
  }

  Future<void> migrateWorkoutIcons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutsJson = prefs.getStringList(_workoutHistoryKey) ?? [];
      await WorkoutService.instance.loadData();
      final workouts = WorkoutService.instance.workouts;
      
      bool needsUpdate = false;
      final updatedWorkoutsJson = <String>[];
      
      for (final json in workoutsJson) {
        final workoutMap = jsonDecode(json);
        final workout = Workout.fromMap(workoutMap);
        
        // Check if this workout entry needs icon/color update
        if (workout.iconCodePoint == 0xe1a3 && workout.colorValue == 0xFF2196F3) {
          // Find matching workout by ID or name
          Workout? matchingWorkout;
          try {
            matchingWorkout = workouts.firstWhere(
              (w) => w.id == workout.templateId || w.name == workout.name,
            );
          } catch (e) {
            // No matching workout found, use default values
            matchingWorkout = null;
          }
          
          if (matchingWorkout != null) {
            final updatedWorkout = Workout(
              id: workout.id,
              name: workout.name,
              description: workout.description,
              iconCodePoint: matchingWorkout.iconCodePoint ?? 0xe1a3, // Default if null
              colorValue: matchingWorkout.colorValue ?? 0xFF2196F3,    // Default if null
              folderId: workout.folderId,
              notes: workout.notes,
              lastUsed: workout.lastUsed,
              orderIndex: workout.orderIndex,
              status: workout.status,
              templateId: workout.templateId,
              startedAt: workout.startedAt,
              completedAt: workout.completedAt,
              exercises: workout.exercises, // This list itself might need deep copy if modified
            );
            
            updatedWorkoutsJson.add(jsonEncode(updatedWorkout.toMap()));
            needsUpdate = true;
          } else {
            updatedWorkoutsJson.add(json);
          }
        } else {
          updatedWorkoutsJson.add(json);
        }
      }
      
      if (needsUpdate) {
        await prefs.setStringList(_workoutHistoryKey, updatedWorkoutsJson);
      }
    } catch (e) {
    }
  }
}
