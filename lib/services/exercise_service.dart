import '../models/exercise.dart';
import 'dao/exercise_dao.dart';
import 'dao/muscle_group_dao.dart';

class ExerciseService {
  static final ExerciseService _instance = ExerciseService._internal();
  factory ExerciseService() => _instance;
  ExerciseService._internal();
  
  static ExerciseService get instance => _instance;

  // Inject DAOs - now can be overridden for testing
  ExerciseDao _exerciseDao = ExerciseDao();
  MuscleGroupDao _muscleGroupDao = MuscleGroupDao();

  // Cache for exercises
  List<Exercise> _exercises = [];
  List<Exercise> get exercises => _exercises;

  // Cache for muscle groups
  List<String> _muscleGroups = [];

  // Constructor for testing with dependency injection
  ExerciseService.withDependencies({
    required ExerciseDao exerciseDao,
    required MuscleGroupDao muscleGroupDao,
  }) : _exerciseDao = exerciseDao,
       _muscleGroupDao = muscleGroupDao;

  Future<void> loadExercises() async {
    // Load exercises with individual error handling
    try {
      _exercises = await _exerciseDao.getAllExercises();
    } catch (e) {
      _exercises = [];
      // Log error in production: print('Failed to load exercises: $e');
    }
    
    // Load muscle groups with individual error handling
    try {
      final muscleGroups = await _muscleGroupDao.getAllMuscleGroups();
      _muscleGroups = muscleGroups.map((mg) => mg.name).toList()..sort();
    } catch (e) {
      _muscleGroups = [];
      // Log error in production: print('Failed to load muscle groups: $e');
    }
  }

  List<Exercise> searchExercises(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return _exercises;
    
    final lowerQuery = trimmedQuery.toLowerCase();
    
    // Filter exercises in memory
    return _exercises.where((exercise) {
      // Check exercise name
      if (exercise.name.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // Check primary muscle group
      if (exercise.primaryMuscleGroup.name.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // Check secondary muscle groups
      if (exercise.secondaryMuscleGroups.any((mg) => 
          mg.name.toLowerCase().contains(lowerQuery))) {
        return true;
      }
      
      return false;
    }).toList();
  }

  List<Exercise> filterByMuscleGroup(String muscleGroup) {
    final trimmedMuscleGroup = muscleGroup.trim();
    if (trimmedMuscleGroup.isEmpty) return _exercises;
    
    // Filter exercises in memory
    return _exercises.where((exercise) {
      return exercise.primaryMuscleGroup.name.toLowerCase() == trimmedMuscleGroup.toLowerCase();
    }).toList();
  }

  List<String> get allMuscleGroups {
    return _muscleGroups;
  }
}
