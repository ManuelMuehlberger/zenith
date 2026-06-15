import 'package:flutter/cupertino.dart';

import '../../models/exercise.dart';
import '../../models/workout.dart';
import '../../services/exercise_service.dart';
import '../../services/insights_service.dart';
import '../../services/workout_muscle_activation_service.dart';
import '../workout_muscle_activation_radar_card.dart';

// policy: allow-public-api insights card showing muscle activation over recent workouts.
class WeeklyMuscleActivationCard extends StatefulWidget {
  const WeeklyMuscleActivationCard({
    super.key,
    this.insightsService,
    this.activationService,
    this.exerciseCatalog,
    this.now,
  });

  final InsightsService? insightsService;
  final WorkoutMuscleActivationService? activationService;
  final Map<String, Exercise>? exerciseCatalog;
  final DateTime? now;

  @override
  State<WeeklyMuscleActivationCard> createState() =>
      _WeeklyMuscleActivationCardState();
}

class _WeeklyMuscleActivationCardState
    extends State<WeeklyMuscleActivationCard> {
  late Future<WorkoutMuscleActivationProfile?> _profileFuture;

  InsightsService get _insightsService =>
      widget.insightsService ?? InsightsService.instance;

  WorkoutMuscleActivationService get _activationService =>
      widget.activationService ?? WorkoutMuscleActivationService();

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  @override
  void didUpdateWidget(covariant WeeklyMuscleActivationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.insightsService != oldWidget.insightsService ||
        widget.activationService != oldWidget.activationService ||
        widget.exerciseCatalog != oldWidget.exerciseCatalog ||
        widget.now != oldWidget.now) {
      _profileFuture = _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WorkoutMuscleActivationProfile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(child: CupertinoActivityIndicator(radius: 12)),
          );
        }

        final profile = snapshot.data;
        if (profile == null || !profile.hasActivation) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: WorkoutMuscleActivationRadarCard(
            profile: profile,
            title: 'Last month',
            idleSubtitle:
                'Last month activation with your latest workout overlay',
            plannedLabel: 'Last month',
            actualLabel: 'Last workout',
          ),
        );
      },
    );
  }

  Future<WorkoutMuscleActivationProfile?> _loadProfile() async {
    final workouts = await _insightsService.getWorkouts();
    final recentWorkouts = _hydrateWorkouts(
      _filterRecentCompletedWorkouts(
        workouts,
        widget.now ?? DateTime.now(),
      ).toList(growable: false),
    );

    if (recentWorkouts.isEmpty) {
      return null;
    }

    recentWorkouts.sort(_compareByMostRecentCompletion);
    final profile = await _buildComparisonProfile(recentWorkouts);
    return profile.hasActivation ? profile : null;
  }

  Future<WorkoutMuscleActivationProfile> _buildComparisonProfile(
    List<Workout> recentWorkouts,
  ) async {
    final config = await _activationService.loadConfig();
    final windowTotals =
        WorkoutMuscleActivationService.buildWorkoutsAxisActivation(
          recentWorkouts,
          config,
        );
    final latestWorkoutTotals =
        WorkoutMuscleActivationService.buildWorkoutAxisActivation(
          recentWorkouts.first,
          config,
        );

    final normalizer = _normalizerFor(windowTotals, latestWorkoutTotals);

    return WorkoutMuscleActivationProfile(
      points: config.axes
          .map(
            (axis) => WorkoutMuscleActivationPoint(
              axisId: axis.id,
              label: axis.label,
              planned: (windowTotals.actualFor(axis.id)) / normalizer,
              actual: (latestWorkoutTotals.actualFor(axis.id)) / normalizer,
            ),
          )
          .toList(growable: false),
    );
  }

  Iterable<Workout> _filterRecentCompletedWorkouts(
    Iterable<Workout> workouts,
    DateTime now,
  ) {
    final windowStart = now.subtract(const Duration(days: 30));
    return workouts.where((workout) {
      if (workout.status != WorkoutStatus.completed) {
        return false;
      }
      final occurredAt = workout.completedAt ?? workout.startedAt;
      if (occurredAt == null) {
        return false;
      }
      return !occurredAt.isBefore(windowStart) && !occurredAt.isAfter(now);
    });
  }

  int _compareByMostRecentCompletion(Workout left, Workout right) {
    final leftDate = left.completedAt ?? left.startedAt ?? DateTime(0);
    final rightDate = right.completedAt ?? right.startedAt ?? DateTime(0);
    return rightDate.compareTo(leftDate);
  }

  List<Workout> _hydrateWorkouts(List<Workout> workouts) {
    final catalog = widget.exerciseCatalog ?? _catalogFromService();
    if (catalog.isEmpty) {
      return workouts;
    }

    return workouts
        .map((workout) {
          final exercises = workout.exercises
              .map((exercise) {
                if (exercise.exerciseDetail != null) {
                  return exercise;
                }
                final detail = catalog[exercise.exerciseSlug];
                if (detail == null) {
                  return exercise;
                }
                return exercise.copyWith(exerciseDetail: detail);
              })
              .toList(growable: false);

          return workout.copyWith(exercises: exercises);
        })
        .toList(growable: false);
  }

  Map<String, Exercise> _catalogFromService() {
    final exerciseService = ExerciseService.instance;
    return {
      for (final exercise in exerciseService.exercises) exercise.slug: exercise,
    };
  }

  double _normalizerFor(
    WorkoutMuscleActivationTotals windowTotals,
    WorkoutMuscleActivationTotals latestWorkoutTotals,
  ) {
    var maxValue = 0.0;
    for (final value in windowTotals.actualByAxis.values) {
      if (value > maxValue) {
        maxValue = value;
      }
    }
    for (final value in latestWorkoutTotals.actualByAxis.values) {
      if (value > maxValue) {
        maxValue = value;
      }
    }
    return maxValue <= 0 ? 1 : maxValue;
  }
}
