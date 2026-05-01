import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/live_workout_notification_service.dart';

class TestNotificationsPlugin implements LiveWorkoutNotificationsPlugin {
  InitializationSettings? initializationSettings;
  DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse;
  final List<TestShownNotification> shownNotifications =
      <TestShownNotification>[];
  final List<int> cancelledNotificationIds = <int>[];
  final List<AndroidNotificationChannel> createdChannels =
      <AndroidNotificationChannel>[];
  bool? permissionGranted = true;
  int requestPermissionCallCount = 0;

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    this.initializationSettings = initializationSettings;
    this.onDidReceiveNotificationResponse = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<void> createNotificationChannel(
    AndroidNotificationChannel notificationChannel,
  ) async {
    createdChannels.add(notificationChannel);
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {
    shownNotifications.add(
      TestShownNotification(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      ),
    );
  }

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelledNotificationIds.add(id);
  }

  @override
  Future<bool?> requestNotificationsPermission() async {
    requestPermissionCallCount += 1;
    return permissionGranted;
  }
}

class TestShownNotification {
  const TestShownNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationDetails,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final NotificationDetails? notificationDetails;
  final String? payload;
}

Workout buildSession({
  WorkoutStatus status = WorkoutStatus.inProgress,
  DateTime? startedAt,
  List<WorkoutExercise>? exercises,
}) {
  const firstExerciseId = 'exercise-1';
  const secondExerciseId = 'exercise-2';

  return Workout(
    id: 'workout-1',
    name: 'Push Day',
    status: status,
    startedAt: startedAt,
    exercises:
        exercises ??
        <WorkoutExercise>[
          WorkoutExercise(
            id: firstExerciseId,
            workoutId: 'workout-1',
            exerciseSlug: 'bench-press',
            orderIndex: 0,
            sets: <WorkoutSet>[
              WorkoutSet(
                id: 'set-1',
                workoutExerciseId: firstExerciseId,
                setIndex: 0,
                targetReps: 10,
                targetWeight: 60,
                isCompleted: true,
              ),
              WorkoutSet(
                id: 'set-2',
                workoutExerciseId: firstExerciseId,
                setIndex: 1,
                targetReps: 8,
                targetWeight: 70,
              ),
            ],
          ),
          WorkoutExercise(
            id: secondExerciseId,
            workoutId: 'workout-1',
            exerciseSlug: 'row',
            orderIndex: 1,
            sets: <WorkoutSet>[
              WorkoutSet(
                id: 'set-3',
                workoutExerciseId: secondExerciseId,
                setIndex: 0,
                targetReps: 12,
              ),
            ],
          ),
        ],
  );
}

void main() {
  group('LiveWorkoutNotificationService', () {
    late TestNotificationsPlugin notificationsPlugin;
    late LiveWorkoutNotificationService service;

    setUp(() {
      notificationsPlugin = TestNotificationsPlugin();
      service = LiveWorkoutNotificationService.withDependencies(
        notificationsPlugin: notificationsPlugin,
      );
    });

    tearDown(() async {
      await service.stopService();
    });

    test(
      'initialize wires callbacks and creates the notification channel',
      () async {
        var nextSetTapped = 0;
        service.setNextSetCallback(() {
          nextSetTapped += 1;
        });

        await service.initialize();

        expect(notificationsPlugin.initializationSettings, isNotNull);
        expect(notificationsPlugin.createdChannels, hasLength(1));
        expect(
          notificationsPlugin.createdChannels.single.id,
          notificationChannelId,
        );
        expect(
          notificationsPlugin.initializationSettings!.android,
          isA<AndroidInitializationSettings>(),
        );
        expect(notificationsPlugin.onDidReceiveNotificationResponse, isNotNull);

        notificationsPlugin.onDidReceiveNotificationResponse!(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            actionId: 'next_set',
          ),
        );
        notificationsPlugin.onDidReceiveNotificationResponse!(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            actionId: 'ignored',
          ),
        );

        expect(nextSetTapped, 1);
      },
    );

    test(
      'startService returns early when Android notification permission is denied',
      () async {
        notificationsPlugin.permissionGranted = false;

        await service.startService(buildSession(), 0, 1);

        expect(notificationsPlugin.requestPermissionCallCount, 1);
        expect(service.isServiceRunning, isFalse);
        expect(notificationsPlugin.shownNotifications, isEmpty);
      },
    );

    test(
      'startService shows the initial notification and periodic updates',
      () {
        fakeAsync((async) {
          unawaited(
            service.startService(
              buildSession(startedAt: DateTime(2024, 1, 1, 10)),
              0,
              1,
            ),
          );
          async.flushMicrotasks();

          expect(service.isServiceRunning, isTrue);
          expect(notificationsPlugin.requestPermissionCallCount, 1);
          expect(notificationsPlugin.shownNotifications, hasLength(1));

          final firstNotification =
              notificationsPlugin.shownNotifications.single;
          expect(firstNotification.id, notificationId);
          expect(firstNotification.title, startsWith('bench-press | '));
          expect(
            firstNotification.body,
            'Set 2 of 2 | 8 reps at 70.0 kg | Next: row',
          );
          expect(firstNotification.payload, 'active_workout_screen');
          expect(firstNotification.notificationDetails!.android!.progress, 33);
          expect(
            firstNotification.notificationDetails!.android!.subText,
            'Sets: 1/3',
          );

          async.elapse(const Duration(seconds: 1));
          async.flushMicrotasks();

          expect(notificationsPlugin.shownNotifications, hasLength(2));
        });
      },
    );

    test(
      'updateNotification starts the service when it is not already running',
      () async {
        await service.updateNotification(buildSession(), 0, 1);

        expect(service.isServiceRunning, isTrue);
        expect(notificationsPlugin.shownNotifications, hasLength(1));
      },
    );

    test(
      'updateNotification refreshes notification content for an active service',
      () async {
        await service.startService(buildSession(), 0, 1);

        await service.updateNotification(buildSession(), 1, 0);

        expect(notificationsPlugin.shownNotifications, hasLength(2));
        expect(
          notificationsPlugin.shownNotifications.last.title,
          startsWith('row | '),
        );
        expect(
          notificationsPlugin.shownNotifications.last.body,
          'Set 1 of 1 | 12 reps | Final exercise!',
        );
        expect(
          notificationsPlugin
              .shownNotifications
              .last
              .notificationDetails!
              .android!
              .subText,
          'Sets: 1/3',
        );
      },
    );

    test(
      'stopService cancels notifications, clears callback, and stops timer updates',
      () async {
        var nextSetTapped = 0;
        service.setNextSetCallback(() {
          nextSetTapped += 1;
        });
        await service.initialize();

        fakeAsync((async) {
          unawaited(service.startService(buildSession(), 0, 1));
          async.flushMicrotasks();
          expect(notificationsPlugin.shownNotifications, hasLength(1));

          unawaited(service.stopService());
          async.flushMicrotasks();

          expect(service.isServiceRunning, isFalse);
          expect(
            notificationsPlugin.cancelledNotificationIds,
            contains(notificationId),
          );

          notificationsPlugin.onDidReceiveNotificationResponse!(
            const NotificationResponse(
              notificationResponseType:
                  NotificationResponseType.selectedNotificationAction,
              actionId: 'next_set',
            ),
          );

          async.elapse(const Duration(seconds: 2));
          async.flushMicrotasks();

          expect(nextSetTapped, 0);
          expect(notificationsPlugin.shownNotifications, hasLength(1));
        });
      },
    );

    test(
      'restartServiceIfNeeded only restarts for a stopped in-progress session',
      () async {
        await service.restartServiceIfNeeded(buildSession(), 0, 1);

        expect(service.isServiceRunning, isTrue);
        expect(notificationsPlugin.shownNotifications, hasLength(1));

        final shownCountAfterRestart =
            notificationsPlugin.shownNotifications.length;
        await service.restartServiceIfNeeded(buildSession(), 0, 1);
        await service.stopService();
        await service.restartServiceIfNeeded(
          buildSession(status: WorkoutStatus.completed),
          0,
          1,
        );
        await service.restartServiceIfNeeded(null, 0, 1);

        expect(
          notificationsPlugin.shownNotifications.length,
          shownCountAfterRestart,
        );
      },
    );

    test(
      'stopService is a no-op when the service is already stopped',
      () async {
        await service.stopService();

        expect(service.isServiceRunning, isFalse);
        expect(notificationsPlugin.cancelledNotificationIds, isEmpty);
      },
    );
  });
}
