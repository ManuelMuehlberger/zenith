import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/models/typedefs.dart';

void main() {
  group('WorkoutExercise', () {
    late WorkoutExercise workoutExercise;

    setUp(() {
      workoutExercise = WorkoutExercise(
        workoutId: 'workout1',
        exerciseSlug: 'bench-press',
        notes: 'Test notes',
        orderIndex: 1,
      );
    });

    test('should create a workout exercise with default values', () {
      expect(workoutExercise.id, isNotNull);
      expect(workoutExercise.workoutId, 'workout1');
      expect(workoutExercise.exerciseSlug, 'bench-press');
      expect(workoutExercise.notes, 'Test notes');
      expect(workoutExercise.orderIndex, 1);
      expect(workoutExercise.sets, isEmpty);
      expect(workoutExercise.exerciseDetail, isNull);
    });

    test('should create a workout exercise from map', () {
      final map = {
        'id': 'exercise1',
        'workoutId': 'workout1',
        'exerciseSlug': 'squat',
        'notes': 'Leg day',
        'orderIndex': 2,
      };

      final exerciseFromMap = WorkoutExercise.fromMap(map);

      expect(exerciseFromMap.id, 'exercise1');
      expect(exerciseFromMap.workoutId, 'workout1');
      expect(exerciseFromMap.exerciseSlug, 'squat');
      expect(exerciseFromMap.notes, 'Leg day');
      expect(exerciseFromMap.orderIndex, 2);
      expect(exerciseFromMap.sets, isEmpty);
      expect(exerciseFromMap.exerciseDetail, isNull);
    });

    test('should convert workout exercise to map', () {
      final map = workoutExercise.toMap();

      expect(map['id'], workoutExercise.id);
      expect(map['workoutId'], 'workout1');
      expect(map['exerciseSlug'], 'bench-press');
      expect(map['notes'], 'Test notes');
      expect(map['orderIndex'], 1);
    });

    test('should copy with new values', () {
      final copiedExercise = workoutExercise.copyWith(
        notes: 'Updated notes',
        orderIndex: 3,
      );

      expect(copiedExercise.id, workoutExercise.id);
      expect(copiedExercise.workoutId, workoutExercise.workoutId);
      expect(copiedExercise.exerciseSlug, workoutExercise.exerciseSlug);
      expect(copiedExercise.notes, 'Updated notes');
      expect(copiedExercise.orderIndex, 3);
      expect(copiedExercise.sets, workoutExercise.sets);
    });

    test('should copy with null values', () {
      final exerciseWithNotes = workoutExercise.copyWith(notes: 'Some notes');
      final copiedExercise = exerciseWithNotes.copyWith(notes: null);

      expect(copiedExercise.notes, isNull);
    });

    test('should calculate total sets', () {
      final exerciseWithSets = workoutExercise.copyWith(
        sets: List.generate(3, (index) => WorkoutSet(
          workoutExerciseId: workoutExercise.id,
          setIndex: index,
        )),
      );

      expect(exerciseWithSets.totalSets, 3);
    });

    test('should add a new set', () {
      final exerciseWithNewSet = workoutExercise.addSet(
        targetReps: 10,
        targetWeight: 50.0,
        targetRestSeconds: 60,
      );

      expect(exerciseWithNewSet.sets.length, 1);
      expect(exerciseWithNewSet.sets.first.targetReps, 10);
      expect(exerciseWithNewSet.sets.first.targetWeight, 50.0);
      expect(exerciseWithNewSet.sets.first.targetRestSeconds, 60);
      expect(exerciseWithNewSet.sets.first.setIndex, 0);
      expect(exerciseWithNewSet.sets.first.workoutExerciseId, workoutExercise.id);
    });

    test('should remove a set', () {
      final exerciseWithSets = workoutExercise
          .addSet(targetReps: 10)
          .addSet(targetReps: 8)
          .addSet(targetReps: 6);

      expect(exerciseWithSets.sets.length, 3);

      final exerciseWithSetRemoved = exerciseWithSets.removeSet(exerciseWithSets.sets[1].id);

      expect(exerciseWithSetRemoved.sets.length, 2);
      expect(exerciseWithSetRemoved.sets[0].targetReps, 10);
      expect(exerciseWithSetRemoved.sets[1].targetReps, 6);
    });

    test('should update a set', () {
      final exerciseWithSet = workoutExercise.addSet(
        targetReps: 10,
        targetWeight: 50.0,
      );

      final setId = exerciseWithSet.sets.first.id;
      final exerciseWithUpdatedSet = exerciseWithSet.updateSet(
        setId,
        targetReps: 12,
        targetWeight: 55.0,
        targetRestSeconds: 90,
      );

      expect(exerciseWithUpdatedSet.sets.length, 1);
      expect(exerciseWithUpdatedSet.sets.first.id, setId);
      expect(exerciseWithUpdatedSet.sets.first.targetReps, 12);
      expect(exerciseWithUpdatedSet.sets.first.targetWeight, 55.0);
      expect(exerciseWithUpdatedSet.sets.first.targetRestSeconds, 90);
    });
  });
}
