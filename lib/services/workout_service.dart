import 'package:logging/logging.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';
import 'dao/workout_dao.dart';
import 'dao/workout_exercise_dao.dart';
import 'dao/workout_set_dao.dart';
import '../models/workout_folder.dart';
import 'dao/workout_folder_dao.dart';

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();
  final Logger _logger = Logger('WorkoutService');

  factory WorkoutService() => _instance;
  WorkoutService._internal();
  
  static WorkoutService get instance => _instance;

  // Inject DAOs
  WorkoutDao _workoutDao = WorkoutDao();
  WorkoutExerciseDao _workoutExerciseDao = WorkoutExerciseDao();
  WorkoutSetDao _workoutSetDao = WorkoutSetDao();
  WorkoutFolderDao _workoutFolderDao = WorkoutFolderDao();

  // Allow for mock injection in tests
  set workoutDao(WorkoutDao dao) => _workoutDao = dao;
  set workoutExerciseDao(WorkoutExerciseDao dao) => _workoutExerciseDao = dao;
  set workoutSetDao(WorkoutSetDao dao) => _workoutSetDao = dao;
  set workoutFolderDao(WorkoutFolderDao dao) => _workoutFolderDao = dao;

  List<Workout> _workouts = [];
  List<WorkoutFolder> _folders = [];

  List<Workout> get workouts => _workouts;
  List<WorkoutFolder> get folders => _folders;

  Future<void> loadData() async {
    _logger.info('Loading all workout data');
    try {

      _workouts = await _workoutDao.getAllWorkouts();
      _logger.fine('Loaded ${_workouts.length} workouts');
      
      for (int i = 0; i < _workouts.length; i++) {
        final workout = _workouts[i];
        final workoutExercises = await _workoutExerciseDao.getWorkoutExercisesByWorkoutId(workout.id);
        
        final List<WorkoutExercise> exercisesWithSets = [];
        for (final workoutExercise in workoutExercises) {
          final sets = await _workoutSetDao.getWorkoutSetsByWorkoutExerciseId(workoutExercise.id);
          exercisesWithSets.add(workoutExercise.copyWith(sets: sets));
        }
        
        _workouts[i] = workout.copyWith(exercises: exercisesWithSets);
      }
      _logger.info('Finished loading exercises and sets for all workouts');
    } catch (e) {
      _logger.severe('Failed to load workout data: $e');
      _workouts = [];
    }
  }

  Future<void> saveData() async {
    // Data is saved directly to the database through DAO operations
    // This method is kept for compatibility but doesn't need to do anything
  }

  // Folder operations
  Future<void> loadFolders() async {
    _logger.info('Loading folder data');
    try {
      _folders = await _workoutFolderDao.getAllWorkoutFoldersOrdered();
      _logger.fine('Loaded ${_folders.length} folders');
    } catch (e) {
      _logger.severe('Failed to load folder data: $e');
      _folders = [];
    }
  }

  Future<WorkoutFolder> createFolder(String name) async {
    _logger.info('Creating new folder with name: $name');
    final folder = WorkoutFolder(name: name);
    await _workoutFolderDao.insert(folder);
    _folders.add(folder);
    _logger.fine('Folder created with id: ${folder.id}');
    return folder;
  }

  Future<void> updateFolder(WorkoutFolder folder) async {
    _logger.info('Updating folder with id: ${folder.id}');
    await _workoutFolderDao.updateWorkoutFolder(folder);
    final index = _folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      _folders[index] = folder;
      _logger.fine('Folder updated in cache');
    }
  }

  Future<void> deleteFolder(String folderId) async {
    _logger.info('Deleting folder with id: $folderId');

    // Move all workouts in this folder to root
    final workoutsInFolder = getWorkoutsInFolder(folderId);
    for (final workout in workoutsInFolder) {
      final updatedWorkout = workout.copyWith(folderId: null);
      await _workoutDao.updateWorkout(updatedWorkout);
      final idx = _workouts.indexWhere((w) => w.id == updatedWorkout.id);
      if (idx != -1) {
        _workouts[idx] = updatedWorkout;
      }
    }

    await _workoutFolderDao.deleteWorkoutFolder(folderId);
    _folders.removeWhere((f) => f.id == folderId);
    _logger.fine('Folder deleted from database and cache');
  }

  WorkoutFolder? getFolderById(String id) {
    try {
      return _folders.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  // Workout operations
  Future<Workout> createWorkout(String name, {String? folderId}) async {
    _logger.info('Creating new workout with name: $name in folder: $folderId');
    final workout = Workout(
      name: name,
      exercises: [],
      folderId: folderId,
      status: WorkoutStatus.template,
    );
    
    await _workoutDao.insert(workout);
    _workouts.add(workout);
    _logger.fine('Workout created with id: ${workout.id}');
    return workout;
  }

  Future<void> updateWorkout(Workout workout) async {
    _logger.info('Updating workout with id: ${workout.id}');
    await _workoutDao.updateWorkout(workout);
    final index = _workouts.indexWhere((w) => w.id == workout.id);
    if (index != -1) {
      _workouts[index] = workout;
      _logger.fine('Workout updated in cache');
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    _logger.info('Deleting workout with id: $workoutId');
    final workoutExercises = await _workoutExerciseDao.getWorkoutExercisesByWorkoutId(workoutId);
    for (final exercise in workoutExercises) {
      await _workoutSetDao.deleteWorkoutSetsByWorkoutExerciseId(exercise.id);
    }
    await _workoutExerciseDao.deleteWorkoutExercisesByWorkoutId(workoutId);
    _logger.fine('Deleted associated exercises and sets');
    
    await _workoutDao.deleteWorkout(workoutId);
    _workouts.removeWhere((w) => w.id == workoutId);
    _logger.fine('Workout deleted from database and cache');
  }

  Future<void> moveWorkoutToFolder(String workoutId, String? folderId) async {
    _logger.info('Moving workout $workoutId to folder $folderId');
    final index = _workouts.indexWhere((w) => w.id == workoutId);
    if (index != -1) {
      final updatedWorkout = _workouts[index].copyWith(folderId: folderId);
      await _workoutDao.updateWorkout(updatedWorkout);
      _workouts[index] = updatedWorkout;
      _logger.fine('Workout moved successfully');
    } else {
      _logger.warning('Workout with id $workoutId not found in cache');
    }
  }

  Future<void> reorderWorkoutsInFolder(String? folderId, int oldIndex, int newIndex) async {
    _logger.info('Reordering workouts in folder $folderId from $oldIndex to $newIndex');
    final workoutsInFolder = getWorkoutsInFolder(folderId);
    if (oldIndex < 0 || oldIndex >= workoutsInFolder.length || 
        newIndex < 0 || newIndex >= workoutsInFolder.length) {
      _logger.warning('Invalid reorder indices');
      return;
    }

    // Remove the workout from the old position
    final workout = workoutsInFolder.removeAt(oldIndex);
    // Insert it at the new position
    workoutsInFolder.insert(newIndex, workout);

    // Update orderIndex for all workouts in the folder to reflect the new order.
    for (int i = 0; i < workoutsInFolder.length; i++) {
      final updatedWorkout = workoutsInFolder[i].copyWith(orderIndex: i);
      await _workoutDao.updateWorkout(updatedWorkout);
      final index = _workouts.indexWhere((w) => w.id == updatedWorkout.id);
      if (index != -1) {
        _workouts[index] = updatedWorkout;
      }
    }
  }

  Future<void> reorderExercisesInWorkout(String workoutId, int oldIndex, int newIndex) async {
    _logger.info('Reordering exercises in workout $workoutId from $oldIndex to $newIndex');
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex == -1) {
      _logger.warning('Workout with id $workoutId not found');
      return;
    }
    
    final workout = _workouts[workoutIndex];
    if (oldIndex < 0 || oldIndex >= workout.exercises.length || 
        newIndex < 0 || newIndex >= workout.exercises.length) {
      _logger.warning('Invalid reorder indices for exercises');
      return;
    }

    // Create a copy of the exercises list
    final exercises = List<WorkoutExercise>.from(workout.exercises);
    
    // Remove the exercise from the old position
    final exercise = exercises.removeAt(oldIndex);
    // Insert it at the new position
    exercises.insert(newIndex, exercise);

    // Update orderIndex for all exercises in the workout
    for (int i = 0; i < exercises.length; i++) {
      final updatedExercise = exercises[i].copyWith(orderIndex: i);
      await _workoutExerciseDao.updateWorkoutExercise(updatedExercise);
      exercises[i] = updatedExercise;
    }

    // Update the workout with reordered exercises
    final updatedWorkout = workout.copyWith(exercises: exercises);
    await _workoutDao.updateWorkout(updatedWorkout);
    _workouts[workoutIndex] = updatedWorkout;
  }

  // Exercise operations within workout
  Future<void> addExerciseToWorkout(String workoutId, Exercise exerciseDetail) async {
    _logger.info('Adding exercise ${exerciseDetail.slug} to workout $workoutId');
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      final workoutExercise = WorkoutExercise(
        workoutId: workoutId,
        exerciseSlug: exerciseDetail.slug,
        sets: [],
      );
      await _workoutExerciseDao.insert(workoutExercise);
      
      final defaultSet = WorkoutSet(
        workoutExerciseId: workoutExercise.id,
        setIndex: 0,
        targetReps: 10,
        targetWeight: 0.0,
      );
      await _workoutSetDao.insert(defaultSet);
      
      final exerciseWithSet = workoutExercise.copyWith(sets: [defaultSet]);
      
      final updatedExercises = List<WorkoutExercise>.from(_workouts[workoutIndex].exercises)..add(exerciseWithSet);
      
      final updatedWorkout = _workouts[workoutIndex].copyWith(exercises: updatedExercises);
      await _workoutDao.updateWorkout(updatedWorkout);
      _workouts[workoutIndex] = updatedWorkout;
      _logger.fine('Exercise added successfully');
    } else {
      _logger.warning('Workout with id $workoutId not found');
    }
  }

  Future<void> removeExerciseFromWorkout(String workoutId, String exerciseId) async {
    _logger.info('Removing exercise $exerciseId from workout $workoutId');
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      await _workoutSetDao.deleteWorkoutSetsByWorkoutExerciseId(exerciseId);
      await _workoutExerciseDao.deleteWorkoutExercise(exerciseId);
      
      final updatedExercises = _workouts[workoutIndex].exercises.where((e) => e.id != exerciseId).toList();
      
      final updatedWorkout = _workouts[workoutIndex].copyWith(exercises: updatedExercises);
      await _workoutDao.updateWorkout(updatedWorkout);
      _workouts[workoutIndex] = updatedWorkout;
      _logger.fine('Exercise removed successfully');
    } else {
      _logger.warning('Workout with id $workoutId not found');
    }
  }

  Future<void> updateWorkoutExercise(String workoutId, WorkoutExercise exercise) async {
    _logger.fine('Updating workout exercise ${exercise.id} in workout $workoutId');
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      await _workoutExerciseDao.updateWorkoutExercise(exercise);
      
      final updatedExercises = _workouts[workoutIndex].exercises.map((e) => e.id == exercise.id ? exercise : e).toList();
      
      final updatedWorkout = _workouts[workoutIndex].copyWith(exercises: updatedExercises);
      await _workoutDao.updateWorkout(updatedWorkout);
      _workouts[workoutIndex] = updatedWorkout;
    } else {
      _logger.warning('Workout with id $workoutId not found');
    }
  }

  // Set operations within workout exercise
  Future<void> addSetToExercise(String workoutId, String exerciseId, {int targetReps = 10, double targetWeight = 0.0}) async {
    _logger.info('Adding set to exercise $exerciseId in workout $workoutId');
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      final exerciseIndex = _workouts[workoutIndex].exercises.indexWhere((e) => e.id == exerciseId);
      if (exerciseIndex != -1) {
        final exercise = _workouts[workoutIndex].exercises[exerciseIndex];
        final nextIndex = exercise.sets.length;
        
        final newSet = WorkoutSet(
          workoutExerciseId: exerciseId,
          setIndex: nextIndex,
          targetReps: targetReps,
          targetWeight: targetWeight,
        );
        await _workoutSetDao.insert(newSet);
        
        final updatedSets = List<WorkoutSet>.from(exercise.sets)..add(newSet);
        final updatedExercise = exercise.copyWith(sets: updatedSets);
        
        await updateWorkoutExercise(workoutId, updatedExercise);
        _logger.fine('Set added successfully');
      } else {
        _logger.warning('Exercise with id $exerciseId not found in workout $workoutId');
      }
    } else {
      _logger.warning('Workout with id $workoutId not found');
    }
  }

  Future<void> removeSetFromExercise(String workoutId, String exerciseId, String setId) async {
    _logger.info('Removing set $setId from exercise $exerciseId in workout $workoutId');
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      final exerciseIndex = _workouts[workoutIndex].exercises.indexWhere((e) => e.id == exerciseId);
      if (exerciseIndex != -1) {
        final exercise = _workouts[workoutIndex].exercises[exerciseIndex];
        
        await _workoutSetDao.deleteWorkoutSet(setId);
        
        final updatedSets = exercise.sets.where((s) => s.id != setId).toList();
        final updatedExercise = exercise.copyWith(sets: updatedSets);
        
        await updateWorkoutExercise(workoutId, updatedExercise);
        _logger.fine('Set removed successfully');
      } else {
        _logger.warning('Exercise with id $exerciseId not found in workout $workoutId');
      }
    } else {
      _logger.warning('Workout with id $workoutId not found');
    }
  }

  Future<void> updateSet(String workoutId, String exerciseId, String setId, {int? targetReps, double? targetWeight, int? targetRestSeconds}) async {
    _logger.fine('Updating set $setId in exercise $exerciseId');
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      final exerciseIndex = _workouts[workoutIndex].exercises.indexWhere((e) => e.id == exerciseId);
      if (exerciseIndex != -1) {
        final exercise = _workouts[workoutIndex].exercises[exerciseIndex];
        final setIndex = exercise.sets.indexWhere((s) => s.id == setId);
        
        if (setIndex != -1) {
          final set = exercise.sets[setIndex];
          final updatedSet = set.copyWith(
            targetReps: targetReps ?? set.targetReps,
            targetWeight: targetWeight ?? set.targetWeight,
            targetRestSeconds: targetRestSeconds ?? set.targetRestSeconds,
          );
          
          await _workoutSetDao.updateWorkoutSet(updatedSet);
          
          final updatedSets = List<WorkoutSet>.from(exercise.sets);
          updatedSets[setIndex] = updatedSet;
          final updatedExercise = exercise.copyWith(sets: updatedSets);
          
          await updateWorkoutExercise(workoutId, updatedExercise);
          _logger.fine('Set updated successfully');
        } else {
          _logger.warning('Set with id $setId not found in exercise $exerciseId');
        }
      } else {
        _logger.warning('Exercise with id $exerciseId not found in workout $workoutId');
      }
    } else {
      _logger.warning('Workout with id $workoutId not found');
    }
  }

  // Helper methods
  List<Workout> getWorkoutsInFolder(String? folderId) {
    final workouts = _workouts.where((w) => w.folderId == folderId).toList();
    workouts.sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));
    return workouts;
  }

  List<Workout> getWorkoutsNotInFolder() {
    return _workouts.where((w) => w.folderId == null).toList();
  }

  Workout? getWorkoutById(String id) {
    try {
      return _workouts.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearUserWorkouts() async {
    _logger.warning('Clearing all user workouts');
    for (final workout in _workouts) {
      for (final exercise in workout.exercises) {
        await _workoutSetDao.deleteWorkoutSetsByWorkoutExerciseId(exercise.id);
      }
      await _workoutExerciseDao.deleteWorkoutExercisesByWorkoutId(workout.id);
      await _workoutDao.deleteWorkout(workout.id);
    }
    
    _workouts = [];
    _logger.info('All user workouts cleared');
  }
}
