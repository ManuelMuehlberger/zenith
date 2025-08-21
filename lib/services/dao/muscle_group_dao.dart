import '../../models/muscle_group.dart';
import 'base_dao.dart';

class MuscleGroupDao extends BaseDao<MuscleGroup> {
  @override
  String get tableName => 'MuscleGroup';

  @override
  MuscleGroup fromMap(Map<String, dynamic> map) {
    return MuscleGroup.fromName(map['name'] as String);
  }

  @override
  Map<String, dynamic> toMap(MuscleGroup muscleGroup) {
    return {
      'name': muscleGroup.name,
    };
  }

  /// Get all muscle groups
  Future<List<MuscleGroup>> getAllMuscleGroups() async {
    return await getAll();
  }

  /// Get muscle group by name
  Future<MuscleGroup?> getMuscleGroupByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'name = ?',
      whereArgs: [name],
    );
    
    if (maps.isNotEmpty) {
      return fromMap(maps.first);
    }
    return null;
  }
}
