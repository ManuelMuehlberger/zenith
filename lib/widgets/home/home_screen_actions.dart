import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../../models/workout.dart';
import '../../screens/home/home_timeline_data.dart';
import '../../screens/workout_detail_screen.dart';
import '../../screens/workout_history_screen.dart';
import '../../services/workout_session_service.dart';
import '../../utils/navigation_helper.dart';

// policy: no-test-needed actions are covered by Home screen flow tests.
class HomeScreenActions {
  const HomeScreenActions._();

  static void handleWorkoutServiceChanged({
    required bool mounted,
    required ValueChanged<List<Workout>> applyTimeline,
    required List<Workout> workouts,
  }) {
    if (!mounted) return;
    applyTimeline(workouts);
  }

  static void applyTimeline({
    required bool mounted,
    required Logger logger,
    required List<Workout> workouts,
    required ValueChanged<HomeTimelineData> onTimelineReady,
    required VoidCallback onFailure,
  }) {
    if (!mounted) return;
    try {
      logger.info('Loading completed workouts for Home timeline');
      logger.fine(
        'Loaded ${workouts.length} workouts from WorkoutService cache',
      );
      onTimelineReady(HomeTimelineAssembler.build(workouts));
      logger.info('Home timeline workouts loaded successfully');
    } catch (error) {
      logger.severe('Failed to load workouts for Home timeline: $error');
      onFailure();
    }
  }

  static Future<void> loadWorkouts({
    required bool mounted,
    required void Function(VoidCallback fn) setStateCallback,
    required ValueChanged<bool> setLoading,
    required Future<void> Function() loadData,
  }) async {
    if (!mounted) return;
    setStateCallback(() {
      setLoading(true);
    });
    await loadData();
  }

  static Future<void> openWorkoutDetail({
    required BuildContext context,
    required Workout workout,
    required Future<void> Function() loadWorkouts,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(workout: workout),
      ),
    );
    if (result == true) {
      unawaited(loadWorkouts());
    }
  }

  static Future<void> openWorkoutHistory({
    required BuildContext context,
    required Future<void> Function() loadWorkouts,
  }) async {
    await Navigator.push<void>(
      context,
      CupertinoPageRoute<void>(
        builder: (context) => const WorkoutHistoryScreen(),
      ),
    );
    unawaited(loadWorkouts());
  }

  static Future<void> startWorkout({
    required BuildContext context,
    required Workout workout,
    required Future<void> Function() loadWorkouts,
  }) async {
    try {
      await WorkoutSessionService.instance.startWorkout(workout);
      unawaited(HapticFeedback.mediumImpact());
      NavigationHelper.goToTab(1);
      unawaited(loadWorkouts());
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start workout: $error'),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  static void openWorkoutBuilder() {
    HapticFeedback.selectionClick();
    NavigationHelper.goToTab(1);
  }
}
