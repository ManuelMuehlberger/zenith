import '../../models/typedefs.dart';
import '../../models/workout_achievement.dart';
import 'base_dao.dart';

// policy: allow-public-api DAO used by workout achievement persistence flows.
class WorkoutAchievementDao extends BaseDao<WorkoutAchievement> {
  WorkoutAchievementDao() : super('WorkoutAchievementDao');

  @override
  String get tableName => 'WorkoutAchievement';

  @override
  WorkoutAchievement fromMap(Map<String, dynamic> map) {
    return WorkoutAchievement.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(WorkoutAchievement achievement) {
    return achievement.toMap();
  }

  Future<List<WorkoutAchievement>> getAchievementsByWorkoutId(
    WorkoutId workoutId,
  ) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'workoutId = ?',
      whereArgs: [workoutId],
      orderBy: 'earnedAt ASC, title ASC',
    );
    return maps.map(fromMap).toList(growable: false);
  }

  Future<Map<WorkoutId, List<WorkoutAchievement>>> getAchievementsByWorkoutIds(
    List<WorkoutId> workoutIds,
  ) async {
    if (workoutIds.isEmpty) {
      return const {};
    }

    final db = await database;
    final placeholders = List.filled(workoutIds.length, '?').join(', ');
    final maps = await db.query(
      tableName,
      where: 'workoutId IN ($placeholders)',
      whereArgs: workoutIds,
      orderBy: 'earnedAt ASC, title ASC',
    );

    final grouped = <WorkoutId, List<WorkoutAchievement>>{};
    for (final map in maps) {
      final achievement = fromMap(map);
      grouped.putIfAbsent(achievement.workoutId, () => []).add(achievement);
    }
    return grouped;
  }

  Future<int> deleteAchievementsByWorkoutId(WorkoutId workoutId) async {
    final db = await database;
    return db.delete(tableName, where: 'workoutId = ?', whereArgs: [workoutId]);
  }

  Future<void> replaceAchievementsForWorkout(
    WorkoutId workoutId,
    List<WorkoutAchievement> achievements,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        tableName,
        where: 'workoutId = ?',
        whereArgs: [workoutId],
      );
      for (final achievement in achievements) {
        await txn.insert(tableName, toMap(achievement));
      }
    });
  }
}
