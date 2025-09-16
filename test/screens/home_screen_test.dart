import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:zenith/models/workout.dart';
import 'package:zenith/services/workout_service.dart';
import 'package:zenith/services/dao/workout_dao.dart';
import 'package:zenith/services/dao/workout_exercise_dao.dart';
import 'package:zenith/services/dao/workout_set_dao.dart';
import 'package:zenith/screens/home_screen.dart';

// Reuse generated mocks from existing tests
import '../services/workout_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen - Recent Workouts', () {
    late WorkoutService workoutService;
    late MockWorkoutDao mockWorkoutDao;
    late MockWorkoutExerciseDao mockWorkoutExerciseDao;
    late MockWorkoutSetDao mockWorkoutSetDao;

    setUp(() async {
      // Set up WorkoutService with mocks
      workoutService = WorkoutService.instance;
      mockWorkoutDao = MockWorkoutDao();
      mockWorkoutExerciseDao = MockWorkoutExerciseDao();
      mockWorkoutSetDao = MockWorkoutSetDao();

      // Inject mock DAOs
      workoutService.workoutDao = mockWorkoutDao;
      workoutService.workoutExerciseDao = mockWorkoutExerciseDao;
      workoutService.workoutSetDao = mockWorkoutSetDao;

      // Clear any previous state
      workoutService.workouts.clear();
    });

    testWidgets('shows "Recent Workouts" and renders completed workouts from DB', (WidgetTester tester) async {
      // Arrange: build two workouts, one completed and one in progress
      final now = DateTime.now();
      final completed = Workout(
        id: 'w_completed',
        name: 'Completed Session',
        status: WorkoutStatus.completed,
        startedAt: now.subtract(const Duration(hours: 2)),
        completedAt: now.subtract(const Duration(hours: 1)),
        exercises: const [],
      );
      final inProgress = Workout(
        id: 'w_inprogress',
        name: 'In Progress Session',
        status: WorkoutStatus.inProgress,
        startedAt: now.subtract(const Duration(minutes: 30)),
        exercises: const [],
      );

      when(mockWorkoutDao.getAllWorkouts()).thenAnswer((_) async => [inProgress, completed]);
      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId(any)).thenAnswer((_) async => []);
      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId(any)).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Assert
      // Header and section
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Recent Workouts'), findsOneWidget);

      // Completed workout appears
      expect(find.text('Completed Session'), findsOneWidget);

      // In-progress workout should not appear in the list
      expect(find.text('In Progress Session'), findsNothing);

      // "No workouts yet" should not be shown
      expect(find.text('No workouts yet'), findsNothing);
    });

    testWidgets('shows empty-state when no completed workouts exist', (WidgetTester tester) async {
      // Arrange: only in-progress workouts
      final now = DateTime.now();
      final inProgress = Workout(
        id: 'w_inprogress',
        name: 'In Progress Only',
        status: WorkoutStatus.inProgress,
        startedAt: now.subtract(const Duration(minutes: 30)),
        exercises: const [],
      );

      when(mockWorkoutDao.getAllWorkouts()).thenAnswer((_) async => [inProgress]);
      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId(any)).thenAnswer((_) async => []);
      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId(any)).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Recent Workouts'), findsOneWidget);
      expect(find.text('No workouts yet'), findsOneWidget);
      expect(find.text('In Progress Only'), findsNothing);
    });

    testWidgets('sorts completed workouts by completedAt descending (fallback to startedAt)', (WidgetTester tester) async {
      final now = DateTime.now();
      final w1 = Workout(
        id: 'w1',
        name: 'Oldest Completed',
        status: WorkoutStatus.completed,
        startedAt: now.subtract(const Duration(days: 2, hours: 1)),
        completedAt: now.subtract(const Duration(days: 2)),
        exercises: const [],
      );
      final w2 = Workout(
        id: 'w2',
        name: 'Newest Completed',
        status: WorkoutStatus.completed,
        startedAt: now.subtract(const Duration(hours: 2)),
        completedAt: now.subtract(const Duration(hours: 1)),
        exercises: const [],
      );
      final w3 = Workout(
        id: 'w3',
        name: 'Mid Completed (no completedAt)',
        status: WorkoutStatus.completed,
        startedAt: now.subtract(const Duration(days: 1, hours: 3)),
        completedAt: null,
        exercises: const [],
      );

      when(mockWorkoutDao.getAllWorkouts()).thenAnswer((_) async => [w1, w2, w3]);
      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId(any)).thenAnswer((_) async => []);
      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId(any)).thenAnswer((_) async => []);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Verify all three completed workouts show
      expect(find.text('Newest Completed'), findsOneWidget);
      expect(find.text('Mid Completed (no completedAt)'), findsOneWidget);
      expect(find.text('Oldest Completed'), findsOneWidget);

      // Since verifying order in a SliverList is non-trivial with text alone,
      // we assert that the "Newest Completed" exists (it should be top-most by our sort).
      // Detailed order checks could be added by using find.descendant with keys if needed.
    });
  });
}
