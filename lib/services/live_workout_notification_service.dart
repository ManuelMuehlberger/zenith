import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';

import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';

abstract class NotificationServiceAPI {
  bool get isServiceRunning;

  Future<void> initialize();
  void setNextSetCallback(Function() callback);
  Future<void> startService(Workout session, int currentExerciseIndex, int currentSetIndex);
  Future<void> updateNotification(Workout session, int currentExerciseIndex, int currentSetIndex);
  Future<void> stopService();
  Future<void> restartServiceIfNeeded(Workout? session, int currentExerciseIndex, int currentSetIndex);
}

const String notificationChannelId = 'workout_progress_channel';
const String notificationChannelName = 'Workout Progress';
const String notificationChannelDescription = 'Notifications for active workout progress';
const int notificationId = 888;
const String appIcon = 'ic_workout_notification';

class LiveWorkoutNotificationService implements NotificationServiceAPI {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger('LiveWorkoutNotificationService');
  
  static final LiveWorkoutNotificationService _instance = LiveWorkoutNotificationService._internal();
  factory LiveWorkoutNotificationService() => _instance;
  LiveWorkoutNotificationService._internal();

  bool _isServiceRunning = false;
  Timer? _updateTimer;
  Workout? _currentSession;
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  DateTime? _sessionStartTime;
  
  // Callback for handling notification actions
  Function()? _onNextSetCallback;
  
  @override
  bool get isServiceRunning => _isServiceRunning;

  @override
  Future<void> initialize() async {
    _logger.info('Initializing notification service');
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(appIcon);

    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        _logger.info('Notification action received: ${notificationResponse.actionId}');
        
        if (notificationResponse.actionId == 'next_set') {
          _logger.info('Next set action triggered from notification');
          _onNextSetCallback?.call();
        }
      },
    );

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description: notificationChannelDescription,
      importance: Importance.low,
      showBadge: false,
      enableVibration: false,
      playSound: false,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    _logger.info('Notification service initialized');
  }

  @override
  void setNextSetCallback(Function() callback) {
    _logger.fine('Setting next set callback');
    _onNextSetCallback = callback;
  }

  @override
  Future<void> startService(Workout session, int currentExerciseIndex, int currentSetIndex) async {
    _logger.info('Starting notification service for session: ${session.id}');
    final androidPlugin = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
        final bool? permissionGranted = await androidPlugin.requestNotificationsPermission();
        if (permissionGranted == null || !permissionGranted) {
            _logger.warning("Notification permission not granted for Android.");
            return;
        }
    }
    
    _isServiceRunning = true;
    _currentSession = session;
    _currentExerciseIndex = currentExerciseIndex;
    _currentSetIndex = currentSetIndex;
    _sessionStartTime = session.startedAt ?? DateTime.now();
    
    _startPeriodicUpdates();
    
    await _showNotification();
    _logger.info('Notification service started successfully');
  }

  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession != null && _isServiceRunning) {
        _showNotification();
      }
    });
  }

  @override
  Future<void> updateNotification(Workout session, int currentExerciseIndex, int currentSetIndex) async {
    _logger.fine('Updating notification for session: ${session.id}');
    if (!_isServiceRunning) {
      _logger.warning('Service not running, starting it now');
      await startService(session, currentExerciseIndex, currentSetIndex);
      return;
    }
    
    _currentSession = session;
    _currentExerciseIndex = currentExerciseIndex;
    _currentSetIndex = currentSetIndex;
    
    await _showNotification();
    _logger.fine('Notification updated successfully');
  }

  @override
  Future<void> stopService() async {
    _logger.info('Stopping notification service');
    if (!_isServiceRunning) {
      _logger.info('Service was not running');
      return;
    }
    
    _updateTimer?.cancel();
    _updateTimer = null;
    _isServiceRunning = false;
    _currentSession = null;
    _sessionStartTime = null;
    _onNextSetCallback = null;
    
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    _logger.info('Notification service stopped');
  }

  @override
  Future<void> restartServiceIfNeeded(Workout? session, int currentExerciseIndex, int currentSetIndex) async {
    if (session != null && session.status == WorkoutStatus.inProgress && !_isServiceRunning) {
      _logger.info('Restarting notification service for active session: ${session.id}');
      await startService(session, currentExerciseIndex, currentSetIndex);
    }
  }

  Future<void> _showNotification() async {
    if (_currentSession == null) {
      _logger.finer('No current session, skipping notification update');
      return;
    }

    final sessionData = _formatSessionData(_currentSession!, _currentExerciseIndex, _currentSetIndex);
    _logger.finest('Showing notification with data: $sessionData');
    
    final String title = sessionData['title'] ?? 'Active Workout';
    final String body = sessionData['body'] ?? 'Tracking progress...';
    final String subText = sessionData['subText'] ?? '';
    final String elapsedTime = sessionData['elapsedTime'] ?? '00:00';
    final int completedSets = sessionData['completedSets'] ?? 0;
    final int totalSets = sessionData['totalSets'] ?? 0;
    final int progressValue = sessionData['progressValue'] ?? 0;
    //final bool canAdvanceSet = sessionData['canAdvanceSet'] ?? false;
    
    // Create notification actions
    List<AndroidNotificationAction> actions = [];

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      '$title | $elapsedTime',
      '$body${subText.isNotEmpty ? ' | $subText' : ''}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          notificationChannelName,
          channelDescription: notificationChannelDescription,
          icon: appIcon,
          ongoing: true,
          autoCancel: false,
          playSound: false,
          enableVibration: false,
          priority: Priority.low,
          importance: Importance.low,
          showProgress: true,
          maxProgress: 100,
          progress: progressValue,
          ticker: 'Workout Progress Update',
          subText: totalSets > 0 ? 'Sets: $completedSets/$totalSets' : null,
          actions: actions,
          category: AndroidNotificationCategory.workout,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
          subtitle: subText.isNotEmpty ? subText : null,
          threadIdentifier: 'workout_progress',
        ),
      ),
      payload: 'active_workout_screen'
    );
  }

  Map<String, dynamic> _formatSessionData(Workout session, int currentExerciseIndex, int currentSetIndex) {
    String currentExerciseName = "Workout Starting...";
    String nextExerciseName = "";
    String progressDetails = "";
    String setProgress = "";
    int totalWorkoutExercises = session.exercises.length;
    int currentWorkoutExerciseNum = currentExerciseIndex + 1;
    
    // Use the same progress calculation as the active workout screen
    int completedSets = 0;
    int totalSets = 0;
    
    // Calculate completed and total sets
    for (final exercise in session.exercises) {
      totalSets += exercise.sets.length;
      completedSets += exercise.sets.where((set) => set.isCompleted).length;
    }

    if (totalWorkoutExercises > 0 && currentExerciseIndex < totalWorkoutExercises) {
      final WorkoutExercise currentWorkoutExercise = session.exercises[currentExerciseIndex];
      // Use exerciseDetail, ensure it's loaded or provide fallback
      currentExerciseName = currentWorkoutExercise.exerciseDetail?.name ?? currentWorkoutExercise.exerciseSlug;

      if (currentWorkoutExercise.sets.isNotEmpty && currentSetIndex < currentWorkoutExercise.sets.length) {
        final WorkoutSet currentWorkoutSet = currentWorkoutExercise.sets[currentSetIndex];
        int currentSetNum = currentSetIndex + 1;
        int totalSetsForExercise = currentWorkoutExercise.sets.length;
        
        setProgress = "Set $currentSetNum of $totalSetsForExercise";
        
        // repRange fields removed from WorkoutSet, using targetReps
        String repsStr = currentWorkoutSet.targetReps != null 
            ? "${currentWorkoutSet.targetReps} reps" 
            : "Reps not set";
        progressDetails = repsStr;
        if (currentWorkoutSet.targetWeight != null && currentWorkoutSet.targetWeight! > 0) {
          progressDetails += " at ${currentWorkoutSet.targetWeight} kg"; // Assuming kg for now
        }
      } else if (currentWorkoutExercise.sets.isEmpty) {
        progressDetails = "No sets configured";
        setProgress = "Exercise $currentWorkoutExerciseNum of $totalWorkoutExercises";
      } else {
         progressDetails = "Moving to next exercise...";
         setProgress = "Exercise $currentWorkoutExerciseNum of $totalWorkoutExercises";
      }

      if (currentExerciseIndex + 1 < totalWorkoutExercises) {
        final nextWorkoutExercise = session.exercises[currentExerciseIndex + 1];
        // Use exerciseDetail, ensure it's loaded or provide fallback
        nextExerciseName = "Next: ${nextWorkoutExercise.exerciseDetail?.name ?? nextWorkoutExercise.exerciseSlug}";
      } else {
        nextExerciseName = "Final exercise!";
      }
    } else if (currentExerciseIndex >= totalWorkoutExercises && totalWorkoutExercises > 0) {
        currentExerciseName = "Workout Complete!";
        nextExerciseName = "Tap to finish";
        progressDetails = "Great job!";
        setProgress = "All exercises completed";
        currentWorkoutExerciseNum = totalWorkoutExercises;
        completedSets = totalSets;
    } else {
        currentExerciseName = "No exercises in workout";
        nextExerciseName = "";
        progressDetails = "";
        setProgress = "";
    }
    
    Duration elapsedTime = DateTime.now().difference(_sessionStartTime ?? (session.startedAt ?? DateTime.now()));
    String elapsedTimeStr = "${elapsedTime.inMinutes.toString().padLeft(2, '0')}:${(elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}";

    // Calculate progress percentage
    double progressValue = 0;
    if (totalSets > 0) {
      progressValue = (completedSets / totalSets) * 100;
      if (progressValue > 100) progressValue = 100;
    }

    return {
      'title': currentExerciseName,
      'body': '$setProgress | $progressDetails',
      'subText': nextExerciseName,
      'elapsedTime': elapsedTimeStr,
      'totalExercises': totalWorkoutExercises,
      'currentExerciseNum': currentWorkoutExerciseNum,
      'completedSets': completedSets,
      'totalSets': totalSets,
      'progressValue': progressValue.toInt(),
      'canAdvanceSet': currentExerciseIndex < totalWorkoutExercises && 
                      currentSetIndex < (totalWorkoutExercises > 0 ? session.exercises[currentExerciseIndex].sets.length : 0),
    };
  }
}
