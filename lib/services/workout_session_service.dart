import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import 'database_service.dart';
import 'live_workout_notification_service.dart';

class WorkoutSessionService {
  static final WorkoutSessionService _instance = WorkoutSessionService._internal();
  factory WorkoutSessionService() => _instance;
  WorkoutSessionService._internal();
  
  static WorkoutSessionService get instance => _instance;

  Workout? _currentSession;
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  static const String _currentSessionKey = 'current_workout_session';
  static const String _currentExerciseIndexKey = 'current_exercise_index';
  static const String _currentSetIndexKey = 'current_set_index';

  Workout? get currentSession => _currentSession;
  int get currentExerciseIndex => _currentExerciseIndex;
  int get currentSetIndex => _currentSetIndex;
  bool get hasActiveSession => _currentSession != null && _currentSession!.status == WorkoutStatus.inProgress;

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
        _currentSession = Workout.fromMap(sessionMap);
        _currentExerciseIndex = prefs.getInt(_currentExerciseIndexKey) ?? 0;
        _currentSetIndex = prefs.getInt(_currentSetIndexKey) ?? 0;
        
        // If the session is completed, clear it
        if (_currentSession!.status == WorkoutStatus.completed) {
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

  Future<Workout> startWorkout(Workout workout) async {
    // Clear any existing session first
    await clearActiveSession();
    
    // Create a new workout session from the template
    final sessionExercises = <WorkoutExercise>[];
    
    // Populate lastReps and lastWeight from history
    for (int i = 0; i < workout.exercises.length; i++) {
      final workoutExercise = workout.exercises[i];
      final exerciseSlug = workoutExercise.exerciseSlug;
      
      // Fetch the last workout for this specific exercise
      final Workout? lastWorkout = await DatabaseService.instance.getLastWorkoutForExercise(exerciseSlug);

      if (lastWorkout != null) {
        final List<WorkoutSet> updatedSets = [];
        for (int j = 0; j < workoutExercise.sets.length; j++) {
          WorkoutSet currentSet = workoutExercise.sets[j];
          
          // For now, we'll just copy the set as-is since we don't have the history structure anymore
          // In a full implementation, we would populate actualReps and actualWeight from history
          updatedSets.add(currentSet);
        }
        sessionExercises.add(workoutExercise.copyWith(sets: updatedSets));
      } else {
        sessionExercises.add(workoutExercise);
      }
    }

    _currentSession = Workout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: workout.name,
      description: workout.description,
      iconCodePoint: workout.iconCodePoint,
      colorValue: workout.colorValue,
      folderId: workout.folderId,
      notes: workout.notes,
      status: WorkoutStatus.inProgress,
      templateId: workout.id,
      startedAt: DateTime.now(),
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

  Future<void> updateSession(Workout session) async {
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
    int? actualReps,
    double? actualWeight,
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
      actualReps: actualReps,
      actualWeight: actualWeight,
      isCompleted: isCompleted,
    );

    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIdx] = updatedSet;

    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedExercises = List<WorkoutExercise>.from(_currentSession!.exercises);
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

    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIdx] = updatedSet;

    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedExercises = List<WorkoutExercise>.from(_currentSession!.exercises);
    updatedExercises[exerciseIdx] = updatedExercise;

    _currentSession = _currentSession!.copyWith(exercises: updatedExercises);
    await _saveCurrentSession();
    if (hasActiveSession) {
      LiveWorkoutNotificationService().updateNotification(_currentSession!, _currentExerciseIndex, _currentSetIndex);
    }
  }

  Future<Workout> completeWorkout({
    String? notes,
    int? mood,
  }) async {
    if (_currentSession == null) {
      throw Exception('No active workout session');
    }

    // Round up duration to the next full minute
    final now = DateTime.now();
    final startTime = _currentSession!.startedAt ?? DateTime.now();
    final rawDuration = now.difference(startTime);
    final needsRounding = rawDuration.inSeconds % 60 != 0;
    final roundedDuration = needsRounding
        ? Duration(minutes: rawDuration.inMinutes + 1)
        : rawDuration;
    final roundedEndTime = startTime.add(roundedDuration);

    final completedSession = _currentSession!.copyWith(
      status: WorkoutStatus.completed,
      completedAt: roundedEndTime,
      notes: notes,
    );

    await DatabaseService.instance.saveWorkout(completedSession);
    await LiveWorkoutNotificationService().stopService();
    await clearActiveSession();
    return completedSession;
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
