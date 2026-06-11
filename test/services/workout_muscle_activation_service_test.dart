import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/workout_muscle_activation_service.dart';

void main() {
  group('WorkoutMuscleActivationService', () {
    test('normalizes planned and actual activation by planned peak', () {
      const config = WorkoutMuscleActivationConfig(
        primaryWeight: 1,
        secondaryWeight: 0.35,
        axes: [
          WorkoutMuscleActivationAxis(id: 'chest', label: 'Chest'),
          WorkoutMuscleActivationAxis(id: 'arms', label: 'Arms'),
          WorkoutMuscleActivationAxis(id: 'core', label: 'Core'),
        ],
        muscleContributions: {
          MuscleGroup.chest: {'chest': 1, 'core': 0.1},
          MuscleGroup.triceps: {'arms': 1, 'chest': 0.1},
        },
      );
      final workout = Workout(
        name: 'Push',
        exercises: [
          WorkoutExercise(
            workoutId: 'workout-1',
            exerciseSlug: 'bench-press',
            exerciseDetail: Exercise(
              slug: 'bench-press',
              name: 'Bench Press',
              primaryMuscleGroup: MuscleGroup.chest,
              secondaryMuscleGroups: const [MuscleGroup.triceps],
              instructions: const [],
              image: '',
              animation: '',
            ),
            sets: List.generate(
              4,
              (index) => WorkoutSet(
                workoutExerciseId: 'exercise-1',
                setIndex: index,
                isCompleted: index < 2,
              ),
            ),
          ),
        ],
      );

      final profile = WorkoutMuscleActivationService.buildProfileFromConfig(
        workout,
        config,
      );

      final chest = profile.points.firstWhere(
        (point) => point.axisId == 'chest',
      );
      final arms = profile.points.firstWhere((point) => point.axisId == 'arms');
      final core = profile.points.firstWhere((point) => point.axisId == 'core');

      expect(chest.planned, 1);
      expect(chest.actual, closeTo(0.5, 0.001));
      expect(arms.planned, closeTo(0.338, 0.001));
      expect(arms.actual, closeTo(0.169, 0.001));
      expect(core.planned, closeTo(0.097, 0.001));
      expect(core.actual, closeTo(0.048, 0.001));
      expect(chest.completionRatio, 0.5);
    });

    test('sums configured percentage contributions per exercise role', () {
      const config = WorkoutMuscleActivationConfig(
        primaryWeight: 1,
        secondaryWeight: 0.5,
        axes: [
          WorkoutMuscleActivationAxis(id: 'legs', label: 'Legs'),
          WorkoutMuscleActivationAxis(id: 'core', label: 'Core'),
          WorkoutMuscleActivationAxis(id: 'glutes', label: 'Glutes'),
        ],
        muscleContributions: {
          MuscleGroup.quads: {'legs': 1, 'glutes': 0.2, 'core': 0.1},
          MuscleGroup.glutes: {'glutes': 1, 'legs': 0.35, 'core': 0.15},
          MuscleGroup.core: {'core': 1},
        },
      );
      final workout = Workout(
        name: 'Legs',
        exercises: [
          WorkoutExercise(
            workoutId: 'workout-1',
            exerciseSlug: 'squat',
            exerciseDetail: Exercise(
              slug: 'squat',
              name: 'Squat',
              primaryMuscleGroup: MuscleGroup.quads,
              secondaryMuscleGroups: const [
                MuscleGroup.glutes,
                MuscleGroup.core,
              ],
              instructions: const [],
              image: '',
              animation: '',
            ),
            sets: [
              WorkoutSet(
                workoutExerciseId: 'exercise-1',
                setIndex: 0,
                isCompleted: true,
              ),
            ],
          ),
        ],
      );

      final profile = WorkoutMuscleActivationService.buildProfileFromConfig(
        workout,
        config,
      );

      final legs = profile.points.firstWhere((point) => point.axisId == 'legs');
      final core = profile.points.firstWhere((point) => point.axisId == 'core');
      final glutes = profile.points.firstWhere(
        (point) => point.axisId == 'glutes',
      );

      expect(legs.planned, 1);
      expect(glutes.planned, closeTo(0.596, 0.001));
      expect(core.planned, closeTo(0.574, 0.001));
    });
  });
}
