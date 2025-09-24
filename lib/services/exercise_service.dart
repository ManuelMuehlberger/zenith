import 'package:logging/logging.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
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
    _logger.fine('searchExercises: processing query="$trimmedQuery" (lowercased="$lowerQuery")');

    // Start with strict contains matches to prioritize exact/substring hits
    final containsMatches = _exercises.where((exercise) {
      final name = exercise.name.toLowerCase();
      final primary = exercise.primaryMuscleGroup.name.toLowerCase();
      final secondaries = exercise.secondaryMuscleGroups.map((mg) => mg.name.toLowerCase());
      final equipment = exercise.equipment.toLowerCase();
      final normalizedEquipment = equipment == 'dumbell' ? 'dumbbell' : equipment;
      return name.contains(lowerQuery) ||
          primary.contains(lowerQuery) ||
          secondaries.any((mg) => mg.contains(lowerQuery)) ||
          (normalizedEquipment.isNotEmpty && normalizedEquipment.contains(lowerQuery)) ||
          (lowerQuery.contains('bodyweight') && exercise.isBodyWeightExercise);
    }).toList();
    _logger.fine('searchExercises: found ${containsMatches.length} contains matches');

    // Fuzzy matches across name, muscle groups, equipment, and bodyweight
    _logger.fine('searchExercises: running fuzzy search on ${_exercises.length} exercises');
    final fuzzyResults = extractAllSorted<Exercise>(
      query: lowerQuery,
      choices: _exercises,
      getter: (e) => _buildSearchBlob(e),
      cutoff: 70, // stricter primary cutoff to avoid noisy false positives
    );
    _logger.fine('searchExercises: containsMatches=${containsMatches.length}, fuzzyCandidates=${fuzzyResults.length}');
    // Log up to 5 top fuzzy candidates (name:score)
    final topFuzzySample = fuzzyResults.take(5).map((r) => '${r.choice.name}:${r.score}').join(', ');
    if (topFuzzySample.isNotEmpty) {
      _logger.finer('searchExercises top fuzzy candidates: $topFuzzySample');
    }

    // Merge scores, giving contains matches a perfect score to rank them first
    final Map<Exercise, int> scored = {};
    for (final r in fuzzyResults) {
      scored[r.choice] = r.score;
    }
    for (final e in containsMatches) {
      scored[e] = 100;
    }
    _logger.finer('searchExercises: merged scored entries count=${scored.length}');

    // If there are NO direct contains matches and too few results, add top fuzzy
    // suggestions based on NAME only (to avoid tokens like "bodyweight" dominating).
    const int minResults = 6;
    const int fallbackLimit = 12;
    if (containsMatches.isEmpty && scored.length < minResults && _exercises.length > scored.length) {
      _logger.fine('searchExercises: No direct contains matches and scored.length=${scored.length} < minResults=$minResults — running name-only fallback');
      final top = extractTop<Exercise>(
        query: lowerQuery,
        choices: _exercises,
        getter: (e) => e.name.toLowerCase(),
        limit: fallbackLimit,
        cutoff: 50, // allow more candidates but still keep a floor
      );
      final int bestScore = top.isNotEmpty ? top.first.score : 0;
      _logger.finer('searchExercises fallback: topCandidates=${top.length}, bestScore=$bestScore');
      final fallbackSample = top.take(8).map((r) => '${r.choice.name}:${r.score}').join(', ');
      if (fallbackSample.isNotEmpty) {
        _logger.finer('searchExercises fallback candidates: $fallbackSample');
      }
      if (bestScore >= 70) { // guard against unrelated queries
        for (final t in top) {
          if (!scored.containsKey(t.choice)) {
            scored[t.choice] = t.score;
            _logger.fine('searchExercises fallback: adding ${t.choice.name} with score ${t.score}');
            if (scored.length >= minResults) break;
          }
        }
      } else {
        _logger.fine('searchExercises fallback: bestScore $bestScore below guard threshold, not adding fallback results');
      }
    }

    // Sort by score desc then by name asc for stability
    final sorted = scored.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.name.compareTo(b.key.name);
      });

    final results = sorted.map((e) => e.key).toList();
    // Log top result names for easier debugging
    final topNames = results.take(10).map((ex) => ex.name).toList();
    _logger.fine('searchExercises result count=${results.length} for query="$trimmedQuery" (contains=${containsMatches.length}, fuzzyCandidates=${fuzzyResults.length}) top=${topNames.join(", ")}');
    return results;
  }

  // Build a lowercased searchable string for an exercise for fuzzy matching
  String _buildSearchBlob(Exercise e) {
    final equipment = e.equipment.toLowerCase() == 'dumbell' ? 'dumbbell' : e.equipment.toLowerCase();
    final secondaries = e.secondaryMuscleGroups.map((mg) => mg.name.toLowerCase()).join(' ');
    final bodyweight = e.isBodyWeightExercise ? 'bodyweight' : '';
    final blob = '${e.name.toLowerCase()} ${e.primaryMuscleGroup.name.toLowerCase()} $secondaries $equipment $bodyweight';
    // Use a very fine-grained log level because this is called many times during fuzzy evaluation.
    _logger.finest('buildSearchBlob(${e.name}) => "${blob}" (len=${blob.length})');
    return blob;
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

  /// Filter exercises by equipment type.
  ///
  /// Example inputs: "Barbell", "Dumbbell", "Machine", "Cable", "None"
  List<Exercise> filterByEquipment(String equipment) {
    final eq = equipment.trim().toLowerCase();
    _logger.fine('Filtering exercises by equipment: "$eq"');
    if (eq.isEmpty) {
      _logger.fine('Equipment filter is empty, returning all exercises');
      return _exercises;
    }
    
    // Handle the spelling variation in the data ("Dumbell" vs "Dumbbell")
    final normalizedEquipment = eq == 'dumbbell' ? 'dumbell' : eq;
    _logger.fine('filterByEquipment: searching for normalized equipment="$normalizedEquipment"');
    final results = _exercises
        .where((e) => (e.equipment).toLowerCase() == normalizedEquipment)
        .toList();
    _logger.fine('filterByEquipment: matched ${results.length} exercises for equipment="$equipment" (normalized="$normalizedEquipment")');
    return results;
  }

  // New: Filter by bodyweight flag
  // If isBodyweight == null, returns all. Otherwise filters to matching flag.
  List<Exercise> filterByBodyweight(bool? isBodyweight) {
    if (isBodyweight == null) {
      _logger.fine('Bodyweight filter is null, returning all exercises');
      return _exercises;
    }
    _logger.fine('Filtering exercises by bodyweight: $isBodyweight');
    final results = _exercises.where((e) => e.isBodyWeightExercise == isBodyweight).toList();
    _logger.fine('filterByBodyweight: matched ${results.length} exercises for isBodyweight=$isBodyweight');
    return results;
  }

  // Test-only helpers to enable widget testing without DB
  void setDependenciesForTesting({
    ExerciseDao? exerciseDao,
    MuscleGroupDao? muscleGroupDao,
    List<Exercise>? seedExercises,
    List<String>? seedMuscleGroups,
  }) {
    _logger.fine('setDependenciesForTesting called');
    if (exerciseDao != null) {
      _exerciseDao = exerciseDao;
      _logger.fine('setDependenciesForTesting: exerciseDao overridden');
    }
    if (muscleGroupDao != null) {
      _muscleGroupDao = muscleGroupDao;
      _logger.fine('setDependenciesForTesting: muscleGroupDao overridden');
    }
    if (seedExercises != null) {
      _exercises = seedExercises;
      _logger.fine('setDependenciesForTesting: seeded ${_exercises.length} exercises');
    }
    if (seedMuscleGroups != null) {
      _muscleGroups = seedMuscleGroups;
      _logger.fine('setDependenciesForTesting: seeded ${_muscleGroups.length} muscle groups');
    }
  }

  void resetForTesting() {
    _logger.fine('resetForTesting: clearing exercises and muscle groups');
    _exercises = [];
    _muscleGroups = [];
  }
}
