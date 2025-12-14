import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/services/dao/workout_exercise_dao.dart';

void main() {
  group('WorkoutExerciseDao', () {
    late WorkoutExerciseDao dao;

    setUp(() {
      dao = WorkoutExerciseDao();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'WorkoutExercise');
    });

    test('should convert workout exercise to map', () {
      final workoutExercise = WorkoutExercise(
        id: 'exercise123',
        workoutId: 'workout123',
        exerciseSlug: 'bench-press',
        notes: 'Use spotter',
        orderIndex: 1,
        sets: [],
      );

      final map = dao.toMap(workoutExercise);

      expect(map['id'], 'exercise123');
      expect(map['workoutId'], 'workout123');
      expect(map['exerciseSlug'], 'bench-press');
      expect(map['notes'], 'Use spotter');
      expect(map['orderIndex'], 1);
    });

    test('should convert map to workout exercise', () {
      final map = {
        'id': 'exercise456',
        'workoutId': 'workout456',
        'exerciseSlug': 'squat',
        'notes': 'Keep back straight',
        'orderIndex': 2,
      };

      final workoutExercise = dao.fromMap(map);

      expect(workoutExercise.id, 'exercise456');
      expect(workoutExercise.workoutId, 'workout456');
      expect(workoutExercise.exerciseSlug, 'squat');
      expect(workoutExercise.notes, 'Keep back straight');
      expect(workoutExercise.orderIndex, 2);
      expect(workoutExercise.sets, isEmpty);
    });

    test('should handle null values', () {
      final map = {
        'id': 'exercise789',
        'workoutId': 'workout789',
        'exerciseSlug': 'deadlift',
        'notes': null,
        'orderIndex': null,
      };

      final workoutExercise = dao.fromMap(map);

      expect(workoutExercise.id, 'exercise789');
      expect(workoutExercise.workoutId, 'workout789');
      expect(workoutExercise.exerciseSlug, 'deadlift');
      expect(workoutExercise.notes, isNull);
      expect(workoutExercise.orderIndex, isNull);
    });
  });
}
