import '../../models/workout_exercise.dart';
import '../../models/typedefs.dart';
import 'base_dao.dart';

class WorkoutExerciseDao extends BaseDao<WorkoutExercise> {
  WorkoutExerciseDao() : super('WorkoutExerciseDao');

  @override
  String get tableName => 'WorkoutExercise';

  @override
  WorkoutExercise fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      id: map['id'] as WorkoutExerciseId,
      workoutTemplateId: map['workoutTemplateId'] as WorkoutTemplateId?,
      workoutId: map['workoutId'] as WorkoutId?,
      exerciseSlug: map['exerciseSlug'] as ExerciseSlug,
      notes: map['notes'] as String?,
      orderIndex: map['orderIndex'] as int?,
      sets: [], // Initialize as empty, to be loaded by service layer
      // exerciseDetail will be loaded by service layer using exerciseSlug
    );
  }

  @override
  Map<String, dynamic> toMap(WorkoutExercise workoutExercise) {
    return {
      'id': workoutExercise.id,
      'workoutTemplateId': workoutExercise.workoutTemplateId,
      'workoutId': workoutExercise.workoutId,
      'exerciseSlug': workoutExercise.exerciseSlug,
      'notes': workoutExercise.notes,
      'orderIndex': workoutExercise.orderIndex,
    };
  }

  /// Get workout exercise by ID
  Future<WorkoutExercise?> getWorkoutExerciseById(WorkoutExerciseId id) async {
    return await getById(id);
  }

  /// Get workout exercises by workout ID
  Future<List<WorkoutExercise>> getWorkoutExercisesByWorkoutId(
      WorkoutId workoutId) async {
    final db = await database;
    logger.fine('Getting workout exercises for workoutId: $workoutId');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'workoutId = ?',
        whereArgs: [workoutId],
        orderBy: 'orderIndex ASC',
      );
      final exercises = maps.map((map) => fromMap(map)).toList();
      logger
          .fine('Found ${exercises.length} exercises for workoutId: $workoutId');
      return exercises;
    } catch (e) {
      logger.severe('Failed to get exercises for workoutId $workoutId: $e');
      rethrow;
    }
  }

  /// Get workout exercises by workout template ID
  Future<List<WorkoutExercise>> getWorkoutExercisesByWorkoutTemplateId(
      WorkoutTemplateId workoutTemplateId) async {
    final db = await database;
    logger.fine('Getting workout exercises for workoutTemplateId: $workoutTemplateId');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'workoutTemplateId = ?',
        whereArgs: [workoutTemplateId],
        orderBy: 'orderIndex ASC',
      );
      final exercises = maps.map((map) => fromMap(map)).toList();
      logger
          .fine('Found ${exercises.length} exercises for workoutTemplateId: $workoutTemplateId');
      return exercises;
    } catch (e) {
      logger.severe('Failed to get exercises for workoutTemplateId $workoutTemplateId: $e');
      rethrow;
    }
  }

  /// Get workout exercises by exercise slug
  Future<List<WorkoutExercise>> getWorkoutExercisesByExerciseSlug(
      ExerciseSlug exerciseSlug) async {
    final db = await database;
    logger.fine('Getting workout exercises for exerciseSlug: $exerciseSlug');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'exerciseSlug = ?',
        whereArgs: [exerciseSlug],
      );
      final exercises = maps.map((map) => fromMap(map)).toList();
      logger.fine(
          'Found ${exercises.length} exercises for exerciseSlug: $exerciseSlug');
      return exercises;
    } catch (e) {
      logger.severe('Failed to get exercises for exerciseSlug $exerciseSlug: $e');
      rethrow;
    }
  }

  /// Update workout exercise
  Future<int> updateWorkoutExercise(WorkoutExercise workoutExercise) async {
    return await update(workoutExercise);
  }

  /// Delete workout exercise
  Future<int> deleteWorkoutExercise(WorkoutExerciseId id) async {
    logger.fine('Deleting workout exercise with id: $id');
    try {
      final result = await delete(id);
      logger.fine('Successfully deleted workout exercise with id: $id. Rows affected: $result');
      return result;
    } catch (e) {
      logger.severe('Failed to delete workout exercise with id: $id. Error: $e');
      rethrow;
    }
  }

  /// Delete workout exercises by workout ID
  Future<int> deleteWorkoutExercisesByWorkoutId(WorkoutId workoutId) async {
    final db = await database;
    logger.fine('Deleting workout exercises for workoutId: $workoutId');
    try {
      final count = await db.delete(
        tableName,
        where: 'workoutId = ?',
        whereArgs: [workoutId],
      );
      logger.fine('Deleted $count exercises for workoutId: $workoutId');
      return count;
    } catch (e) {
      logger.severe('Failed to delete exercises for workoutId $workoutId: $e');
      rethrow;
    }
  }

  /// Delete workout exercises by workout template ID
  Future<int> deleteWorkoutExercisesByWorkoutTemplateId(WorkoutTemplateId workoutTemplateId) async {
    final db = await database;
    logger.fine('Deleting workout exercises for workoutTemplateId: $workoutTemplateId');
    try {
      final count = await db.delete(
        tableName,
        where: 'workoutTemplateId = ?',
        whereArgs: [workoutTemplateId],
      );
      logger.fine('Deleted $count exercises for workoutTemplateId: $workoutTemplateId');
      return count;
    } catch (e) {
      logger.severe('Failed to delete exercises for workoutTemplateId $workoutTemplateId: $e');
      rethrow;
    }
  }
}
