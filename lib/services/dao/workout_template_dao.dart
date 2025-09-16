import '../../models/workout_template.dart';
import '../../models/typedefs.dart';
import 'base_dao.dart';

class WorkoutTemplateDao extends BaseDao<WorkoutTemplate> {
  WorkoutTemplateDao() : super('WorkoutTemplateDao');

  @override
  String get tableName => 'WorkoutTemplate';

  @override
  WorkoutTemplate fromMap(Map<String, dynamic> map) {
    return WorkoutTemplate(
      id: map['id'] as WorkoutTemplateId,
      name: map['name'] as String,
      description: map['description'] as String?,
      iconCodePoint: map['iconCodePoint'] as int?,
      colorValue: map['colorValue'] as int?,
      folderId: map['folderId'] as WorkoutFolderId?,
      notes: map['notes'] as String?,
      lastUsed: map['lastUsed'] as String?,
      orderIndex: map['orderIndex'] as int?,
    );
  }

  @override
  Map<String, dynamic> toMap(WorkoutTemplate workoutTemplate) {
    return {
      'id': workoutTemplate.id,
      'name': workoutTemplate.name,
      'description': workoutTemplate.description,
      'iconCodePoint': workoutTemplate.iconCodePoint,
      'colorValue': workoutTemplate.colorValue,
      'folderId': workoutTemplate.folderId,
      'notes': workoutTemplate.notes,
      'lastUsed': workoutTemplate.lastUsed,
      'orderIndex': workoutTemplate.orderIndex,
    };
  }

  /// Get workout template by ID
  Future<WorkoutTemplate?> getWorkoutTemplateById(WorkoutTemplateId id) async {
    return await getById(id);
  }

  /// Get all workout templates in a specific folder ordered by orderIndex
  Future<List<WorkoutTemplate>> getWorkoutTemplatesByFolderId(WorkoutFolderId folderId) async {
    final db = await database;
    logger.fine('Getting workout templates for folder: $folderId');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'folderId = ?',
        whereArgs: [folderId],
        orderBy: 'orderIndex ASC',
      );
      final templates = maps.map((map) => fromMap(map)).toList();
      logger.fine('Found ${templates.length} workout templates in folder $folderId');
      return templates;
    } catch (e) {
      logger.severe('Failed to get workout templates for folder $folderId: $e');
      rethrow;
    }
  }

  /// Get all workout templates without a folder (orphaned templates)
  Future<List<WorkoutTemplate>> getWorkoutTemplatesWithoutFolder() async {
    final db = await database;
    logger.fine('Getting workout templates without folder');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'folderId IS NULL',
        orderBy: 'orderIndex ASC',
      );
      final templates = maps.map((map) => fromMap(map)).toList();
      logger.fine('Found ${templates.length} workout templates without folder');
      return templates;
    } catch (e) {
      logger.severe('Failed to get workout templates without folder: $e');
      rethrow;
    }
  }

  /// Get all workout templates ordered by folder and orderIndex
  Future<List<WorkoutTemplate>> getAllWorkoutTemplatesOrdered() async {
    final db = await database;
    logger.fine('Getting all workout templates ordered');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        orderBy: 'folderId ASC, orderIndex ASC',
      );
      final templates = maps.map((map) => fromMap(map)).toList();
      logger.fine('Found ${templates.length} workout templates');
      return templates;
    } catch (e) {
      logger.severe('Failed to get all workout templates: $e');
      rethrow;
    }
  }

  /// Update workout template
  Future<int> updateWorkoutTemplate(WorkoutTemplate workoutTemplate) async {
    return await update(workoutTemplate);
  }

  /// Delete workout template
  Future<int> deleteWorkoutTemplate(WorkoutTemplateId id) async {
    return await delete(id);
  }

  /// Update the lastUsed timestamp for a workout template
  Future<int> updateLastUsed(WorkoutTemplateId id, String timestamp) async {
    final db = await database;
    logger.fine('Updating lastUsed for workout template: $id');
    try {
      final count = await db.update(
        tableName,
        {'lastUsed': timestamp},
        where: 'id = ?',
        whereArgs: [id],
      );
      logger.fine('Updated lastUsed for workout template $id');
      return count;
    } catch (e) {
      logger.severe('Failed to update lastUsed for workout template $id: $e');
      rethrow;
    }
  }

  /// Get workout templates ordered by last used (most recent first)
  Future<List<WorkoutTemplate>> getWorkoutTemplatesByLastUsed({int? limit}) async {
    final db = await database;
    logger.fine('Getting workout templates ordered by lastUsed');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'lastUsed IS NOT NULL',
        orderBy: 'lastUsed DESC',
        limit: limit,
      );
      final templates = maps.map((map) => fromMap(map)).toList();
      logger.fine('Found ${templates.length} recently used workout templates');
      return templates;
    } catch (e) {
      logger.severe('Failed to get workout templates by lastUsed: $e');
      rethrow;
    }
  }
}
