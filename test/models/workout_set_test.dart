import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/models/typedefs.dart';

void main() {
  group('WorkoutSet', () {
    test('WorkoutSet.fromMap creates a valid WorkoutSet object', () {
      final map = {
        'id': 'set1',
        'workoutExerciseId': 'w_ex1',
        'setIndex': 0,
        'targetReps': 10,
        'targetWeight': 50.5,
        'targetRestSeconds': 60,
        'actualReps': 8,
        'actualWeight': 50.5,
        'isCompleted': 1,
      };

      final workoutSet = WorkoutSet.fromMap(map);

      expect(workoutSet.id, 'set1');
      expect(workoutSet.workoutExerciseId, 'w_ex1');
      expect(workoutSet.setIndex, 0);
      expect(workoutSet.targetReps, 10);
      expect(workoutSet.targetWeight, 50.5);
      expect(workoutSet.targetRestSeconds, 60);
      expect(workoutSet.actualReps, 8);
      expect(workoutSet.actualWeight, 50.5);
      expect(workoutSet.isCompleted, isTrue);
    });

    test('WorkoutSet.toMap creates a valid map', () {
      final workoutSet = WorkoutSet(
        id: 'set1',
        workoutExerciseId: 'w_ex1',
        setIndex: 0,
        targetReps: 10,
        targetWeight: 50.5,
        targetRestSeconds: 60,
        actualReps: 8,
        actualWeight: 50.5,
        isCompleted: true,
      );

      final map = workoutSet.toMap();

      expect(map['id'], 'set1');
      expect(map['workoutExerciseId'], 'w_ex1');
      expect(map['setIndex'], 0);
      expect(map['targetReps'], 10);
      expect(map['targetWeight'], 50.5);
      expect(map['targetRestSeconds'], 60);
      expect(map['actualReps'], 8);
      expect(map['actualWeight'], 50.5);
      expect(map['isCompleted'], 1);
    });

    test('copyWith creates a copy with updated values', () {
      final workoutSet = WorkoutSet(
        workoutExerciseId: 'w_ex1',
        setIndex: 0,
        targetReps: 10,
        isCompleted: false,
      );

      final updatedSet = workoutSet.copyWith(
        actualReps: 10,
        actualWeight: 55.0,
        isCompleted: true,
      );

      expect(updatedSet.id, workoutSet.id);
      expect(updatedSet.targetReps, 10);
      expect(updatedSet.actualReps, 10);
      expect(updatedSet.actualWeight, 55.0);
      expect(updatedSet.isCompleted, isTrue);
      expect(workoutSet.isCompleted, isFalse);
    });

    test('copyWith handles nulling out values', () {
      final workoutSet = WorkoutSet(
        workoutExerciseId: 'w_ex1',
        setIndex: 0,
        actualReps: 10,
        actualWeight: 50.0,
      );

      final updatedSet = workoutSet.copyWith(
        actualReps: null,
        actualWeight: null,
      );

      expect(updatedSet.actualReps, isNull);
      expect(updatedSet.actualWeight, isNull);
    });
  });
}
