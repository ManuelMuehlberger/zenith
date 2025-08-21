import '../models/exercise.dart';
import '../models/muscle_group.dart';
import 'dao/exercise_dao.dart';
import 'dao/muscle_group_dao.dart';

class ExerciseService {
  static final ExerciseService _instance = ExerciseService._internal();
  factory ExerciseService() => _instance;
  ExerciseService._internal();
  
  static ExerciseService get instance => _instance;

  // Inject DAOs
  final ExerciseDao _exerciseDao = ExerciseDao();
  final MuscleGroupDao _muscleGroupDao = MuscleGroupDao();

  // Cache for exercises
  List<Exercise> _exercises = [];
  List<Exercise> get exercises => _exercises;

  // Cache for muscle groups
  List<String> _muscleGroups = [];

  Future<void> loadExercises() async {
    try {
      // Load exercises from database
      _exercises = await _exerciseDao.getAllExercises();
      
      // Load muscle groups from database
      final muscleGroups = await _muscleGroupDao.getAllMuscleGroups();
      _muscleGroups = muscleGroups.map((mg) => mg.name).toList()..sort();
    } catch (e) {
      _exercises = [];
      _muscleGroups = [];
    }
  }

  List<Exercise> searchExercises(String query) {
    if (query.isEmpty) return _exercises;
    
    // Filter exercises in memory
    return _exercises.where((exercise) {
      return exercise.name.toLowerCase().contains(query.toLowerCase()) ||
             exercise.primaryMuscleGroup.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<Exercise> filterByMuscleGroup(String muscleGroup) {
    if (muscleGroup.isEmpty) return _exercises;
    
    // Filter exercises in memory
    return _exercises.where((exercise) {
      return exercise.primaryMuscleGroup.name.toLowerCase() == muscleGroup.toLowerCase();
    }).toList();
  }

  List<String> get allMuscleGroups {
    return _muscleGroups;
  }
}
