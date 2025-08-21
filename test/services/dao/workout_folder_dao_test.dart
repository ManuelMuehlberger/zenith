import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_folder.dart';
import 'package:zenith/services/dao/workout_folder_dao.dart';

void main() {
  group('WorkoutFolderDao', () {
    late WorkoutFolderDao dao;

    setUp(() {
      dao = WorkoutFolderDao();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'WorkoutFolder');
    });

    test('should convert workout folder to map', () {
      final workoutFolder = WorkoutFolder(
        id: 'folder123',
        name: 'Chest Workouts',
        orderIndex: 1,
      );

      final map = dao.toMap(workoutFolder);

      expect(map['id'], 'folder123');
      expect(map['name'], 'Chest Workouts');
      expect(map['orderIndex'], 1);
    });

    test('should convert map to workout folder', () {
      final map = {
        'id': 'folder456',
        'name': 'Leg Workouts',
        'orderIndex': 2,
      };

      final workoutFolder = dao.fromMap(map);

      expect(workoutFolder.id, 'folder456');
      expect(workoutFolder.name, 'Leg Workouts');
      expect(workoutFolder.orderIndex, 2);
    });

    test('should handle null order index', () {
      final map = {
        'id': 'folder789',
        'name': 'Arm Workouts',
        'orderIndex': null,
      };

      final workoutFolder = dao.fromMap(map);

      expect(workoutFolder.id, 'folder789');
      expect(workoutFolder.name, 'Arm Workouts');
      expect(workoutFolder.orderIndex, isNull);
    });
  });
}
