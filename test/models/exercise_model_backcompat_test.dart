import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';

void main() {
  group('Exercise.fromMap backward compatibility', () {
    test('parses snake_case keys correctly', () {
      final map = {
        'slug': 'push-up',
        'name': 'Push-Up',
        'primary_muscle_group': 'Chest',
        'secondary_muscle_groups': '["Triceps","Shoulders"]',
        'instructions': '["Do this","Then that"]',
        'equipment': 'None',
        'image': '',
        'animation': '',
        'is_bodyweight_exercise': 1,
      };

      final ex = Exercise.fromMap(map);
      expect(ex.slug, 'push-up');
      expect(ex.name, 'Push-Up');
      expect(ex.primaryMuscleGroup, MuscleGroup.chest);
      expect(ex.secondaryMuscleGroups, containsAllInOrder([MuscleGroup.triceps, MuscleGroup.shoulders]));
      expect(ex.instructions, containsAllInOrder(['Do this', 'Then that']));
      expect(ex.equipment, 'None');
      expect(ex.isBodyWeightExercise, isTrue);
    });

    test('parses camelCase keys correctly', () {
      final map = {
        'slug': 'bench-press',
        'name': 'Bench Press',
        'primaryMuscleGroup': 'Chest',
        'secondaryMuscleGroups': ['Triceps'],
        'instructions': ['Unrack', 'Lower', 'Press'],
        'equipment': 'Barbell',
        'image': '',
        'animation': '',
        'isBodyWeightExercise': 0,
      };

      final ex = Exercise.fromMap(map);
      expect(ex.slug, 'bench-press');
      expect(ex.name, 'Bench Press');
      expect(ex.primaryMuscleGroup, MuscleGroup.chest);
      expect(ex.secondaryMuscleGroups, contains(MuscleGroup.triceps));
      expect(ex.instructions, containsAllInOrder(['Unrack', 'Lower', 'Press']));
      expect(ex.equipment, 'Barbell');
      expect(ex.isBodyWeightExercise, isFalse);
    });

    test('parses mixed keys and different bodyweight representations', () {
      final mapBool = {
        'slug': 'air-squat',
        'name': 'Air Squat',
        'primary_muscle_group': 'Quads',
        'secondaryMuscleGroups': '[]',
        'instructions': [],
        'equipment': 'None',
        'bodyweight': true,
      };
      final exBool = Exercise.fromMap(mapBool);
      expect(exBool.primaryMuscleGroup, MuscleGroup.quads);
      expect(exBool.isBodyWeightExercise, isTrue);

      final mapIntZero = {
        'slug': 'deadlift',
        'name': 'Deadlift',
        'primaryMuscleGroup': 'Glutes',
        'secondary_muscle_groups': '["Hamstrings"]',
        'instructions': '[]',
        'equipment': 'Barbell',
        'is_bodyweight_exercise': 0,
      };
      final exZero = Exercise.fromMap(mapIntZero);
      expect(exZero.primaryMuscleGroup, MuscleGroup.glutes);
      expect(exZero.isBodyWeightExercise, isFalse);
    });

    test('handles null/empty secondary groups and instructions gracefully', () {
      final map = {
        'slug': 'plank',
        'name': 'Plank',
        'primary_muscle_group': 'Abs',
        'secondary_muscle_groups': null,
        'instructions': null,
        'equipment': 'None',
        'is_bodyweight_exercise': 1,
      };

      final ex = Exercise.fromMap(map);
      expect(ex.secondaryMuscleGroups, isEmpty);
      expect(ex.instructions, isEmpty);
      expect(ex.primaryMuscleGroup, MuscleGroup.abs);
      expect(ex.isBodyWeightExercise, isTrue);
    });
  });

  group('Exercise.toMap serialization', () {
    test('emits snake_case keys expected by legacy consumers/tests', () {
      final ex = Exercise(
        slug: 'push-up',
        name: 'Push-Up',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps, MuscleGroup.shoulders],
        instructions: ['Do this', 'Then that'],
        equipment: 'None',
        image: '',
        animation: '',
        isBodyWeightExercise: true,
      );

      final map = ex.toMap();
      expect(map['slug'], 'push-up');
      expect(map['name'], 'Push-Up');
      expect(map['primary_muscle_group'], 'Chest');
      expect(map['secondary_muscle_groups'], isA<String>());
      expect(map['instructions'], isA<String>());
      expect(map['equipment'], 'None');
      expect(map['image'], '');
      expect(map['animation'], '');
      expect(map['is_bodyweight_exercise'], 1);
    });
  });
}
