import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_session.dart';
import '../models/workout.dart';
import '../models/workout_history.dart';
import 'database_service.dart';
import 'live_workout_notification_service.dart';

class WorkoutSessionService {
  static final WorkoutSessionService _instance = WorkoutSessionService._internal();
  factory WorkoutSessionService() => _instance;
  WorkoutSessionService._internal();
  
  static WorkoutSessionService get instance => _instance;

  WorkoutSession? _currentSession;
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  static const String _currentSessionKey = 'current_workout_session';
  static const String _currentExerciseIndexKey = 'current_exercise_index';
  static const String _currentSetIndexKey = 'current_set_index';

  WorkoutSession? get currentSession => _currentSession;
  int get currentExerciseIndex => _currentExerciseIndex;
  int get currentSetIndex => _currentSetIndex;
  bool get hasActiveSession => _currentSession != null && !_currentSession!.isCompleted;

  void initializeNotificationCallback() {
    LiveWorkoutNotificationService().setNextSetCallback(() {
      if (hasActiveSession) {
        nextSet();
      }
    });
  }

  Future<void> loadActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_currentSessionKey);
    
    if (sessionJson != null) {
      try {
        final sessionMap = json.decode(sessionJson);
        _currentSession = WorkoutSession.fromMap(sessionMap);
        _currentExerciseIndex = prefs.getInt(_currentExerciseIndexKey) ?? 0;
        _currentSetIndex = prefs.getInt(_currentSetIndexKey) ?? 0;
        
        // If the session is completed, clear it
        if (_currentSession!.isCompleted) {
          await clearActiveSession();
        } else {
          // If session is active, ensure indices are valid
          if (_currentExerciseIndex >= _currentSession!.exercises.length) {
            _currentExerciseIndex = _currentSession!.exercises.isNotEmpty ? _currentSession!.exercises.length - 1 : 0;
          }
          if (_currentSession!.exercises.isNotEmpty && _currentExerciseIndex < _currentSession!.exercises.length) {
            final currentExercise = _currentSession!.exercises[_currentExerciseIndex];
            if (_currentSetIndex >= currentExercise.sets.length) {
              _currentSetIndex = currentExercise.sets.isNotEmpty ? currentExercise.sets.length - 1 : 0;
            }
          } else {
            _currentSetIndex = 0;
          }
          // Restart notification service if session is active
          await LiveWorkoutNotificationService().restartServiceIfNeeded(_currentSession!, _currentExerciseIndex, _currentSetIndex);
        }
      } catch (e) {
        await clearActiveSession();
      }
    }
  }

  Future<WorkoutSession> startWorkout(Workout workout) async {
    // Clear any existing session first
    await clearActiveSession();
    // Create initial session exercises from the workout template
    List<SessionExercise> sessionExercises = workout.exercises
        .map((e) => SessionExercise.fromWorkoutExercise(e))
        .toList();

    // Populate lastReps and lastWeight from history
    for (int i = 0; i < sessionExercises.length; i++) {
      final sessionExercise = sessionExercises[i];
      final exerciseSlug = sessionExercise.workoutExercise.exercise.slug;
      
      // Fetch the last workout history for this specific exercise
      final WorkoutHistory? lastHistory = await DatabaseService.instance.getLastWorkoutHistoryForExercise(exerciseSlug);

      if (lastHistory != null) {
        final List<SessionSet> updatedSets = [];
        for (int j = 0; j < sessionExercise.sets.length; j++) {
          SessionSet currentSet = sessionExercise.sets[j];
          
          // Try to find corresponding exercise history
          WorkoutExerciseHistory? exerciseHistory;
          for (final eh in lastHistory.exercises) {
            if (eh.exerciseId == exerciseSlug) {
              exerciseHistory = eh;
              break;
            }
          }

          if (exerciseHistory != null && exerciseHistory.sets.isNotEmpty) {
            // Use the set at the same index if available, otherwise fallback or leave null
            // This is a simple matching strategy; could be more sophisticated
            if (j < exerciseHistory.sets.length) {
              final historicalSet = exerciseHistory.sets[j];
              currentSet = currentSet.copyWith(
                reps: historicalSet.reps,
                weight: historicalSet.weight,
                lastReps: historicalSet.reps,
                lastWeight: historicalSet.weight,
              );
            } else {
              final fallbackHistoricalSet = exerciseHistory.sets.last;
              currentSet = currentSet.copyWith(
                reps: fallbackHistoricalSet.reps,
                weight: fallbackHistoricalSet.weight,
                lastReps: fallbackHistoricalSet.reps,
                lastWeight: fallbackHistoricalSet.weight,
              );
            }
          }
          updatedSets.add(currentSet);
        }
        sessionExercises[i] = sessionExercise.copyWith(sets: updatedSets);
      }
    }

    _currentSession = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workout: workout,
      startTime: DateTime.now(),
      exercises: sessionExercises,
    );
    
    _currentExerciseIndex = 0;
    _currentSetIndex = 0;
    await _saveCurrentSession();

    if (_currentSession!.exercises.isNotEmpty) {
      LiveWorkoutNotificationService().startService(_currentSession!, _currentExerciseIndex, _currentSetIndex);
    }
    return _currentSession!;
  }

  Future<void> updateSession(WorkoutSession session) async {
    _currentSession = session;
    await _saveCurrentSession();
    if (hasActiveSession) {
      LiveWorkoutNotificationService().updateNotification(_currentSession!, _currentExerciseIndex, _currentSetIndex);
    }
  }

  Future<void> selectExercise(int index) async {
    if (_currentSession == null || index < 0 || index >= _currentSession!.exercises.length) return;
    _currentExerciseIndex = index;
    _currentSetIndex = 0;
    await _saveCurrentSession();
    if (hasActiveSession) {
      LiveWorkoutNotificationService().updateNotification(_currentSession!, _currentExerciseIndex, _currentSetIndex);
    }
  }

  Future<void> nextSet() async {
    if (!hasActiveSession) return;
    
    final currentExercise = _currentSession!.exercises[_currentExerciseIndex];
    if (_currentSetIndex < currentExercise.sets.length) {
      // Mark current set as completed first
      final currentSet = currentExercise.sets[_currentSetIndex];
      if (!currentSet.isCompleted) {
        await toggleSetCompletion(currentExercise.id, currentSet.id);
      }
      
      // Then advance to next set or exercise
      if (_currentSetIndex < currentExercise.sets.length - 1) {
        _currentSetIndex++;
      } else {
        // Move to next exercise or complete workout
        if (_currentExerciseIndex < _currentSession!.exercises.length - 1) {
          _currentExerciseIndex++;
          _currentSetIndex = 0;
        } else {
        }
      }
    }
    await _saveCurrentSession();
    LiveWorkoutNotificationService().updateNotification(_currentSession!, _currentExerciseIndex, _currentSetIndex);
  }

  // Added: Method to go to the previous set or exercise
  Future<void> previousSet() async {
    if (!hasActiveSession) return;
    if (_currentSetIndex > 0) {
      _currentSetIndex--;
    } else {
      // Move to previous exercise
      if (_currentExerciseIndex > 0) {
        _currentExerciseIndex--;
        final previousExercise = _currentSession!.exercises[_currentExerciseIndex];
        _currentSetIndex = previousExercise.sets.isNotEmpty ? previousExercise.sets.length - 1 : 0;
      }
    }
    await _saveCurrentSession();
    LiveWorkoutNotificationService().updateNotification(_currentSession!, _currentExerciseIndex, _currentSetIndex);
  }


  Future<void> updateSet(String exerciseId, String setId, {
    int? reps,
    double? weight,
    bool? isCompleted,
  }) async {
    if (_currentSession == null) return;

    // Find the exercise and set indices based on IDs
    final exerciseIdx = _currentSession!.exercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIdx == -1) return;

    final exercise = _currentSession!.exercises[exerciseIdx];
    final setIdx = exercise.sets.indexWhere((s) => s.id == setId);
    if (setIdx == -1) return;

    // Update current indices if the modified set is the current one
    _currentExerciseIndex = exerciseIdx;
    _currentSetIndex = setIdx;

    final updatedSet = exercise.sets[setIdx].copyWith(
      reps: reps,
      weight: weight,
      isCompleted: isCompleted,
    );

    final updatedSets = List<SessionSet>.from(exercise.sets);
    updatedSets[setIdx] = updatedSet;

    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedExercises = List<SessionExercise>.from(_currentSession!.exercises);
    updatedExercises[exerciseIdx] = updatedExercise;

    _currentSession = _currentSession!.copyWith(exercises: updatedExercises);
    await _saveCurrentSession();
    if (hasActiveSession) {
      LiveWorkoutNotificationService().updateNotification(_currentSession!, _currentExerciseIndex, _currentSetIndex);
    }
  }

  Future<void> toggleSetCompletion(String exerciseId, String setId) async {
    if (_currentSession == null) return;

    final exerciseIdx = _currentSession!.exercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIdx == -1) return;
    
    final exercise = _currentSession!.exercises[exerciseIdx];
    final setIdx = exercise.sets.indexWhere((s) => s.id == setId);
    if (setIdx == -1) return;

    // Update current indices if the toggled set is the current one
    _currentExerciseIndex = exerciseIdx;
    _currentSetIndex = setIdx;

    final currentSet = exercise.sets[setIdx];
    final updatedSet = currentSet.copyWith(isCompleted: !currentSet.isCompleted);

    final updatedSets = List<SessionSet>.from(exercise.sets);
    updatedSets[setIdx] = updatedSet;

    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedExercises = List<SessionExercise>.from(_currentSession!.exercises);
    updatedExercises[exerciseIdx] = updatedExercise;

    _currentSession = _currentSession!.copyWith(exercises: updatedExercises);
    await _saveCurrentSession();
    if (hasActiveSession) {
      LiveWorkoutNotificationService().updateNotification(_currentSession!, _currentExerciseIndex, _currentSetIndex);
    }
  }

  Future<WorkoutHistory> completeWorkout({
    String? notes,
    WorkoutMood? mood,
  }) async {
    if (_currentSession == null) {
      throw Exception('No active workout session');
    }

    // Round up duration to the next full minute
    final now = DateTime.now();
    final startTime = _currentSession!.startTime;
    final rawDuration = now.difference(startTime);
    final needsRounding = rawDuration.inSeconds % 60 != 0;
    final roundedDuration = needsRounding
        ? Duration(minutes: rawDuration.inMinutes + 1)
        : rawDuration;
    final roundedEndTime = startTime.add(roundedDuration);

    final completedSession = _currentSession!.copyWith(
      isCompleted: true,
      endTime: roundedEndTime,
      notes: notes,
      mood: mood,
    );

    final exerciseHistories = completedSession.exercises.map((sessionExercise) {
      return WorkoutExerciseHistory(
        exerciseId: sessionExercise.workoutExercise.exercise.slug,
        exerciseName: sessionExercise.workoutExercise.exercise.name,
        sets: sessionExercise.sets.map((sessionSet) {
          return SetHistory(
            reps: sessionSet.reps,
            weight: sessionSet.weight,
            completed: sessionSet.isCompleted,
          );
        }).toList(),
      );
    }).toList();

    final workoutHistory = WorkoutHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workoutId: completedSession.workout.id,
      workoutName: completedSession.workout.name,
      startTime: completedSession.startTime,
      endTime: roundedEndTime,
      exercises: exerciseHistories,
      notes: notes ?? '',
      mood: mood?.index ?? 2, 
      totalSets: completedSession.completedSets,
      totalWeight: completedSession.totalWeight,
      iconCodePoint: completedSession.workout.iconCodePoint,
      colorValue: completedSession.workout.colorValue,
    );

    await DatabaseService.instance.saveWorkoutHistory(workoutHistory);
    await LiveWorkoutNotificationService().stopService();
    await clearActiveSession();
    return workoutHistory;
  }

  Future<void> clearActiveSession() async {
    _currentSession = null;
    _currentExerciseIndex = 0;
    _currentSetIndex = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSessionKey);
    await prefs.remove(_currentExerciseIndexKey);
    await prefs.remove(_currentSetIndexKey);
    await LiveWorkoutNotificationService().stopService();
  }

  Future<void> _saveCurrentSession() async {
    if (_currentSession == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentExerciseIndexKey);
      await prefs.remove(_currentSetIndexKey);
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = json.encode(_currentSession!.toMap());
    await prefs.setString(_currentSessionKey, sessionJson);
    await prefs.setInt(_currentExerciseIndexKey, _currentExerciseIndex);
    await prefs.setInt(_currentSetIndexKey, _currentSetIndex);
  }

  // Helper methods for UI
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String formatWeight(double weight) {
    if (weight == weight.toInt()) {
      return weight.toInt().toString();
    } else {
      return weight.toStringAsFixed(1);
    }
  }
}
