import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';

// policy: allow-public-api configuration contract for workout muscle radar axes.
class WorkoutMuscleActivationAxis {
  const WorkoutMuscleActivationAxis({required this.id, required this.label});

  final String id;
  final String label;

  factory WorkoutMuscleActivationAxis.fromJson(Map<String, dynamic> json) {
    return WorkoutMuscleActivationAxis(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }
}

// policy: allow-public-api configuration contract for workout muscle activation rules.
class WorkoutMuscleActivationConfig {
  const WorkoutMuscleActivationConfig({
    required this.primaryWeight,
    required this.secondaryWeight,
    required this.axes,
    required this.muscleContributions,
  });

  final double primaryWeight;
  final double secondaryWeight;
  final List<WorkoutMuscleActivationAxis> axes;
  final Map<MuscleGroup, Map<String, double>> muscleContributions;

  factory WorkoutMuscleActivationConfig.fromJson(Map<String, dynamic> json) {
    final weights = json['activationWeights'] as Map<String, dynamic>? ?? {};
    final axesJson = json['radarAxes'] as List<dynamic>? ?? const [];
    final contributionsJson =
        json['muscleContributions'] as Map<String, dynamic>? ?? {};
    final axes = axesJson
        .cast<Map<String, dynamic>>()
        .map(WorkoutMuscleActivationAxis.fromJson)
        .toList(growable: false);

    return WorkoutMuscleActivationConfig(
      primaryWeight: (weights['primary'] as num? ?? 1).toDouble(),
      secondaryWeight: (weights['secondary'] as num? ?? 0.35).toDouble(),
      axes: axes,
      muscleContributions: _readMuscleContributions(contributionsJson),
    );
  }
}

// policy: allow-public-api view-model point consumed by workout muscle activation widgets.
class WorkoutMuscleActivationPoint {
  const WorkoutMuscleActivationPoint({
    required this.axisId,
    required this.label,
    required this.planned,
    required this.actual,
  });

  final String axisId;
  final String label;
  final double planned;
  final double actual;

  double get completionRatio {
    if (planned <= 0) {
      return 0;
    }
    return (actual / planned).clamp(0, 1).toDouble();
  }
}

// policy: allow-public-api view-model consumed by workout completion presentation.
class WorkoutMuscleActivationProfile {
  const WorkoutMuscleActivationProfile({required this.points});

  final List<WorkoutMuscleActivationPoint> points;

  bool get hasActivation =>
      points.any((point) => point.planned > 0 || point.actual > 0);
}

// policy: allow-public-api raw planned/actual activation totals for service consumers.
class WorkoutMuscleActivationTotals {
  const WorkoutMuscleActivationTotals({
    required this.plannedByAxis,
    required this.actualByAxis,
  });

  final Map<String, double> plannedByAxis;
  final Map<String, double> actualByAxis;

  double plannedFor(String axisId) => plannedByAxis[axisId] ?? 0;

  double actualFor(String axisId) => actualByAxis[axisId] ?? 0;

  double completionRatioFor(String axisId) {
    final planned = plannedFor(axisId);
    if (planned <= 0) {
      return 0;
    }
    return (actualFor(axisId) / planned).clamp(0, 1).toDouble();
  }
}

// policy: allow-public-api service contract for computing workout muscle activation profiles.
class WorkoutMuscleActivationService {
  WorkoutMuscleActivationService({
    AssetBundle? assetBundle,
    this.configAsset = defaultConfigAsset,
  }) : _assetBundle = assetBundle ?? rootBundle;

  static const defaultConfigAsset =
      'assets/workout/workout_analysis_config.json';

  final AssetBundle _assetBundle;
  final String configAsset;
  Future<WorkoutMuscleActivationConfig>? _configFuture;

  Future<WorkoutMuscleActivationProfile> buildProfile(Workout workout) async {
    final config = await loadConfig();
    return buildProfileFromConfig(workout, config);
  }

  Future<WorkoutMuscleActivationProfile> buildProfileForWorkouts(
    Iterable<Workout> workouts,
  ) async {
    final config = await loadConfig();
    return buildProfileForWorkoutsFromConfig(workouts, config);
  }

  Future<WorkoutMuscleActivationConfig> loadConfig() {
    return _configFuture ??= _loadConfig();
  }

  Future<WorkoutMuscleActivationConfig> _loadConfig() async {
    final raw = await _assetBundle.loadString(configAsset);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return WorkoutMuscleActivationConfig.fromJson(decoded);
  }

  static WorkoutMuscleActivationProfile buildProfileFromConfig(
    Workout workout,
    WorkoutMuscleActivationConfig config,
  ) {
    return buildProfileForWorkoutsFromConfig([workout], config);
  }

  static WorkoutMuscleActivationProfile buildProfileForWorkoutsFromConfig(
    Iterable<Workout> workouts,
    WorkoutMuscleActivationConfig config,
  ) {
    final totals = buildWorkoutsAxisActivation(workouts, config);
    final plannedByAxis = totals.plannedByAxis;
    final actualByAxis = totals.actualByAxis;

    final normalizer = _normalizerFor(plannedByAxis, actualByAxis);

    return WorkoutMuscleActivationProfile(
      points: config.axes
          .map(
            (axis) => WorkoutMuscleActivationPoint(
              axisId: axis.id,
              label: axis.label,
              planned: (plannedByAxis[axis.id] ?? 0) / normalizer,
              actual: (actualByAxis[axis.id] ?? 0) / normalizer,
            ),
          )
          .toList(growable: false),
    );
  }

  static WorkoutMuscleActivationTotals buildWorkoutAxisActivation(
    Workout workout,
    WorkoutMuscleActivationConfig config,
  ) {
    return buildWorkoutsAxisActivation([workout], config);
  }

  static WorkoutMuscleActivationTotals buildWorkoutsAxisActivation(
    Iterable<Workout> workouts,
    WorkoutMuscleActivationConfig config,
  ) {
    final plannedByAxis = _emptyAxisMap(config);
    final actualByAxis = _emptyAxisMap(config);

    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        _accumulateExerciseActivation(
          exercise,
          config,
          plannedByAxis,
          actualByAxis,
        );
      }
    }

    return WorkoutMuscleActivationTotals(
      plannedByAxis: Map.unmodifiable(plannedByAxis),
      actualByAxis: Map.unmodifiable(actualByAxis),
    );
  }

  static Map<MuscleGroup, double> buildExerciseMuscleActivation(
    Exercise exercise,
    WorkoutMuscleActivationConfig config,
  ) {
    final exerciseIntensity = exercise.exerciseIntensity;
    final explicitActivation = exercise.muscleActivation;

    if (explicitActivation.isNotEmpty) {
      return Map.unmodifiable({
        for (final entry in explicitActivation.entries)
          if (entry.value > 0) entry.key: entry.value * exerciseIntensity,
      });
    }

    final activation = <MuscleGroup, double>{};
    _addMuscleActivation(
      activation,
      exercise.primaryMuscleGroup,
      config.primaryWeight * exerciseIntensity,
    );
    for (final secondary in exercise.secondaryMuscleGroups) {
      _addMuscleActivation(
        activation,
        secondary,
        config.secondaryWeight * exerciseIntensity,
      );
    }
    return Map.unmodifiable(activation);
  }

  static Map<String, double> buildExerciseAxisActivation(
    Exercise exercise,
    WorkoutMuscleActivationConfig config,
  ) {
    final axisWeights = _emptyAxisMap(config);
    final muscleActivation = buildExerciseMuscleActivation(exercise, config);
    for (final entry in muscleActivation.entries) {
      _applyMuscleContribution(axisWeights, entry.key, entry.value, config);
    }
    return Map.unmodifiable(axisWeights);
  }

  static double exerciseActivationLoad(
    Exercise exercise,
    WorkoutMuscleActivationConfig config,
  ) {
    return buildExerciseMuscleActivation(
      exercise,
      config,
    ).values.fold<double>(0, (sum, weight) => sum + weight);
  }
}

Map<String, double> _emptyAxisMap(WorkoutMuscleActivationConfig config) {
  return <String, double>{for (final axis in config.axes) axis.id: 0};
}

void _accumulateExerciseActivation(
  WorkoutExercise exercise,
  WorkoutMuscleActivationConfig config,
  Map<String, double> plannedByAxis,
  Map<String, double> actualByAxis,
) {
  final detail = exercise.exerciseDetail;
  if (detail == null) {
    return;
  }

  final plannedSetCount = exercise.sets.length;
  final actualSetCount = exercise.sets.where((set) => set.isCompleted).length;
  if (plannedSetCount == 0 && actualSetCount == 0) {
    return;
  }

  final axisWeights =
      WorkoutMuscleActivationService.buildExerciseAxisActivation(
        detail,
        config,
      );
  for (final entry in axisWeights.entries) {
    if (entry.value <= 0) {
      continue;
    }
    plannedByAxis[entry.key] =
        (plannedByAxis[entry.key] ?? 0) + plannedSetCount * entry.value;
    actualByAxis[entry.key] =
        (actualByAxis[entry.key] ?? 0) + actualSetCount * entry.value;
  }
}

void _applyMuscleContribution(
  Map<String, double> axisWeights,
  MuscleGroup muscleGroup,
  double weight,
  WorkoutMuscleActivationConfig config,
) {
  final contributions = config.muscleContributions[muscleGroup];
  if (contributions == null) {
    return;
  }
  for (final entry in contributions.entries) {
    if (!axisWeights.containsKey(entry.key)) {
      continue;
    }
    axisWeights[entry.key] =
        (axisWeights[entry.key] ?? 0) + weight * entry.value;
  }
}

void _addMuscleActivation(
  Map<MuscleGroup, double> activation,
  MuscleGroup muscleGroup,
  double weight,
) {
  if (weight <= 0) {
    return;
  }
  activation[muscleGroup] = (activation[muscleGroup] ?? 0) + weight;
}

double _normalizerFor(
  Map<String, double> plannedByAxis,
  Map<String, double> actualByAxis,
) {
  final maxActivation = max(
    plannedByAxis.values.fold<double>(0, max),
    actualByAxis.values.fold<double>(0, max),
  );
  return maxActivation <= 0 ? 1 : maxActivation;
}

Map<MuscleGroup, Map<String, double>> _readMuscleContributions(
  Map<String, dynamic> json,
) {
  return json.map((muscleName, value) {
    final contributionJson = value as Map<String, dynamic>;
    return MapEntry(
      MuscleGroup.fromName(muscleName),
      contributionJson.map(
        (axisId, percentage) =>
            MapEntry(axisId, (percentage as num).toDouble()),
      ),
    );
  });
}
