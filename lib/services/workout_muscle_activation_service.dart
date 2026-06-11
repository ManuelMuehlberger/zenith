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
    final plannedByAxis = _emptyAxisMap(config);
    final actualByAxis = _emptyAxisMap(config);

    for (final exercise in workout.exercises) {
      _accumulateExerciseActivation(
        exercise,
        config,
        plannedByAxis,
        actualByAxis,
      );
    }

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

  final axisWeights = _axisWeightsForExercise(detail, config);
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

Map<String, double> _axisWeightsForExercise(
  Exercise detail,
  WorkoutMuscleActivationConfig config,
) {
  final axisWeights = _emptyAxisMap(config);
  _applyMuscleContribution(
    axisWeights,
    detail.primaryMuscleGroup,
    config.primaryWeight,
    config,
  );
  for (final secondary in detail.secondaryMuscleGroups) {
    _applyMuscleContribution(
      axisWeights,
      secondary,
      config.secondaryWeight,
      config,
    );
  }
  return axisWeights;
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
