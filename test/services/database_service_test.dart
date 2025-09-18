import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/database_service.dart';
import 'package:zenith/services/workout_service.dart';
import 'package:zenith/services/dao/workout_dao.dart';
import 'package:zenith/services/dao/workout_exercise_dao.dart';
import 'package:zenith/services/dao/workout_set_dao.dart';

/* Use existing generated mocks from workout_service_test.mocks.dart to avoid new codegen */
import 'workout_service_test.mocks.dart';

void main() {
  late DatabaseService databaseService;
  late WorkoutService workoutService;

  late MockWorkoutDao mockWorkoutDao;
  late MockWorkoutExerciseDao mockWorkoutExerciseDao;
  late MockWorkoutSetDao mockWorkoutSetDao;

  setUp(() {
    // Reset in-memory and prefs before each test
    SharedPreferences.setMockInitialValues({});

    databaseService = DatabaseService.instance;
    workoutService = WorkoutService.instance;

    // Fresh mocks each test
    mockWorkoutDao = MockWorkoutDao();
    mockWorkoutExerciseDao = MockWorkoutExerciseDao();
    mockWorkoutSetDao = MockWorkoutSetDao();

    // Inject mocks into WorkoutService (so loadData() uses DAOs via these mocks)
    workoutService.workoutDao = mockWorkoutDao;
    workoutService.workoutExerciseDao = mockWorkoutExerciseDao;
    workoutService.workoutSetDao = mockWorkoutSetDao;

    // Clear in-memory cache
    workoutService.workouts.clear();
  });

  group('DatabaseService.getWorkouts (SQL-backed)', () {
    test('returns workouts loaded via WorkoutService and sorted by startedAt desc (nulls last)', () async {
      // Arrange: three workouts with different startedAt (one null)
      final w1 = Workout(
        id: 'w1',
        name: 'Workout 1',
        status: WorkoutStatus.completed,
        startedAt: DateTime(2023, 1, 1),
        exercises: const [],
      );
      final w2 = Workout(
        id: 'w2',
        name: 'Workout 2',
        status: WorkoutStatus.completed,
        startedAt: null, // should sort last
        exercises: const [],
      );
      final w3 = Workout(
        id: 'w3',
        name: 'Workout 3',
        status: WorkoutStatus.completed,
        startedAt: DateTime(2023, 2, 1),
        exercises: const [],
      );

      when(mockWorkoutDao.getAllWorkouts()).thenAnswer((_) async => [w1, w2, w3]);

      // Each workout has one exercise with one set
      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId('w1')).thenAnswer((_) async => [
            WorkoutExercise(id: 'e1', workoutId: 'w1', exerciseSlug: 'bench-press', sets: const []),
          ]);
      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId('w2')).thenAnswer((_) async => [
            WorkoutExercise(id: 'e2', workoutId: 'w2', exerciseSlug: 'squat', sets: const []),
          ]);
      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId('w3')).thenAnswer((_) async => [
            WorkoutExercise(id: 'e3', workoutId: 'w3', exerciseSlug: 'deadlift', sets: const []),
          ]);

      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId('e1')).thenAnswer((_) async => [
            WorkoutSet(id: 's1', workoutExerciseId: 'e1', setIndex: 0, targetReps: 10, targetWeight: 100),
          ]);
      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId('e2')).thenAnswer((_) async => [
            WorkoutSet(id: 's2', workoutExerciseId: 'e2', setIndex: 0, targetReps: 8, targetWeight: 120),
          ]);
      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId('e3')).thenAnswer((_) async => [
            WorkoutSet(id: 's3', workoutExerciseId: 'e3', setIndex: 0, targetReps: 5, targetWeight: 150),
          ]);

      // Act
      final result = await databaseService.getWorkouts();

      // Assert
      expect(result.length, 3);
      // Sorted by startedAt desc: w3 (Feb) -> w1 (Jan) -> w2 (null)
      expect(result.map((w) => w.id).toList(), ['w3', 'w1', 'w2']);

      // Exercises and sets are loaded via WorkoutService
      final w3Loaded = result.firstWhere((w) => w.id == 'w3');
      expect(w3Loaded.exercises.length, 1);
      expect(w3Loaded.exercises.first.sets.length, 1);

      verify(mockWorkoutDao.getAllWorkouts()).called(1);
      verify(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId(any)).called(3);
      verify(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId(any)).called(3);
    });

    test('returns empty list when DAO throws inside loadData()', () async {
      // Arrange
      when(mockWorkoutDao.getAllWorkouts()).thenThrow(Exception('db error'));

      // Act
      final result = await databaseService.getWorkouts();

      // Assert
      expect(result, isEmpty);
      verify(mockWorkoutDao.getAllWorkouts()).called(1);
    });

    test('returns empty list when there are no workouts', () async {
      // Arrange
      when(mockWorkoutDao.getAllWorkouts()).thenAnswer((_) async => []);

      // Act
      final result = await databaseService.getWorkouts();

      // Assert
      expect(result, isEmpty);
      verify(mockWorkoutDao.getAllWorkouts()).called(1);
      verifyNever(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId(any));
      verifyNever(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId(any));
    });
  });

  group('Active workout state', () {
    test('saveActiveWorkoutState and getActiveWorkoutState round-trip', () async {
      final state = {'id': 'active123', 'status': 'inProgress'};
      await DatabaseService.instance.saveActiveWorkoutState(state);
      final loaded = await DatabaseService.instance.getActiveWorkoutState();
      expect(loaded, isNotNull);
      expect(loaded!['id'], 'active123');
      expect(loaded['status'], 'inProgress');
    });

    test('clearActiveWorkoutState removes state', () async {
      await DatabaseService.instance.saveActiveWorkoutState({'foo': 'bar'});
      await DatabaseService.instance.clearActiveWorkoutState();
      final loaded = await DatabaseService.instance.getActiveWorkoutState();
      expect(loaded, isNull);
    });
  });

  group('App settings', () {
    test('getAppSettings returns defaults when none saved', () async {
      final settings = await DatabaseService.instance.getAppSettings();
      expect(settings['units'], 'metric');
      expect(settings['theme'], 'dark');
    });

    test('saveAppSettings persists and getAppSettings returns saved', () async {
      final saved = {'units': 'imperial', 'theme': 'light', 'custom': 1};
      await DatabaseService.instance.saveAppSettings(saved);
      final settings = await DatabaseService.instance.getAppSettings();
      expect(settings['units'], 'imperial');
      expect(settings['theme'], 'light');
      expect(settings['custom'], 1);
    });
  });

  group('getWorkoutsForDate and getDatesWithWorkouts', () {
    test('filters workouts by exact date and returns sorted unique dates', () async {
      // Arrange: 2 on May 10, 1 on May 11
      final w1 = Workout(id: 'a', name: 'A', status: WorkoutStatus.completed, startedAt: DateTime(2023, 5, 10), exercises: const []);
      final w2 = Workout(id: 'b', name: 'B', status: WorkoutStatus.completed, startedAt: DateTime(2023, 5, 10, 12), exercises: const []);
      final w3 = Workout(id: 'c', name: 'C', status: WorkoutStatus.completed, startedAt: DateTime(2023, 5, 11), exercises: const []);

      when(mockWorkoutDao.getAllWorkouts()).thenAnswer((_) async => [w1, w2, w3]);
      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId(any)).thenAnswer((_) async => []);
      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId(any)).thenAnswer((_) async => []);

      final list10 = await DatabaseService.instance.getWorkoutsForDate(DateTime(2023, 5, 10));
      expect(list10.length, 2);
      expect(list10.map((w) => w.id).toSet(), {'a', 'b'});

      final dates = await DatabaseService.instance.getDatesWithWorkouts();
      expect(dates.length, 2);
      expect(dates.first, DateTime(2023, 5, 10));
      expect(dates.last, DateTime(2023, 5, 11));
    });
  });

  group('getLastWorkoutForExercise', () {
    test('returns most recent workout containing the exercise', () async {
      final older = Workout(
        id: 'old',
        name: 'Old',
        status: WorkoutStatus.completed,
        startedAt: DateTime(2023, 1, 1),
        exercises: const [],
      );
      final newer = Workout(
        id: 'new',
        name: 'New',
        status: WorkoutStatus.completed,
        startedAt: DateTime(2023, 2, 1),
        exercises: const [],
      );

      when(mockWorkoutDao.getAllWorkouts()).thenAnswer((_) async => [older, newer]);

      // Only 'older' has some other exercise, 'newer' has the target
      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId('old')).thenAnswer((_) async => [
            WorkoutExercise(id: 'e_old', workoutId: 'old', exerciseSlug: 'squat', sets: const []),
          ]);
      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId('new')).thenAnswer((_) async => [
            WorkoutExercise(id: 'e_new', workoutId: 'new', exerciseSlug: 'bench-press', sets: const []),
          ]);

      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId(any)).thenAnswer((_) async => []);

      final result = await DatabaseService.instance.getLastWorkoutForExercise('bench-press');
      expect(result, isNotNull);
      expect(result!.id, 'new');
    });

    test('returns null when no workout contains exercise', () async {
      when(mockWorkoutDao.getAllWorkouts()).thenAnswer((_) async => [
            Workout(id: 'x', name: 'X', status: WorkoutStatus.completed, startedAt: DateTime(2023, 3, 1), exercises: const []),
          ]);
      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId(any)).thenAnswer((_) async => []);
      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId(any)).thenAnswer((_) async => []);
      final result = await DatabaseService.instance.getLastWorkoutForExercise('non-existent');
      expect(result, isNull);
    });
  });

  group('Data clearing', () {
    test('clearAllData removes workouts, settings, and active state', () async {
      // Seed prefs directly to simulate legacy data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('workouts', ['{}']);
      await prefs.setString('app_settings', '{"units":"imperial","theme":"light"}');
      await prefs.setString('active_workout', '{"id":"active"}');

      await DatabaseService.instance.clearAllData();

      expect(prefs.getStringList('workouts'), isNull);
      expect(prefs.getString('app_settings'), isNull);
      expect(prefs.getString('active_workout'), isNull);
    });
  });

  // Additional varied-data robustness tests
  group('Robustness and varied data', () {
    test('getAppSettings returns defaults on corrupt JSON', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_settings', '{invalid-json');
      final settings = await DatabaseService.instance.getAppSettings();
      expect(settings['units'], 'metric');
      expect(settings['theme'], 'dark');
    });

    test('getActiveWorkoutState returns null on corrupt JSON', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_workout', '{invalid-json');
      final state = await DatabaseService.instance.getActiveWorkoutState();
      expect(state, isNull);
    });

    test('getDatesWithWorkouts ignores null startedAt and deduplicates dates', () async {
      final d1a = Workout(
        id: 'd1a',
        name: 'D1 Morning',
        status: WorkoutStatus.completed,
        startedAt: DateTime(2024, 1, 1, 8, 30),
        exercises: const [],
      );
      final d1b = Workout(
        id: 'd1b',
        name: 'D1 Evening',
        status: WorkoutStatus.completed,
        startedAt: DateTime(2024, 1, 1, 20, 0),
        exercises: const [],
      );
      final dNull = Workout(
        id: 'dn',
        name: 'No Date',
        status: WorkoutStatus.completed,
        startedAt: null,
        exercises: const [],
      );

      when(mockWorkoutDao.getAllWorkouts()).thenAnswer((_) async => [d1a, d1b, dNull]);
      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId(any)).thenAnswer((_) async => []);
      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId(any)).thenAnswer((_) async => []);

      final dates = await DatabaseService.instance.getDatesWithWorkouts();
      expect(dates.length, 1);
      expect(dates.single, DateTime(2024, 1, 1));
    });

    test('getWorkouts sorts with future dates first, then past, null last', () async {
      final future = Workout(
        id: 'f',
        name: 'Future',
        status: WorkoutStatus.completed,
        startedAt: DateTime(2030, 1, 1),
        exercises: const [],
      );
      final past = Workout(
        id: 'p',
        name: 'Past',
        status: WorkoutStatus.completed,
        startedAt: DateTime(2020, 1, 1),
        exercises: const [],
      );
      final noDate = Workout(
        id: 'n',
        name: 'NoDate',
        status: WorkoutStatus.completed,
        startedAt: null,
        exercises: const [],
      );

      when(mockWorkoutDao.getAllWorkouts()).thenAnswer((_) async => [past, noDate, future]);
      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId(any)).thenAnswer((_) async => []);
      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId(any)).thenAnswer((_) async => []);

      final list = await DatabaseService.instance.getWorkouts();
      expect(list.map((w) => w.id).toList(), ['f', 'p', 'n']);
    });
  });
}
