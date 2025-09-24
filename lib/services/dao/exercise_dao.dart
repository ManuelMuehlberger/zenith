import 'dart:convert';
import '../../models/exercise.dart';
import '../../models/muscle_group.dart';
import 'base_dao.dart';

class ExerciseDao extends BaseDao<Exercise> {
  ExerciseDao() : super('ExerciseDao');

  @override
  String get tableName => 'Exercise';

  @override
  Exercise fromMap(Map<String, dynamic> map) {
    // Helper function to safely get muscle group with fallback
    MuscleGroup _safeMuscleGroupFromName(String name, String exerciseSlug) {
      if (name.trim().isEmpty) {
        logger.warning('Empty muscle group name for exercise $exerciseSlug, using NA as fallback');
        return MuscleGroup.na;
      }
      try {
        return MuscleGroup.fromName(name);
      } catch (e) {
        logger.warning('Invalid muscle group "$name" for exercise $exerciseSlug, using NA as fallback: $e');
        return MuscleGroup.na;
      }
    }

    // Helper function to safely parse secondary muscle groups
    List<MuscleGroup> _safeSecondaryMuscleGroups(String? secondaryMuscleGroupsJson, String exerciseSlug) {
      if (secondaryMuscleGroupsJson == null) return [];
      
      try {
        final List<dynamic> muscleGroupNames = jsonDecode(secondaryMuscleGroupsJson) as List;
        final List<MuscleGroup> validMuscleGroups = [];
        
        for (final name in muscleGroupNames) {
          final nameStr = name.toString().trim();
          if (nameStr.isNotEmpty) {
            try {
              validMuscleGroups.add(MuscleGroup.fromName(nameStr));
            } catch (e) {
              logger.warning('Invalid secondary muscle group "$nameStr" for exercise $exerciseSlug, skipping: $e');
            }
          }
        }
        
        return validMuscleGroups;
      } catch (e) {
        logger.warning('Failed to parse secondary muscle groups for exercise $exerciseSlug: $e');
        return [];
      }
    }

    final exerciseSlug = map['slug'] as String;
    
    return Exercise(
      slug: exerciseSlug,
      name: map['name'] as String,
      primaryMuscleGroup: _safeMuscleGroupFromName(map['primaryMuscleGroup'] as String, exerciseSlug),
      secondaryMuscleGroups: _safeSecondaryMuscleGroups(map['secondaryMuscleGroups'] as String?, exerciseSlug),
      instructions: map['instructions'] != null
          ? List<String>.from(jsonDecode(map['instructions']) as List)
          : [],
      equipment: (map['equipment'] as String?) ?? '',
      image: map['image'] as String,
      animation: map['animation'] as String,
      isBodyWeightExercise: map['isBodyWeightExercise'] is int
          ? map['isBodyWeightExercise'] == 1
          : (map['isBodyWeightExercise'] ?? false),
    );
  }

  @override
  Map<String, dynamic> toMap(Exercise exercise) {
    return {
      'slug': exercise.slug,
      'name': exercise.name,
      'primaryMuscleGroup': exercise.primaryMuscleGroup.name,
      'secondaryMuscleGroups': jsonEncode(
          exercise.secondaryMuscleGroups.map((e) => e.name).toList()),
      'instructions': jsonEncode(exercise.instructions),
      'equipment': exercise.equipment,
      'image': exercise.image,
      'animation': exercise.animation,
      'isBodyWeightExercise': exercise.isBodyWeightExercise ? 1 : 0,
    };
  }

  /// Get all exercises
  Future<List<Exercise>> getAllExercises() async {
    return await getAll();
  }

  /// Get exercise by slug
  Future<Exercise?> getExerciseBySlug(String slug) async {
    final db = await database;
    logger.fine('Getting exercise by slug: $slug');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'slug = ?',
        whereArgs: [slug],
      );

      if (maps.isNotEmpty) {
        logger.fine('Found exercise with slug: $slug');
        return fromMap(maps.first);
      }
      logger.fine('Exercise with slug $slug not found');
      return null;
    } catch (e) {
      logger.severe('Failed to get exercise by slug $slug: $e');
      rethrow;
    }
  }

  /// Get exercises by primary muscle group
  Future<List<Exercise>> getExercisesByPrimaryMuscleGroup(
      String muscleGroupName) async {
    final db = await database;
    logger.fine('Getting exercises for primary muscle group: $muscleGroupName');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'primaryMuscleGroup = ?',
        whereArgs: [muscleGroupName],
      );
      final exercises = maps.map((map) => fromMap(map)).toList();
      logger.fine(
          'Found ${exercises.length} exercises for primary muscle group: $muscleGroupName');
      return exercises;
    } catch (e) {
      logger.severe(
          'Failed to get exercises for primary muscle group $muscleGroupName: $e');
      rethrow;
    }
  }

  /// Get exercises by secondary muscle group
  Future<List<Exercise>> getExercisesBySecondaryMuscleGroup(
      String muscleGroupName) async {
    final db = await database;
    logger.fine('Getting exercises for secondary muscle group: $muscleGroupName');
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName 
      WHERE secondaryMuscleGroups LIKE ?
    ''', ['%$muscleGroupName%']);
      final exercises = maps.map((map) => fromMap(map)).toList();
      logger.fine(
          'Found ${exercises.length} exercises for secondary muscle group: $muscleGroupName');
      return exercises;
    } catch (e) {
      logger.severe(
          'Failed to get exercises for secondary muscle group $muscleGroupName: $e');
      rethrow;
    }
  }

  /// Search exercises by name
  Future<List<Exercise>> searchExercisesByName(String query) async {
    final db = await database;
    logger.fine('Searching exercises by name with query: "$query"');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
      );
      final exercises = maps.map((map) => fromMap(map)).toList();
      logger.fine('Found ${exercises.length} exercises matching query: "$query"');
      return exercises;
    } catch (e) {
      logger.severe('Failed to search exercises by name with query "$query": $e');
      rethrow;
    }
  }
}
