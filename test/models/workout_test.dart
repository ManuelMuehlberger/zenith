import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';

void main() {
  group('Workout', () {
    late Workout workout;

    setUp(() {
      workout = Workout(
        name: 'Test Workout',
        description: 'A test workout',
        iconCodePoint: 0xe1a3,
        colorValue: 0xFF2196F3,
        notes: 'Test notes',
        exercises: [],
      );
    });

    test('should create a workout with default values', () {
      expect(workout.id, isNotNull);
      expect(workout.name, 'Test Workout');
      expect(workout.description, 'A test workout');
      expect(workout.status, WorkoutStatus.template);
      expect(workout.templateId, isNull);
      expect(workout.startedAt, isNull);
      expect(workout.completedAt, isNull);
    });

    test('should create a workout from map', () {
      final now = DateTime.now();
      final map = {
        'id': 'test-id',
        'name': 'Test Workout',
        'description': 'A test workout',
        'iconCodePoint': 0xe1a3,
        'colorValue': 0xFF2196F3,
        'folderId': 'folder-id',
        'notes': 'Test notes',
        'lastUsed': now.toIso8601String(),
        'orderIndex': 1,
        'status': 1, // inProgress
        'templateId': 'template-id',
        'startedAt': now.toIso8601String(),
        'completedAt': null,
      };

      final workoutFromMap = Workout.fromMap(map);

      expect(workoutFromMap.id, 'test-id');
      expect(workoutFromMap.name, 'Test Workout');
      expect(workoutFromMap.description, 'A test workout');
      expect(workoutFromMap.iconCodePoint, 0xe1a3);
      expect(workoutFromMap.colorValue, 0xFF2196F3);
      expect(workoutFromMap.folderId, 'folder-id');
      expect(workoutFromMap.notes, 'Test notes');
      expect(workoutFromMap.lastUsed, now.toIso8601String());
      expect(workoutFromMap.orderIndex, 1);
      expect(workoutFromMap.status, WorkoutStatus.inProgress);
      expect(workoutFromMap.templateId, 'template-id');
      expect(workoutFromMap.startedAt, now);
      expect(workoutFromMap.completedAt, isNull);
    });

    test('should convert workout to map', () {
      final now = DateTime.now();
      final workoutInProgress = workout.copyWith(
        status: WorkoutStatus.inProgress,
        templateId: 'template-id',
        startedAt: now,
      );

      final map = workoutInProgress.toMap();

      expect(map['id'], workoutInProgress.id);
      expect(map['name'], 'Test Workout');
      expect(map['description'], 'A test workout');
      expect(map['iconCodePoint'], 0xe1a3);
      expect(map['colorValue'], 0xFF2196F3);
      expect(map['folderId'], isNull);
      expect(map['notes'], 'Test notes');
      expect(map['lastUsed'], isNull);
      expect(map['orderIndex'], isNull);
      expect(map['status'], 1); // inProgress
      expect(map['templateId'], 'template-id');
      expect(map['startedAt'], now.toIso8601String());
      expect(map['completedAt'], isNull);
    });

    test('should copy with new values', () {
      final copiedWorkout = workout.copyWith(
        name: 'Copied Workout',
        status: WorkoutStatus.completed,
        completedAt: DateTime.now(),
      );

      expect(copiedWorkout.name, 'Copied Workout');
      expect(copiedWorkout.status, WorkoutStatus.completed);
      expect(copiedWorkout.completedAt, isNotNull);
      // Other values should remain the same
      expect(copiedWorkout.description, workout.description);
      expect(copiedWorkout.iconCodePoint, workout.iconCodePoint);
      expect(copiedWorkout.colorValue, workout.colorValue);
      expect(copiedWorkout.notes, workout.notes);
    });

    test('should calculate total sets', () {
      final exercise1 = WorkoutExercise(
        workoutId: workout.id,
        exerciseSlug: 'exercise1',
        sets: List.generate(3, (index) => WorkoutSet(
          workoutExerciseId: 'exercise1',
          setIndex: index,
        )),
      );
      final exercise2 = WorkoutExercise(
        workoutId: workout.id,
        exerciseSlug: 'exercise2',
        sets: List.generate(2, (index) => WorkoutSet(
          workoutExerciseId: 'exercise2',
          setIndex: index,
        )),
      );

      final workoutWithExercises = workout.copyWith(
        exercises: [exercise1, exercise2],
      );

      expect(workoutWithExercises.totalSets, 5);
    });

    test('should calculate completed sets', () {
      final completedSet = WorkoutSet(
        workoutExerciseId: 'exercise1',
        setIndex: 0,
        isCompleted: true,
      );
      final incompleteSet = WorkoutSet(
        workoutExerciseId: 'exercise1',
        setIndex: 1,
        isCompleted: false,
      );
      final exercise = WorkoutExercise(
        workoutId: workout.id,
        exerciseSlug: 'exercise1',
        sets: [completedSet, incompleteSet],
      );

      final workoutWithExercises = workout.copyWith(
        exercises: [exercise],
      );

      expect(workoutWithExercises.completedSets, 1);
    });

    test('should calculate total weight', () {
      final completedSet1 = WorkoutSet(
        workoutExerciseId: 'exercise1',
        setIndex: 0,
        actualReps: 10,
        actualWeight: 50.0,
        isCompleted: true,
      );
      final completedSet2 = WorkoutSet(
        workoutExerciseId: 'exercise1',
        setIndex: 1,
        actualReps: 8,
        actualWeight: 60.0,
        isCompleted: true,
      );
      final incompleteSet = WorkoutSet(
        workoutExerciseId: 'exercise1',
        setIndex: 2,
        actualReps: 5,
        actualWeight: 70.0,
        isCompleted: false,
      );
      final exercise = WorkoutExercise(
        workoutId: workout.id,
        exerciseSlug: 'exercise1',
        sets: [completedSet1, completedSet2, incompleteSet],
      );

      final workoutWithExercises = workout.copyWith(
        exercises: [exercise],
      );

      // Total weight = (10 * 50.0) + (8 * 60.0) = 500 + 480 = 980
      expect(workoutWithExercises.totalWeight, 980.0);
    });

    test('should handle null values in total weight calculation', () {
      final setWithNullReps = WorkoutSet(
        workoutExerciseId: 'exercise1',
        setIndex: 0,
        actualReps: null,
        actualWeight: 50.0,
        isCompleted: true,
      );
      final setWithNullWeight = WorkoutSet(
        workoutExerciseId: 'exercise1',
        setIndex: 1,
        actualReps: 10,
        actualWeight: null,
        isCompleted: true,
      );
      final exercise = WorkoutExercise(
        workoutId: workout.id,
        exerciseSlug: 'exercise1',
        sets: [setWithNullReps, setWithNullWeight],
      );

      final workoutWithExercises = workout.copyWith(
        exercises: [exercise],
      );

      expect(workoutWithExercises.totalWeight, 0.0);
    });

    test('should get icon data', () {
      expect(workout.icon, Icons.fitness_center);
      expect(workout.icon.fontFamily, 'MaterialIcons');

      final workoutWithoutIcon = Workout(name: 'Test');
      expect(workoutWithoutIcon.icon, Icons.fitness_center); // Default
    });

    test('should get color', () {
      expect(workout.color.value, 0xFF2196F3);

      final workoutWithoutColor = Workout(name: 'Test');
      expect(workoutWithoutColor.color.value, 0xFF2196F3); // Default
    });

    test('should handle different icon code points', () {
      final runWorkout = workout.copyWith(iconCodePoint: 0xe02f);
      expect(runWorkout.icon, Icons.directions_run);

      final poolWorkout = workout.copyWith(iconCodePoint: 0xe047);
      expect(poolWorkout.icon, Icons.pool);

      final sportsWorkout = workout.copyWith(iconCodePoint: 0xe52f);
      expect(sportsWorkout.icon, Icons.sports);

      final gymnasticsWorkout = workout.copyWith(iconCodePoint: 0xe531);
      expect(gymnasticsWorkout.icon, Icons.sports_gymnastics);

      final handballWorkout = workout.copyWith(iconCodePoint: 0xe532);
      expect(handballWorkout.icon, Icons.sports_handball);

      final martialArtsWorkout = workout.copyWith(iconCodePoint: 0xe533);
      expect(martialArtsWorkout.icon, Icons.sports_martial_arts);

      final mmaWorkout = workout.copyWith(iconCodePoint: 0xe534);
      expect(mmaWorkout.icon, Icons.sports_mma);

      final motorsportsWorkout = workout.copyWith(iconCodePoint: 0xe535);
      expect(motorsportsWorkout.icon, Icons.sports_motorsports);

      final scoreWorkout = workout.copyWith(iconCodePoint: 0xe536);
      expect(scoreWorkout.icon, Icons.sports_score);

      final unknownWorkout = workout.copyWith(iconCodePoint: 0x123456);
      expect(unknownWorkout.icon.codePoint, 0x123456);
      expect(unknownWorkout.icon.fontFamily, 'MaterialIcons');
    });

    test('should create workout with different statuses', () {
      final templateWorkout = Workout(name: 'Template');
      expect(templateWorkout.status, WorkoutStatus.template);

      final inProgressWorkout = Workout(
        name: 'In Progress',
        status: WorkoutStatus.inProgress,
      );
      expect(inProgressWorkout.status, WorkoutStatus.inProgress);

      final completedWorkout = Workout(
        name: 'Completed',
        status: WorkoutStatus.completed,
      );
      expect(completedWorkout.status, WorkoutStatus.completed);
    });

    test('should create workout with templateId', () {
      final templateId = 'template-123';
      final sessionWorkout = Workout(
        name: 'Session',
        status: WorkoutStatus.inProgress,
        templateId: templateId,
      );

      expect(sessionWorkout.templateId, templateId);
      expect(sessionWorkout.status, WorkoutStatus.inProgress);
    });

    test('should create workout with startedAt and completedAt', () {
      final startedAt = DateTime.now().subtract(Duration(hours: 1));
      final completedAt = DateTime.now();

      final completedWorkout = Workout(
        name: 'Completed Session',
        status: WorkoutStatus.completed,
        startedAt: startedAt,
        completedAt: completedAt,
      );

      expect(completedWorkout.startedAt, startedAt);
      expect(completedWorkout.completedAt, completedAt);
    });
  });
}
