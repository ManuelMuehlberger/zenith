import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';
import '../models/workout_folder.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();
  
  static WorkoutService get instance => _instance;

  List<Workout> _workouts = [];
  List<WorkoutFolder> _folders = [];

  List<Workout> get workouts => _workouts;
  List<WorkoutFolder> get folders => _folders;

  static const String _workoutsKey = 'workouts';
  static const String _foldersKey = 'folders';

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load workouts
    final workoutsJson = prefs.getString(_workoutsKey);
    if (workoutsJson != null) {
      final List<dynamic> workoutsList = json.decode(workoutsJson);
      _workouts = workoutsList.map((w) => Workout.fromMap(w)).toList();
    }
    
    // Load folders
    final foldersJson = prefs.getString(_foldersKey);
    if (foldersJson != null) {
      final List<dynamic> foldersList = json.decode(foldersJson);
      _folders = foldersList.map((f) => WorkoutFolder.fromMap(f)).toList();
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save workouts
    final workoutsJson = json.encode(_workouts.map((w) => w.toMap()).toList());
    await prefs.setString(_workoutsKey, workoutsJson);
    
    // Save folders
    final foldersJson = json.encode(_folders.map((f) => f.toMap()).toList());
    await prefs.setString(_foldersKey, foldersJson);
  }

  // Folder operations
  Future<WorkoutFolder> createFolder(String name) async {
    final folder = WorkoutFolder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _folders.add(folder);
    await saveData();
    return folder;
  }

  Future<void> updateFolder(WorkoutFolder folder) async {
    final index = _folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      _folders[index] = folder.copyWith(updatedAt: DateTime.now());
      await saveData();
    }
  }

  Future<void> deleteFolder(String folderId) async {
    // Move workouts out of folder before deleting
    for (int i = 0; i < _workouts.length; i++) {
      if (_workouts[i].folderId == folderId) {
        _workouts[i] = _workouts[i].copyWith(folderId: null);
      }
    }
    
    _folders.removeWhere((f) => f.id == folderId);
    await saveData();
  }

  // Workout operations
  Future<Workout> createWorkout(String name, {String? folderId}) async {
    final workout = Workout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      exercises: [],
      folderId: folderId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _workouts.add(workout);
    await saveData();
    return workout;
  }

  Future<void> updateWorkout(Workout workout) async {
    final index = _workouts.indexWhere((w) => w.id == workout.id);
    if (index != -1) {
      _workouts[index] = workout.copyWith(updatedAt: DateTime.now());
      await saveData();
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    _workouts.removeWhere((w) => w.id == workoutId);
    await saveData();
  }

  Future<void> moveWorkoutToFolder(String workoutId, String? folderId) async {
    final index = _workouts.indexWhere((w) => w.id == workoutId);
    if (index != -1) {
      _workouts[index] = _workouts[index].copyWith(
        folderId: folderId,
        updatedAt: DateTime.now(),
      );
      await saveData();
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

    // Update the main workouts list with the new order
    final otherWorkouts = _workouts.where((w) => w.folderId != folderId).toList();
    _workouts = [...otherWorkouts, ...workoutsInFolder];
    
    await saveData();
  }

  // Exercise operations within workout
  Future<void> addExerciseToWorkout(String workoutId, Exercise exercise) async {
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      // Create a workout exercise with one default set
      final defaultSet = WorkoutSet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reps: 10,
        weight: 0.0,
      );
      
      final workoutExercise = WorkoutExercise(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        exercise: exercise,
        sets: [defaultSet],
      );
      
      final updatedExercises = List<WorkoutExercise>.from(_workouts[workoutIndex].exercises);
      updatedExercises.add(workoutExercise);
      
      _workouts[workoutIndex] = _workouts[workoutIndex].copyWith(
        exercises: updatedExercises,
        updatedAt: DateTime.now(),
      );
      
      await saveData();
    }
  }

  Future<void> removeExerciseFromWorkout(String workoutId, String exerciseId) async {
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      final updatedExercises = _workouts[workoutIndex].exercises
          .where((e) => e.id != exerciseId)
          .toList();
      
      _workouts[workoutIndex] = _workouts[workoutIndex].copyWith(
        exercises: updatedExercises,
        updatedAt: DateTime.now(),
      );
      
      await saveData();
    }
  }

  Future<void> updateWorkoutExercise(String workoutId, WorkoutExercise exercise) async {
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      final updatedExercises = _workouts[workoutIndex].exercises.map((e) {
        return e.id == exercise.id ? exercise : e;
      }).toList();
      
      _workouts[workoutIndex] = _workouts[workoutIndex].copyWith(
        exercises: updatedExercises,
        updatedAt: DateTime.now(),
      );
      
      await saveData();
    }
  }

  // Set operations within workout exercise
  Future<void> addSetToExercise(String workoutId, String exerciseId, {int reps = 10, double weight = 0.0}) async {
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      final exerciseIndex = _workouts[workoutIndex].exercises.indexWhere((e) => e.id == exerciseId);
      if (exerciseIndex != -1) {
        final exercise = _workouts[workoutIndex].exercises[exerciseIndex];
        final updatedExercise = exercise.addSet(reps: reps, weight: weight);
        
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
        final updatedExercise = exercise.removeSet(setId);
        
        await updateWorkoutExercise(workoutId, updatedExercise);
      }
    }
  }

  Future<void> updateSet(String workoutId, String exerciseId, String setId, {int? reps, double? weight, bool? isCompleted}) async {
    final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex != -1) {
      final exerciseIndex = _workouts[workoutIndex].exercises.indexWhere((e) => e.id == exerciseId);
      if (exerciseIndex != -1) {
        final exercise = _workouts[workoutIndex].exercises[exerciseIndex];
        final updatedExercise = exercise.updateSet(setId, reps: reps, weight: weight, isCompleted: isCompleted);
        
        await updateWorkoutExercise(workoutId, updatedExercise);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_workoutsKey);
    await prefs.remove(_foldersKey);
    _workouts = [];
    _folders = [];
    // No need to call saveData() as we are clearing.
  }
}
