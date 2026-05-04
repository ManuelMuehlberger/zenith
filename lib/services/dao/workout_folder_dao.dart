import '../../models/typedefs.dart';
import '../../models/workout_folder.dart';
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
      parentFolderId: map['parentFolderId'] as WorkoutFolderId?,
      depth: (map['depth'] as int?) ?? 0,
      orderIndex: map['orderIndex'] as int?,
    );
  }

  @override
  Map<String, dynamic> toMap(WorkoutFolder workoutFolder) {
    return {
      'id': workoutFolder.id,
      'name': workoutFolder.name,
      'parentFolderId': workoutFolder.parentFolderId,
      'depth': workoutFolder.depth,
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
        orderBy:
            'depth ASC, parentFolderId ASC, orderIndex ASC, name COLLATE NOCASE ASC',
      );
      final folders = maps.map((map) => fromMap(map)).toList();
      logger.fine('Found ${folders.length} workout folders');
      return folders;
    } catch (e) {
      logger.severe('Failed to get all workout folders: $e');
      rethrow;
    }
  }

  /// Get workout folders within a specific parent ordered by orderIndex.
  Future<List<WorkoutFolder>> getWorkoutFoldersByParentId(
    WorkoutFolderId? parentFolderId,
  ) async {
    final db = await database;
    logger.fine('Getting workout folders for parent: $parentFolderId');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: parentFolderId == null
            ? 'parentFolderId IS NULL'
            : 'parentFolderId = ?',
        whereArgs: parentFolderId == null ? null : [parentFolderId],
        orderBy: 'orderIndex ASC, name COLLATE NOCASE ASC',
      );
      final folders = maps.map((map) => fromMap(map)).toList();
      logger.fine(
        'Found ${folders.length} workout folders for parent $parentFolderId',
      );
      return folders;
    } catch (e) {
      logger.severe(
        'Failed to get workout folders for parent $parentFolderId: $e',
      );
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
