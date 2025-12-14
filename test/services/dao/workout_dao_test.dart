import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/services/dao/workout_dao.dart';

void main() {
  group('WorkoutDao', () {
    late WorkoutDao dao;

    setUp(() {
      dao = WorkoutDao();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'Workout');
    });

    test('should convert workout to map', () {
      final now = DateTime.now();
      final workout = Workout(
        id: 'workout123',
        name: 'Chest Day',
        description: 'Focus on chest exercises',
        iconCodePoint: 0xe1a3,
        colorValue: 0xFF2196F3,
        folderId: 'folder123',
        notes: 'Warm up properly',
        lastUsed: now.toIso8601String(),
        orderIndex: 1,
        status: WorkoutStatus.template,
        templateId: null,
        startedAt: null,
        completedAt: null,
        exercises: [],
      );

      final map = dao.toMap(workout);

      expect(map['id'], 'workout123');
      expect(map['name'], 'Chest Day');
      expect(map['description'], 'Focus on chest exercises');
      expect(map['iconCodePoint'], 0xe1a3);
      expect(map['colorValue'], 0xFF2196F3);
      expect(map['folderId'], 'folder123');
      expect(map['notes'], 'Warm up properly');
      expect(map['lastUsed'], now.toIso8601String());
      expect(map['orderIndex'], 1);
      expect(map['status'], 0); // template
      expect(map['templateId'], isNull);
      expect(map['startedAt'], isNull);
      expect(map['completedAt'], isNull);
    });

    test('should convert map to workout', () {
      final now = DateTime.now();
      final map = {
        'id': 'workout456',
        'name': 'Leg Day',
        'description': 'Focus on leg exercises',
        'iconCodePoint': 0xe531,
        'colorValue': 0xFF4CAF50,
        'folderId': 'folder456',
        'notes': 'Stretch well',
        'lastUsed': now.toIso8601String(),
        'orderIndex': 2,
        'status': 1, // inProgress
        'templateId': 'template123',
        'startedAt': now.toIso8601String(),
        'completedAt': null,
      };

      final workout = dao.fromMap(map);

      expect(workout.id, 'workout456');
      expect(workout.name, 'Leg Day');
      expect(workout.description, 'Focus on leg exercises');
      expect(workout.iconCodePoint, 0xe531);
      expect(workout.colorValue, 0xFF4CAF50);
      expect(workout.folderId, 'folder456');
      expect(workout.notes, 'Stretch well');
      expect(workout.lastUsed, now.toIso8601String());
      expect(workout.orderIndex, 2);
      expect(workout.status, WorkoutStatus.inProgress);
      expect(workout.templateId, 'template123');
      expect(workout.startedAt, now);
      expect(workout.completedAt, isNull);
      expect(workout.exercises, isEmpty);
    });

    test('should handle completed workout', () {
      final startedAt = DateTime.now().subtract(Duration(hours: 1));
      final completedAt = DateTime.now();
      final map = {
        'id': 'workout789',
        'name': 'Full Body',
        'status': 2, // completed
        'templateId': 'template456',
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
      };

      final workout = dao.fromMap(map);

      expect(workout.id, 'workout789');
      expect(workout.name, 'Full Body');
      expect(workout.status, WorkoutStatus.completed);
      expect(workout.templateId, 'template456');
      expect(workout.startedAt, startedAt);
      expect(workout.completedAt, completedAt);
    });
  });
}
