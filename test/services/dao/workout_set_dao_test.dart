import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/dao/workout_set_dao.dart';

void main() {
  group('WorkoutSetDao', () {
    late WorkoutSetDao dao;

    setUp(() {
      dao = WorkoutSetDao();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'WorkoutSet');
    });

    test('should convert workout set to map', () {
      final workoutSet = WorkoutSet(
        id: 'set123',
        workoutExerciseId: 'exercise123',
        setIndex: 1,
        targetReps: 10,
        targetWeight: 50.0,
        targetRestSeconds: 60,
        actualReps: 8,
        actualWeight: 50.0,
        isCompleted: true,
      );

      final map = dao.toMap(workoutSet);

      expect(map['id'], 'set123');
      expect(map['workoutExerciseId'], 'exercise123');
      expect(map['setIndex'], 1);
      expect(map['targetReps'], 10);
      expect(map['targetWeight'], 50.0);
      expect(map['targetRestSeconds'], 60);
      expect(map['actualReps'], 8);
      expect(map['actualWeight'], 50.0);
      expect(map['isCompleted'], 1);
    });

    test('should convert map to workout set', () {
      final map = {
        'id': 'set456',
        'workoutExerciseId': 'exercise456',
        'setIndex': 2,
        'targetReps': 12,
        'targetWeight': 40.0,
        'targetRestSeconds': 90,
        'actualReps': 12,
        'actualWeight': 40.0,
        'isCompleted': 1,
      };

      final workoutSet = dao.fromMap(map);

      expect(workoutSet.id, 'set456');
      expect(workoutSet.workoutExerciseId, 'exercise456');
      expect(workoutSet.setIndex, 2);
      expect(workoutSet.targetReps, 12);
      expect(workoutSet.targetWeight, 40.0);
      expect(workoutSet.targetRestSeconds, 90);
      expect(workoutSet.actualReps, 12);
      expect(workoutSet.actualWeight, 40.0);
      expect(workoutSet.isCompleted, true);
    });

    test('should handle null values', () {
      final map = {
        'id': 'set789',
        'workoutExerciseId': 'exercise789',
        'setIndex': 3,
        'targetReps': null,
        'targetWeight': null,
        'targetRestSeconds': null,
        'actualReps': null,
        'actualWeight': null,
        'isCompleted': 0,
      };

      final workoutSet = dao.fromMap(map);

      expect(workoutSet.id, 'set789');
      expect(workoutSet.workoutExerciseId, 'exercise789');
      expect(workoutSet.setIndex, 3);
      expect(workoutSet.targetReps, isNull);
      expect(workoutSet.targetWeight, isNull);
      expect(workoutSet.targetRestSeconds, isNull);
      expect(workoutSet.actualReps, isNull);
      expect(workoutSet.actualWeight, isNull);
      expect(workoutSet.isCompleted, false);
    });

    test('should handle incomplete set', () {
      final map = {
        'id': 'set999',
        'workoutExerciseId': 'exercise999',
        'setIndex': 1,
        'isCompleted': 0,
      };

      final workoutSet = dao.fromMap(map);
      expect(workoutSet.isCompleted, false);
    });
  });
}
