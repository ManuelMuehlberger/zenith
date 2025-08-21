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

    test('fromMap creates Exercise instance from valid map', () {
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
      expect(map['primary_muscle_group'], 'chest');
      expect(map['secondary_muscle_groups'], ['triceps']);
      expect(map['instructions'], ['Lie on bench', 'Press bar up']);
      expect(map['image'], 'bench_press.jpg');
      expect(map['animation'], 'bench_press.gif');
      expect(map['is_bodyweight_exercise'], false);
    });

    test('fromMap handles missing is_bodyweight_exercise field', () {
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
  });
}
