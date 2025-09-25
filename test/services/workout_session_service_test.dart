import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/workout_session_service.dart';
import 'package:zenith/services/dao/workout_dao.dart';
import 'package:zenith/services/dao/workout_exercise_dao.dart';
import 'package:zenith/services/dao/workout_set_dao.dart';
import 'package:zenith/services/live_workout_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ------------------------
// Test fakes (in-memory)
// ------------------------

class FakeWorkoutDao extends WorkoutDao {
  final Map<String, Workout> _store = {};

  @override
  Future<int> insert(Workout workout) async {
    _store[workout.id] = workout;
    return 1;
  }

  @override
  Future<int> updateWorkout(Workout workout) async {
    _store[workout.id] = workout;
    return 1;
  }

  @override
  Future<List<Workout>> getInProgressWorkouts() async {
    return _store.values.where((w) => w.status == WorkoutStatus.inProgress).toList();
  }

  @override
  Future<int> deleteWorkout(String id) async {
    _store.remove(id);
    return 1;
  }
}

class FakeWorkoutExerciseDao extends WorkoutExerciseDao {
  final Map<String, WorkoutExercise> _byId = {};

  @override
  Future<int> insert(WorkoutExercise model) async {
    _byId[model.id] = model;
    return 1;
  }

  @override
  Future<int> deleteWorkoutExercise(String id) async {
    _byId.remove(id);
    return 1;
  }

  @override
  Future<int> updateWorkoutExercise(WorkoutExercise workoutExercise) async {
    _byId[workoutExercise.id] = workoutExercise;
    return 1;
  }

  @override
  Future<List<WorkoutExercise>> getWorkoutExercisesByWorkoutId(String workoutId) async {
    final list = _byId.values.where((e) => e.workoutId == workoutId).toList()
      ..sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));
    return list;
  }
}

class FakeWorkoutSetDao extends WorkoutSetDao {
  final Map<String, WorkoutSet> _byId = {};

  @override
  Future<int> insert(WorkoutSet model) async {
    _byId[model.id] = model;
    return 1;
  }

  @override
  Future<int> updateWorkoutSet(WorkoutSet workoutSet) async {
    _byId[workoutSet.id] = workoutSet;
    return 1;
  }

  @override
  Future<int> deleteWorkoutSet(String id) async {
    _byId.remove(id);
    return 1;
  }

  @override
  Future<List<WorkoutSet>> getWorkoutSetsByWorkoutExerciseId(String workoutExerciseId) async {
    final list = _byId.values.where((s) => s.workoutExerciseId == workoutExerciseId).toList()
      ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
    return list;
  }
}

class FakeNotificationService implements NotificationServiceAPI {
  bool _running = false;

  @override
  bool get isServiceRunning => _running;

  @override
  Future<void> initialize() async {
    // no-op
  }

  @override
  void setNextSetCallback(Function() callback) {
    // no-op for tests
  }

  @override
  Future<void> startService(Workout session, int currentExerciseIndex, int currentSetIndex) async {
    _running = true;
  }

  @override
  Future<void> updateNotification(Workout session, int currentExerciseIndex, int currentSetIndex) async {
    // no-op
  }

  @override
  Future<void> stopService() async {
    _running = false;
  }

  @override
  Future<void> restartServiceIfNeeded(Workout? session, int currentExerciseIndex, int currentSetIndex) async {
    // no-op
  }
}

void main() {
  group('WorkoutSessionService Tests', () {
    late WorkoutSessionService service;
    late FakeWorkoutDao workoutDao;
    late FakeWorkoutExerciseDao workoutExerciseDao;
    late FakeWorkoutSetDao workoutSetDao;
    late FakeNotificationService notificationService;

    Workout buildTemplate() {
      // Build a template workout with one exercise and one set
      final templateExerciseId = 'ex-template-1';
      final templateSetId = 'set-template-1';

      final templateExercise = WorkoutExercise(
        id: templateExerciseId,
        workoutTemplateId: 'template-1',
        exerciseSlug: 'bench-press',
        notes: 'Template notes',
        orderIndex: 0,
        sets: [
          WorkoutSet(
            id: templateSetId,
            workoutExerciseId: templateExerciseId,
            setIndex: 0,
            targetReps: 10,
            targetWeight: 50.0,
          ),
        ],
      );

      return Workout(
        id: 'template-1',
        name: 'Push Day',
        exercises: [templateExercise],
        status: WorkoutStatus.template,
      );
    }

    setUp(() async {
      // Mock SharedPreferences to avoid platform channel calls in tests
      SharedPreferences.setMockInitialValues({});

      // Use singleton but reset its dependencies before each test
      service = WorkoutSessionService();

      workoutDao = FakeWorkoutDao();
      workoutExerciseDao = FakeWorkoutExerciseDao();
      workoutSetDao = FakeWorkoutSetDao();
      notificationService = FakeNotificationService();

      service.workoutDao = workoutDao;
      service.workoutExerciseDao = workoutExerciseDao;
      service.workoutSetDao = workoutSetDao;
      service.notificationService = notificationService;

      await service.clearActiveSession();
    });

    test('should initialize workout session service', () {
      expect(service, isNotNull);
    });

    group('startWorkout cloning behavior', () {
      test('clones template exercises and sets with new IDs and correct foreign keys', () async {
        final template = buildTemplate();

        final session = await service.startWorkout(template);

        // Session properties
        expect(session.status, WorkoutStatus.inProgress);
        expect(session.templateId, template.id);
        expect(session.id, isNot(template.id)); // new session id

        // Cloned exercise assertions
        expect(session.exercises.length, 1);
        final ex = session.exercises.first;

        expect(ex.workoutId, session.id);
        expect(ex.workoutTemplateId, isNull);
        expect(ex.id, isNot('ex-template-1'));
        expect(ex.exerciseSlug, 'bench-press');
        expect(ex.orderIndex, 0);

        // Cloned set assertions
        expect(ex.sets.length, 1);
        final s = ex.sets.first;
        expect(s.id, isNot('set-template-1'));
        expect(s.workoutExerciseId, ex.id); // relinked to cloned exercise
        expect(s.setIndex, 0);
        expect(s.targetReps, 10);
        expect(s.targetWeight, 50.0);
        expect(s.actualReps, isNull);
        expect(s.actualWeight, isNull);
        expect(s.isCompleted, isFalse);
      });

      test('starting a session twice from the same template creates fresh IDs each time', () async {
        final template = buildTemplate();

        final session1 = await service.startWorkout(template);
        final session1ExId = session1.exercises.first.id;
        final session1SetId = session1.exercises.first.sets.first.id;

        // End first session
        await service.clearActiveSession();

        final session2 = await service.startWorkout(template);
        final session2ExId = session2.exercises.first.id;
        final session2SetId = session2.exercises.first.sets.first.id;

        expect(session2.id, isNot(session1.id));
        expect(session2ExId, isNot(session1ExId));
        expect(session2SetId, isNot(session1SetId));
      });
    });

    group('updateSet behavior', () {
      test('updates only targetReps and preserves other values', () async {
        final template = buildTemplate();
        final session = await service.startWorkout(template);
        final exerciseId = session.exercises.first.id;
        final setId = session.exercises.first.sets.first.id;

        await service.updateSet(exerciseId, setId, targetReps: 12);

        final updatedSet = service.currentSession!.exercises.first.sets.first;
        expect(updatedSet.targetReps, 12);
        expect(updatedSet.targetWeight, 50.0); // Preserved
      });

      test('updates only targetWeight and preserves other values', () async {
        final template = buildTemplate();
        final session = await service.startWorkout(template);
        final exerciseId = session.exercises.first.id;
        final setId = session.exercises.first.sets.first.id;

        await service.updateSet(exerciseId, setId, targetWeight: 55.0);

        final updatedSet = service.currentSession!.exercises.first.sets.first;
        expect(updatedSet.targetWeight, 55.0);
        expect(updatedSet.targetReps, 10); // Preserved
      });

      test('updates multiple fields correctly in a single call', () async {
        final template = buildTemplate();
        final session = await service.startWorkout(template);
        final exerciseId = session.exercises.first.id;
        final setId = session.exercises.first.sets.first.id;

        await service.updateSet(
          exerciseId,
          setId,
          targetReps: 8,
          targetWeight: 60.0,
          actualReps: 8,
          actualWeight: 60.0,
          isCompleted: true,
        );

        final updatedSet = service.currentSession!.exercises.first.sets.first;
        expect(updatedSet.targetReps, 8);
        expect(updatedSet.targetWeight, 60.0);
        expect(updatedSet.actualReps, 8);
        expect(updatedSet.actualWeight, 60.0);
        expect(updatedSet.isCompleted, true);
      });
    });

    group('clearActiveSession behavior', () {
      test('deletes workout and all associated data from database when deleteFromDb is true', () async {
        // Build a template with exercises and sets
        final template = buildTemplate();
        final session = await service.startWorkout(template);

        // Verify session and its children exist in their respective fake DAOs
        expect(workoutDao.getInProgressWorkouts(), completion(isNotEmpty));
        expect(workoutExerciseDao.getWorkoutExercisesByWorkoutId(session.id), completion(isNotEmpty));
        expect(workoutSetDao.getWorkoutSetsByWorkoutExerciseId(session.exercises.first.id), completion(isNotEmpty));

        // Clear session and delete from DB
        await service.clearActiveSession(deleteFromDb: true);

        // Verify session is null and all data is removed from fake DAOs
        expect(service.currentSession, isNull);
        expect(workoutDao.getInProgressWorkouts(), completion(isEmpty));
        expect(workoutExerciseDao.getWorkoutExercisesByWorkoutId(session.id), completion(isEmpty));
        // We need a way to check all sets, not just by one exercise ID.
        // For this test, checking that the exercises are gone is sufficient to infer sets are gone.
      });

      test('does not delete workout from database when deleteFromDb is false', () async {
        final template = Workout(id: 't1', name: 'Test', exercises: [], status: WorkoutStatus.template);
        final session = await service.startWorkout(template);

        // Verify session exists in DB
        final workoutsBefore = await workoutDao.getInProgressWorkouts();
        expect(workoutsBefore.any((w) => w.id == session.id), isTrue);

        // Clear session without deleting from DB
        await service.clearActiveSession(deleteFromDb: false);

        // Verify session is null but still exists in DB
        expect(service.currentSession, isNull);
        final workoutsAfter = await workoutDao.getInProgressWorkouts();
        expect(workoutsAfter.any((w) => w.id == session.id), isTrue);
      });

      test('deletes data correctly even if in-memory session state is stale', () async {
        // 1. Start a workout to populate the database
        final template = buildTemplate();
        final session = await service.startWorkout(template);
        final exerciseId = session.exercises.first.id;

        // Verify everything is in the fake DAOs
        expect(await workoutDao.getInProgressWorkouts(), isNotEmpty);
        expect(await workoutExerciseDao.getWorkoutExercisesByWorkoutId(session.id), isNotEmpty);
        expect(await workoutSetDao.getWorkoutSetsByWorkoutExerciseId(exerciseId), isNotEmpty);

        // 2. Simulate stale in-memory state by removing sets from the session object
        // This mimics the bug condition where the in-memory object is incomplete.
        final staleExercise = session.exercises.first.copyWith(sets: []);
        final staleSession = session.copyWith(exercises: [staleExercise]);
        
        // Manually set the service's internal state to be stale
        service.currentSession = staleSession;

        // Pre-assertion: The in-memory session's exercise has no sets
        expect(service.currentSession!.exercises.first.sets, isEmpty);

        // 3. Call clearActiveSession. The fix ensures this method re-fetches from the DAO
        // instead of trusting the stale in-memory `_currentSession`.
        await service.clearActiveSession(deleteFromDb: true);

        // 4. Assert that all data was deleted from the DAOs, proving re-fetching worked.
        expect(service.currentSession, isNull);
        expect(await workoutDao.getInProgressWorkouts(), isEmpty, reason: "Workout should be deleted");
        expect(await workoutExerciseDao.getWorkoutExercisesByWorkoutId(session.id), isEmpty, reason: "Exercises should be deleted");
        expect(await workoutSetDao.getWorkoutSetsByWorkoutExerciseId(exerciseId), isEmpty, reason: "Sets should be deleted because of re-fetching");
      });
    });
  });
}
