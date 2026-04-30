import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'exercise_service.dart';
import 'live_workout_notification_service.dart';
import 'user_service.dart';
import 'workout_service.dart';
import 'workout_session_service.dart';

class AppStartupService {
  AppStartupService._internal();

  static final AppStartupService _instance = AppStartupService._internal();
  static AppStartupService get instance => _instance;

  final Logger _logger = Logger('AppStartupService');

  Future<void>? _initializationFuture;

  Future<void> initializeMainApp() {
    final existingFuture = _initializationFuture;
    if (existingFuture != null) {
      return existingFuture;
    }

    final future = _initializeMainApp();
    _initializationFuture = future;
    future.catchError((Object error, StackTrace stackTrace) {
      if (identical(_initializationFuture, future)) {
        _initializationFuture = null;
      }
      _logger.severe('Main app initialization failed', error, stackTrace);
    });
    return future;
  }

  Future<void> _initializeMainApp() async {
    _logger.info('Initializing main app services');

    await LiveWorkoutNotificationService().initialize();
    WorkoutSessionService.instance.initializeNotificationCallback();

    await Future.wait<void>([
      ExerciseService.instance.loadExercises(),
      WorkoutService.instance.loadData(),
      UserService.instance.loadUserProfile(),
    ]);

    await WorkoutSessionService.instance.loadActiveSession();
    _logger.info('Main app services initialized');
  }

  @visibleForTesting
  void resetForTesting() {
    _initializationFuture = null;
  }
}