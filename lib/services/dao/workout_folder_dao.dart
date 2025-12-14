import '../../models/workout_folder.dart';
import '../../models/typedefs.dart';
import 'base_dao.dart';

class WorkoutFolderDao extends BaseDao<WorkoutFolder> {
  WorkoutFolderDao() : super('WorkoutFolderDao');

  @override
  String get tableName => 'WorkoutFolder';

  @override
  WorkoutFolder fromMap(Map<String, dynamic> map) {
    return WorkoutFolder(
      id: map['id'] as WorkoutFolderId,
      name: map['name'] as String,
      orderIndex: map['orderIndex'] as int?,
    );
  }

  @override
  Map<String, dynamic> toMap(WorkoutFolder workoutFolder) {
    return {
      'id': workoutFolder.id,
      'name': workoutFolder.name,
      'orderIndex': workoutFolder.orderIndex,
    };
  }

  /// Get workout folder by ID
  Future<WorkoutFolder?> getWorkoutFolderById(WorkoutFolderId id) async {
    return await getById(id);
  }

  /// Get all workout folders ordered by orderIndex
  Future<List<WorkoutFolder>> getAllWorkoutFoldersOrdered() async {
    final db = await database;
    logger.fine('Getting all workout folders ordered by orderIndex');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        orderBy: 'orderIndex ASC',
      );
      final folders = maps.map((map) => fromMap(map)).toList();
      logger.fine('Found ${folders.length} workout folders');
      return folders;
    } catch (e) {
      logger.severe('Failed to get all workout folders: $e');
      rethrow;
    }
  }

  /// Update workout folder
  Future<int> updateWorkoutFolder(WorkoutFolder workoutFolder) async {
    return await update(workoutFolder);
  }

  /// Delete workout folder
  Future<int> deleteWorkoutFolder(WorkoutFolderId id) async {
    return await delete(id);
  }
}
