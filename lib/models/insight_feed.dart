import 'package:flutter/foundation.dart';

// policy: allow-public-api ephemeral insight feed card rendered on Insights.
enum InsightFeedCardType {
  trainingVelocity,
  recentAchievementShoutout,
  highIntensityShoutout,
  consistencyPulse,
  comebackCard,
  personalBestMomentum,
  muscleActivationRadar,
  latestWorkoutComparison,
  bodyWeightTrend,
}

// policy: allow-public-api visual variants supported by insights feed cards.
enum InsightFeedVisualType {
  none,
  baselineBars,
  calendarStrip,
  sparklineBand,
  percentileDot,
  radar,
  bodyWeightLine,
  awardPreview,
}

// policy: allow-public-api visual size contract for insights feed cards.
enum InsightFeedCardSize { compact, wide, featured }

@immutable
// policy: allow-public-api visual configuration parsed from feed rules.
class InsightFeedVisualConfig {
  final bool enabled;
  final InsightFeedVisualType type;
  final InsightFeedCardSize size;
  final Map<String, Object?> params;

  const InsightFeedVisualConfig({
    this.enabled = false,
    this.type = InsightFeedVisualType.none,
    this.size = InsightFeedCardSize.wide,
    this.params = const {},
  });

  factory InsightFeedVisualConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const InsightFeedVisualConfig();
    }
    return InsightFeedVisualConfig(
      enabled: map['enabled'] == true,
      type: _readVisualType(map['type']),
      size: _readCardSize(map['size']),
      params: Map<String, Object?>.unmodifiable(
        (map['params'] as Map?)?.cast<String, Object?>() ?? const {},
      ),
    );
  }
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
  final InsightFeedVisualType visualType;
  final InsightFeedCardSize size;
  final Map<String, Object?> visualData;
  final String? detailMetricLabel;
  final String? comparisonLabel;

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
    this.visualType = InsightFeedVisualType.none,
    this.size = InsightFeedCardSize.wide,
    this.visualData = const {},
    this.detailMetricLabel,
    this.comparisonLabel,
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
      visualType: _readVisualType(map['visualType']),
      size: _readCardSize(map['size']),
      visualData: Map<String, Object?>.unmodifiable(
        (map['visualData'] as Map?)?.cast<String, Object?>() ?? const {},
      ),
      detailMetricLabel: map['detailMetricLabel'] as String?,
      comparisonLabel: map['comparisonLabel'] as String?,
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
      'visualType': visualType.name,
      'size': size.name,
      'visualData': visualData,
      'detailMetricLabel': detailMetricLabel,
      'comparisonLabel': comparisonLabel,
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
  final InsightFeedVisualConfig visual;

  const InsightFeedRule({
    required this.id,
    required this.type,
    required this.enabled,
    required this.priority,
    this.params = const {},
    this.visual = const InsightFeedVisualConfig(),
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
      visual: InsightFeedVisualConfig.fromMap(
        (map['visual'] as Map?)?.cast<String, dynamic>(),
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

InsightFeedVisualType _readVisualType(Object? value) {
  if (value is String) {
    for (final type in InsightFeedVisualType.values) {
      if (type.name == value) {
        return type;
      }
    }
  }
  return InsightFeedVisualType.none;
}

InsightFeedCardSize _readCardSize(Object? value) {
  if (value is String) {
    for (final size in InsightFeedCardSize.values) {
      if (size.name == value) {
        return size;
      }
    }
  }
  return InsightFeedCardSize.wide;
}
