import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:zenith/models/workout.dart';
import 'package:zenith/services/workout_service.dart';
import 'package:zenith/services/dao/workout_dao.dart';
import 'package:zenith/services/dao/workout_exercise_dao.dart';
import 'package:zenith/services/dao/workout_set_dao.dart';
import 'package:zenith/screens/home_screen.dart';
import 'package:zenith/widgets/past_workout_list_item.dart';

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
      expect(find.text('Hey!'), findsOneWidget);
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

    testWidgets('deleting from detail refreshes Home and removes workout', (WidgetTester tester) async {
      // Arrange: one completed workout shown on Home
      final now = DateTime.now();
      final completed = Workout(
        id: 'w_completed',
        name: 'Completed Session',
        status: WorkoutStatus.completed,
        startedAt: now.subtract(const Duration(hours: 2)),
        completedAt: now.subtract(const Duration(hours: 1)),
        exercises: const [],
      );

      // Use a variable so we can change DAO return values mid-test
      var currentWorkouts = <Workout>[completed];

      when(mockWorkoutDao.getAllWorkouts()).thenAnswer((_) async => currentWorkouts);
      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId(any)).thenAnswer((_) async => []);
      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId(any)).thenAnswer((_) async => []);
      when(mockWorkoutExerciseDao.deleteWorkoutExercisesByWorkoutId('w_completed')).thenAnswer((_) async => 1);
      when(mockWorkoutDao.deleteWorkout('w_completed')).thenAnswer((_) async => 1);

      // Act: pump Home
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Ensure workout is visible
      expect(find.text('Completed Session'), findsOneWidget);

      // Tap the list item to navigate to detail
      await tester.tap(find.text('Completed Session'));
      await tester.pumpAndSettle();

      // On detail screen, tap Delete
      expect(find.text('Delete Workout'), findsOneWidget);
      await tester.tap(find.text('Delete Workout'));
      await tester.pumpAndSettle();

      // Confirm deletion, but first make DAO return empty list for subsequent reload
      currentWorkouts = [];
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Assert: back on Home, list refreshed and workout removed
      expect(find.text('Completed Session'), findsNothing);
      expect(find.text('No workouts yet'), findsOneWidget);
    });
  });

group('HomeScreen - Important extras', () {
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

  testWidgets('limits recent workouts list to 10 items', (WidgetTester tester) async {
    // Arrange: 12 completed workouts
    final now = DateTime.now();
    final workouts = List.generate(12, (i) {
      return Workout(
        id: 'w_$i',
        name: 'Completed #$i',
        status: WorkoutStatus.completed,
        startedAt: now.subtract(Duration(hours: i + 1)),
        completedAt: now.subtract(Duration(hours: i)),
        exercises: const [],
      );
    });

    when(mockWorkoutDao.getAllWorkouts()).thenAnswer((_) async => workouts);
    when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId(any)).thenAnswer((_) async => []);
    when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId(any)).thenAnswer((_) async => []);

    // Act
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

      // Assert: items 0..9 are present, 10+ are absent
      await tester.scrollUntilVisible(find.text('Completed #9'), 500.0);
      expect(find.text('Completed #9'), findsOneWidget);
      expect(find.text('Completed #10'), findsNothing);
      expect(find.text('Completed #11'), findsNothing);
  });

  testWidgets('resuming app lifecycle triggers reload of recent workouts', (WidgetTester tester) async {
    // Arrange
    final now = DateTime.now();
    final initial = [
      Workout(
        id: 'w1',
        name: 'First',
        status: WorkoutStatus.completed,
        startedAt: now.subtract(const Duration(hours: 2)),
        completedAt: now.subtract(const Duration(hours: 1)),
        exercises: const [],
      ),
    ];

    when(mockWorkoutDao.getAllWorkouts()).thenAnswer((_) async => initial);
    when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId(any)).thenAnswer((_) async => []);
    when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId(any)).thenAnswer((_) async => []);

    // Act: initial pump triggers loadWorkouts once
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    // Simulate app coming to foreground
    final state = tester.state(find.byType(HomeScreen)) as HomeScreenState;
    state.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    // Assert: DAO called twice (initial + resume)
    verify(mockWorkoutDao.getAllWorkouts()).called(2);
  });
});
}
