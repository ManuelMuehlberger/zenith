import 'package:logging/logging.dart';
import '../models/exercise.dart';
import 'dao/exercise_dao.dart';
import 'dao/muscle_group_dao.dart';

class ExerciseService {
  static final ExerciseService _instance = ExerciseService._internal();
  factory ExerciseService() => _instance;
  ExerciseService._internal();

  final Logger _logger = Logger('ExerciseService');
  
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
    _logger.info('Loading exercises and muscle groups');
    try {
      _exercises = await _exerciseDao.getAllExercises();
      _logger.info('Successfully loaded ${_exercises.length} exercises');
    } catch (e) {
      _logger.severe('Failed to load exercises: $e');
      _exercises = [];
    }
    
    try {
      final muscleGroups = await _muscleGroupDao.getAllMuscleGroups();
      _muscleGroups = muscleGroups.map((mg) => mg.name).toList()..sort();
      _logger.info('Successfully loaded ${_muscleGroups.length} muscle groups');
    } catch (e) {
      _logger.severe('Failed to load muscle groups: $e');
      _muscleGroups = [];
    }
  }

  List<Exercise> searchExercises(String query) {
    final trimmedQuery = query.trim();
    _logger.fine('Searching exercises with query: "$trimmedQuery"');
    if (trimmedQuery.isEmpty) {
      _logger.fine('Query is empty, returning all exercises');
      return _exercises;
    }
    
    final lowerQuery = trimmedQuery.toLowerCase();
    
    final results = _exercises.where((exercise) {
      final isMatch = exercise.name.toLowerCase().contains(lowerQuery) ||
                      exercise.primaryMuscleGroup.name.toLowerCase().contains(lowerQuery) ||
                      exercise.secondaryMuscleGroups.any((mg) => mg.name.toLowerCase().contains(lowerQuery));
      return isMatch;
    }).toList();
    
    _logger.fine('Found ${results.length} exercises for query: "$trimmedQuery"');
    return results;
  }

  List<Exercise> filterByMuscleGroup(String muscleGroup) {
    final trimmedMuscleGroup = muscleGroup.trim();
    _logger.fine('Filtering exercises by muscle group: "$trimmedMuscleGroup"');
    if (trimmedMuscleGroup.isEmpty) {
      _logger.fine('Muscle group is empty, returning all exercises');
      return _exercises;
    }
    
    final results = _exercises.where((exercise) {
      return exercise.primaryMuscleGroup.name.toLowerCase() == trimmedMuscleGroup.toLowerCase();
    }).toList();
    
    _logger.fine('Found ${results.length} exercises for muscle group: "$trimmedMuscleGroup"');
    return results;
  }

  List<String> get allMuscleGroups {
    return _muscleGroups;
  }
}
