import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'typedefs.dart';

// policy: allow-public-api core model for achievement system.
enum WorkoutAchievementType {
  firstWorkout,
  highVolume,
  longSession,
  heavy,
  workoutMilestone,
  workoutStreak,
}

@immutable
// policy: allow-public-api data model for tracking workout milestones.
class WorkoutAchievement {
  final WorkoutAchievementId id;
  final WorkoutId workoutId;
  final String ruleId;
  final WorkoutAchievementType type;
  final String title;
  final String reason;
  final DateTime earnedAt;
  final Map<String, Object?> metrics;

  WorkoutAchievement({
    WorkoutAchievementId? id,
    required this.workoutId,
    required this.ruleId,
    required this.type,
    required this.title,
    required this.reason,
    required this.earnedAt,
    Map<String, Object?> metrics = const {},
  }) : id = id ?? const Uuid().v4(),
       metrics = Map<String, Object?>.unmodifiable(metrics);

  factory WorkoutAchievement.fromMap(Map<String, dynamic> map) {
    return WorkoutAchievement(
      id: _readRequiredString(map, 'id'),
      workoutId: _readRequiredString(map, 'workoutId'),
      ruleId: _readRequiredString(map, 'ruleId'),
      type: _readAchievementType(map['type']),
      title: _readRequiredString(map, 'title'),
      reason: _readRequiredString(map, 'reason'),
      earnedAt: _readRequiredDateTime(map, 'earnedAt'),
      metrics: _readMetrics(map['metricsJson']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'ruleId': ruleId,
      'type': type.name,
      'title': title,
      'reason': reason,
      'earnedAt': earnedAt.toIso8601String(),
      'metricsJson': jsonEncode(metrics),
    };
  }
}

String _readRequiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing or invalid "$key" for WorkoutAchievement');
}

DateTime _readRequiredDateTime(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String) {
    return DateTime.parse(value);
  }
  throw FormatException('Invalid "$key" for WorkoutAchievement');
}

WorkoutAchievementType _readAchievementType(Object? value) {
  if (value is String) {
    for (final type in WorkoutAchievementType.values) {
      if (type.name == value) {
        return type;
      }
    }
  }
  if (value is int &&
      value >= 0 &&
      value < WorkoutAchievementType.values.length) {
    return WorkoutAchievementType.values[value];
  }
  throw const FormatException('Invalid "type" for WorkoutAchievement');
}

Map<String, Object?> _readMetrics(Object? value) {
  if (value == null) {
    return const {};
  }
  if (value is! String || value.isEmpty) {
    throw const FormatException('Invalid "metricsJson" for WorkoutAchievement');
  }
  final decoded = jsonDecode(value);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Invalid achievement metrics payload');
  }
  return Map<String, Object?>.unmodifiable(decoded);
}
