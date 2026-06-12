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

    test('prefers explicit exercise muscle activation over generic roles', () {
      const config = WorkoutMuscleActivationConfig(
        primaryWeight: 1,
        secondaryWeight: 0.35,
        axes: [
          WorkoutMuscleActivationAxis(id: 'arms', label: 'Arms'),
          WorkoutMuscleActivationAxis(id: 'legs', label: 'Legs'),
          WorkoutMuscleActivationAxis(id: 'core', label: 'Core'),
        ],
        muscleContributions: {
          MuscleGroup.biceps: {'arms': 1},
          MuscleGroup.forearms: {'arms': 0.7},
          MuscleGroup.quads: {'legs': 1},
          MuscleGroup.glutes: {'legs': 0.35},
          MuscleGroup.core: {'core': 1},
        },
      );
      final workout = Workout(
        name: 'Mixed',
        exercises: [
          WorkoutExercise(
            workoutId: 'workout-1',
            exerciseSlug: 'barbell-squat',
            exerciseDetail: Exercise(
              slug: 'barbell-squat',
              name: 'Barbell Squat',
              primaryMuscleGroup: MuscleGroup.quads,
              secondaryMuscleGroups: const [],
              instructions: const [],
              image: '',
              animation: '',
              muscleActivation: const {
                MuscleGroup.quads: 1.0,
                MuscleGroup.glutes: 0.85,
                MuscleGroup.core: 0.55,
              },
              exerciseIntensity: 1.0,
            ),
            sets: [WorkoutSet(workoutExerciseId: 'exercise-1', setIndex: 0)],
          ),
          WorkoutExercise(
            workoutId: 'workout-1',
            exerciseSlug: 'curl',
            exerciseDetail: Exercise(
              slug: 'curl',
              name: 'Curl',
              primaryMuscleGroup: MuscleGroup.biceps,
              secondaryMuscleGroups: const [],
              instructions: const [],
              image: '',
              animation: '',
              muscleActivation: const {
                MuscleGroup.biceps: 1.0,
                MuscleGroup.forearms: 0.3,
              },
              exerciseIntensity: 0.6,
            ),
            sets: [WorkoutSet(workoutExerciseId: 'exercise-2', setIndex: 0)],
          ),
        ],
      );

      final profile = WorkoutMuscleActivationService.buildProfileFromConfig(
        workout,
        config,
      );

      final legs = profile.points.firstWhere((point) => point.axisId == 'legs');
      final arms = profile.points.firstWhere((point) => point.axisId == 'arms');
      final core = profile.points.firstWhere((point) => point.axisId == 'core');

      expect(legs.planned, 1);
      expect(arms.planned, closeTo(0.559, 0.001));
      expect(core.planned, closeTo(0.424, 0.001));
    });

    test('exposes reusable raw exercise activation helpers', () {
      const config = WorkoutMuscleActivationConfig(
        primaryWeight: 1,
        secondaryWeight: 0.35,
        axes: [
          WorkoutMuscleActivationAxis(id: 'legs', label: 'Legs'),
          WorkoutMuscleActivationAxis(id: 'core', label: 'Core'),
        ],
        muscleContributions: {
          MuscleGroup.quads: {'legs': 1, 'core': 0.1},
          MuscleGroup.glutes: {'legs': 0.4, 'core': 0.15},
          MuscleGroup.core: {'core': 1},
        },
      );
      final exercise = Exercise(
        slug: 'barbell-squat',
        name: 'Barbell Squat',
        primaryMuscleGroup: MuscleGroup.quads,
        secondaryMuscleGroups: const [],
        instructions: const [],
        image: '',
        animation: '',
        muscleActivation: const {
          MuscleGroup.quads: 1.0,
          MuscleGroup.glutes: 0.85,
          MuscleGroup.core: 0.55,
        },
        exerciseIntensity: 1.2,
      );

      final muscleActivation =
          WorkoutMuscleActivationService.buildExerciseMuscleActivation(
            exercise,
            config,
          );
      final axisActivation =
          WorkoutMuscleActivationService.buildExerciseAxisActivation(
            exercise,
            config,
          );
      final load = WorkoutMuscleActivationService.exerciseActivationLoad(
        exercise,
        config,
      );

      expect(muscleActivation[MuscleGroup.quads], 1.2);
      expect(muscleActivation[MuscleGroup.glutes], closeTo(1.02, 0.001));
      expect(muscleActivation[MuscleGroup.core], closeTo(0.66, 0.001));
      expect(axisActivation['legs'], closeTo(1.608, 0.001));
      expect(axisActivation['core'], closeTo(0.933, 0.001));
      expect(load, closeTo(2.88, 0.001));
      expect(() => axisActivation['legs'] = 0, throwsUnsupportedError);
    });

    test('exposes raw planned and actual workout activation totals', () {
      const config = WorkoutMuscleActivationConfig(
        primaryWeight: 1,
        secondaryWeight: 0.5,
        axes: [
          WorkoutMuscleActivationAxis(id: 'chest', label: 'Chest'),
          WorkoutMuscleActivationAxis(id: 'arms', label: 'Arms'),
        ],
        muscleContributions: {
          MuscleGroup.chest: {'chest': 1},
          MuscleGroup.triceps: {'arms': 1},
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
            sets: [
              WorkoutSet(
                workoutExerciseId: 'exercise-1',
                setIndex: 0,
                isCompleted: true,
              ),
              WorkoutSet(workoutExerciseId: 'exercise-1', setIndex: 1),
            ],
          ),
        ],
      );

      final totals = WorkoutMuscleActivationService.buildWorkoutAxisActivation(
        workout,
        config,
      );

      expect(totals.plannedFor('chest'), 2);
      expect(totals.actualFor('chest'), 1);
      expect(totals.plannedFor('arms'), 1);
      expect(totals.actualFor('arms'), 0.5);
      expect(totals.completionRatioFor('chest'), 0.5);
      expect(() => totals.plannedByAxis['chest'] = 0, throwsUnsupportedError);
    });

    test('builds one profile across multiple workouts', () {
      const config = WorkoutMuscleActivationConfig(
        primaryWeight: 1,
        secondaryWeight: 0.5,
        axes: [
          WorkoutMuscleActivationAxis(id: 'chest', label: 'Chest'),
          WorkoutMuscleActivationAxis(id: 'legs', label: 'Legs'),
        ],
        muscleContributions: {
          MuscleGroup.chest: {'chest': 1},
          MuscleGroup.quads: {'legs': 1},
        },
      );
      final workouts = [
        Workout(
          name: 'Push',
          exercises: [
            WorkoutExercise(
              workoutId: 'workout-1',
              exerciseSlug: 'bench-press',
              exerciseDetail: Exercise(
                slug: 'bench-press',
                name: 'Bench Press',
                primaryMuscleGroup: MuscleGroup.chest,
                secondaryMuscleGroups: const [],
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
        ),
        Workout(
          name: 'Legs',
          exercises: [
            WorkoutExercise(
              workoutId: 'workout-2',
              exerciseSlug: 'squat',
              exerciseDetail: Exercise(
                slug: 'squat',
                name: 'Squat',
                primaryMuscleGroup: MuscleGroup.quads,
                secondaryMuscleGroups: const [],
                instructions: const [],
                image: '',
                animation: '',
              ),
              sets: [
                WorkoutSet(
                  workoutExerciseId: 'exercise-2',
                  setIndex: 0,
                  isCompleted: true,
                ),
                WorkoutSet(workoutExerciseId: 'exercise-2', setIndex: 1),
              ],
            ),
          ],
        ),
      ];

      final profile =
          WorkoutMuscleActivationService.buildProfileForWorkoutsFromConfig(
            workouts,
            config,
          );
      final chest = profile.points.firstWhere(
        (point) => point.axisId == 'chest',
      );
      final legs = profile.points.firstWhere((point) => point.axisId == 'legs');

      expect(chest.planned, 0.5);
      expect(chest.actual, 0.5);
      expect(legs.planned, 1);
      expect(legs.actual, 0.5);
    });
  });
}
