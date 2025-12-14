import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';
import 'workout_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final Logger _logger = Logger('DatabaseService');
  
  static DatabaseService get instance => _instance;

  static const String _workoutHistoryKey = 'workouts';
  static const String _activeWorkoutKey = 'active_workout';
  static const String _settingsKey = 'app_settings';

  // Workout Management
  Future<List<Workout>> getWorkouts() async {
    _logger.fine('Getting all workouts from SQL via WorkoutService');
    try {
      // Ensure in-memory cache is loaded from the SQL database
      await WorkoutService.instance.loadData();
      final workouts = List<Workout>.from(WorkoutService.instance.workouts)
        ..sort(
          (a, b) => (b.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
      _logger.fine('Successfully retrieved ${workouts.length} workouts from SQL');
      return workouts;
    } catch (e) {
      _logger.severe('Failed to get workouts from SQL: $e');
      return [];
    }
  }

  Future<void> saveWorkout(Workout workout) async {
    _logger.fine('Saving workout with id: ${workout.id}');
    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutsJson = prefs.getStringList(_workoutHistoryKey) ?? [];
      
      // Check if workout already exists
      final existingIndex = workoutsJson.indexWhere((json) {
        final workoutMap = jsonDecode(json);
        return workoutMap['id'] == workout.id;
      });
      
      if (existingIndex != -1) {
        _logger.fine('Updating existing workout with id: ${workout.id}');
        workoutsJson[existingIndex] = jsonEncode(workout.toMap());
      } else {
        _logger.fine('Adding new workout with id: ${workout.id}');
        workoutsJson.add(jsonEncode(workout.toMap()));
      }
      
      await prefs.setStringList(_workoutHistoryKey, workoutsJson);
      _logger.fine('Workout with id: ${workout.id} saved successfully');
    } catch (e) {
      _logger.severe('Failed to save workout with id: ${workout.id}: $e');
    }
  }


  Future<void> deleteWorkout(String workoutId) async {
    _logger.fine('Deleting workout with id: $workoutId');
    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutsJson = prefs.getStringList(_workoutHistoryKey) ?? [];
      
      final updatedWorkoutsJson = workoutsJson.where((json) {
        final workoutMap = jsonDecode(json);
        return workoutMap['id'] != workoutId;
      }).toList();
      
      await prefs.setStringList(_workoutHistoryKey, updatedWorkoutsJson);
      _logger.fine('Workout with id: $workoutId deleted successfully');
    } catch (e) {
      _logger.severe('Failed to delete workout with id: $workoutId: $e');
      rethrow;
    }
  }

  Future<List<Workout>> getWorkoutsForDate(DateTime date) async {
    _logger.fine('Getting workouts for date: ${date.toIso8601String()}');
    final allWorkouts = await getWorkouts();
    final targetDate = DateTime(date.year, date.month, date.day);
    
    final workoutsForDate = allWorkouts.where((workout) {
      final workoutDate = DateTime(
        workout.startedAt?.year ?? 0,
        workout.startedAt?.month ?? 0,
        workout.startedAt?.day ?? 0,
      );
      return workoutDate == targetDate;
    }).toList();
    
    _logger.fine('Found ${workoutsForDate.length} workouts for date: ${date.toIso8601String()}');
    return workoutsForDate;
  }

  Future<List<DateTime>> getDatesWithWorkouts() async {
    _logger.fine('Getting dates with workouts');
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
    
    final sortedDates = dates.toList()..sort();
    _logger.fine('Found ${sortedDates.length} dates with workouts');
    return sortedDates;
  }

  // Active Workout State Management
  Future<void> saveActiveWorkoutState(Map<String, dynamic> workoutState) async {
    _logger.fine('Saving active workout state');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeWorkoutKey, jsonEncode(workoutState));
      _logger.fine('Active workout state saved successfully');
    } catch (e) {
      _logger.severe('Failed to save active workout state: $e');
    }
  }

  Future<Map<String, dynamic>?> getActiveWorkoutState() async {
    _logger.fine('Getting active workout state');
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_activeWorkoutKey);
      
      if (stateJson != null) {
        _logger.fine('Active workout state found');
        return jsonDecode(stateJson);
      }
      _logger.fine('No active workout state found');
      return null;
    } catch (e) {
      _logger.severe('Failed to get active workout state: $e');
      return null;
    }
  }

  Future<void> clearActiveWorkoutState() async {
    _logger.fine('Clearing active workout state');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeWorkoutKey);
      _logger.fine('Active workout state cleared successfully');
    } catch (e) {
      _logger.severe('Failed to clear active workout state: $e');
    }
  }

  // App Settings Management
  Future<Map<String, dynamic>> getAppSettings() async {
    _logger.fine('Getting app settings');
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        _logger.fine('App settings found');
        return jsonDecode(settingsJson);
      }
      
      _logger.fine('No app settings found, returning default settings');
      return {
        'units': 'metric', // 'metric' or 'imperial'
        'theme': 'dark',
      };
    } catch (e) {
      _logger.severe('Failed to get app settings, returning default settings: $e');
      return {
        'units': 'metric',
        'theme': 'dark',
      };
    }
  }

  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    _logger.fine('Saving app settings');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(settings));
      _logger.fine('App settings saved successfully');
    } catch (e) {
      _logger.severe('Failed to save app settings: $e');
    }
  }

  Future<Workout?> getLastWorkoutForExercise(String exerciseSlug) async {
    _logger.fine('Getting last workout for exercise slug: $exerciseSlug');
    try {
      final allWorkouts = await getWorkouts(); // Already sorted by most recent first
      for (final workout in allWorkouts) {
        for (final exerciseInWorkout in workout.exercises) { 
          if (exerciseInWorkout.exerciseSlug == exerciseSlug) {
            _logger.fine('Found last workout with id: ${workout.id} for exercise slug: $exerciseSlug');
            return workout;
          }
        }
      }
      _logger.fine('No workout found for exercise slug: $exerciseSlug');
      return null;
    } catch (e) {
      _logger.severe('Failed to get last workout for exercise slug: $exerciseSlug: $e');
      return null;
    }
  }

  // Data Export/Import
  Future<String> exportWorkoutData() async {
    _logger.info('Exporting workout data');
    try {
      final workouts = await getWorkouts();
      final settings = await getAppSettings();
      
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'workouts': workouts.map((w) => w.toMap()).toList(),
        'settings': settings,
      };
      
      final jsonData = jsonEncode(exportData);
      _logger.info('Workout data exported successfully');
      return jsonData;
    } catch (e) {
      _logger.severe('Failed to export workout data: $e');
      return '';
    }
  }

  Future<bool> importWorkoutData(String jsonData) async {
    _logger.info('Importing workout data');
    try {
      final data = jsonDecode(jsonData);
      
      if (data['workouts'] != null) {
        _logger.fine('Importing workouts');
        final prefs = await SharedPreferences.getInstance();
        final workoutsList = (data['workouts'] as List)
            .map((w) => jsonEncode(w))
            .toList();
        
        await prefs.setStringList(_workoutHistoryKey, workoutsList);
        _logger.fine('Workouts imported successfully');
      }
      
      if (data['settings'] != null) {
        _logger.fine('Importing settings');
        await saveAppSettings(data['settings']);
        _logger.fine('Settings imported successfully');
      }
      
      _logger.info('Workout data imported successfully');
      return true;
    } catch (e) {
      _logger.severe('Failed to import workout data: $e');
      return false;
    }
  }

  Future<void> clearAllData() async {
    _logger.warning('Clearing all data from SharedPreferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_workoutHistoryKey);
      await prefs.remove(_activeWorkoutKey);
      await prefs.remove(_settingsKey);
      _logger.info('All data cleared successfully');
    } catch (e) {
      _logger.severe('Failed to clear all data: $e');
    }
  }

  Future<void> migrateWorkoutIcons() async {
    _logger.info('Starting workout icon migration');
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
        
        if (workout.iconCodePoint == 0xe1a3 && workout.colorValue == 0xFF2196F3) {
          _logger.fine('Found workout with default icon/color: ${workout.id}');
          Workout? matchingWorkout;
          try {
            matchingWorkout = workouts.firstWhere(
              (w) => w.id == workout.templateId || w.name == workout.name,
            );
          } catch (e) {
            _logger.warning('No matching workout template found for id: ${workout.id}');
            matchingWorkout = null;
          }
          
          if (matchingWorkout != null) {
            _logger.fine('Updating workout icon/color for id: ${workout.id}');
            final updatedWorkout = Workout(
              id: workout.id,
              name: workout.name,
              description: workout.description,
              iconCodePoint: matchingWorkout.iconCodePoint ?? 0xe1a3,
              colorValue: matchingWorkout.colorValue ?? 0xFF2196F3,
              folderId: workout.folderId,
              notes: workout.notes,
              lastUsed: workout.lastUsed,
              orderIndex: workout.orderIndex,
              status: workout.status,
              templateId: workout.templateId,
              startedAt: workout.startedAt,
              completedAt: workout.completedAt,
              exercises: workout.exercises,
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
        _logger.info('Applying updated workout icons to SharedPreferences');
        await prefs.setStringList(_workoutHistoryKey, updatedWorkoutsJson);
        _logger.info('Workout icon migration completed successfully');
      } else {
        _logger.info('No workout icons needed migration');
      }
    } catch (e) {
      _logger.severe('Failed to migrate workout icons: $e');
    }
  }
}
