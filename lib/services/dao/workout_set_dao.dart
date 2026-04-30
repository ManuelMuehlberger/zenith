import '../../models/workout_set.dart';
import '../../models/typedefs.dart';
import 'base_dao.dart';

class WorkoutSetDao extends BaseDao<WorkoutSet> {
  WorkoutSetDao() : super('WorkoutSetDao');

  @override
  String get tableName => 'WorkoutSet';

  @override
  WorkoutSet fromMap(Map<String, dynamic> map) {
    return WorkoutSet.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(WorkoutSet workoutSet) {
    return {
      'id': workoutSet.id,
      'workoutExerciseId': workoutSet.workoutExerciseId,
      'setIndex': workoutSet.setIndex,
      'targetReps': workoutSet.targetReps,
      'targetWeight': workoutSet.targetWeight,
      'targetRestSeconds': workoutSet.targetRestSeconds,
      'actualReps': workoutSet.actualReps,
      'actualWeight': workoutSet.actualWeight,
      'isCompleted': workoutSet.isCompleted ? 1 : 0,
    };
  }

  /// Get workout set by ID
  Future<WorkoutSet?> getWorkoutSetById(WorkoutSetId id) async {
    return await getById(id);
  }

  /// Get workout sets by workout exercise ID
  Future<List<WorkoutSet>> getWorkoutSetsByWorkoutExerciseId(
    WorkoutExerciseId workoutExerciseId,
  ) async {
    final db = await database;
    logger.fine(
      'Getting workout sets for workoutExerciseId: $workoutExerciseId',
    );
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'workoutExerciseId = ?',
        whereArgs: [workoutExerciseId],
      );
      final sets = maps.map((map) => fromMap(map)).toList()
        ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
      logger.fine(
        'Found ${sets.length} sets for workoutExerciseId: $workoutExerciseId',
      );
      return sets;
    } catch (e) {
      logger.severe(
        'Failed to get sets for workoutExerciseId $workoutExerciseId: $e',
      );
      rethrow;
    }
  }

  Future<List<WorkoutSet>> getWorkoutSetsByWorkoutExerciseIds(
    List<WorkoutExerciseId> workoutExerciseIds,
  ) async {
    if (workoutExerciseIds.isEmpty) {
      return [];
    }

    final db = await database;
    final placeholders = List.filled(workoutExerciseIds.length, '?').join(', ');
    logger.fine(
      'Getting workout sets for ${workoutExerciseIds.length} workout exercises',
    );

    try {
      final maps = await db.query(
        tableName,
        where: 'workoutExerciseId IN ($placeholders)',
        whereArgs: workoutExerciseIds,
        orderBy: 'workoutExerciseId ASC, setIndex ASC',
      );
      final sets = maps.map((map) => fromMap(map)).toList();
      logger.fine(
        'Found ${sets.length} sets across ${workoutExerciseIds.length} workout exercises',
      );
      return sets;
    } catch (e) {
      logger.severe(
        'Failed to get sets for workoutExerciseIds $workoutExerciseIds: $e',
      );
      rethrow;
    }
  }

  /// Get completed workout sets by workout exercise ID
  Future<List<WorkoutSet>> getCompletedWorkoutSetsByWorkoutExerciseId(
    WorkoutExerciseId workoutExerciseId,
  ) async {
    final db = await database;
    logger.fine(
      'Getting completed workout sets for workoutExerciseId: $workoutExerciseId',
    );
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'workoutExerciseId = ? AND isCompleted = ?',
        whereArgs: [workoutExerciseId, 1],
      );
      final sets = maps.map((map) => fromMap(map)).toList()
        ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
      logger.fine(
        'Found ${sets.length} completed sets for workoutExerciseId: $workoutExerciseId',
      );
      return sets;
    } catch (e) {
      logger.severe(
        'Failed to get completed sets for workoutExerciseId $workoutExerciseId: $e',
      );
      rethrow;
    }
  }

  /// Update workout set
  Future<int> updateWorkoutSet(WorkoutSet workoutSet) async {
    return await update(workoutSet);
  }

  /// Delete workout set
  Future<int> deleteWorkoutSet(WorkoutSetId id) async {
    logger.fine('Deleting workout set with id: $id');
    try {
      final result = await delete(id);
      logger.fine(
        'Successfully deleted workout set with id: $id. Rows affected: $result',
      );
      return result;
    } catch (e) {
      logger.severe('Failed to delete workout set with id: $id. Error: $e');
      rethrow;
    }
  }

  /// Delete workout sets by workout exercise ID
  Future<int> deleteWorkoutSetsByWorkoutExerciseId(
    WorkoutExerciseId workoutExerciseId,
  ) async {
    final db = await database;
    logger.fine(
      'Deleting workout sets for workoutExerciseId: $workoutExerciseId',
    );
    try {
      final count = await db.delete(
        tableName,
        where: 'workoutExerciseId = ?',
        whereArgs: [workoutExerciseId],
      );
      logger.fine(
        'Deleted $count sets for workoutExerciseId: $workoutExerciseId',
      );
      return count;
    } catch (e) {
      logger.severe(
        'Failed to delete sets for workoutExerciseId $workoutExerciseId: $e',
      );
      rethrow;
    }
  }
}
