import '../../models/workout_set.dart';
import '../../models/typedefs.dart';
import 'base_dao.dart';

class WorkoutSetDao extends BaseDao<WorkoutSet> {
  @override
  String get tableName => 'WorkoutSet';

  @override
  WorkoutSet fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] as WorkoutSetId,
      workoutExerciseId: map['workoutExerciseId'] as WorkoutExerciseId,
      setIndex: map['setIndex'] as int,
      targetReps: map['targetReps'] as int?,
      targetWeight: (map['targetWeight'] as num?)?.toDouble(),
      targetRestSeconds: map['targetRestSeconds'] as int?,
      actualReps: map['actualReps'] as int?,
      actualWeight: (map['actualWeight'] as num?)?.toDouble(),
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
    );
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
  Future<List<WorkoutSet>> getWorkoutSetsByWorkoutExerciseId(WorkoutExerciseId workoutExerciseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'workoutExerciseId = ?',
      whereArgs: [workoutExerciseId],
    );
    
    return maps.map((map) => fromMap(map)).toList()
      ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
  }

  /// Get completed workout sets by workout exercise ID
  Future<List<WorkoutSet>> getCompletedWorkoutSetsByWorkoutExerciseId(WorkoutExerciseId workoutExerciseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'workoutExerciseId = ? AND isCompleted = ?',
      whereArgs: [workoutExerciseId, 1],
    );
    
    return maps.map((map) => fromMap(map)).toList()
      ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
  }

  /// Update workout set
  Future<int> updateWorkoutSet(WorkoutSet workoutSet) async {
    return await update(workoutSet);
  }

  /// Delete workout set
  Future<int> deleteWorkoutSet(WorkoutSetId id) async {
    return await delete(id);
  }

  /// Delete workout sets by workout exercise ID
  Future<int> deleteWorkoutSetsByWorkoutExerciseId(WorkoutExerciseId workoutExerciseId) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'workoutExerciseId = ?',
      whereArgs: [workoutExerciseId],
    );
  }
}
