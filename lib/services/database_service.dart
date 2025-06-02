import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_history.dart';
import '../models/workout.dart';
import 'workout_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  static DatabaseService get instance => _instance;

  static const String _workoutHistoryKey = 'workout_history';
  static const String _activeWorkoutKey = 'active_workout';
  static const String _settingsKey = 'app_settings';

  // Workout History Management
  Future<List<WorkoutHistory>> getWorkoutHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_workoutHistoryKey) ?? [];
      
      return historyJson
          .map((json) => WorkoutHistory.fromMap(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
    } catch (e) {
      return [];
    }
  }

  Future<void> saveWorkoutHistory(WorkoutHistory workout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_workoutHistoryKey) ?? [];
      
      // Add new workout to history
      historyJson.add(jsonEncode(workout.toMap()));
      
      await prefs.setStringList(_workoutHistoryKey, historyJson);
    } catch (e) {
    }
  }

  Future<void> deleteWorkoutHistory(String workoutId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_workoutHistoryKey) ?? [];
      
      final updatedHistoryJson = historyJson.where((json) {
        final workoutMap = jsonDecode(json);
        return workoutMap['id'] != workoutId;
      }).toList();
      
      await prefs.setStringList(_workoutHistoryKey, updatedHistoryJson);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<WorkoutHistory>> getWorkoutHistoryForDate(DateTime date) async {
    final allHistory = await getWorkoutHistory();
    final targetDate = DateTime(date.year, date.month, date.day);
    
    return allHistory.where((workout) {
      final workoutDate = DateTime(
        workout.startTime.year,
        workout.startTime.month,
        workout.startTime.day,
      );
      return workoutDate == targetDate;
    }).toList();
  }

  Future<List<DateTime>> getDatesWithWorkouts() async {
    final allHistory = await getWorkoutHistory();
    final dates = <DateTime>{};
    
    for (final workout in allHistory) {
      dates.add(DateTime(
        workout.startTime.year,
        workout.startTime.month,
        workout.startTime.day,
      ));
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

  Future<WorkoutHistory?> getLastWorkoutHistoryForExercise(String exerciseSlug) async {
    try {
      final allHistory = await getWorkoutHistory(); // Already sorted by most recent first
      for (final historyEntry in allHistory) {
        for (final exerciseInHistory in historyEntry.exercises) {
          if (exerciseInHistory.exerciseId == exerciseSlug) {
            return historyEntry; // Return the first (most recent) history containing this exercise
          }
        }
      }
      return null; // No history found for this exercise
    } catch (e) {
      return null;
    }
  }

  // Data Export/Import
  Future<String> exportWorkoutData() async {
    try {
      final history = await getWorkoutHistory();
      final settings = await getAppSettings();
      
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'workoutHistory': history.map((w) => w.toMap()).toList(),
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
      
      if (data['workoutHistory'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final historyList = (data['workoutHistory'] as List)
            .map((w) => jsonEncode(w))
            .toList();
        
        await prefs.setStringList(_workoutHistoryKey, historyList);
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

  Future<void> migrateWorkoutHistoryIcons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_workoutHistoryKey) ?? [];
      await WorkoutService.instance.loadData();
      final workouts = WorkoutService.instance.workouts;
      
      bool needsUpdate = false;
      final updatedHistoryJson = <String>[];
      
      for (final json in historyJson) {
        final historyMap = jsonDecode(json);
        final history = WorkoutHistory.fromMap(historyMap);
        
        // Check if this history entry needs icon/color update
        if (history.iconCodePoint == 0xe1a3 && history.colorValue == 0xFF2196F3) {
          // Find matching workout by ID or name
          Workout? matchingWorkout;
          try {
            matchingWorkout = workouts.firstWhere(
              (w) => w.id == history.workoutId || w.name == history.workoutName,
            );
          } catch (e) {
            // No matching workout found, use default values
            matchingWorkout = null;
          }
          
          if (matchingWorkout != null) {
            final updatedHistory = WorkoutHistory(
              id: history.id,
              workoutId: history.workoutId,
              workoutName: history.workoutName,
              startTime: history.startTime,
              endTime: history.endTime,
              exercises: history.exercises,
              notes: history.notes,
              mood: history.mood,
              totalSets: history.totalSets,
              totalWeight: history.totalWeight,
              iconCodePoint: matchingWorkout.iconCodePoint,
              colorValue: matchingWorkout.colorValue,
            );
            
            updatedHistoryJson.add(jsonEncode(updatedHistory.toMap()));
            needsUpdate = true;
          } else {
            updatedHistoryJson.add(json);
          }
        } else {
          updatedHistoryJson.add(json);
        }
      }
      
      if (needsUpdate) {
        await prefs.setStringList(_workoutHistoryKey, updatedHistoryJson);
      }
    } catch (e) {
    }
  }
}
