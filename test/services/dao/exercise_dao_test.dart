import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/services/dao/exercise_dao.dart';

void main() {
  group('ExerciseDao', () {
    late ExerciseDao dao;

    setUp(() {
      dao = ExerciseDao();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'Exercise');
    });

    test('should convert exercise to map', () {
      final exercise = Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps, MuscleGroup.shoulders],
        instructions: ['Lie on bench', 'Press barbell'],
        image: 'bench_press.jpg',
        animation: 'bench_press.gif',
        isBodyWeightExercise: false,
      );

      final map = dao.toMap(exercise);

      expect(map['slug'], 'bench-press');
      expect(map['name'], 'Bench Press');
      expect(map['primaryMuscleGroup'], 'Chest');
      expect(map['image'], 'bench_press.jpg');
      expect(map['animation'], 'bench_press.gif');
      expect(map['isBodyWeightExercise'], 0);
      // Check that secondary muscle groups and instructions are JSON encoded
      expect(map['secondaryMuscleGroups'], '[\"Triceps\",\"Shoulders\"]');
      expect(map['instructions'], '[\"Lie on bench\",\"Press barbell\"]');
    });

    test('should convert map to exercise', () {
      final map = {
        'slug': 'squat',
        'name': 'Squat',
        'primaryMuscleGroup': 'Quads',
        'secondaryMuscleGroups': '[\"Glutes\",\"Hamstrings\"]',
        'instructions': '[\"Stand with feet shoulder width apart\",\"Lower body\"]',
        'image': 'squat.jpg',
        'animation': 'squat.gif',
        'isBodyWeightExercise': 0,
      };

      final exercise = dao.fromMap(map);

      expect(exercise.slug, 'squat');
      expect(exercise.name, 'Squat');
      expect(exercise.primaryMuscleGroup.name, 'Quads');
      expect(exercise.image, 'squat.jpg');
      expect(exercise.animation, 'squat.gif');
      expect(exercise.isBodyWeightExercise, false);
      expect(exercise.secondaryMuscleGroups.length, 2);
      expect(exercise.secondaryMuscleGroups[0].name, 'Glutes');
      expect(exercise.secondaryMuscleGroups[1].name, 'Hamstrings');
      expect(exercise.instructions.length, 2);
      expect(exercise.instructions[0], 'Stand with feet shoulder width apart');
      expect(exercise.instructions[1], 'Lower body');
    });

    test('should handle bodyweight exercise', () {
      final map = {
        'slug': 'push-up',
        'name': 'Push-up',
        'primaryMuscleGroup': 'Chest',
        'secondaryMuscleGroups': '[\"Triceps\",\"Shoulders\"]',
        'instructions': '[\"Start in plank position\",\"Lower body\"]',
        'image': 'push_up.jpg',
        'animation': 'push_up.gif',
        'isBodyWeightExercise': 1,
      };

      final exercise = dao.fromMap(map);
      expect(exercise.isBodyWeightExercise, true);
    });
  });
}
