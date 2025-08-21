import '../../models/workout_exercise.dart';
import '../../models/typedefs.dart';
import 'base_dao.dart';

class WorkoutExerciseDao extends BaseDao<WorkoutExercise> {
  @override
  String get tableName => 'WorkoutExercise';

  @override
  WorkoutExercise fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      id: map['id'] as WorkoutExerciseId,
      workoutId: map['workoutId'] as WorkoutId,
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
  Future<List<WorkoutExercise>> getWorkoutExercisesByWorkoutId(WorkoutId workoutId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'workoutId = ?',
      whereArgs: [workoutId],
    );
    
    return maps.map((map) => fromMap(map)).toList()
      ..sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));
  }

  /// Get workout exercises by exercise slug
  Future<List<WorkoutExercise>> getWorkoutExercisesByExerciseSlug(ExerciseSlug exerciseSlug) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'exerciseSlug = ?',
      whereArgs: [exerciseSlug],
    );
    
    return maps.map((map) => fromMap(map)).toList();
  }

  /// Update workout exercise
  Future<int> updateWorkoutExercise(WorkoutExercise workoutExercise) async {
    return await update(workoutExercise);
  }

  /// Delete workout exercise
  Future<int> deleteWorkoutExercise(WorkoutExerciseId id) async {
    return await delete(id);
  }

  /// Delete workout exercises by workout ID
  Future<int> deleteWorkoutExercisesByWorkoutId(WorkoutId workoutId) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'workoutId = ?',
      whereArgs: [workoutId],
    );
  }
}
