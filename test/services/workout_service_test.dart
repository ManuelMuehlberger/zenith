import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/services/workout_service.dart';
import 'package:zenith/services/dao/workout_dao.dart';
import 'package:zenith/services/dao/workout_exercise_dao.dart';
import 'package:zenith/services/dao/workout_set_dao.dart';

// Generate mocks
@GenerateMocks([
  WorkoutDao,
  WorkoutExerciseDao,
  WorkoutSetDao,
])
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
        when(mockWorkoutDao.getAllWorkouts())
            .thenAnswer((_) async => mockWorkouts);
        when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId('workout1'))
            .thenAnswer((_) async => mockExercises);
        when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId('exercise1'))
            .thenAnswer((_) async => mockSets);

        // Act
        await workoutService.loadData();

        // Assert
        expect(workoutService.workouts.length, 1);
        expect(workoutService.workouts.first.exercises.length, 1);
        expect(workoutService.workouts.first.exercises.first.sets.length, 1);
      });

      test('should handle load data errors gracefully', () async {
        // Arrange
        when(mockWorkoutDao.getAllWorkouts())
            .thenThrow(Exception('Database error'));

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
          
          when(mockWorkoutDao.insert(any))
              .thenAnswer((_) async => 1);

          // Act
          final result = await workoutService.createWorkout(workoutName);

          // Assert
          expect(result.name, workoutName);
          expect(result.status, WorkoutStatus.template);
          expect(workoutService.workouts.contains(result), true);
          verify(mockWorkoutDao.insert(any)).called(1);
        });
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
          
          when(mockWorkoutDao.updateWorkout(updatedWorkout))
              .thenAnswer((_) async => 1);

          // Act
          await workoutService.updateWorkout(updatedWorkout);

          // Assert
          expect(workoutService.workouts.first.name, 'Updated Name');
          verify(mockWorkoutDao.updateWorkout(updatedWorkout)).called(1);
        });
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
          
          when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId('workout1'))
              .thenAnswer((_) async => [exercise]);
          when(mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId('exercise1'))
              .thenAnswer((_) async => 1);
          when(mockWorkoutExerciseDao.deleteWorkoutExercisesByWorkoutId('workout1'))
              .thenAnswer((_) async => 1);
          when(mockWorkoutDao.deleteWorkout('workout1'))
              .thenAnswer((_) async => 1);

          // Act
          await workoutService.deleteWorkout('workout1');

          // Assert
          expect(workoutService.workouts, isEmpty);
          verify(mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId('exercise1')).called(1);
          verify(mockWorkoutExerciseDao.deleteWorkoutExercisesByWorkoutId('workout1')).called(1);
          verify(mockWorkoutDao.deleteWorkout('workout1')).called(1);
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
          
          when(mockWorkoutExerciseDao.updateWorkoutExercise(any))
              .thenAnswer((_) async => 1);
          when(mockWorkoutDao.updateWorkout(any))
              .thenAnswer((_) async => 1);

          // Act
          await workoutService.reorderExercisesInWorkout('workout1', 0, 1);

          // Assert
          expect(workoutService.workouts.first.exercises.first.exerciseSlug, 'squat');
          expect(workoutService.workouts.first.exercises.last.exerciseSlug, 'bench-press');
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
          
          when(mockWorkoutExerciseDao.insert(any))
              .thenAnswer((_) async => 1);
          when(mockWorkoutSetDao.insert(any))
              .thenAnswer((_) async => 1);
          when(mockWorkoutDao.updateWorkout(any))
              .thenAnswer((_) async => 1);

          // Act
          await workoutService.addExerciseToWorkout('workout1', exercise);

          // Assert
          expect(workoutService.workouts.first.exercises.length, 1);
          expect(workoutService.workouts.first.exercises.first.exerciseSlug, 'bench-press');
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
          
          when(mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId('exercise1'))
              .thenAnswer((_) async => 1);
          when(mockWorkoutExerciseDao.deleteWorkoutExercise('exercise1'))
              .thenAnswer((_) async => 1);
          when(mockWorkoutDao.updateWorkout(any))
              .thenAnswer((_) async => 1);

          // Act
          await workoutService.removeExerciseFromWorkout('workout1', 'exercise1');

          // Assert
          expect(workoutService.workouts.first.exercises, isEmpty);
          verify(mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId('exercise1')).called(1);
          verify(mockWorkoutExerciseDao.deleteWorkoutExercise('exercise1')).called(1);
          verify(mockWorkoutDao.updateWorkout(any)).called(1);
        });
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
          
          final updatedExercise = exercise.copyWith(exerciseSlug: 'incline-bench-press');
          
          when(mockWorkoutExerciseDao.updateWorkoutExercise(updatedExercise))
              .thenAnswer((_) async => 1);
          when(mockWorkoutDao.updateWorkout(any))
              .thenAnswer((_) async => 1);

          // Act
          await workoutService.updateWorkoutExercise('workout1', updatedExercise);

          // Assert
          expect(workoutService.workouts.first.exercises.first.exerciseSlug, 'incline-bench-press');
          verify(mockWorkoutExerciseDao.updateWorkoutExercise(updatedExercise)).called(1);
          verify(mockWorkoutDao.updateWorkout(any)).called(1);
        });
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
          
          when(mockWorkoutSetDao.insert(any))
              .thenAnswer((_) async => 1);
          when(mockWorkoutExerciseDao.updateWorkoutExercise(any))
              .thenAnswer((_) async => 1);
          when(mockWorkoutDao.updateWorkout(any))
              .thenAnswer((_) async => 1);

          // Act
          await workoutService.addSetToExercise('workout1', 'exercise1', targetReps: 12, targetWeight: 50.0);

          // Assert
          expect(workoutService.workouts.first.exercises.first.sets.length, 1);
          expect(workoutService.workouts.first.exercises.first.sets.first.targetReps, 12);
          expect(workoutService.workouts.first.exercises.first.sets.first.targetWeight, 50.0);
          verify(mockWorkoutSetDao.insert(any)).called(1);
        });
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
          
          when(mockWorkoutSetDao.deleteWorkoutSet('set1'))
              .thenAnswer((_) async => 1);
          when(mockWorkoutExerciseDao.updateWorkoutExercise(any))
              .thenAnswer((_) async => 1);
          when(mockWorkoutDao.updateWorkout(any))
              .thenAnswer((_) async => 1);

          // Act
          await workoutService.removeSetFromExercise('workout1', 'exercise1', 'set1');

          // Assert
          expect(workoutService.workouts.first.exercises.first.sets, isEmpty);
          verify(mockWorkoutSetDao.deleteWorkoutSet('set1')).called(1);
        });
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
          
          when(mockWorkoutSetDao.updateWorkoutSet(any))
              .thenAnswer((_) async => 1);
          when(mockWorkoutExerciseDao.updateWorkoutExercise(any))
              .thenAnswer((_) async => 1);
          when(mockWorkoutDao.updateWorkout(any))
              .thenAnswer((_) async => 1);

          // Act
          await workoutService.updateSet('workout1', 'exercise1', 'set1', 
              targetReps: 12, targetWeight: 110.0, targetRestSeconds: 90);

          // Assert
          final updatedSet = workoutService.workouts.first.exercises.first.sets.first;
          expect(updatedSet.targetReps, 12);
          expect(updatedSet.targetWeight, 110.0);
          expect(updatedSet.targetRestSeconds, 90);
          verify(mockWorkoutSetDao.updateWorkoutSet(any)).called(1);
        });
      });
    });

    group('Helper Methods', () {

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
          
          when(mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId(any))
              .thenAnswer((_) async => 1);
          when(mockWorkoutExerciseDao.deleteWorkoutExercisesByWorkoutId(any))
              .thenAnswer((_) async => 1);
          when(mockWorkoutDao.deleteWorkout(any))
              .thenAnswer((_) async => 1);

          // Act
          await workoutService.clearUserWorkouts();

          // Assert
          expect(workoutService.workouts, isEmpty);
        });
      });
    });
  });
}
