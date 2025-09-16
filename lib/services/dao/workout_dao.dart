import '../../models/workout.dart';
import '../../models/typedefs.dart';
import 'base_dao.dart';

class WorkoutDao extends BaseDao<Workout> {
  WorkoutDao() : super('WorkoutDao');

  @override
  String get tableName => 'Workout';

  @override
  Workout fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as WorkoutId,
      name: map['name'] as String,
      description: map['description'] as String?,
      iconCodePoint: map['iconCodePoint'] as int?,
      colorValue: map['colorValue'] as int?,
      folderId: map['folderId'] as WorkoutFolderId?,
      notes: map['notes'] as String?,
      lastUsed: map['lastUsed'] as String?,
      orderIndex: map['orderIndex'] as int?,
      status: WorkoutStatus.values[map['status'] as int],
      templateId: map['templateId'] as WorkoutId?,
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt'] as String) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
      exercises: [], // To be loaded separately
    );
  }

  @override
  Map<String, dynamic> toMap(Workout workout) {
    return {
      'id': workout.id,
      'name': workout.name,
      'description': workout.description,
      'iconCodePoint': workout.iconCodePoint,
      'colorValue': workout.colorValue,
      'folderId': workout.folderId,
      'notes': workout.notes,
      'lastUsed': workout.lastUsed,
      'orderIndex': workout.orderIndex,
      'status': workout.status.index,
      'templateId': workout.templateId,
      'startedAt': workout.startedAt?.toIso8601String(),
      'completedAt': workout.completedAt?.toIso8601String(),
    };
  }

  /// Get workout by ID
  Future<Workout?> getWorkoutById(WorkoutId id) async {
    return await getById(id);
  }

  /// Get all workouts
  Future<List<Workout>> getAllWorkouts() async {
    return await getAll();
  }

  /// Get workouts by folder ID
  Future<List<Workout>> getWorkoutsByFolderId(WorkoutFolderId folderId) async {
    final db = await database;
    logger.fine('Getting workouts for folderId: $folderId');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'folderId = ?',
        whereArgs: [folderId],
      );
      final workouts = maps.map((map) => fromMap(map)).toList()
        ..sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));
      logger.fine('Found ${workouts.length} workouts for folderId: $folderId');
      return workouts;
    } catch (e) {
      logger.severe('Failed to get workouts for folderId $folderId: $e');
      rethrow;
    }
  }

  /// Get workouts by status
  Future<List<Workout>> getWorkoutsByStatus(WorkoutStatus status) async {
    final db = await database;
    logger.fine('Getting workouts with status: ${status.name}');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'status = ?',
        whereArgs: [status.index],
      );
      final workouts = maps.map((map) => fromMap(map)).toList();
      logger.fine(
          'Found ${workouts.length} workouts with status: ${status.name}');
      return workouts;
    } catch (e) {
      logger.severe('Failed to get workouts with status ${status.name}: $e');
      rethrow;
    }
  }

  /// Get template workouts (status = template)
  Future<List<Workout>> getTemplateWorkouts() async {
    return await getWorkoutsByStatus(WorkoutStatus.template);
  }

  /// Get in-progress workouts (status = inProgress)
  Future<List<Workout>> getInProgressWorkouts() async {
    return await getWorkoutsByStatus(WorkoutStatus.inProgress);
  }

  /// Get completed workouts (status = completed)
  Future<List<Workout>> getCompletedWorkouts() async {
    return await getWorkoutsByStatus(WorkoutStatus.completed);
  }

  /// Get workouts by template ID
  Future<List<Workout>> getWorkoutsByTemplateId(WorkoutId templateId) async {
    final db = await database;
    logger.fine('Getting workouts for templateId: $templateId');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'templateId = ?',
        whereArgs: [templateId],
      );
      final workouts = maps.map((map) => fromMap(map)).toList();
      logger.fine('Found ${workouts.length} workouts for templateId: $templateId');
      return workouts;
    } catch (e) {
      logger.severe('Failed to get workouts for templateId $templateId: $e');
      rethrow;
    }
  }

  /// Get workouts within a date range
  Future<List<Workout>> getWorkoutsInDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await database;
    logger.fine(
        'Getting completed workouts between ${startDate.toIso8601String()} and ${endDate.toIso8601String()}');
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT * FROM $tableName 
        WHERE startedAt >= ? AND startedAt <= ? AND status = ?
        ORDER BY startedAt DESC
      ''', [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
        WorkoutStatus.completed.index
      ]);
      final workouts = maps.map((map) => fromMap(map)).toList();
      logger.fine('Found ${workouts.length} workouts in the date range.');
      return workouts;
    } catch (e) {
      logger.severe('Failed to get workouts in date range: $e');
      rethrow;
    }
  }

  /// Update workout
  Future<int> updateWorkout(Workout workout) async {
    return await update(workout);
  }

  /// Delete workout
  Future<int> deleteWorkout(WorkoutId id) async {
    return await delete(id);
  }
}
