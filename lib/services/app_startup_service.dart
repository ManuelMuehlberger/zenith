import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'exercise_service.dart';
import 'live_workout_notification_service.dart';
import 'user_service.dart';
import 'workout_service.dart';
import 'workout_session_service.dart';

class AppStartupService {
  AppStartupService({
    Future<void> Function()? initializeNotifications,
    void Function()? initializeNotificationCallback,
    Future<void> Function()? loadExercises,
    Future<void> Function()? loadWorkoutData,
    Future<void> Function()? loadUserProfile,
    Future<void> Function()? loadActiveSession,
  }) : _initializeNotifications =
           initializeNotifications ??
           (() => LiveWorkoutNotificationService().initialize()),
       _initializeNotificationCallback =
           initializeNotificationCallback ??
           WorkoutSessionService.instance.initializeNotificationCallback,
       _loadExercises = loadExercises ?? ExerciseService.instance.loadExercises,
       _loadWorkoutData = loadWorkoutData ?? WorkoutService.instance.loadData,
       _loadUserProfile =
           loadUserProfile ?? UserService.instance.loadUserProfile,
       _loadActiveSession =
           loadActiveSession ??
           WorkoutSessionService.instance.loadActiveSession;

  AppStartupService._internal() : this();

  static final AppStartupService _instance = AppStartupService._internal();
  static AppStartupService get instance => _instance;

  final Logger _logger = Logger('AppStartupService');
  final Future<void> Function() _initializeNotifications;
  final void Function() _initializeNotificationCallback;
  final Future<void> Function() _loadExercises;
  final Future<void> Function() _loadWorkoutData;
  final Future<void> Function() _loadUserProfile;
  final Future<void> Function() _loadActiveSession;

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

    await _initializeNotifications();
    _initializeNotificationCallback();

    await Future.wait<void>([
      _loadExercises(),
      _loadWorkoutData(),
      _loadUserProfile(),
    ]);

    await _loadActiveSession();
    _logger.info('Main app services initialized');
  }

  @visibleForTesting
  void resetForTesting() {
    _initializationFuture = null;
  }
}
