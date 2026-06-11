import 'package:flutter/foundation.dart';

// policy: allow-public-api ephemeral insight feed card rendered on Insights.
enum InsightFeedCardType {
  trainingVelocity,
  recentAchievementShoutout,
  highIntensityShoutout,
  consistencyPulse,
  comebackCard,
  personalBestMomentum,
}

@immutable
// policy: allow-public-api serializable card payload for the insights feed.
class InsightFeedCard {
  final String id;
  final InsightFeedCardType type;
  final int priority;
  final String title;
  final String body;
  final String metric;
  final String accent;
  final String icon;
  final DateTime generatedAt;
  final String? sourceWorkoutId;

  const InsightFeedCard({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.body,
    required this.metric,
    required this.accent,
    required this.icon,
    required this.generatedAt,
    this.sourceWorkoutId,
  });

  factory InsightFeedCard.fromMap(Map<String, dynamic> map) {
    return InsightFeedCard(
      id: _readString(map, 'id'),
      type: _readType(map['type']),
      priority: _readInt(map, 'priority'),
      title: _readString(map, 'title'),
      body: _readString(map, 'body'),
      metric: _readString(map, 'metric'),
      accent: _readString(map, 'accent'),
      icon: _readString(map, 'icon'),
      generatedAt: DateTime.parse(_readString(map, 'generatedAt')),
      sourceWorkoutId: map['sourceWorkoutId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'priority': priority,
      'title': title,
      'body': body,
      'metric': metric,
      'accent': accent,
      'icon': icon,
      'generatedAt': generatedAt.toIso8601String(),
      'sourceWorkoutId': sourceWorkoutId,
    };
  }
}

@immutable
// policy: allow-public-api rule definition controlling feed card generation.
class InsightFeedRule {
  final String id;
  final InsightFeedCardType type;
  final bool enabled;
  final int priority;
  final Map<String, Object?> params;

  const InsightFeedRule({
    required this.id,
    required this.type,
    required this.enabled,
    required this.priority,
    this.params = const {},
  });

  factory InsightFeedRule.fromMap(Map<String, dynamic> map) {
    return InsightFeedRule(
      id: _readString(map, 'id'),
      type: _readType(map['type']),
      enabled: map['enabled'] != false,
      priority: _readInt(map, 'priority'),
      params: Map<String, Object?>.unmodifiable(
        (map['params'] as Map?)?.cast<String, Object?>() ?? const {},
      ),
    );
  }
}

String _readString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing or invalid "$key" for InsightFeed');
}

int _readInt(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is int) {
    return value;
  }
  throw FormatException('Missing or invalid "$key" for InsightFeed');
}

InsightFeedCardType _readType(Object? value) {
  if (value is String) {
    for (final type in InsightFeedCardType.values) {
      if (type.name == value) {
        return type;
      }
    }
  }
  throw const FormatException('Invalid insight feed card type');
}
