import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/services/dao/muscle_group_dao.dart';

void main() {
  group('MuscleGroupDao', () {
    late MuscleGroupDao dao;

    setUp(() {
      dao = MuscleGroupDao();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'MuscleGroup');
    });

    test('should convert muscle group to map', () {
      final muscleGroup = MuscleGroup.chest;
      final map = dao.toMap(muscleGroup);
      expect(map['name'], 'Chest');
    });

    test('should convert map to muscle group', () {
      final map = {'name': 'Quads'};
      final muscleGroup = dao.fromMap(map);
      expect(muscleGroup.name, 'Quads');
    });
  });
}
