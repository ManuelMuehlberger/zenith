import '../models/workout.dart';
import '../models/workout_folder.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';
import '../models/typedefs.dart';
import 'dao/workout_dao.dart';
import 'dao/workout_folder_dao.dart';
import 'dao/workout_exercise_dao.dart';
import 'dao/workout_set_dao.dart';
import 'exercise_service.dart';

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();
  
  static WorkoutService get instance => _instance;

  // Inject DAOs
  final WorkoutDao _workoutDao = WorkoutDao();
  final WorkoutFolderDao _workoutFolderDao = WorkoutFolderDao();
  final WorkoutExerciseDao _workoutExerciseDao = WorkoutExerciseDao();
  final WorkoutSetDao _workoutSetDao = WorkoutSetDao();

  List<Workout> _workouts = [];
  List<WorkoutFolder> _folders = [];

  List<Workout> get workouts => _workouts;
  List<WorkoutFolder> get folders => _folders;

  Future<void> loadData() async {
    try {
      // Load folders
      _folders = await _workoutFolderDao.getAllWorkoutFoldersOrdered();
      
      // Load workouts
      _workouts = await _workoutDao.getAllWorkouts();
      
      // Load exercises and sets for each workout
      for (int i = 0; i < _workouts.length; i++) {
        final workout = _workouts[i];
        final workoutExercises = await _workoutExerciseDao.getWorkoutExercisesByWorkoutId(workout.id);
        
        // Load sets for each exercise
        final List<WorkoutExercise> exercisesWithSets = [];
        for (final workoutExercise in workoutExercises) {
          final sets = await _workoutSetDao.getWorkoutSetsByWorkoutExerciseId(workoutExercise.id);
          final exerciseWithSets = workoutExercise.copyWith(sets: sets);
          exercisesWithSets.add(exerciseWithSets);
        }
        
        // Update workout with exercises and sets
        _workouts[i] = workout.copyWith(exercises: exercisesWithSets);
      }
    } catch (e) {
      _workouts = [];
      _folders = [];
    }
  }

  Future<void> saveData() async {
    // Data is saved directly to the database through DAO operations
    // This method is kept for compatibility but doesn't need to do anything
  }

  // Folder operations
  Future<WorkoutFolder> createFolder(String name) async {
    final folder = WorkoutFolder(
      name: name,
    );
    
    await _workoutFolderDao.insert(folder);
    _folders.add(folder);
    return folder;
  }

  Future<void> updateFolder(WorkoutFolder folder) async {
    await _workoutFolderDao.updateWorkoutFolder(folder);
    final index = _folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      _folders[index] = folder;
    }
  }

  Future<void> deleteFolder(String folderId) async {
    // Move workouts out of folder before deleting
    for (int i = 0; i < _workouts.length; i++) {
      if (_workouts[i].folderId == folderId) {
        final updatedWorkout = _workouts[i].copyWith(folderId: null);
        await _workoutDao.updateWorkout(updatedWorkout);
        _workouts[i] = updatedWorkout;
      }
    }
    
    await _workoutFolderDao.deleteWorkoutFolder(folderId);
    _folders.removeWhere((f) => f.id == folderId);
  }

  // Workout operations
  Future<Workout> createWorkout(String name, {String? folderId}) async {
    final workout = Workout(
      name: name,
      exercises: [],
      folderId: folderId,
      status: WorkoutStatus.template,
    );
    
    await _workoutDao.insert(workout);
    _workouts.add(workout);
    return workout;
  }

  Future<void> updateWorkout(Workout workout) async {
    await _workoutDao.updateWorkout(workout);
    final index = _workouts.indexWhere((w) => w.id == workout.id);
    if (index != -1) {
      _workouts[index] = workout;
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    // Delete associated exercises and sets first
    final workoutExercises = await _workoutExerciseDao.getWorkoutExercisesByWorkoutId(workoutId);
    for (final exercise in workoutExercises) {
      await _workoutSetDao.deleteWorkoutSetsByWorkoutExerciseId(exercise.id);
    }
    await _workoutExerciseDao.deleteWorkoutExercisesByWorkoutId(workoutId);
    
    await _workoutDao.deleteWorkout(workoutId);
    _workouts.removeWhere((w) => w.id == workoutId);
  }

  Future<void> moveWorkoutToFolder(String workoutId, String? folderId) async {
    final index = _workouts.indexWhere((w) => w.id == workoutId);
    if (index != -1) {
      final updatedWorkout = _workouts[index].copyWith(folderId: folderId);
      await _workoutDao.updateWorkout(updatedWorkout);
      _workouts[index] = updatedWorkout;
    }
  }

  Future<void> reorderWorkoutsInFolder(String? folderId, int oldIndex, int newIndex) async {
    final workoutsInFolder = getWorkoutsInFolder(folderId);
    if (oldIndex < 0 || oldIndex >= workoutsInFolder.length || 
        newIndex < 0 || newIndex >= workoutsInFolder.length) {
      return;
    }

    // Remove the workout from the old position
    final workout = workoutsInFolder.removeAt(oldIndex);
    // Insert it at the new position
    workoutsInFolder.insert(newIndex, workout);

    // Update orderIndex for all workouts in the folder
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
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex == -1) return;
    
    final workout = _workouts[workoutIndex];
    if (oldIndex < 0 || oldIndex >= workout.exercises.length || 
        newIndex < 0 || newIndex >= workout.exercises.length) {
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

  Future<void> reorderFolders(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _folders.length || 
        newIndex < 0 || newIndex >= _folders.length) {
      return;
    }

    // Remove the folder from the old position
    final folder = _folders.removeAt(oldIndex);
    // Insert it at the new position
    _folders.insert(newIndex, folder);

    // Update orderIndex for all folders
    for (int i = 0; i < _folders.length; i++) {
      final updatedFolder = _folders[i].copyWith(orderIndex: i);
      await _workoutFolderDao.updateWorkoutFolder(updatedFolder);
      _folders[i] = updatedFolder;
    }
  }

  // Exercise operations within workout
  Future<void> addExerciseToWorkout(String workoutId, Exercise exerciseDetail) async {
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      // Create a workout exercise
      final workoutExercise = WorkoutExercise(
        workoutId: workoutId,
        exerciseSlug: exerciseDetail.slug,
        sets: [],
      );
      
      // Insert the workout exercise into the database
      await _workoutExerciseDao.insert(workoutExercise);
      
      // Create a default set
      final defaultSet = WorkoutSet(
        workoutExerciseId: workoutExercise.id,
        setIndex: 0,
        targetReps: 10,
        targetWeight: 0.0,
      );
      
      // Insert the default set into the database
      await _workoutSetDao.insert(defaultSet);
      
      // Update the workout exercise with the set
      final exerciseWithSet = workoutExercise.copyWith(sets: [defaultSet]);
      
      // Update the workout with the new exercise
      final updatedExercises = List<WorkoutExercise>.from(_workouts[workoutIndex].exercises);
      updatedExercises.add(exerciseWithSet);
      
      final updatedWorkout = _workouts[workoutIndex].copyWith(exercises: updatedExercises);
      await _workoutDao.updateWorkout(updatedWorkout);
      _workouts[workoutIndex] = updatedWorkout;
    }
  }

  Future<void> removeExerciseFromWorkout(String workoutId, String exerciseId) async {
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      // Delete associated sets first
      await _workoutSetDao.deleteWorkoutSetsByWorkoutExerciseId(exerciseId);
      
      // Delete the workout exercise
      await _workoutExerciseDao.deleteWorkoutExercise(exerciseId);
      
      // Update the workout
      final updatedExercises = _workouts[workoutIndex].exercises
          .where((e) => e.id != exerciseId)
          .toList();
      
      final updatedWorkout = _workouts[workoutIndex].copyWith(exercises: updatedExercises);
      await _workoutDao.updateWorkout(updatedWorkout);
      _workouts[workoutIndex] = updatedWorkout;
    }
  }

  Future<void> updateWorkoutExercise(String workoutId, WorkoutExercise exercise) async {
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      // Update the workout exercise in the database
      await _workoutExerciseDao.updateWorkoutExercise(exercise);
      
      // Update the workout
      final updatedExercises = _workouts[workoutIndex].exercises.map((e) {
        return e.id == exercise.id ? exercise : e;
      }).toList();
      
      final updatedWorkout = _workouts[workoutIndex].copyWith(exercises: updatedExercises);
      await _workoutDao.updateWorkout(updatedWorkout);
      _workouts[workoutIndex] = updatedWorkout;
    }
  }

  // Set operations within workout exercise
  Future<void> addSetToExercise(String workoutId, String exerciseId, {int targetReps = 10, double targetWeight = 0.0}) async {
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      final exerciseIndex = _workouts[workoutIndex].exercises.indexWhere((e) => e.id == exerciseId);
      if (exerciseIndex != -1) {
        final exercise = _workouts[workoutIndex].exercises[exerciseIndex];
        
        // Determine the next set index
        final nextIndex = exercise.sets.length;
        
        // Create a new set
        final newSet = WorkoutSet(
          workoutExerciseId: exerciseId,
          setIndex: nextIndex,
          targetReps: targetReps,
          targetWeight: targetWeight,
        );
        
        // Insert the new set into the database
        await _workoutSetDao.insert(newSet);
        
        // Update the exercise with the new set
        final updatedSets = List<WorkoutSet>.from(exercise.sets)..add(newSet);
        final updatedExercise = exercise.copyWith(sets: updatedSets);
        
        await updateWorkoutExercise(workoutId, updatedExercise);
      }
    }
  }

  Future<void> removeSetFromExercise(String workoutId, String exerciseId, String setId) async {
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      final exerciseIndex = _workouts[workoutIndex].exercises.indexWhere((e) => e.id == exerciseId);
      if (exerciseIndex != -1) {
        final exercise = _workouts[workoutIndex].exercises[exerciseIndex];
        
        // Delete the set from the database
        await _workoutSetDao.deleteWorkoutSet(setId);
        
        // Update the exercise without the deleted set
        final updatedSets = exercise.sets.where((s) => s.id != setId).toList();
        final updatedExercise = exercise.copyWith(sets: updatedSets);
        
        await updateWorkoutExercise(workoutId, updatedExercise);
      }
    }
  }

  Future<void> updateSet(String workoutId, String exerciseId, String setId, {int? targetReps, double? targetWeight, int? targetRestSeconds}) async {
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      final exerciseIndex = _workouts[workoutIndex].exercises.indexWhere((e) => e.id == exerciseId);
      if (exerciseIndex != -1) {
        final exercise = _workouts[workoutIndex].exercises[exerciseIndex];
        
        // Find the set to update
        final setIndex = exercise.sets.indexWhere((s) => s.id == setId);
        if (setIndex != -1) {
          final set = exercise.sets[setIndex];
          
          // Create updated set
          final updatedSet = set.copyWith(
            targetReps: targetReps ?? set.targetReps,
            targetWeight: targetWeight ?? set.targetWeight,
            targetRestSeconds: targetRestSeconds ?? set.targetRestSeconds,
          );
          
          // Update the set in the database
          await _workoutSetDao.updateWorkoutSet(updatedSet);
          
          // Update the exercise with the updated set
          final updatedSets = List<WorkoutSet>.from(exercise.sets);
          updatedSets[setIndex] = updatedSet;
          final updatedExercise = exercise.copyWith(sets: updatedSets);
          
          await updateWorkoutExercise(workoutId, updatedExercise);
        }
      }
    }
  }

  // Helper methods
  List<Workout> getWorkoutsInFolder(String? folderId) {
    return _workouts.where((w) => w.folderId == folderId).toList();
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

  WorkoutFolder? getFolderById(String id) {
    try {
      return _folders.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearUserWorkoutsAndFolders() async {
    // Delete all workout sets
    for (final workout in _workouts) {
      for (final exercise in workout.exercises) {
        await _workoutSetDao.deleteWorkoutSetsByWorkoutExerciseId(exercise.id);
      }
    }
    
    // Delete all workout exercises
    for (final workout in _workouts) {
      await _workoutExerciseDao.deleteWorkoutExercisesByWorkoutId(workout.id);
    }
    
    // Delete all workouts
    for (final workout in _workouts) {
      await _workoutDao.deleteWorkout(workout.id);
    }
    
    // Delete all folders
    for (final folder in _folders) {
      await _workoutFolderDao.deleteWorkoutFolder(folder.id);
    }
    
    _workouts = [];
    _folders = [];
  }
}
