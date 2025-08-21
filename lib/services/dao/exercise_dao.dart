import 'dart:convert';
import '../../models/exercise.dart';
import '../../models/muscle_group.dart';
import 'base_dao.dart';

class ExerciseDao extends BaseDao<Exercise> {
  @override
  String get tableName => 'Exercise';

  @override
  Exercise fromMap(Map<String, dynamic> map) {
    return Exercise(
      slug: map['slug'] as String,
      name: map['name'] as String,
      primaryMuscleGroup: MuscleGroup.fromName(map['primaryMuscleGroup'] as String),
      secondaryMuscleGroups: map['secondaryMuscleGroups'] != null
          ? List<MuscleGroup>.from(
              (jsonDecode(map['secondaryMuscleGroups']) as List)
                  .map((e) => MuscleGroup.fromName(e.toString())))
          : [],
      instructions: map['instructions'] != null
          ? List<String>.from(jsonDecode(map['instructions']) as List)
          : [],
      image: map['image'] as String,
      animation: map['animation'] as String,
      isBodyWeightExercise: map['isBodyWeightExercise'] == 1,
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
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'slug = ?',
      whereArgs: [slug],
    );
    
    if (maps.isNotEmpty) {
      return fromMap(maps.first);
    }
    return null;
  }

  /// Get exercises by primary muscle group
  Future<List<Exercise>> getExercisesByPrimaryMuscleGroup(String muscleGroupName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'primaryMuscleGroup = ?',
      whereArgs: [muscleGroupName],
    );
    
    return maps.map((map) => fromMap(map)).toList();
  }

  /// Get exercises by secondary muscle group
  Future<List<Exercise>> getExercisesBySecondaryMuscleGroup(String muscleGroupName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName 
      WHERE secondaryMuscleGroups LIKE ?
    ''', ['%$muscleGroupName%']);
    
    return maps.map((map) => fromMap(map)).toList();
  }

  /// Search exercises by name
  Future<List<Exercise>> searchExercisesByName(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    
    return maps.map((map) => fromMap(map)).toList();
  }
}
