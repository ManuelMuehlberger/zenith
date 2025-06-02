import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/workout_session.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';

const String notificationChannelId = 'workout_progress_channel';
const String notificationChannelName = 'Workout Progress';
const String notificationChannelDescription = 'Notifications for active workout progress';
const int notificationId = 888;
const String appIcon = 'ic_workout_notification';

class LiveWorkoutNotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  static final LiveWorkoutNotificationService _instance = LiveWorkoutNotificationService._internal();
  factory LiveWorkoutNotificationService() => _instance;
  LiveWorkoutNotificationService._internal();

  bool _isServiceRunning = false;
  Timer? _updateTimer;
  WorkoutSession? _currentSession;
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  DateTime? _sessionStartTime;
  
  // Callback for handling notification actions
  Function()? _onNextSetCallback;
  
  bool get isServiceRunning => _isServiceRunning;

  Future<void> initialize() async {
    // Initialize flutter_local_notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(appIcon);

    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        // Handle notification tapped logic here if needed for older iOS versions
      },
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        debugPrint('Notification action: ${notificationResponse.actionId}');
        
        // Handle notification actions
        if (notificationResponse.actionId == 'next_set') {
          debugPrint('Next set action triggered from notification');
          // Call the callback if it's set
          if (_onNextSetCallback != null) {
            _onNextSetCallback!();
          }
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
  }

  void setNextSetCallback(Function() callback) {
    _onNextSetCallback = callback;
  }

  Future<void> startService(WorkoutSession session, int currentExerciseIndex, int currentSetIndex) async {
    final androidPlugin = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
        final bool? permissionGranted = await androidPlugin.requestNotificationsPermission();
        if (permissionGranted == null || !permissionGranted) {
            debugPrint("Notification permission not granted for Android.");
            return;
        }
    }
    
    _isServiceRunning = true;
    _currentSession = session;
    _currentExerciseIndex = currentExerciseIndex;
    _currentSetIndex = currentSetIndex;
    _sessionStartTime = session.startTime;
    
    // Start periodic updates every second for real-time elapsed time
    _startPeriodicUpdates();
    
    // Show initial notification
    await _showNotification();
  }

  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession != null && _isServiceRunning) {
        _showNotification();
      }
    });
  }

  Future<void> updateNotification(WorkoutSession session, int currentExerciseIndex, int currentSetIndex) async {
    if (!_isServiceRunning) {
      await startService(session, currentExerciseIndex, currentSetIndex);
      return;
    }
    
    _currentSession = session;
    _currentExerciseIndex = currentExerciseIndex;
    _currentSetIndex = currentSetIndex;
    
    await _showNotification();
  }

  Future<void> stopService() async {
    if (!_isServiceRunning) return;
    
    _updateTimer?.cancel();
    _updateTimer = null;
    _isServiceRunning = false;
    _currentSession = null;
    _sessionStartTime = null;
    _onNextSetCallback = null;
    
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  Future<void> restartServiceIfNeeded(WorkoutSession? session, int currentExerciseIndex, int currentSetIndex) async {
    if (session != null && !session.isCompleted && !_isServiceRunning) {
      debugPrint("[LiveWorkoutNotificationService] Restarting notification service for active session");
      await startService(session, currentExerciseIndex, currentSetIndex);
    }
  }

  Future<void> _showNotification() async {
    if (_currentSession == null) return;

    final sessionData = _formatSessionData(_currentSession!, _currentExerciseIndex, _currentSetIndex);
    
    final String title = sessionData['title'] ?? 'Active Workout';
    final String body = sessionData['body'] ?? 'Tracking progress...';
    final String subText = sessionData['subText'] ?? '';
    final String elapsedTime = sessionData['elapsedTime'] ?? '00:00';
    final int completedSets = sessionData['completedSets'] ?? 0;
    final int totalSets = sessionData['totalSets'] ?? 0;
    final int progressValue = sessionData['progressValue'] ?? 0;
    final bool canAdvanceSet = sessionData['canAdvanceSet'] ?? false;
    
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

  Map<String, dynamic> _formatSessionData(WorkoutSession session, int currentExerciseIndex, int currentSetIndex) {
    String currentExerciseName = "Workout Starting...";
    String nextExerciseName = "";
    String progressDetails = "";
    String setProgress = "";
    int totalWorkoutExercises = session.workout.exercises.length;
    int currentWorkoutExerciseNum = currentExerciseIndex + 1;
    
    // Use the same progress calculation as the active workout screen
    int completedSets = session.completedSets;
    int totalSets = session.totalSets;

    if (totalWorkoutExercises > 0 && currentExerciseIndex < totalWorkoutExercises) {
      final WorkoutExercise currentWorkoutExercise = session.workout.exercises[currentExerciseIndex];
      currentExerciseName = currentWorkoutExercise.exercise.name;

      if (currentWorkoutExercise.sets.isNotEmpty && currentSetIndex < currentWorkoutExercise.sets.length) {
        final WorkoutSet currentWorkoutSet = currentWorkoutExercise.sets[currentSetIndex];
        int currentSetNum = currentSetIndex + 1;
        int totalSetsForExercise = currentWorkoutExercise.sets.length;
        
        setProgress = "Set $currentSetNum of $totalSetsForExercise";
        
        String repsStr = currentWorkoutSet.isRepRange 
            ? "${currentWorkoutSet.repRangeMin}-${currentWorkoutSet.repRangeMax} reps" 
            : "${currentWorkoutSet.reps} reps";
        progressDetails = repsStr;
        if (currentWorkoutSet.weight > 0) {
          progressDetails += " at ${currentWorkoutSet.weight} kg";
        }
      } else if (currentWorkoutExercise.sets.isEmpty) {
        progressDetails = "No sets configured";
        setProgress = "Exercise $currentWorkoutExerciseNum of $totalWorkoutExercises";
      } else {
         progressDetails = "Moving to next exercise...";
         setProgress = "Exercise $currentWorkoutExerciseNum of $totalWorkoutExercises";
      }

      if (currentExerciseIndex + 1 < totalWorkoutExercises) {
        nextExerciseName = "Next: ${session.workout.exercises[currentExerciseIndex + 1].exercise.name}";
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
    
    Duration elapsedTime = DateTime.now().difference(_sessionStartTime ?? session.startTime);
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
                      currentSetIndex < (totalWorkoutExercises > 0 ? session.workout.exercises[currentExerciseIndex].sets.length : 0),
    };
  }
}
