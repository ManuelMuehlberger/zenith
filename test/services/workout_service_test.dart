import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/dao/workout_dao.dart';
import 'package:zenith/services/dao/workout_exercise_dao.dart';
import 'package:zenith/services/dao/workout_set_dao.dart';
import 'package:zenith/services/workout_service.dart';

// Generate mocks
@GenerateMocks([WorkoutDao, WorkoutExerciseDao, WorkoutSetDao])
import 'workout_service_test.mocks.dart';

void main() {
  group('WorkoutService Tests', () {
    late WorkoutService workoutService;
    late MockWorkoutDao mockWorkoutDao;
    late MockWorkoutExerciseDao mockWorkoutExerciseDao;
    late MockWorkoutSetDao mockWorkoutSetDao;

    setUp(() {
      // Create mocks
      mockWorkoutDao = MockWorkoutDao();
      mockWorkoutExerciseDao = MockWorkoutExerciseDao();
      mockWorkoutSetDao = MockWorkoutSetDao();

      // Get the singleton instance
      workoutService = WorkoutService.instance;

      // Reset the service state for each test
      workoutService.workouts.clear();

      // Inject mocks by overriding the DAO instances in the service
      workoutService.workoutDao = mockWorkoutDao;
      workoutService.workoutExerciseDao = mockWorkoutExerciseDao;
      workoutService.workoutSetDao = mockWorkoutSetDao;
    });

    test('should initialize workout service', () {
      expect(workoutService, isNotNull);
    });

    test('should be a singleton', () {
      final service1 = WorkoutService();
      final service2 = WorkoutService();
      expect(service1, same(service2));
      expect(service1, same(WorkoutService.instance));
    });

    group('loadData', () {
      test('should load workouts successfully', () async {
        // Arrange
        final mockWorkouts = [
          Workout(
            id: 'workout1',
            name: 'Push Day',
            exercises: [],
            status: WorkoutStatus.inProgress,
          ),
        ];

        final mockExercises = [
          WorkoutExercise(
            id: 'exercise1',
            workoutId: 'workout1',
            exerciseSlug: 'bench-press',
            sets: [],
          ),
        ];

        final mockSets = [
          WorkoutSet(
            id: 'set1',
            workoutExerciseId: 'exercise1',
            setIndex: 0,
            targetReps: 10,
            targetWeight: 100.0,
          ),
        ];

        // Mock DAO calls
        when(
          mockWorkoutDao.getAllWorkouts(),
        ).thenAnswer((_) async => mockWorkouts);
        when(
          mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutIds(['workout1']),
        ).thenAnswer((_) async => mockExercises);
        when(
          mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseIds(['exercise1']),
        ).thenAnswer((_) async => mockSets);

        // Act
        await workoutService.loadData();

        // Assert
        expect(workoutService.workouts.length, 1);
        expect(workoutService.workouts.first.exercises.length, 1);
        expect(workoutService.workouts.first.exercises.first.sets.length, 1);
      });

      test(
        'should stop loading related data when there are no workouts',
        () async {
          when(mockWorkoutDao.getAllWorkouts()).thenAnswer((_) async => []);

          await workoutService.loadData();

          expect(workoutService.workouts, isEmpty);
          verify(mockWorkoutDao.getAllWorkouts()).called(1);
          verifyNever(
            mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutIds(any),
          );
          verifyNever(
            mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseIds(any),
          );
        },
      );

      test(
        'should ignore orphaned exercises and default missing sets to empty',
        () async {
          final workouts = [
            Workout(
              id: 'workout1',
              name: 'Push Day',
              exercises: const [],
              status: WorkoutStatus.inProgress,
            ),
            Workout(
              id: 'workout2',
              name: 'Pull Day',
              exercises: const [],
              status: WorkoutStatus.inProgress,
            ),
          ];
          final exercises = [
            WorkoutExercise(
              id: 'exercise1',
              workoutId: 'workout1',
              exerciseSlug: 'bench-press',
              sets: const [],
            ),
            WorkoutExercise(
              id: 'orphan',
              workoutTemplateId: 'template1',
              exerciseSlug: 'squat',
              sets: const [],
            ),
          ];

          when(
            mockWorkoutDao.getAllWorkouts(),
          ).thenAnswer((_) async => workouts);
          when(
            mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutIds([
              'workout1',
              'workout2',
            ]),
          ).thenAnswer((_) async => exercises);
          when(
            mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseIds([
              'exercise1',
              'orphan',
            ]),
          ).thenAnswer((_) async => []);

          await workoutService.loadData();

          expect(workoutService.workouts[0].exercises, hasLength(1));
          expect(
            workoutService.workouts[0].exercises.single.exerciseSlug,
            'bench-press',
          );
          expect(workoutService.workouts[0].exercises.single.sets, isEmpty);
          expect(workoutService.workouts[1].exercises, isEmpty);
        },
      );

      test('should return workouts sorted by startedAt desc', () async {
        final past = Workout(
          id: 'past',
          name: 'Past',
          exercises: const [],
          status: WorkoutStatus.completed,
          startedAt: DateTime(2020, 1, 1),
        );
        final future = Workout(
          id: 'future',
          name: 'Future',
          exercises: const [],
          status: WorkoutStatus.completed,
          startedAt: DateTime(2030, 1, 1),
        );
        final noDate = Workout(
          id: 'no-date',
          name: 'No Date',
          exercises: const [],
          status: WorkoutStatus.completed,
        );

        when(
          mockWorkoutDao.getAllWorkouts(),
        ).thenAnswer((_) async => [past, noDate, future]);
        when(
          mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutIds([
            'past',
            'no-date',
            'future',
          ]),
        ).thenAnswer((_) async => []);
        when(
          mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseIds([]),
        ).thenAnswer((_) async => []);

        final workouts = await workoutService.getWorkoutsSortedByStartedAt();

        expect(workouts.map((w) => w.id).toList(), [
          'future',
          'past',
          'no-date',
        ]);
      });

      test('should filter workouts for a date', () async {
        final w1 = Workout(
          id: 'a',
          name: 'A',
          exercises: const [],
          status: WorkoutStatus.completed,
          startedAt: DateTime(2023, 5, 10, 8),
        );
        final w2 = Workout(
          id: 'b',
          name: 'B',
          exercises: const [],
          status: WorkoutStatus.completed,
          startedAt: DateTime(2023, 5, 10, 18),
        );
        final w3 = Workout(
          id: 'c',
          name: 'C',
          exercises: const [],
          status: WorkoutStatus.completed,
          startedAt: DateTime(2023, 5, 11),
        );

        when(
          mockWorkoutDao.getAllWorkouts(),
        ).thenAnswer((_) async => [w1, w2, w3]);
        when(
          mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutIds([
            'a',
            'b',
            'c',
          ]),
        ).thenAnswer((_) async => []);
        when(
          mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseIds([]),
        ).thenAnswer((_) async => []);

        final workouts = await workoutService.getWorkoutsForDate(
          DateTime(2023, 5, 10),
        );

        expect(workouts.map((w) => w.id).toList(), ['b', 'a']);
      });

      test(
        'should ignore workouts without a startedAt when filtering by date',
        () async {
          final undated = Workout(
            id: 'undated',
            name: 'Undated',
            exercises: const [],
            status: WorkoutStatus.completed,
          );
          final dated = Workout(
            id: 'dated',
            name: 'Dated',
            exercises: const [],
            status: WorkoutStatus.completed,
            startedAt: DateTime(2024, 2, 3, 10),
          );

          when(
            mockWorkoutDao.getAllWorkouts(),
          ).thenAnswer((_) async => [undated, dated]);
          when(
            mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutIds([
              'undated',
              'dated',
            ]),
          ).thenAnswer((_) async => []);
          when(
            mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseIds([]),
          ).thenAnswer((_) async => []);

          final workouts = await workoutService.getWorkoutsForDate(
            DateTime(2024, 2, 3),
          );

          expect(workouts.map((w) => w.id).toList(), ['dated']);
        },
      );

      test('should return sorted unique workout dates', () async {
        final d1a = Workout(
          id: 'd1a',
          name: 'D1 Morning',
          exercises: const [],
          status: WorkoutStatus.completed,
          startedAt: DateTime(2024, 1, 1, 8, 30),
        );
        final d1b = Workout(
          id: 'd1b',
          name: 'D1 Evening',
          exercises: const [],
          status: WorkoutStatus.completed,
          startedAt: DateTime(2024, 1, 1, 20),
        );
        final d2 = Workout(
          id: 'd2',
          name: 'D2',
          exercises: const [],
          status: WorkoutStatus.completed,
          startedAt: DateTime(2024, 1, 2),
        );

        when(
          mockWorkoutDao.getAllWorkouts(),
        ).thenAnswer((_) async => [d1a, d1b, d2]);
        when(
          mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutIds([
            'd1a',
            'd1b',
            'd2',
          ]),
        ).thenAnswer((_) async => []);
        when(
          mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseIds([]),
        ).thenAnswer((_) async => []);

        final dates = await workoutService.getDatesWithWorkouts();

        expect(dates, [DateTime(2024, 1, 1), DateTime(2024, 1, 2)]);
      });

      test(
        'should ignore workouts without dates when collecting workout dates',
        () async {
          final undated = Workout(
            id: 'undated',
            name: 'Undated',
            exercises: const [],
            status: WorkoutStatus.completed,
          );
          final dated = Workout(
            id: 'dated',
            name: 'Dated',
            exercises: const [],
            status: WorkoutStatus.completed,
            startedAt: DateTime(2024, 3, 4, 7),
          );

          when(
            mockWorkoutDao.getAllWorkouts(),
          ).thenAnswer((_) async => [undated, dated]);
          when(
            mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutIds([
              'undated',
              'dated',
            ]),
          ).thenAnswer((_) async => []);
          when(
            mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseIds([]),
          ).thenAnswer((_) async => []);

          final dates = await workoutService.getDatesWithWorkouts();

          expect(dates, [DateTime(2024, 3, 4)]);
        },
      );

      test(
        'should return most recent workout containing an exercise slug',
        () async {
          final older = Workout(
            id: 'old',
            name: 'Old',
            exercises: const [],
            status: WorkoutStatus.completed,
            startedAt: DateTime(2023, 1, 1),
          );
          final newer = Workout(
            id: 'new',
            name: 'New',
            exercises: const [],
            status: WorkoutStatus.completed,
            startedAt: DateTime(2023, 2, 1),
          );

          when(
            mockWorkoutDao.getAllWorkouts(),
          ).thenAnswer((_) async => [older, newer]);
          when(
            mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutIds([
              'old',
              'new',
            ]),
          ).thenAnswer(
            (_) async => [
              WorkoutExercise(
                id: 'old-exercise',
                workoutId: 'old',
                exerciseSlug: 'squat',
                sets: const [],
              ),
              WorkoutExercise(
                id: 'new-exercise',
                workoutId: 'new',
                exerciseSlug: 'bench-press',
                sets: const [],
              ),
            ],
          );
          when(
            mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseIds([
              'old-exercise',
              'new-exercise',
            ]),
          ).thenAnswer((_) async => []);

          final workout = await workoutService.getLastWorkoutForExercise(
            'bench-press',
          );

          expect(workout?.id, 'new');
        },
      );

      test(
        'should return null when no workout contains the exercise slug',
        () async {
          final workout = Workout(
            id: 'workout1',
            name: 'Workout',
            exercises: const [],
            status: WorkoutStatus.completed,
            startedAt: DateTime(2024, 1, 1),
          );

          when(
            mockWorkoutDao.getAllWorkouts(),
          ).thenAnswer((_) async => [workout]);
          when(
            mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutIds([
              'workout1',
            ]),
          ).thenAnswer(
            (_) async => [
              WorkoutExercise(
                id: 'exercise1',
                workoutId: 'workout1',
                exerciseSlug: 'squat',
                sets: const [],
              ),
            ],
          );
          when(
            mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseIds(['exercise1']),
          ).thenAnswer((_) async => []);

          final result = await workoutService.getLastWorkoutForExercise(
            'bench-press',
          );

          expect(result, isNull);
        },
      );

      test('should handle load data errors gracefully', () async {
        // Arrange
        when(
          mockWorkoutDao.getAllWorkouts(),
        ).thenThrow(Exception('Database error'));

        // Act
        await workoutService.loadData();

        // Assert
        expect(workoutService.workouts, isEmpty);
      });
    });

    group('saveData', () {
      test('should complete without errors', () async {
        // Act & Assert
        expect(() => workoutService.saveData(), returnsNormally);
      });
    });

    group('Workout Operations', () {
      group('createWorkout', () {
        test('should create workout successfully', () async {
          // Arrange
          const workoutName = 'New Workout';

          when(mockWorkoutDao.insert(any)).thenAnswer((_) async => 1);

          // Act
          final result = await workoutService.createWorkout(workoutName);

          // Assert
          expect(result.name, workoutName);
          expect(result.status, WorkoutStatus.template);
          expect(workoutService.workouts.contains(result), true);
          verify(mockWorkoutDao.insert(any)).called(1);
        });

        test(
          'should create workout in a folder when folderId is provided',
          () async {
            when(mockWorkoutDao.insert(any)).thenAnswer((_) async => 1);

            final result = await workoutService.createWorkout(
              'Folder Workout',
              folderId: 'folder1',
            );

            expect(result.folderId, 'folder1');
            expect(workoutService.workouts.single.folderId, 'folder1');
          },
        );
      });

      group('updateWorkout', () {
        test('should update workout successfully', () async {
          // Arrange
          final workout = Workout(
            id: 'workout1',
            name: 'Original Name',
            exercises: [],
            status: WorkoutStatus.template,
          );
          workoutService.workouts.add(workout);

          final updatedWorkout = workout.copyWith(name: 'Updated Name');

          when(
            mockWorkoutDao.updateWorkout(updatedWorkout),
          ).thenAnswer((_) async => 1);

          // Act
          await workoutService.updateWorkout(updatedWorkout);

          // Assert
          expect(workoutService.workouts.first.name, 'Updated Name');
          verify(mockWorkoutDao.updateWorkout(updatedWorkout)).called(1);
        });

        test(
          'should still persist updates when the workout is not cached',
          () async {
            final workout = Workout(
              id: 'workout1',
              name: 'Detached Workout',
              exercises: const [],
              status: WorkoutStatus.template,
            );

            when(
              mockWorkoutDao.updateWorkout(workout),
            ).thenAnswer((_) async => 1);

            await workoutService.updateWorkout(workout);

            expect(workoutService.workouts, isEmpty);
            verify(mockWorkoutDao.updateWorkout(workout)).called(1);
          },
        );
      });

      group('deleteWorkout', () {
        test('should delete workout and associated data', () async {
          // Arrange
          final workout = Workout(
            id: 'workout1',
            name: 'Test Workout',
            exercises: [],
            status: WorkoutStatus.template,
          );
          final exercise = WorkoutExercise(
            id: 'exercise1',
            workoutId: 'workout1',
            exerciseSlug: 'bench-press',
            sets: [],
          );

          workoutService.workouts.add(workout);

          when(
            mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId('workout1'),
          ).thenAnswer((_) async => [exercise]);
          when(
            mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId('exercise1'),
          ).thenAnswer((_) async => 1);
          when(
            mockWorkoutExerciseDao.deleteWorkoutExercisesByWorkoutId(
              'workout1',
            ),
          ).thenAnswer((_) async => 1);
          when(
            mockWorkoutDao.deleteWorkout('workout1'),
          ).thenAnswer((_) async => 1);

          // Act
          await workoutService.deleteWorkout('workout1');

          // Assert
          expect(workoutService.workouts, isEmpty);
          verify(
            mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId('exercise1'),
          ).called(1);
          verify(
            mockWorkoutExerciseDao.deleteWorkoutExercisesByWorkoutId(
              'workout1',
            ),
          ).called(1);
          verify(mockWorkoutDao.deleteWorkout('workout1')).called(1);
        });

        test(
          'should delete all exercise sets and preserve other cached workouts',
          () async {
            final workout1 = Workout(
              id: 'workout1',
              name: 'Test Workout',
              exercises: const [],
              status: WorkoutStatus.template,
            );
            final workout2 = Workout(
              id: 'workout2',
              name: 'Keep Workout',
              exercises: const [],
              status: WorkoutStatus.template,
            );
            final exercises = [
              WorkoutExercise(
                id: 'exercise1',
                workoutId: 'workout1',
                exerciseSlug: 'bench-press',
                sets: const [],
              ),
              WorkoutExercise(
                id: 'exercise2',
                workoutId: 'workout1',
                exerciseSlug: 'squat',
                sets: const [],
              ),
            ];

            workoutService.workouts.addAll([workout1, workout2]);

            when(
              mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId('workout1'),
            ).thenAnswer((_) async => exercises);
            when(
              mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId(any),
            ).thenAnswer((_) async => 1);
            when(
              mockWorkoutExerciseDao.deleteWorkoutExercisesByWorkoutId(
                'workout1',
              ),
            ).thenAnswer((_) async => 1);
            when(
              mockWorkoutDao.deleteWorkout('workout1'),
            ).thenAnswer((_) async => 1);

            await workoutService.deleteWorkout('workout1');

            expect(workoutService.workouts.map((w) => w.id), ['workout2']);
            verify(
              mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId(
                'exercise1',
              ),
            ).called(1);
            verify(
              mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId(
                'exercise2',
              ),
            ).called(1);
          },
        );
      });

      group('moveWorkoutToFolder', () {
        test('should move a cached workout to a folder', () async {
          final workout = Workout(
            id: 'workout1',
            name: 'Workout',
            exercises: const [],
            status: WorkoutStatus.template,
          );
          workoutService.workouts.add(workout);
          when(mockWorkoutDao.updateWorkout(any)).thenAnswer((_) async => 1);

          await workoutService.moveWorkoutToFolder('workout1', 'folder1');

          expect(workoutService.workouts.single.folderId, 'folder1');
          verify(mockWorkoutDao.updateWorkout(any)).called(1);
        });

        test('should do nothing when moving a missing workout', () async {
          await workoutService.moveWorkoutToFolder('missing', 'folder1');

          verifyNever(mockWorkoutDao.updateWorkout(any));
        });
      });

      group('reorderWorkoutsInFolder', () {
        test(
          'should reorder workouts in a folder and persist order indexes',
          () async {
            final first = Workout(
              id: 'workout1',
              name: 'Workout 1',
              exercises: const [],
              folderId: 'folder1',
              orderIndex: 0,
              status: WorkoutStatus.template,
            );
            final second = Workout(
              id: 'workout2',
              name: 'Workout 2',
              exercises: const [],
              folderId: 'folder1',
              orderIndex: 1,
              status: WorkoutStatus.template,
            );
            workoutService.workouts.addAll([first, second]);
            when(mockWorkoutDao.updateWorkout(any)).thenAnswer((_) async => 1);

            await workoutService.reorderWorkoutsInFolder('folder1', 0, 1);

            expect(
              workoutService
                  .getWorkoutsInFolder('folder1')
                  .map((w) => w.id)
                  .toList(),
              ['workout2', 'workout1'],
            );
            expect(workoutService.getWorkoutById('workout2')?.orderIndex, 0);
            expect(workoutService.getWorkoutById('workout1')?.orderIndex, 1);
            verify(mockWorkoutDao.updateWorkout(any)).called(2);
          },
        );

        test('should ignore invalid workout reorder indices', () async {
          final workout = Workout(
            id: 'workout1',
            name: 'Workout 1',
            exercises: const [],
            folderId: 'folder1',
            orderIndex: 0,
            status: WorkoutStatus.template,
          );
          workoutService.workouts.add(workout);

          await workoutService.reorderWorkoutsInFolder('folder1', 0, 2);

          verifyNever(mockWorkoutDao.updateWorkout(any));
          expect(
            workoutService.getWorkoutsInFolder('folder1').single.id,
            'workout1',
          );
        });
      });

      group('reorderExercisesInWorkout', () {
        test('should reorder exercises in workout successfully', () async {
          // Arrange
          final exercise1 = WorkoutExercise(
            id: 'exercise1',
            workoutId: 'workout1',
            exerciseSlug: 'bench-press',
            sets: [],
            orderIndex: 0,
          );
          final exercise2 = WorkoutExercise(
            id: 'exercise2',
            workoutId: 'workout1',
            exerciseSlug: 'squat',
            sets: [],
            orderIndex: 1,
          );

          final workout = Workout(
            id: 'workout1',
            name: 'Test Workout',
            exercises: [exercise1, exercise2],
            status: WorkoutStatus.template,
          );

          workoutService.workouts.add(workout);

          when(
            mockWorkoutExerciseDao.updateWorkoutExercise(any),
          ).thenAnswer((_) async => 1);
          when(mockWorkoutDao.updateWorkout(any)).thenAnswer((_) async => 1);

          // Act
          await workoutService.reorderExercisesInWorkout('workout1', 0, 1);

          // Assert
          expect(
            workoutService.workouts.first.exercises.first.exerciseSlug,
            'squat',
          );
          expect(
            workoutService.workouts.first.exercises.last.exerciseSlug,
            'bench-press',
          );
          verify(mockWorkoutExerciseDao.updateWorkoutExercise(any)).called(2);
          verify(mockWorkoutDao.updateWorkout(any)).called(1);
        });

        test('should handle workout not found', () async {
          // Act
          await workoutService.reorderExercisesInWorkout('nonexistent', 0, 1);

          // Assert
          verifyNever(mockWorkoutExerciseDao.updateWorkoutExercise(any));
          verifyNever(mockWorkoutDao.updateWorkout(any));
        });

        test('should ignore invalid exercise reorder indices', () async {
          final workout = Workout(
            id: 'workout1',
            name: 'Test Workout',
            exercises: [
              WorkoutExercise(
                id: 'exercise1',
                workoutId: 'workout1',
                exerciseSlug: 'bench-press',
                sets: const [],
              ),
            ],
            status: WorkoutStatus.template,
          );
          workoutService.workouts.add(workout);

          await workoutService.reorderExercisesInWorkout('workout1', 0, 2);

          verifyNever(mockWorkoutExerciseDao.updateWorkoutExercise(any));
          verifyNever(mockWorkoutDao.updateWorkout(any));
        });
      });
    });

    group('Exercise Operations', () {
      group('addExerciseToWorkout', () {
        test('should add exercise to workout successfully', () async {
          // Arrange
          final workout = Workout(
            id: 'workout1',
            name: 'Test Workout',
            exercises: [],
            status: WorkoutStatus.template,
          );
          workoutService.workouts.add(workout);

          final exercise = Exercise(
            slug: 'bench-press',
            name: 'Bench Press',
            primaryMuscleGroup: MuscleGroup.chest,
            secondaryMuscleGroups: [],
            instructions: [],
            image: 'bench-press.jpg',
            animation: 'bench-press.gif',
          );

          when(mockWorkoutExerciseDao.insert(any)).thenAnswer((_) async => 1);
          when(mockWorkoutSetDao.insert(any)).thenAnswer((_) async => 1);
          when(mockWorkoutDao.updateWorkout(any)).thenAnswer((_) async => 1);

          // Act
          await workoutService.addExerciseToWorkout('workout1', exercise);

          // Assert
          expect(workoutService.workouts.first.exercises.length, 1);
          expect(
            workoutService.workouts.first.exercises.first.exerciseSlug,
            'bench-press',
          );
          expect(workoutService.workouts.first.exercises.first.sets.length, 1);
          verify(mockWorkoutExerciseDao.insert(any)).called(1);
          verify(mockWorkoutSetDao.insert(any)).called(1);
          verify(mockWorkoutDao.updateWorkout(any)).called(1);
        });

        test('should handle workout not found', () async {
          // Arrange
          final exercise = Exercise(
            slug: 'bench-press',
            name: 'Bench Press',
            primaryMuscleGroup: MuscleGroup.chest,
            secondaryMuscleGroups: [],
            instructions: [],
            image: 'bench-press.jpg',
            animation: 'bench-press.gif',
          );

          // Act
          await workoutService.addExerciseToWorkout('nonexistent', exercise);

          // Assert
          verifyNever(mockWorkoutExerciseDao.insert(any));
          verifyNever(mockWorkoutSetDao.insert(any));
          verifyNever(mockWorkoutDao.updateWorkout(any));
        });
      });

      group('removeExerciseFromWorkout', () {
        test('should remove exercise from workout successfully', () async {
          // Arrange
          final exercise = WorkoutExercise(
            id: 'exercise1',
            workoutId: 'workout1',
            exerciseSlug: 'bench-press',
            sets: [],
          );
          final workout = Workout(
            id: 'workout1',
            name: 'Test Workout',
            exercises: [exercise],
            status: WorkoutStatus.template,
          );
          workoutService.workouts.add(workout);

          when(
            mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId('exercise1'),
          ).thenAnswer((_) async => 1);
          when(
            mockWorkoutExerciseDao.deleteWorkoutExercise('exercise1'),
          ).thenAnswer((_) async => 1);
          when(mockWorkoutDao.updateWorkout(any)).thenAnswer((_) async => 1);

          // Act
          await workoutService.removeExerciseFromWorkout(
            'workout1',
            'exercise1',
          );

          // Assert
          expect(workoutService.workouts.first.exercises, isEmpty);
          verify(
            mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId('exercise1'),
          ).called(1);
          verify(
            mockWorkoutExerciseDao.deleteWorkoutExercise('exercise1'),
          ).called(1);
          verify(mockWorkoutDao.updateWorkout(any)).called(1);
        });

        test(
          'should do nothing when removing an exercise from a missing workout',
          () async {
            await workoutService.removeExerciseFromWorkout(
              'missing',
              'exercise1',
            );

            verifyNever(
              mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId(any),
            );
            verifyNever(mockWorkoutExerciseDao.deleteWorkoutExercise(any));
            verifyNever(mockWorkoutDao.updateWorkout(any));
          },
        );
      });

      group('updateWorkoutExercise', () {
        test('should update workout exercise successfully', () async {
          // Arrange
          final exercise = WorkoutExercise(
            id: 'exercise1',
            workoutId: 'workout1',
            exerciseSlug: 'bench-press',
            sets: [],
          );
          final workout = Workout(
            id: 'workout1',
            name: 'Test Workout',
            exercises: [exercise],
            status: WorkoutStatus.template,
          );
          workoutService.workouts.add(workout);

          final updatedExercise = exercise.copyWith(
            exerciseSlug: 'incline-bench-press',
          );

          when(
            mockWorkoutExerciseDao.updateWorkoutExercise(updatedExercise),
          ).thenAnswer((_) async => 1);
          when(mockWorkoutDao.updateWorkout(any)).thenAnswer((_) async => 1);

          // Act
          await workoutService.updateWorkoutExercise(
            'workout1',
            updatedExercise,
          );

          // Assert
          expect(
            workoutService.workouts.first.exercises.first.exerciseSlug,
            'incline-bench-press',
          );
          verify(
            mockWorkoutExerciseDao.updateWorkoutExercise(updatedExercise),
          ).called(1);
          verify(mockWorkoutDao.updateWorkout(any)).called(1);
        });

        test(
          'should do nothing when updating an exercise for a missing workout',
          () async {
            final exercise = WorkoutExercise(
              id: 'exercise1',
              workoutId: 'workout1',
              exerciseSlug: 'bench-press',
              sets: const [],
            );

            await workoutService.updateWorkoutExercise('missing', exercise);

            verifyNever(mockWorkoutExerciseDao.updateWorkoutExercise(any));
            verifyNever(mockWorkoutDao.updateWorkout(any));
          },
        );
      });
    });

    group('Set Operations', () {
      group('addSetToExercise', () {
        test('should add set to exercise successfully', () async {
          // Arrange
          final exercise = WorkoutExercise(
            id: 'exercise1',
            workoutId: 'workout1',
            exerciseSlug: 'bench-press',
            sets: [],
          );
          final workout = Workout(
            id: 'workout1',
            name: 'Test Workout',
            exercises: [exercise],
            status: WorkoutStatus.template,
          );
          workoutService.workouts.add(workout);

          when(mockWorkoutSetDao.insert(any)).thenAnswer((_) async => 1);
          when(
            mockWorkoutExerciseDao.updateWorkoutExercise(any),
          ).thenAnswer((_) async => 1);
          when(mockWorkoutDao.updateWorkout(any)).thenAnswer((_) async => 1);

          // Act
          await workoutService.addSetToExercise(
            'workout1',
            'exercise1',
            targetReps: 12,
            targetWeight: 50.0,
          );

          // Assert
          expect(workoutService.workouts.first.exercises.first.sets.length, 1);
          expect(
            workoutService.workouts.first.exercises.first.sets.first.targetReps,
            12,
          );
          expect(
            workoutService
                .workouts
                .first
                .exercises
                .first
                .sets
                .first
                .targetWeight,
            50.0,
          );
          verify(mockWorkoutSetDao.insert(any)).called(1);
        });

        test(
          'should do nothing when the exercise is missing while adding a set',
          () async {
            final workout = Workout(
              id: 'workout1',
              name: 'Test Workout',
              exercises: const [],
              status: WorkoutStatus.template,
            );
            workoutService.workouts.add(workout);

            await workoutService.addSetToExercise(
              'workout1',
              'missing-exercise',
            );

            verifyNever(mockWorkoutSetDao.insert(any));
            verifyNever(mockWorkoutExerciseDao.updateWorkoutExercise(any));
            verifyNever(mockWorkoutDao.updateWorkout(any));
          },
        );
      });

      group('removeSetFromExercise', () {
        test('should remove set from exercise successfully', () async {
          // Arrange
          final set = WorkoutSet(
            id: 'set1',
            workoutExerciseId: 'exercise1',
            setIndex: 0,
            targetReps: 10,
            targetWeight: 100.0,
          );
          final exercise = WorkoutExercise(
            id: 'exercise1',
            workoutId: 'workout1',
            exerciseSlug: 'bench-press',
            sets: [set],
          );
          final workout = Workout(
            id: 'workout1',
            name: 'Test Workout',
            exercises: [exercise],
            status: WorkoutStatus.template,
          );
          workoutService.workouts.add(workout);

          when(
            mockWorkoutSetDao.deleteWorkoutSet('set1'),
          ).thenAnswer((_) async => 1);
          when(
            mockWorkoutExerciseDao.updateWorkoutExercise(any),
          ).thenAnswer((_) async => 1);
          when(mockWorkoutDao.updateWorkout(any)).thenAnswer((_) async => 1);

          // Act
          await workoutService.removeSetFromExercise(
            'workout1',
            'exercise1',
            'set1',
          );

          // Assert
          expect(workoutService.workouts.first.exercises.first.sets, isEmpty);
          verify(mockWorkoutSetDao.deleteWorkoutSet('set1')).called(1);
        });

        test(
          'should do nothing when removing a set from a missing exercise',
          () async {
            final workout = Workout(
              id: 'workout1',
              name: 'Test Workout',
              exercises: const [],
              status: WorkoutStatus.template,
            );
            workoutService.workouts.add(workout);

            await workoutService.removeSetFromExercise(
              'workout1',
              'missing-exercise',
              'set1',
            );

            verifyNever(mockWorkoutSetDao.deleteWorkoutSet(any));
            verifyNever(mockWorkoutExerciseDao.updateWorkoutExercise(any));
            verifyNever(mockWorkoutDao.updateWorkout(any));
          },
        );
      });

      group('updateSet', () {
        test('should update set successfully', () async {
          // Arrange
          final set = WorkoutSet(
            id: 'set1',
            workoutExerciseId: 'exercise1',
            setIndex: 0,
            targetReps: 10,
            targetWeight: 100.0,
          );
          final exercise = WorkoutExercise(
            id: 'exercise1',
            workoutId: 'workout1',
            exerciseSlug: 'bench-press',
            sets: [set],
          );
          final workout = Workout(
            id: 'workout1',
            name: 'Test Workout',
            exercises: [exercise],
            status: WorkoutStatus.template,
          );
          workoutService.workouts.add(workout);

          when(
            mockWorkoutSetDao.updateWorkoutSet(any),
          ).thenAnswer((_) async => 1);
          when(
            mockWorkoutExerciseDao.updateWorkoutExercise(any),
          ).thenAnswer((_) async => 1);
          when(mockWorkoutDao.updateWorkout(any)).thenAnswer((_) async => 1);

          // Act
          await workoutService.updateSet(
            'workout1',
            'exercise1',
            'set1',
            targetReps: 12,
            targetWeight: 110.0,
            targetRestSeconds: 90,
          );

          // Assert
          final updatedSet =
              workoutService.workouts.first.exercises.first.sets.first;
          expect(updatedSet.targetReps, 12);
          expect(updatedSet.targetWeight, 110.0);
          expect(updatedSet.targetRestSeconds, 90);
          verify(mockWorkoutSetDao.updateWorkoutSet(any)).called(1);
        });

        test(
          'should preserve existing set values when partial updates are omitted',
          () async {
            final set = WorkoutSet(
              id: 'set1',
              workoutExerciseId: 'exercise1',
              setIndex: 0,
              targetReps: 10,
              targetWeight: 100.0,
              targetRestSeconds: 60,
            );
            final exercise = WorkoutExercise(
              id: 'exercise1',
              workoutId: 'workout1',
              exerciseSlug: 'bench-press',
              sets: [set],
            );
            final workout = Workout(
              id: 'workout1',
              name: 'Test Workout',
              exercises: [exercise],
              status: WorkoutStatus.template,
            );
            workoutService.workouts.add(workout);

            when(
              mockWorkoutSetDao.updateWorkoutSet(any),
            ).thenAnswer((_) async => 1);
            when(
              mockWorkoutExerciseDao.updateWorkoutExercise(any),
            ).thenAnswer((_) async => 1);
            when(mockWorkoutDao.updateWorkout(any)).thenAnswer((_) async => 1);

            await workoutService.updateSet(
              'workout1',
              'exercise1',
              'set1',
              targetReps: 12,
            );

            final updatedSet =
                workoutService.workouts.first.exercises.first.sets.first;
            expect(updatedSet.targetReps, 12);
            expect(updatedSet.targetWeight, 100.0);
            expect(updatedSet.targetRestSeconds, 60);
          },
        );

        test(
          'should do nothing when the set is missing during update',
          () async {
            final exercise = WorkoutExercise(
              id: 'exercise1',
              workoutId: 'workout1',
              exerciseSlug: 'bench-press',
              sets: const [],
            );
            final workout = Workout(
              id: 'workout1',
              name: 'Test Workout',
              exercises: [exercise],
              status: WorkoutStatus.template,
            );
            workoutService.workouts.add(workout);

            await workoutService.updateSet(
              'workout1',
              'exercise1',
              'missing-set',
              targetReps: 12,
            );

            verifyNever(mockWorkoutSetDao.updateWorkoutSet(any));
            verifyNever(mockWorkoutExerciseDao.updateWorkoutExercise(any));
            verifyNever(mockWorkoutDao.updateWorkout(any));
          },
        );
      });
    });

    group('Helper Methods', () {
      group('getWorkoutsInFolder', () {
        test('should return workouts in a folder sorted by orderIndex', () {
          workoutService.workouts.addAll([
            Workout(
              id: 'root',
              name: 'Root Workout',
              exercises: const [],
              orderIndex: 5,
              status: WorkoutStatus.template,
            ),
            Workout(
              id: 'second',
              name: 'Second Workout',
              exercises: const [],
              folderId: 'folder1',
              orderIndex: 1,
              status: WorkoutStatus.template,
            ),
            Workout(
              id: 'first',
              name: 'First Workout',
              exercises: const [],
              folderId: 'folder1',
              orderIndex: 0,
              status: WorkoutStatus.template,
            ),
          ]);

          expect(
            workoutService
                .getWorkoutsInFolder('folder1')
                .map((w) => w.id)
                .toList(),
            ['first', 'second'],
          );
          expect(
            workoutService.getWorkoutsNotInFolder().map((w) => w.id).toList(),
            ['root'],
          );
        });
      });

      group('getWorkoutById', () {
        test('should return workout when found', () {
          // Arrange
          final workout = Workout(
            id: 'workout1',
            name: 'Test Workout',
            exercises: [],
            status: WorkoutStatus.template,
          );
          workoutService.workouts.add(workout);

          // Act
          final result = workoutService.getWorkoutById('workout1');

          // Assert
          expect(result, isNotNull);
          expect(result!.id, 'workout1');
        });

        test('should return null when not found', () {
          // Act
          final result = workoutService.getWorkoutById('nonexistent');

          // Assert
          expect(result, isNull);
        });
      });

      group('clearUserWorkouts', () {
        test('should clear all user workouts', () async {
          // Arrange
          final workout = Workout(
            id: 'workout1',
            name: 'Test Workout',
            exercises: [],
            status: WorkoutStatus.inProgress,
          );

          workoutService.workouts.add(workout);

          when(
            mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId(any),
          ).thenAnswer((_) async => 1);
          when(
            mockWorkoutExerciseDao.deleteWorkoutExercisesByWorkoutId(any),
          ).thenAnswer((_) async => 1);
          when(mockWorkoutDao.deleteWorkout(any)).thenAnswer((_) async => 1);

          // Act
          await workoutService.clearUserWorkouts();

          // Assert
          expect(workoutService.workouts, isEmpty);
        });
      });
    });
  });
}
