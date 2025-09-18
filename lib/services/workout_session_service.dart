import 'package:logging/logging.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import 'dao/workout_dao.dart';
import 'dao/workout_exercise_dao.dart';
import 'dao/workout_set_dao.dart';
import 'live_workout_notification_service.dart';
import 'database_service.dart';
import 'exercise_service.dart';
import 'package:meta/meta.dart';

class WorkoutSessionService {
  static final WorkoutSessionService _instance = WorkoutSessionService._internal();
  final Logger _logger = Logger('WorkoutSessionService');

  factory WorkoutSessionService() => _instance;
  WorkoutSessionService._internal();
  
  static WorkoutSessionService get instance => _instance;

  // Inject DAOs
  WorkoutDao _workoutDao = WorkoutDao();
  WorkoutExerciseDao _workoutExerciseDao = WorkoutExerciseDao();
  WorkoutSetDao _workoutSetDao = WorkoutSetDao();

  // Allow for mock injection in tests
  @visibleForTesting
  set workoutDao(WorkoutDao dao) => _workoutDao = dao;
  @visibleForTesting
  set workoutExerciseDao(WorkoutExerciseDao dao) => _workoutExerciseDao = dao;
  @visibleForTesting
  set workoutSetDao(WorkoutSetDao dao) => _workoutSetDao = dao;

  // Notification service (injectable for tests)
  NotificationServiceAPI _notificationService = LiveWorkoutNotificationService();
  @visibleForTesting
  set notificationService(NotificationServiceAPI service) => _notificationService = service;

  // Exercise service (injectable for tests)
  ExerciseService _exerciseService = ExerciseService.instance;
  @visibleForTesting
  set exerciseService(ExerciseService svc) => _exerciseService = svc;

  Workout? _currentSession;
  @visibleForTesting
  set currentSession(Workout? session) => _currentSession = session;
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;

  Workout? get currentSession => _currentSession;
  int get currentExerciseIndex => _currentExerciseIndex;
  int get currentSetIndex => _currentSetIndex;
  bool get hasActiveSession => _currentSession != null && _currentSession!.status == WorkoutStatus.inProgress;

  void initializeNotificationCallback() {
    _logger.info('Initializing notification callback');
    _notificationService.setNextSetCallback(() {
      if (hasActiveSession) {
        _logger.fine('Notification callback triggered for next set');
        nextSet();
      }
    });
  }

  @visibleForTesting
  WorkoutExercise cloneTemplateExerciseForSession(
    WorkoutExercise templateExercise,
    String sessionId,
    int orderIndex,
  ) {
    // Create a new session-scoped exercise with a fresh ID and correct foreign keys
    final clonedExercise = WorkoutExercise(
      workoutTemplateId: null,
      workoutId: sessionId,
      exerciseSlug: templateExercise.exerciseSlug,
      notes: templateExercise.notes,
      orderIndex: orderIndex,
      exerciseDetail: templateExercise.exerciseDetail,
      sets: const [],
    );

    // Deep-clone sets with fresh IDs and link them to the cloned exercise
    final clonedSets = <WorkoutSet>[];
    for (int j = 0; j < templateExercise.sets.length; j++) {
      final s = templateExercise.sets[j];
      clonedSets.add(WorkoutSet(
        workoutExerciseId: clonedExercise.id,
        setIndex: j,
        targetReps: s.targetReps,
        targetWeight: s.targetWeight,
        targetRestSeconds: s.targetRestSeconds,
        actualReps: null,
        actualWeight: null,
        isCompleted: false,
      ));
    }

    return clonedExercise.copyWith(sets: clonedSets);
  }

  @visibleForTesting
  Future<void> enrichExercisesWithDetails(List<WorkoutExercise> exercises) async {
    try {
      if (_exerciseService.exercises.isEmpty) {
        await _exerciseService.loadExercises();
      }
      final all = _exerciseService.exercises;
      final bySlug = {for (final e in all) e.slug: e};
      for (int i = 0; i < exercises.length; i++) {
        final slug = exercises[i].exerciseSlug;
        final detail = bySlug[slug];
        exercises[i] = exercises[i].copyWith(exerciseDetail: detail);
      }
    } catch (e) {
      _logger.fine('Could not enrich exercises with details: $e');
    }
  }

  Future<void> loadActiveSession() async {
    _logger.info('Loading active workout session');
    try {
      final inProgressWorkouts = await _workoutDao.getInProgressWorkouts();
      
      if (inProgressWorkouts.isNotEmpty) {
        _currentSession = inProgressWorkouts.first;
        _logger.fine('Found active session with id: ${_currentSession!.id}');
        
        final workoutExercises = await _workoutExerciseDao.getWorkoutExercisesByWorkoutId(_currentSession!.id);
        
        final List<WorkoutExercise> exercisesWithSets = [];
        for (final workoutExercise in workoutExercises) {
          final sets = await _workoutSetDao.getWorkoutSetsByWorkoutExerciseId(workoutExercise.id);
          exercisesWithSets.add(workoutExercise.copyWith(sets: sets));
        }

        await enrichExercisesWithDetails(exercisesWithSets);
        _currentSession = _currentSession!.copyWith(exercises: exercisesWithSets);
        
        if (_currentSession!.status == WorkoutStatus.completed) {
          _logger.warning('Loaded session is already completed, clearing it');
          await clearActiveSession();
        } else {
          _logger.info('Restarting notification service for active session');
          await _notificationService.restartServiceIfNeeded(_currentSession!, _currentExerciseIndex, _currentSetIndex);
        }
      } else {
        _logger.info('No active session found');
      }
    } catch (e) {
      _logger.severe('Failed to load active session: $e');
      await clearActiveSession();
    }
  }

  Future<Workout> startWorkout(Workout workout) async {
    _logger.info('Starting new workout session from template: ${workout.id}');
    await clearActiveSession();
    
    // Pre-generate session ID so cloned exercises can reference it
    final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    final sessionExercises = <WorkoutExercise>[];

    // Populate lastReps and lastWeight from history (if available) while cloning
    for (int i = 0; i < workout.exercises.length; i++) {
      final templateExercise = workout.exercises[i];
      final exerciseSlug = templateExercise.exerciseSlug;

      // Fetch the last workout for this specific exercise
      final Workout? lastWorkout = await DatabaseService.instance.getLastWorkoutForExercise(exerciseSlug);

      // For now, we preserve template target values; history can be used to prefill actuals in the future
      final sourceExercise = lastWorkout != null
          ? templateExercise.copyWith(sets: List<WorkoutSet>.from(templateExercise.sets))
          : templateExercise;

      // Clone to session-scoped exercise with fresh IDs and proper foreign keys
      final cloned = cloneTemplateExerciseForSession(sourceExercise, sessionId, i);
      sessionExercises.add(cloned);
    }

    // Attach exercise details (name, muscle groups) by slug for UI
    await enrichExercisesWithDetails(sessionExercises);

    _currentSession = Workout(
      id: sessionId,
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
    
    await _workoutDao.insert(_currentSession!);
    _logger.fine('Saved new session to database with id: ${_currentSession!.id}');
    
    for (final exercise in _currentSession!.exercises) {
      await _workoutExerciseDao.insert(exercise);
      for (final set in exercise.sets) {
        await _workoutSetDao.insert(set);
      }
    }
    _logger.fine('Saved exercises and sets for new session');
    
    _currentExerciseIndex = 0;
    _currentSetIndex = 0;

    if (_currentSession!.exercises.isNotEmpty) {
      _logger.info('Starting notification service for new session');
      _notificationService.startService(_currentSession!, _currentExerciseIndex, _currentSetIndex);
    }
    return _currentSession!;
  }

  Future<void> updateSession(Workout session) async {
    _logger.fine('Updating session: ${session.id}');
    _currentSession = session;
    await _workoutDao.updateWorkout(session);
    if (hasActiveSession) {
      _notificationService.updateNotification(_currentSession!, _currentExerciseIndex, _currentSetIndex);
    }
  }

  Future<void> selectExercise(int index) async {
    _logger.fine('Selecting exercise at index: $index');
    if (_currentSession == null || index < 0 || index >= _currentSession!.exercises.length) {
      _logger.warning('Invalid exercise index');
      return;
    }
    _currentExerciseIndex = index;
    _currentSetIndex = 0;
    await _workoutDao.updateWorkout(_currentSession!);
    if (hasActiveSession) {
      _notificationService.updateNotification(_currentSession!, _currentExerciseIndex, _currentSetIndex);
    }
  }

  Future<void> nextSet() async {
    _logger.fine('Moving to next set');
    if (!hasActiveSession) {
      _logger.warning('No active session to advance set');
      return;
    }
    
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
    await _workoutDao.updateWorkout(_currentSession!);
    _notificationService.updateNotification(_currentSession!, _currentExerciseIndex, _currentSetIndex);
  }

  // Added: Method to go to the previous set or exercise
  Future<void> previousSet() async {
    _logger.fine('Moving to previous set');
    if (!hasActiveSession) {
      _logger.warning('No active session to go to previous set');
      return;
    }
    if (_currentSetIndex > 0) {
      _currentSetIndex--;
    } else {
      if (_currentExerciseIndex > 0) {
        _currentExerciseIndex--;
        final previousExercise = _currentSession!.exercises[_currentExerciseIndex];
        _currentSetIndex = previousExercise.sets.isNotEmpty ? previousExercise.sets.length - 1 : 0;
      }
    }
    await _workoutDao.updateWorkout(_currentSession!);
    _notificationService.updateNotification(_currentSession!, _currentExerciseIndex, _currentSetIndex);
  }


  Future<void> updateSet(String exerciseId, String setId, {
    int? targetReps,
    double? targetWeight,
    int? actualReps,
    double? actualWeight,
    bool? isCompleted,
  }) async {
    _logger.fine('Updating set $setId in exercise $exerciseId with: targetReps=$targetReps, targetWeight=$targetWeight, actualReps=$actualReps, actualWeight=$actualWeight, isCompleted=$isCompleted');
    if (_currentSession == null) {
      _logger.warning('No active session to update set');
      return;
    }

    final exerciseIdx = _currentSession!.exercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIdx == -1) {
      _logger.warning('Exercise with id $exerciseId not found');
      return;
    }

    final exercise = _currentSession!.exercises[exerciseIdx];
    final setIdx = exercise.sets.indexWhere((s) => s.id == setId);
    if (setIdx == -1) {
      _logger.warning('Set with id $setId not found');
      return;
    }

    _currentExerciseIndex = exerciseIdx;
    _currentSetIndex = setIdx;

    final currentSet = exercise.sets[setIdx];
    final updatedSet = currentSet.copyWith(
      targetReps: targetReps ?? currentSet.targetReps,
      targetWeight: targetWeight ?? currentSet.targetWeight,
      actualReps: actualReps ?? currentSet.actualReps,
      actualWeight: actualWeight ?? currentSet.actualWeight,
      isCompleted: isCompleted ?? currentSet.isCompleted,
    );
    
    _logger.finer('Set ${updatedSet.id} updated from ${currentSet.toMap()} to ${updatedSet.toMap()}');

    // Update the set in the database
    await _workoutSetDao.updateWorkoutSet(updatedSet);

    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIdx] = updatedSet;

    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedExercises = List<WorkoutExercise>.from(_currentSession!.exercises);
    updatedExercises[exerciseIdx] = updatedExercise;

    _currentSession = _currentSession!.copyWith(exercises: updatedExercises);
    await _workoutDao.updateWorkout(_currentSession!);
    if (hasActiveSession) {
      _notificationService.updateNotification(_currentSession!, _currentExerciseIndex, _currentSetIndex);
    }
  }

  Future<void> toggleSetCompletion(String exerciseId, String setId) async {
    _logger.fine('Toggling completion for set $setId in exercise $exerciseId');
    if (_currentSession == null) {
      _logger.warning('No active session to toggle set completion');
      return;
    }

    final exerciseIdx = _currentSession!.exercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIdx == -1) {
      _logger.warning('Exercise with id $exerciseId not found');
      return;
    }
    
    final exercise = _currentSession!.exercises[exerciseIdx];
    final setIdx = exercise.sets.indexWhere((s) => s.id == setId);
    if (setIdx == -1) {
      _logger.warning('Set with id $setId not found');
      return;
    }

    _currentExerciseIndex = exerciseIdx;
    _currentSetIndex = setIdx;

    final currentSet = exercise.sets[setIdx];
    final updatedSet = currentSet.copyWith(isCompleted: !currentSet.isCompleted);

    // Update the set in the database
    await _workoutSetDao.updateWorkoutSet(updatedSet);

    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIdx] = updatedSet;

    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedExercises = List<WorkoutExercise>.from(_currentSession!.exercises);
    updatedExercises[exerciseIdx] = updatedExercise;

    _currentSession = _currentSession!.copyWith(exercises: updatedExercises);
    await _workoutDao.updateWorkout(_currentSession!);
    if (hasActiveSession) {
      _notificationService.updateNotification(_currentSession!, _currentExerciseIndex, _currentSetIndex);
    }
  }

  Future<Workout> completeWorkout({
    String? notes,
    int? mood,
    Duration? durationOverride,
  }) async {
    _logger.info('Completing workout session: ${_currentSession?.id}');
    if (_currentSession == null) {
      _logger.severe('No active workout session to complete');
      throw Exception('No active workout session');
    }

    final now = DateTime.now();
    final startTime = _currentSession!.startedAt ?? now;

    // Use override duration if provided, otherwise apply existing rounding behavior
    Duration effectiveDuration;
    if (durationOverride != null) {
      effectiveDuration = durationOverride;
    } else {
      // Round up duration to the next full minute
      final rawDuration = now.difference(startTime);
      final needsRounding = rawDuration.inSeconds % 60 != 0;
      effectiveDuration = needsRounding
          ? Duration(minutes: rawDuration.inMinutes + 1)
          : rawDuration;
    }

    _logger.fine('Completing workout: start=$startTime, '
        '${durationOverride != null ? 'override=${durationOverride.inMinutes}m' : 'rounded=${effectiveDuration.inMinutes}m'}');

    final endTime = startTime.add(effectiveDuration);
    _logger.fine('Computed endTime: $endTime');

    final completedSession = _currentSession!.copyWith(
      status: WorkoutStatus.completed,
      completedAt: endTime,
      notes: notes,
    );

    await _workoutDao.updateWorkout(completedSession);
    _logger.fine('Saved completed session to database');
    
    await _notificationService.stopService();
    await clearActiveSession();
    _logger.info('Workout session completed and cleared');
    return completedSession;
  }

  Future<void> clearActiveSession({bool deleteFromDb = false}) async {
    _logger.info('Clearing active session. Delete from DB: $deleteFromDb');
    if (deleteFromDb && _currentSession != null) {
      final workoutId = _currentSession!.id;
      _logger.info('Deleting workout and all associated data from database: $workoutId');

      // Re-fetch the workout and its children from the DB to ensure we have the complete data to delete.
      // This avoids issues with stale in-memory state.
      final exercisesToDelete = await _workoutExerciseDao.getWorkoutExercisesByWorkoutId(workoutId);
      
      for (final exercise in exercisesToDelete) {
        _logger.info('Deleting data for exercise: ${exercise.id}');
        // Fetch sets for this specific exercise before deleting them.
        final setsToDelete = await _workoutSetDao.getWorkoutSetsByWorkoutExerciseId(exercise.id);
        for (final set in setsToDelete) {
          _logger.fine('Deleting set: ${set.id}');
          await _workoutSetDao.deleteWorkoutSet(set.id);
        }
        _logger.fine('Deleting exercise: ${exercise.id}');
        await _workoutExerciseDao.deleteWorkoutExercise(exercise.id);
      }
      
      // Finally, delete the main workout record.
      _logger.info('Deleting workout record: $workoutId');
      await _workoutDao.deleteWorkout(workoutId);
      _logger.info('Workout deletion process complete for workout ID: $workoutId');
    }
    
    _currentSession = null;
    _currentExerciseIndex = 0;
    _currentSetIndex = 0;
    await _notificationService.stopService();
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
