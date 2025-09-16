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
      Workout _buildTemplate() {
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

      test('clones template exercises and sets with new IDs and correct foreign keys', () async {
        final template = _buildTemplate();

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
        final template = _buildTemplate();

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
  });
}
