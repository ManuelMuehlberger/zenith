import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:logging/logging.dart';

import '../models/workout.dart';
import '../models/workout_achievement.dart';

// policy: allow-public-api core logic for calculating rewards.
class WorkoutAchievementService {
  WorkoutAchievementService({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  static final WorkoutAchievementService instance = WorkoutAchievementService();

  static const String defaultRulesAsset =
      'assets/achievements/workout_achievement_rules.json';

  final AssetBundle _assetBundle;
  final Logger _logger = Logger('WorkoutAchievementService');
  List<_AchievementRule>? _cachedRules;

  Future<List<WorkoutAchievement>> evaluateForWorkout(
    Workout workout, {
    required Iterable<Workout> history,
    DateTime? earnedAt,
  }) async {
    if (workout.status != WorkoutStatus.completed) {
      return const [];
    }

    final rules = await _loadRules();
    final metrics = _AchievementMetrics.forWorkout(workout, history: history);
    final awards = <WorkoutAchievement>[];
    final awardTime = earnedAt ?? workout.completedAt ?? DateTime.now();

    for (final rule in rules) {
      if (!rule.matches(metrics.values)) {
        continue;
      }
      awards.add(
        WorkoutAchievement(
          workoutId: workout.id,
          ruleId: rule.id,
          type: rule.type,
          title: rule.title,
          reason: _interpolate(rule.reasonTemplate, {
            ...metrics.values,
            'workoutName': workout.name,
          }),
          earnedAt: awardTime,
          metrics: metrics.values,
        ),
      );
    }

    return List<WorkoutAchievement>.unmodifiable(awards);
  }

  @Deprecated('Use persisted workout.achievements instead.')
  static List<WorkoutAchievement> resolveForWorkout(Workout workout) {
    return workout.achievements;
  }

  Future<List<_AchievementRule>> _loadRules() async {
    final cached = _cachedRules;
    if (cached != null) {
      return cached;
    }

    try {
      final raw = await _assetBundle.loadString(defaultRulesAsset);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Achievement rules root must be an object');
      }
      final rulesJson = decoded['rules'];
      if (rulesJson is! List) {
        throw const FormatException('Achievement rules must contain a list');
      }
      final rules = rulesJson
          .map((json) => _AchievementRule.fromJson(json))
          .toList(growable: false);
      _cachedRules = rules;
      return rules;
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to load workout achievement rules',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  String _interpolate(String template, Map<String, Object?> values) {
    var result = template;
    for (final entry in values.entries) {
      result = result.replaceAll(
        '{${entry.key}}',
        _formatTemplateValue(entry.value),
      );
    }
    return result;
  }

  String _formatTemplateValue(Object? value) {
    if (value == null) {
      return '';
    }
    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.round().toString();
      }
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }
}

class _AchievementMetrics {
  _AchievementMetrics(this.values);

  final Map<String, Object?> values;

  static _AchievementMetrics forWorkout(
    Workout workout, {
    required Iterable<Workout> history,
  }) {
    final completedAt =
        workout.completedAt ?? workout.startedAt ?? DateTime.now();
    final comparableHistory = history
        .where((candidate) {
          final timestamp = candidate.completedAt ?? candidate.startedAt;
          return candidate.status == WorkoutStatus.completed &&
              candidate.id != workout.id &&
              timestamp != null &&
              timestamp.isBefore(completedAt);
        })
        .toList(growable: false);

    const comparisonWindowDays = 90;
    final windowStart = completedAt.subtract(
      const Duration(days: comparisonWindowDays),
    );
    final recentHistory = comparableHistory
        .where((candidate) {
          final timestamp = candidate.completedAt ?? candidate.startedAt;
          return timestamp != null && !timestamp.isBefore(windowStart);
        })
        .toList(growable: false);

    final durationMinutes = _durationOf(workout).inMinutes;
    final totalSetsPercentile = _percentileAboveHistory(
      workout.totalSets,
      recentHistory.map((candidate) => candidate.totalSets),
    );

    return _AchievementMetrics(
      Map<String, Object?>.unmodifiable({
        'totalSets': workout.totalSets,
        'completedSets': workout.completedSets,
        'durationMinutes': durationMinutes,
        'totalWeight': workout.totalWeight,
        'exerciseCount': workout.exercises.length,
        'workoutCountBefore': comparableHistory.length,
        'comparisonWindowDays': comparisonWindowDays,
        'comparisonWorkoutCount': recentHistory.length,
        'totalSetsPercentileLast90Days': totalSetsPercentile,
      }),
    );
  }

  static double? _percentileAboveHistory(
    num current,
    Iterable<num> historyValues,
  ) {
    final values = historyValues.toList(growable: false);
    if (values.isEmpty) {
      return null;
    }
    final lowerCount = values.where((value) => current > value).length;
    return min(100, max(0, (lowerCount / values.length) * 100));
  }

  static Duration _durationOf(Workout workout) {
    final started = workout.startedAt;
    final completed = workout.completedAt;
    if (started == null || completed == null) {
      return Duration.zero;
    }
    final duration = completed.difference(started);
    return duration.isNegative ? Duration.zero : duration;
  }
}

class _AchievementRule {
  _AchievementRule({
    required this.id,
    required this.type,
    required this.title,
    required this.reasonTemplate,
    required this.conditions,
  });

  final String id;
  final WorkoutAchievementType type;
  final String title;
  final String reasonTemplate;
  final List<_RuleCondition> conditions;

  factory _AchievementRule.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Achievement rule must be an object');
    }
    final conditionsJson = json['conditions'];
    if (conditionsJson is! List) {
      throw const FormatException('Achievement rule conditions must be a list');
    }

    return _AchievementRule(
      id: _readString(json, 'id'),
      type: _readType(json['type']),
      title: _readString(json, 'title'),
      reasonTemplate: _readString(json, 'reasonTemplate'),
      conditions: conditionsJson
          .map((condition) => _RuleCondition.fromJson(condition))
          .toList(growable: false),
    );
  }

  bool matches(Map<String, Object?> metrics) {
    return conditions.every((condition) => condition.matches(metrics));
  }
}

class _RuleCondition {
  _RuleCondition({
    required this.metric,
    required this.operator,
    required this.value,
  });

  final String metric;
  final String operator;
  final Object? value;

  factory _RuleCondition.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException(
        'Achievement rule condition must be an object',
      );
    }
    return _RuleCondition(
      metric: _readString(json, 'metric'),
      operator: _readString(json, 'operator'),
      value: json['value'],
    );
  }

  bool matches(Map<String, Object?> metrics) {
    final metricValue = metrics[metric];
    if (metricValue == null) {
      return false;
    }

    switch (operator) {
      case 'equals':
        return metricValue == value;
      case 'greaterThan':
        return _compare(metricValue, value, (left, right) => left > right);
      case 'greaterThanOrEqual':
        return _compare(metricValue, value, (left, right) => left >= right);
      case 'lessThan':
        return _compare(metricValue, value, (left, right) => left < right);
      case 'lessThanOrEqual':
        return _compare(metricValue, value, (left, right) => left <= right);
      default:
        throw FormatException('Unsupported achievement operator "$operator"');
    }
  }

  bool _compare(
    Object? left,
    Object? right,
    bool Function(num left, num right) compare,
  ) {
    if (left is! num || right is! num) {
      return false;
    }
    return compare(left, right);
  }
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing achievement rule "$key"');
}

WorkoutAchievementType _readType(Object? value) {
  if (value is String) {
    for (final type in WorkoutAchievementType.values) {
      if (type.name == value) {
        return type;
      }
    }
  }
  throw FormatException('Invalid achievement type "$value"');
}
