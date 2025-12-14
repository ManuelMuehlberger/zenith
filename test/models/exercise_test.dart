import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';

void main() {
  group('Exercise model', () {
    test('constructor initializes all properties correctly', () {
      final exercise = Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps],
        instructions: ['Lie on bench', 'Press bar up'],
        image: 'bench_press.jpg',
        animation: 'bench_press.gif',
        isBodyWeightExercise: false,
      );

      expect(exercise.slug, 'bench-press');
      expect(exercise.name, 'Bench Press');
      expect(exercise.primaryMuscleGroup, MuscleGroup.chest);
      expect(exercise.secondaryMuscleGroups, [MuscleGroup.triceps]);
      expect(exercise.instructions, ['Lie on bench', 'Press bar up']);
      expect(exercise.image, 'bench_press.jpg');
      expect(exercise.animation, 'bench_press.gif');
      expect(exercise.isBodyWeightExercise, false);
    });

    test('constructor with default isBodyWeightExercise value', () {
      final exercise = Exercise(
        slug: 'push-up',
        name: 'Push Up',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps, MuscleGroup.shoulders],
        instructions: ['Place hands on floor', 'Push body up'],
        image: 'pushup.jpg',
        animation: 'pushup.gif',
      );

      expect(exercise.isBodyWeightExercise, false);
    });

    test('fromMap creates Exercise instance from valid map with string arrays', () {
      final map = {
        'slug': 'bench-press',
        'name': 'Bench Press',
        'primary_muscle_group': 'chest',
        'secondary_muscle_groups': '["triceps"]',
        'instructions': '["Lie on bench","Press bar up"]',
        'image': 'bench_press.jpg',
        'animation': 'bench_press.gif',
        'is_bodyweight_exercise': false,
      };

      final exercise = Exercise.fromMap(map);

      expect(exercise.slug, 'bench-press');
      expect(exercise.name, 'Bench Press');
      expect(exercise.primaryMuscleGroup, MuscleGroup.chest);
      expect(exercise.secondaryMuscleGroups, [MuscleGroup.triceps]);
      expect(exercise.instructions, ['Lie on bench', 'Press bar up']);
      expect(exercise.image, 'bench_press.jpg');
      expect(exercise.animation, 'bench_press.gif');
      expect(exercise.isBodyWeightExercise, false);
    });

    test('fromMap creates Exercise instance from valid map with list arrays', () {
      final map = {
        'slug': 'bench-press',
        'name': 'Bench Press',
        'primary_muscle_group': 'chest',
        'secondary_muscle_groups': ['triceps'],
        'instructions': ['Lie on bench', 'Press bar up'],
        'image': 'bench_press.jpg',
        'animation': 'bench_press.gif',
        'is_bodyweight_exercise': false,
      };

      final exercise = Exercise.fromMap(map);

      expect(exercise.slug, 'bench-press');
      expect(exercise.name, 'Bench Press');
      expect(exercise.primaryMuscleGroup, MuscleGroup.chest);
      expect(exercise.secondaryMuscleGroups, [MuscleGroup.triceps]);
      expect(exercise.instructions, ['Lie on bench', 'Press bar up']);
      expect(exercise.image, 'bench_press.jpg');
      expect(exercise.animation, 'bench_press.gif');
      expect(exercise.isBodyWeightExercise, false);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'slug': 'bodyweight-squat',
        'name': 'Bodyweight Squat',
        'primary_muscle_group': 'legs',
        'secondary_muscle_groups': [],
        'instructions': ['Stand with feet shoulder-width apart', 'Squat down'],
        'image': 'squat.jpg',
        'animation': 'squat.gif',
      };

      final exercise = Exercise.fromMap(map);
      expect(exercise.isBodyWeightExercise, false);
    });

    test('fromMap handles is_bodyweight_exercise as true', () {
      final map = {
        'slug': 'push-up',
        'name': 'Push Up',
        'primary_muscle_group': 'chest',
        'secondary_muscle_groups': ['triceps', 'shoulders'],
        'instructions': ['Place hands on floor', 'Push body up'],
        'image': 'pushup.jpg',
        'animation': 'pushup.gif',
        'is_bodyweight_exercise': true,
      };

      final exercise = Exercise.fromMap(map);
      expect(exercise.isBodyWeightExercise, true);
    });

    test('fromMap handles is_bodyweight_exercise as integer 1', () {
      final map = {
        'slug': 'push-up',
        'name': 'Push Up',
        'primary_muscle_group': 'chest',
        'secondary_muscle_groups': ['triceps', 'shoulders'],
        'instructions': ['Place hands on floor', 'Push body up'],
        'image': 'pushup.jpg',
        'animation': 'pushup.gif',
        'is_bodyweight_exercise': 1,
      };

      final exercise = Exercise.fromMap(map);
      expect(exercise.isBodyWeightExercise, true);
    });

    test('fromMap handles is_bodyweight_exercise as integer 0', () {
      final map = {
        'slug': 'bench-press',
        'name': 'Bench Press',
        'primary_muscle_group': 'chest',
        'secondary_muscle_groups': ['triceps'],
        'instructions': ['Lie on bench', 'Press bar up'],
        'image': 'bench_press.jpg',
        'animation': 'bench_press.gif',
        'is_bodyweight_exercise': 0,
      };

      final exercise = Exercise.fromMap(map);
      expect(exercise.isBodyWeightExercise, false);
    });

    test('fromMap handles null secondary muscle groups', () {
      final map = {
        'slug': 'isolation-exercise',
        'name': 'Isolation Exercise',
        'primary_muscle_group': 'chest',
        'secondary_muscle_groups': null,
        'instructions': ['Perform exercise'],
        'image': 'isolation.jpg',
        'animation': 'isolation.gif',
      };

      final exercise = Exercise.fromMap(map);
      expect(exercise.secondaryMuscleGroups, isEmpty);
    });

    test('fromMap handles null instructions', () {
      final map = {
        'slug': 'simple-exercise',
        'name': 'Simple Exercise',
        'primary_muscle_group': 'chest',
        'secondary_muscle_groups': [],
        'instructions': null,
        'image': 'simple.jpg',
        'animation': 'simple.gif',
      };

      final exercise = Exercise.fromMap(map);
      expect(exercise.instructions, isEmpty);
    });

    test('fromMap handles missing fields with defaults', () {
      final map = {
        'slug': 'minimal-exercise',
        'name': 'Minimal Exercise',
        'primary_muscle_group': 'chest',
      };

      final exercise = Exercise.fromMap(map);
      expect(exercise.slug, 'minimal-exercise');
      expect(exercise.name, 'Minimal Exercise');
      expect(exercise.primaryMuscleGroup, MuscleGroup.chest);
      expect(exercise.secondaryMuscleGroups, isEmpty);
      expect(exercise.instructions, isEmpty);
      expect(exercise.image, '');
      expect(exercise.animation, '');
      expect(exercise.isBodyWeightExercise, false);
    });

    test('fromMap handles case-insensitive muscle group names', () {
      final map = {
        'slug': 'test-exercise',
        'name': 'Test Exercise',
        'primary_muscle_group': 'CHEST',
        'secondary_muscle_groups': ['TRICEPS', 'shoulders'],
        'instructions': ['Test instructions'],
        'image': 'test.jpg',
        'animation': 'test.gif',
      };

      final exercise = Exercise.fromMap(map);
      expect(exercise.primaryMuscleGroup, MuscleGroup.chest);
      expect(exercise.secondaryMuscleGroups, [MuscleGroup.triceps, MuscleGroup.shoulders]);
    });

    test('toMap converts Exercise instance to correct map', () {
      final exercise = Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps],
        instructions: ['Lie on bench', 'Press bar up'],
        image: 'bench_press.jpg',
        animation: 'bench_press.gif',
        isBodyWeightExercise: false,
      );

      final map = exercise.toMap();

      expect(map['slug'], 'bench-press');
      expect(map['name'], 'Bench Press');
      expect(map['primary_muscle_group'], 'Chest');
      expect(map['secondary_muscle_groups'], '["Triceps"]');
      expect(map['instructions'], '["Lie on bench","Press bar up"]');
      expect(map['image'], 'bench_press.jpg');
      expect(map['animation'], 'bench_press.gif');
      expect(map['is_bodyweight_exercise'], 0);
    });

    test('toMap handles bodyweight exercise correctly', () {
      final exercise = Exercise(
        slug: 'push-up',
        name: 'Push Up',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps, MuscleGroup.shoulders],
        instructions: ['Place hands on floor', 'Push body up'],
        image: 'pushup.jpg',
        animation: 'pushup.gif',
        isBodyWeightExercise: true,
      );

      final map = exercise.toMap();

      expect(map['is_bodyweight_exercise'], 1);
    });

    test('toMap handles empty secondary muscle groups', () {
      final exercise = Exercise(
        slug: 'isolation-exercise',
        name: 'Isolation Exercise',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [],
        instructions: ['Perform exercise'],
        image: 'isolation.jpg',
        animation: 'isolation.gif',
      );

      final map = exercise.toMap();

      expect(map['secondary_muscle_groups'], '[]');
    });

    test('toMap handles empty instructions', () {
      final exercise = Exercise(
        slug: 'simple-exercise',
        name: 'Simple Exercise',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [],
        instructions: [],
        image: 'simple.jpg',
        animation: 'simple.gif',
      );

      final map = exercise.toMap();

      expect(map['instructions'], '[]');
    });

    test('toMap handles multiple secondary muscle groups', () {
      final exercise = Exercise(
        slug: 'compound-exercise',
        name: 'Compound Exercise',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps, MuscleGroup.shoulders, MuscleGroup.frontDeltoids],
        instructions: ['Perform compound movement'],
        image: 'compound.jpg',
        animation: 'compound.gif',
      );

      final map = exercise.toMap();

      expect(map['secondary_muscle_groups'], '["Triceps","Shoulders","Front Deltoids"]');
    });

    test('toMap handles multiple instructions', () {
      final exercise = Exercise(
        slug: 'complex-exercise',
        name: 'Complex Exercise',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps],
        instructions: ['Step 1: Prepare', 'Step 2: Execute', 'Step 3: Complete'],
        image: 'complex.jpg',
        animation: 'complex.gif',
      );

      final map = exercise.toMap();

      expect(map['instructions'], '["Step 1: Prepare","Step 2: Execute","Step 3: Complete"]');
    });

    test('Exercise instances with same data are equal', () {
      final exercise1 = Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps],
        instructions: ['Lie on bench', 'Press bar up'],
        image: 'bench_press.jpg',
        animation: 'bench_press.gif',
        isBodyWeightExercise: false,
      );

      final exercise2 = Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps],
        instructions: ['Lie on bench', 'Press bar up'],
        image: 'bench_press.jpg',
        animation: 'bench_press.gif',
        isBodyWeightExercise: false,
      );

      expect(exercise1.slug, exercise2.slug);
      expect(exercise1.name, exercise2.name);
      expect(exercise1.primaryMuscleGroup, exercise2.primaryMuscleGroup);
      expect(exercise1.secondaryMuscleGroups, exercise2.secondaryMuscleGroups);
      expect(exercise1.instructions, exercise2.instructions);
      expect(exercise1.image, exercise2.image);
      expect(exercise1.animation, exercise2.animation);
      expect(exercise1.isBodyWeightExercise, exercise2.isBodyWeightExercise);
    });

    test('Exercise instances with different slugs are different', () {
      final exercise1 = Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps],
        instructions: ['Lie on bench', 'Press bar up'],
        image: 'bench_press.jpg',
        animation: 'bench_press.gif',
        isBodyWeightExercise: false,
      );

      final exercise2 = Exercise(
        slug: 'incline-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps],
        instructions: ['Lie on bench', 'Press bar up'],
        image: 'bench_press.jpg',
        animation: 'bench_press.gif',
        isBodyWeightExercise: false,
      );

      expect(exercise1.slug, isNot(exercise2.slug));
    });
  });
}
