import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/app_startup_service.dart';

void main() {
  group('AppStartupService', () {
    test('deduplicates concurrent initialization requests', () async {
      final initializeNotificationsCompleter = Completer<void>();
      var initializeNotificationsCalls = 0;
      var initializeNotificationCallbackCalls = 0;
      var loadExercisesCalls = 0;
      var loadWorkoutDataCalls = 0;
      var loadUserProfileCalls = 0;
      var loadActiveSessionCalls = 0;

      final service = AppStartupService(
        initializeNotifications: () {
          initializeNotificationsCalls += 1;
          return initializeNotificationsCompleter.future;
        },
        initializeNotificationCallback: () {
          initializeNotificationCallbackCalls += 1;
        },
        loadExercises: () async {
          loadExercisesCalls += 1;
        },
        loadWorkoutData: () async {
          loadWorkoutDataCalls += 1;
        },
        loadUserProfile: () async {
          loadUserProfileCalls += 1;
        },
        loadActiveSession: () async {
          loadActiveSessionCalls += 1;
        },
      );

      final first = service.initializeMainApp();
      final second = service.initializeMainApp();

      expect(second, same(first));
      expect(initializeNotificationsCalls, 1);

      initializeNotificationsCompleter.complete();
      await Future.wait([first, second]);

      expect(initializeNotificationCallbackCalls, 1);
      expect(loadExercisesCalls, 1);
      expect(loadWorkoutDataCalls, 1);
      expect(loadUserProfileCalls, 1);
      expect(loadActiveSessionCalls, 1);
    });

    test('clears cached future after failure so initialization can retry', () async {
      var shouldFail = true;
      var initializeNotificationsCalls = 0;
      var loadExercisesCalls = 0;

      final service = AppStartupService(
        initializeNotifications: () async {
          initializeNotificationsCalls += 1;
        },
        initializeNotificationCallback: () {},
        loadExercises: () async {
          loadExercisesCalls += 1;
          if (shouldFail) {
            throw StateError('bootstrap failed');
          }
        },
        loadWorkoutData: () async {},
        loadUserProfile: () async {},
        loadActiveSession: () async {},
      );

      await expectLater(service.initializeMainApp(), throwsStateError);

      shouldFail = false;
      await service.initializeMainApp();

      expect(initializeNotificationsCalls, 2);
      expect(loadExercisesCalls, 2);
    });

    test('loads active session only after notification setup and parallel data loads finish', () async {
      final events = <String>[];
      final exercisesCompleter = Completer<void>();
      final workoutsCompleter = Completer<void>();
      final userProfileCompleter = Completer<void>();

      final service = AppStartupService(
        initializeNotifications: () async {
          events.add('initializeNotifications');
        },
        initializeNotificationCallback: () {
          events.add('initializeNotificationCallback');
        },
        loadExercises: () async {
          events.add('loadExercises:start');
          await exercisesCompleter.future;
          events.add('loadExercises:end');
        },
        loadWorkoutData: () async {
          events.add('loadWorkoutData:start');
          await workoutsCompleter.future;
          events.add('loadWorkoutData:end');
        },
        loadUserProfile: () async {
          events.add('loadUserProfile:start');
          await userProfileCompleter.future;
          events.add('loadUserProfile:end');
        },
        loadActiveSession: () async {
          events.add('loadActiveSession');
        },
      );

      final initialization = service.initializeMainApp();
      await Future<void>.delayed(Duration.zero);

      expect(
        events,
        equals([
          'initializeNotifications',
          'initializeNotificationCallback',
          'loadExercises:start',
          'loadWorkoutData:start',
          'loadUserProfile:start',
        ]),
      );

      exercisesCompleter.complete();
      workoutsCompleter.complete();
      userProfileCompleter.complete();

      await initialization;

      expect(
        events,
        equals([
          'initializeNotifications',
          'initializeNotificationCallback',
          'loadExercises:start',
          'loadWorkoutData:start',
          'loadUserProfile:start',
          'loadExercises:end',
          'loadWorkoutData:end',
          'loadUserProfile:end',
          'loadActiveSession',
        ]),
      );
    });
  });
}