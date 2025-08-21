import 'package:sqflite/sqflite.dart';
import '../../models/user_data.dart';
import '../../models/typedefs.dart';
import 'base_dao.dart';

class WeightEntryDao extends BaseDao<WeightEntry> {
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
  Future<List<WeightEntry>> getWeightEntriesByUserId(UserDataId userDataId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'userDataId = ?',
      whereArgs: [userDataId],
    );
    
    return maps.map((map) => fromMap(map)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Add a weight entry for a user
  Future<int> addWeightEntryForUser(UserDataId userDataId, WeightEntry weightEntry) async {
    final db = await database;
    final map = toMap(weightEntry);
    map['userDataId'] = userDataId; // Set the user ID
    
    return await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Update a weight entry
  Future<int> updateWeightEntry(UserDataId userDataId, WeightEntry weightEntry) async {
    final db = await database;
    final map = toMap(weightEntry);
    map['userDataId'] = userDataId; // Ensure the user ID is set
    
    // Remove the ID from the map to avoid updating it
    final id = map['id'];
    map.remove('id');
    
    return await db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a weight entry
  Future<int> deleteWeightEntry(String id) async {
    return await delete(id);
  }
}
