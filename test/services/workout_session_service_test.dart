import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/dao/workout_dao.dart';
import 'package:zenith/services/dao/workout_exercise_dao.dart';
import 'package:zenith/services/dao/workout_set_dao.dart';
import 'package:zenith/services/exercise_service.dart';
import 'package:zenith/services/live_workout_notification_service.dart';
import 'package:zenith/services/workout_service.dart';
import 'package:zenith/services/workout_session_service.dart';

// ------------------------
// Test fakes (in-memory)
// ------------------------

class FakeWorkoutDao extends WorkoutDao {
  final Map<String, Workout> _store = {};
  int insertCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  Future<int> insert(Workout workout) async {
    insertCalls++;
    _store[workout.id] = workout;
    return 1;
  }

  @override
  Future<int> updateWorkout(Workout workout) async {
    updateCalls++;
    _store[workout.id] = workout;
    return 1;
  }

  @override
  Future<List<Workout>> getAllWorkouts() async {
    return _store.values.toList();
  }

  @override
  Future<List<Workout>> getInProgressWorkouts() async {
    return _store.values
        .where((w) => w.status == WorkoutStatus.inProgress)
        .toList();
  }

  @override
  Future<int> deleteWorkout(String id) async {
    deleteCalls++;
    _store.remove(id);
    return 1;
  }

  void resetCounts() {
    insertCalls = 0;
    updateCalls = 0;
    deleteCalls = 0;
  }
}

class LooseWorkoutDao extends FakeWorkoutDao {
  @override
  Future<List<Workout>> getInProgressWorkouts() async {
    return _store.values.toList();
  }
}

class ThrowingWorkoutDao extends FakeWorkoutDao {
  @override
  Future<List<Workout>> getInProgressWorkouts() async {
    throw Exception('getInProgressWorkouts failed');
  }
}

class FakeWorkoutExerciseDao extends WorkoutExerciseDao {
  final Map<String, WorkoutExercise> _byId = {};
  int insertCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  Future<int> insert(WorkoutExercise model) async {
    insertCalls++;
    _byId[model.id] = model;
    return 1;
  }

  @override
  Future<int> deleteWorkoutExercise(String id) async {
    deleteCalls++;
    _byId.remove(id);
    return 1;
  }

  @override
  Future<int> updateWorkoutExercise(WorkoutExercise workoutExercise) async {
    updateCalls++;
    _byId[workoutExercise.id] = workoutExercise;
    return 1;
  }

  @override
  Future<List<WorkoutExercise>> getWorkoutExercisesByWorkoutIds(
    List<String> workoutIds,
  ) async {
    return _byId.values
        .where((e) => e.workoutId != null && workoutIds.contains(e.workoutId))
        .toList()
      ..sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));
  }

  @override
  Future<List<WorkoutExercise>> getWorkoutExercisesByWorkoutId(
    String workoutId,
  ) async {
    final list = _byId.values.where((e) => e.workoutId == workoutId).toList()
      ..sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));
    return list;
  }

  void resetCounts() {
    insertCalls = 0;
    updateCalls = 0;
    deleteCalls = 0;
  }
}

class FakeWorkoutSetDao extends WorkoutSetDao {
  final Map<String, WorkoutSet> _byId = {};
  int insertCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  Future<int> insert(WorkoutSet model) async {
    insertCalls++;
    _byId[model.id] = model;
    return 1;
  }

  @override
  Future<int> updateWorkoutSet(WorkoutSet workoutSet) async {
    updateCalls++;
    _byId[workoutSet.id] = workoutSet;
    return 1;
  }

  @override
  Future<int> deleteWorkoutSet(String id) async {
    deleteCalls++;
    _byId.remove(id);
    return 1;
  }

  @override
  Future<List<WorkoutSet>> getWorkoutSetsByWorkoutExerciseIds(
    List<String> workoutExerciseIds,
  ) async {
    return _byId.values
        .where((set) => workoutExerciseIds.contains(set.workoutExerciseId))
        .toList()
      ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
  }

  @override
  Future<List<WorkoutSet>> getWorkoutSetsByWorkoutExerciseId(
    String workoutExerciseId,
  ) async {
    final list =
        _byId.values
            .where((s) => s.workoutExerciseId == workoutExerciseId)
            .toList()
          ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
    return list;
  }

  void resetCounts() {
    insertCalls = 0;
    updateCalls = 0;
    deleteCalls = 0;
  }
}

class FakeNotificationService implements NotificationServiceAPI {
  bool _running = false;
  int startCalls = 0;
  int updateCalls = 0;
  int stopCalls = 0;
  int restartCalls = 0;
  Function()? _nextSetCallback;
  Workout? lastSession;
  int? lastExerciseIndex;
  int? lastSetIndex;

  @override
  bool get isServiceRunning => _running;

  @override
  Future<void> initialize() async {
    // no-op
  }

  @override
  void setNextSetCallback(Function() callback) {
    _nextSetCallback = callback;
  }

  @override
  Future<void> startService(
    Workout session,
    int currentExerciseIndex,
    int currentSetIndex,
  ) async {
    startCalls++;
    _running = true;
    lastSession = session;
    lastExerciseIndex = currentExerciseIndex;
    lastSetIndex = currentSetIndex;
  }

  @override
  Future<void> updateNotification(
    Workout session,
    int currentExerciseIndex,
    int currentSetIndex,
  ) async {
    updateCalls++;
    lastSession = session;
    lastExerciseIndex = currentExerciseIndex;
    lastSetIndex = currentSetIndex;
  }

  @override
  Future<void> stopService() async {
    stopCalls++;
    _running = false;
  }

  @override
  Future<void> restartServiceIfNeeded(
    Workout? session,
    int currentExerciseIndex,
    int currentSetIndex,
  ) async {
    restartCalls++;
    lastSession = session;
    lastExerciseIndex = currentExerciseIndex;
    lastSetIndex = currentSetIndex;
  }

  void triggerNextSet() {
    _nextSetCallback?.call();
  }

  void resetCounts() {
    startCalls = 0;
    updateCalls = 0;
    stopCalls = 0;
    restartCalls = 0;
    lastSession = null;
    lastExerciseIndex = null;
    lastSetIndex = null;
  }
}

void main() {
  group('WorkoutSessionService Tests', () {
    late WorkoutSessionService service;
    late FakeWorkoutDao workoutDao;
    late FakeWorkoutExerciseDao workoutExerciseDao;
    late FakeWorkoutSetDao workoutSetDao;
    late FakeNotificationService notificationService;

    Exercise buildExerciseDetail(
      String slug,
      String name,
      MuscleGroup primaryMuscleGroup,
    ) {
      return Exercise(
        slug: slug,
        name: name,
        primaryMuscleGroup: primaryMuscleGroup,
        secondaryMuscleGroups: const [],
        instructions: const ['Do the lift'],
        image: '',
        animation: '',
      );
    }

    Workout buildTemplate() {
      // Build a template workout with one exercise and one set
      const templateExerciseId = 'ex-template-1';
      const templateSetId = 'set-template-1';

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

    Workout buildMultiExerciseTemplate() {
      const firstExerciseId = 'ex-template-1';
      const secondExerciseId = 'ex-template-2';

      return Workout(
        id: 'template-2',
        name: 'Full Body',
        exercises: [
          WorkoutExercise(
            id: firstExerciseId,
            workoutTemplateId: 'template-2',
            exerciseSlug: 'bench-press',
            orderIndex: 0,
            sets: [
              WorkoutSet(
                id: 'set-template-1',
                workoutExerciseId: firstExerciseId,
                setIndex: 0,
                targetReps: 10,
                targetWeight: 50.0,
              ),
            ],
          ),
          WorkoutExercise(
            id: secondExerciseId,
            workoutTemplateId: 'template-2',
            exerciseSlug: 'row',
            orderIndex: 1,
            sets: [
              WorkoutSet(
                id: 'set-template-2',
                workoutExerciseId: secondExerciseId,
                setIndex: 0,
                targetReps: 12,
                targetWeight: 40.0,
              ),
            ],
          ),
        ],
        status: WorkoutStatus.template,
      );
    }

    Workout buildPreviousSetTemplate() {
      const firstExerciseId = 'ex-template-previous-1';
      const secondExerciseId = 'ex-template-previous-2';

      return Workout(
        id: 'template-previous',
        name: 'Upper Body',
        exercises: [
          WorkoutExercise(
            id: firstExerciseId,
            workoutTemplateId: 'template-previous',
            exerciseSlug: 'bench-press',
            orderIndex: 0,
            sets: [
              WorkoutSet(
                id: 'set-template-previous-1',
                workoutExerciseId: firstExerciseId,
                setIndex: 0,
                targetReps: 10,
                targetWeight: 50.0,
              ),
              WorkoutSet(
                id: 'set-template-previous-2',
                workoutExerciseId: firstExerciseId,
                setIndex: 1,
                targetReps: 8,
                targetWeight: 55.0,
              ),
            ],
          ),
          WorkoutExercise(
            id: secondExerciseId,
            workoutTemplateId: 'template-previous',
            exerciseSlug: 'row',
            orderIndex: 1,
            sets: [
              WorkoutSet(
                id: 'set-template-previous-3',
                workoutExerciseId: secondExerciseId,
                setIndex: 0,
                targetReps: 12,
                targetWeight: 40.0,
              ),
            ],
          ),
        ],
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
      service.exerciseService = ExerciseService.instance;

      ExerciseService.instance.resetForTesting();
      ExerciseService.instance.setDependenciesForTesting(
        seedExercises: [
          buildExerciseDetail('bench-press', 'Bench Press', MuscleGroup.chest),
          buildExerciseDetail('row', 'Row', MuscleGroup.back),
        ],
        seedMuscleGroups: ['Back', 'Chest'],
      );

      WorkoutService.instance.workoutDao = workoutDao;
      WorkoutService.instance.workoutExerciseDao = workoutExerciseDao;
      WorkoutService.instance.workoutSetDao = workoutSetDao;

      await service.clearActiveSession();
      workoutDao.resetCounts();
      workoutExerciseDao.resetCounts();
      workoutSetDao.resetCounts();
      notificationService.resetCounts();
    });

    test('should initialize workout session service', () {
      expect(service, isNotNull);
    });

    test('notifies listeners when session starts and clears', () async {
      final notifications = <Workout?>[];
      void listener() {
        notifications.add(service.currentSession);
      }

      service.addListener(listener);

      final template = buildTemplate();
      await service.startWorkout(template);
      await service.clearActiveSession();

      service.removeListener(listener);

      expect(notifications, isNotEmpty);
      expect(notifications.any((session) => session != null), isTrue);
      expect(notifications.last, isNull);
    });

    group('startWorkout cloning behavior', () {
      test(
        'clones template exercises and sets with new IDs and correct foreign keys',
        () async {
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
        },
      );

      test(
        'starting a session twice from the same template creates fresh IDs each time',
        () async {
          final template = buildTemplate();

          final session1 = await service.startWorkout(template);
          final session1ExId = session1.exercises.first.id;
          final session1SetId = session1.exercises.first.sets.first.id;

          // End first session
          await service.clearActiveSession();
          await Future<void>.delayed(const Duration(milliseconds: 1));

          final session2 = await service.startWorkout(template);
          final session2ExId = session2.exercises.first.id;
          final session2SetId = session2.exercises.first.sets.first.id;

          expect(session2.id, isNot(session1.id));
          expect(session2ExId, isNot(session1ExId));
          expect(session2SetId, isNot(session1SetId));
        },
      );
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

    group('resume and reset flows', () {
      test(
        'loadActiveSession hydrates persisted exercises and restarts notifications',
        () async {
          final session = await service.startWorkout(
            buildMultiExerciseTemplate(),
          );
          final firstExercise = session.exercises.first;
          final firstSet = firstExercise.sets.first;

          await service.updateSet(
            firstExercise.id,
            firstSet.id,
            actualReps: 9,
            actualWeight: 52.5,
            isCompleted: true,
          );
          await service.clearActiveSession(deleteFromDb: false);
          notificationService.resetCounts();

          await service.loadActiveSession();

          final loadedSession = service.currentSession;
          expect(loadedSession, isNotNull);
          expect(loadedSession!.id, session.id);
          expect(loadedSession.exercises, hasLength(2));
          expect(loadedSession.exercises.first.sets.first.actualReps, 9);
          expect(loadedSession.exercises.first.sets.first.actualWeight, 52.5);
          expect(loadedSession.exercises.first.sets.first.isCompleted, isTrue);
          expect(
            loadedSession.exercises.first.exerciseDetail?.name,
            'Bench Press',
          );
          expect(notificationService.restartCalls, 1);
          expect(notificationService.lastSession?.id, session.id);
          expect(notificationService.lastExerciseIndex, 0);
          expect(notificationService.lastSetIndex, 0);
        },
      );

      test(
        'loadActiveSession clears an inconsistent completed session',
        () async {
          final completedWorkoutDao = LooseWorkoutDao();
          final completedSession = Workout(
            id: 'completed-session',
            name: 'Done',
            status: WorkoutStatus.completed,
            startedAt: DateTime(2025, 1, 1, 9),
            completedAt: DateTime(2025, 1, 1, 10),
          );
          completedWorkoutDao._store[completedSession.id] = completedSession;

          service.workoutDao = completedWorkoutDao;
          notificationService.resetCounts();

          await service.loadActiveSession();

          expect(service.currentSession, isNull);
          expect(service.currentExerciseIndex, 0);
          expect(service.currentSetIndex, 0);
          expect(notificationService.restartCalls, 0);
          expect(notificationService.stopCalls, 1);
        },
      );

      test(
        'loadActiveSession clears state when persistence lookup throws',
        () async {
          await service.startWorkout(buildTemplate());
          service.workoutDao = ThrowingWorkoutDao();
          notificationService.resetCounts();

          await service.loadActiveSession();

          expect(service.currentSession, isNull);
          expect(service.hasActiveSession, isFalse);
          expect(service.currentExerciseIndex, 0);
          expect(service.currentSetIndex, 0);
          expect(notificationService.stopCalls, 1);
        },
      );
    });

    group('clearActiveSession behavior', () {
      test(
        'deletes workout and all associated data from database when deleteFromDb is true',
        () async {
          // Build a template with exercises and sets
          final template = buildTemplate();
          final session = await service.startWorkout(template);

          // Verify session and its children exist in their respective fake DAOs
          expect(workoutDao.getInProgressWorkouts(), completion(isNotEmpty));
          expect(
            workoutExerciseDao.getWorkoutExercisesByWorkoutId(session.id),
            completion(isNotEmpty),
          );
          expect(
            workoutSetDao.getWorkoutSetsByWorkoutExerciseId(
              session.exercises.first.id,
            ),
            completion(isNotEmpty),
          );

          // Clear session and delete from DB
          await service.clearActiveSession(deleteFromDb: true);

          // Verify session is null and all data is removed from fake DAOs
          expect(service.currentSession, isNull);
          expect(workoutDao.getInProgressWorkouts(), completion(isEmpty));
          expect(
            workoutExerciseDao.getWorkoutExercisesByWorkoutId(session.id),
            completion(isEmpty),
          );
          // We need a way to check all sets, not just by one exercise ID.
          // For this test, checking that the exercises are gone is sufficient to infer sets are gone.
        },
      );

      test(
        'does not delete workout from database when deleteFromDb is false',
        () async {
          final template = Workout(
            id: 't1',
            name: 'Test',
            exercises: [],
            status: WorkoutStatus.template,
          );
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
        },
      );

      test('deletes data correctly even if in-memory session state is stale', () async {
        // 1. Start a workout to populate the database
        final template = buildTemplate();
        final session = await service.startWorkout(template);
        final exerciseId = session.exercises.first.id;

        // Verify everything is in the fake DAOs
        expect(await workoutDao.getInProgressWorkouts(), isNotEmpty);
        expect(
          await workoutExerciseDao.getWorkoutExercisesByWorkoutId(session.id),
          isNotEmpty,
        );
        expect(
          await workoutSetDao.getWorkoutSetsByWorkoutExerciseId(exerciseId),
          isNotEmpty,
        );

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
        expect(
          await workoutDao.getInProgressWorkouts(),
          isEmpty,
          reason: "Workout should be deleted",
        );
        expect(
          await workoutExerciseDao.getWorkoutExercisesByWorkoutId(session.id),
          isEmpty,
          reason: "Exercises should be deleted",
        );
        expect(
          await workoutSetDao.getWorkoutSetsByWorkoutExerciseId(exerciseId),
          isEmpty,
          reason: "Sets should be deleted because of re-fetching",
        );
      });
    });

    group('navigation and invalid transitions', () {
      test(
        'selectExercise ignores invalid indexes without persisting changes',
        () async {
          await service.startWorkout(buildMultiExerciseTemplate());
          await service.selectExercise(1);
          workoutDao.resetCounts();
          notificationService.resetCounts();

          await service.selectExercise(5);

          expect(service.currentExerciseIndex, 1);
          expect(service.currentSetIndex, 0);
          expect(workoutDao.updateCalls, 0);
          expect(notificationService.updateCalls, 0);
        },
      );

      test(
        'previousSet moves to the prior exercise last set and persists',
        () async {
          await service.startWorkout(buildPreviousSetTemplate());
          await service.selectExercise(1);
          workoutDao.resetCounts();
          notificationService.resetCounts();

          await service.previousSet();

          expect(service.currentExerciseIndex, 0);
          expect(service.currentSetIndex, 1);
          expect(workoutDao.updateCalls, 1);
          expect(notificationService.updateCalls, 1);
          expect(notificationService.lastExerciseIndex, 0);
          expect(notificationService.lastSetIndex, 1);
        },
      );

      test(
        'nextSet completes the final set without advancing past the workout',
        () async {
          final session = await service.startWorkout(buildTemplate());
          final exercise = session.exercises.first;
          workoutDao.resetCounts();
          workoutSetDao.resetCounts();
          notificationService.resetCounts();

          await service.nextSet();

          expect(service.currentExerciseIndex, 0);
          expect(service.currentSetIndex, 0);
          expect(service.currentSession!.completedSets, 1);
          expect(
            service.currentSession!.exercises.first.sets.first.isCompleted,
            isTrue,
          );
          expect(workoutSetDao.updateCalls, 1);
          expect(workoutDao.updateCalls, 2);
          expect(notificationService.updateCalls, 2);
          final persistedSets = await workoutSetDao
              .getWorkoutSetsByWorkoutExerciseId(exercise.id);
          expect(persistedSets.single.isCompleted, isTrue);
        },
      );

      test(
        'updateSet and toggleSetCompletion ignore missing targets without persistence',
        () async {
          final session = await service.startWorkout(buildTemplate());
          final exercise = session.exercises.first;
          final set = exercise.sets.first;
          workoutDao.resetCounts();
          workoutSetDao.resetCounts();
          notificationService.resetCounts();

          await service.updateSet('missing-exercise', set.id, targetReps: 99);
          await service.updateSet(exercise.id, 'missing-set', targetWeight: 99);
          await service.toggleSetCompletion('missing-exercise', set.id);
          await service.toggleSetCompletion(exercise.id, 'missing-set');

          expect(
            service.currentSession!.exercises.first.sets.first.targetReps,
            10,
          );
          expect(
            service.currentSession!.exercises.first.sets.first.targetWeight,
            50.0,
          );
          expect(
            service.currentSession!.exercises.first.sets.first.isCompleted,
            isFalse,
          );
          expect(workoutDao.updateCalls, 0);
          expect(workoutSetDao.updateCalls, 0);
          expect(notificationService.updateCalls, 0);
        },
      );

      test(
        'nextSet and previousSet do nothing for non-active sessions',
        () async {
          final session = await service.startWorkout(buildTemplate());
          service.currentSession = session.copyWith(
            status: WorkoutStatus.completed,
          );
          workoutDao.resetCounts();
          workoutSetDao.resetCounts();
          notificationService.resetCounts();

          await service.nextSet();
          await service.previousSet();

          expect(service.currentExerciseIndex, 0);
          expect(service.currentSetIndex, 0);
          expect(service.currentSession!.status, WorkoutStatus.completed);
          expect(workoutDao.updateCalls, 0);
          expect(workoutSetDao.updateCalls, 0);
          expect(notificationService.updateCalls, 0);
        },
      );
    });

    test(
      'nextSet exits cleanly if listeners clear the session mid-transition',
      () async {
        final session = await service.startWorkout(
          buildMultiExerciseTemplate(),
        );
        var clearedSession = false;

        void listener() {
          final currentSession = service.currentSession;
          if (clearedSession || currentSession == null) {
            return;
          }

          final firstSet = currentSession.exercises.first.sets.first;
          if (firstSet.isCompleted) {
            clearedSession = true;
            service.currentSession = null;
          }
        }

        service.addListener(listener);
        await service.nextSet();
        service.removeListener(listener);

        expect(clearedSession, isTrue);
        expect(service.currentSession, isNull);
        expect(service.currentExerciseIndex, 0);
        expect(service.currentSetIndex, 0);
        expect(session.exercises.length, 2);
      },
    );
  });
}
