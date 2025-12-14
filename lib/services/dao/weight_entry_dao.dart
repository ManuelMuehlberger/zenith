import 'package:sqflite/sqflite.dart';
import '../../models/user_data.dart';
import '../../models/typedefs.dart';
import 'base_dao.dart';

class WeightEntryDao extends BaseDao<WeightEntry> {
  WeightEntryDao() : super('WeightEntryDao');

  @override
  String get tableName => 'WeightEntry';

  @override
  WeightEntry fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      value: map['value'] as double,
    );
  }

  @override
  Map<String, dynamic> toMap(WeightEntry weightEntry) {
    return {
      'id': weightEntry.id,
      'timestamp': weightEntry.timestamp.toIso8601String(),
      'value': weightEntry.value,
    };
  }

  /// Get weight entries by user data ID
  Future<List<WeightEntry>> getWeightEntriesByUserId(
      UserDataId userDataId) async {
    final db = await database;
    logger.fine('Getting weight entries for user: $userDataId');
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'userDataId = ?',
        whereArgs: [userDataId],
      );
      final entries = maps.map((map) => fromMap(map)).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      logger.fine('Found ${entries.length} weight entries for user: $userDataId');
      return entries;
    } catch (e) {
      logger.severe('Failed to get weight entries for user $userDataId: $e');
      rethrow;
    }
  }

  /// Add a weight entry for a user
  Future<int> addWeightEntryForUser(
      UserDataId userDataId, WeightEntry weightEntry) async {
    final db = await database;
    final map = toMap(weightEntry);
    map['userDataId'] = userDataId; // Set the user ID
    logger.fine('Adding weight entry for user: $userDataId');
    try {
      final id = await db.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      logger.fine('Added weight entry with id: $id for user: $userDataId');
      return id;
    } catch (e) {
      logger.severe('Failed to add weight entry for user $userDataId: $e');
      rethrow;
    }
  }

  /// Update a weight entry
  Future<int> updateWeightEntry(
      UserDataId userDataId, WeightEntry weightEntry) async {
    final db = await database;
    final map = toMap(weightEntry);
    map['userDataId'] = userDataId; // Ensure the user ID is set

    final id = map['id'];
    map.remove('id');
    logger.fine('Updating weight entry with id: $id for user: $userDataId');
    try {
      final count = await db.update(
        tableName,
        map,
        where: 'id = ?',
        whereArgs: [id],
      );
      logger.fine('Updated $count weight entry/ies for user: $userDataId');
      return count;
    } catch (e) {
      logger.severe('Failed to update weight entry for user $userDataId: $e');
      rethrow;
    }
  }

  /// Delete a weight entry
  Future<int> deleteWeightEntry(String id) async {
    return await delete(id);
  }
}
