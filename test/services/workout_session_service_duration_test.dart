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

// Local fakes (duplicated here for isolation)
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

  @override
  Future<Workout?> getById(String id) async => _store[id];
}

class FakeWorkoutExerciseDao extends WorkoutExerciseDao {
  final Map<String, WorkoutExercise> _byId = {};
  @override
  Future<int> insert(WorkoutExercise model) async { _byId[model.id] = model; return 1; }
  @override
  Future<int> deleteWorkoutExercise(String id) async { _byId.remove(id); return 1; }
  @override
  Future<int> updateWorkoutExercise(WorkoutExercise workoutExercise) async { _byId[workoutExercise.id] = workoutExercise; return 1; }
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
  Future<int> insert(WorkoutSet model) async { _byId[model.id] = model; return 1; }
  @override
  Future<int> updateWorkoutSet(WorkoutSet workoutSet) async { _byId[workoutSet.id] = workoutSet; return 1; }
  @override
  Future<int> deleteWorkoutSet(String id) async { _byId.remove(id); return 1; }
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
  Future<void> initialize() async {}
  @override
  void setNextSetCallback(Function() callback) {}
  @override
  Future<void> startService(Workout session, int currentExerciseIndex, int currentSetIndex) async { _running = true; }
  @override
  Future<void> updateNotification(Workout session, int currentExerciseIndex, int currentSetIndex) async {}
  @override
  Future<void> stopService() async { _running = false; }
  @override
  Future<void> restartServiceIfNeeded(Workout? session, int currentExerciseIndex, int currentSetIndex) async {}
}

void main() {
  group('WorkoutSessionService.completeWorkout durationOverride', () {
    late WorkoutSessionService service;
    late FakeWorkoutDao workoutDao;
    late FakeWorkoutExerciseDao workoutExerciseDao;
    late FakeWorkoutSetDao workoutSetDao;
    late FakeNotificationService notificationService;

    Workout _buildTemplate() {
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
      SharedPreferences.setMockInitialValues({});
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

    test('uses durationOverride exactly, without rounding', () async {
      final template = _buildTemplate();
      final session = await service.startWorkout(template);

      final customStart = DateTime(2025, 1, 1, 12, 0, 0);
      service.currentSession = session.copyWith(startedAt: customStart);

      final override = const Duration(minutes: 1, seconds: 3);
      final completed = await service.completeWorkout(durationOverride: override);

      expect(completed.completedAt, customStart.add(override));
    });

    test('falls back to rounded behavior when durationOverride is null', () async {
      final template = _buildTemplate();
      final session = await service.startWorkout(template);

      final customStart = DateTime(2025, 1, 1, 12, 0, 0);
      service.currentSession = session.copyWith(startedAt: customStart);

      // Simulate a short elapsed time that would round up to 1 minute
      final completed = await service.completeWorkout(durationOverride: null);

      // We cannot know exact "now" but duration must be a multiple of minutes due to rounding.
      final duration = completed.completedAt!.difference(customStart);
      expect(duration.inSeconds % 60, 0, reason: 'Should be rounded to full minute when no override provided');
    });
  });
}
