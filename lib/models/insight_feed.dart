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
  trainingBalance,
}

// policy: allow-public-api visual variants supported by insights feed cards.
enum InsightFeedVisualType {
  none,
  baselineBars,
  trainingVelocityLine,
  calendarStrip,
  sparklineBand,
  percentileDot,
  radar,
  bodyWeightLine,
  awardPreview,
  balanceFingerprint,
}

// policy: allow-public-api visual size contract for insights feed cards.
enum InsightFeedCardSize { compact, wide, featured }

@immutable
// policy: allow-public-api configurable stack definition for the insights feed.
class InsightFeedStackConfig {
  final String id;
  final String title;
  final bool enabled;
  final int priority;
  final int minCompletedWorkouts;
  final int maxCards;

  const InsightFeedStackConfig({
    required this.id,
    required this.title,
    required this.enabled,
    required this.priority,
    required this.minCompletedWorkouts,
    required this.maxCards,
  });

  factory InsightFeedStackConfig.fromMap(Map<String, dynamic> map) {
    return InsightFeedStackConfig(
      id: _readString(map, 'id'),
      title: _readString(map, 'title'),
      enabled: map['enabled'] != false,
      priority: _readInt(map, 'priority'),
      minCompletedWorkouts: _readOptionalInt(map, 'minCompletedWorkouts', 1),
      maxCards: _readOptionalInt(map, 'maxCards', 3),
    );
  }
}

@immutable
// policy: allow-public-api generated card group rendered by the insights feed.
class InsightFeedStack {
  final String id;
  final String title;
  final int priority;
  final List<InsightFeedCard> cards;

  const InsightFeedStack({
    required this.id,
    required this.title,
    required this.priority,
    required this.cards,
  });

  factory InsightFeedStack.fromMap(Map<String, dynamic> map) {
    final cardsJson = map['cards'];
    return InsightFeedStack(
      id: _readString(map, 'id'),
      title: _readString(map, 'title'),
      priority: _readInt(map, 'priority'),
      cards: List<InsightFeedCard>.unmodifiable(
        (cardsJson is List ? cardsJson : const []).map(
          (entry) =>
              InsightFeedCard.fromMap(Map<String, dynamic>.from(entry as Map)),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'priority': priority,
      'cards': cards.map((card) => card.toMap()).toList(),
    };
  }
}

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
  final String stackId;
  final InsightFeedCardType type;
  final bool enabled;
  final int priority;
  final Map<String, Object?> params;
  final InsightFeedVisualConfig visual;

  const InsightFeedRule({
    required this.id,
    this.stackId = 'recent_trends',
    required this.type,
    required this.enabled,
    required this.priority,
    this.params = const {},
    this.visual = const InsightFeedVisualConfig(),
  });

  factory InsightFeedRule.fromMap(Map<String, dynamic> map) {
    return InsightFeedRule(
      id: _readString(map, 'id'),
      stackId: _readOptionalString(map, 'stackId', 'recent_trends'),
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

@immutable
// policy: allow-public-api parsed feed configuration from JSON assets.
class InsightFeedConfig {
  final List<InsightFeedStackConfig> stacks;
  final List<InsightFeedRule> rules;

  const InsightFeedConfig({required this.stacks, required this.rules});

  factory InsightFeedConfig.fromMap(Map<String, dynamic> map) {
    final stacksJson = map['stacks'];
    final rulesJson = map['rules'];
    if (rulesJson is! List) {
      throw const FormatException('Insight feed rules must contain a list');
    }

    return InsightFeedConfig(
      stacks: List<InsightFeedStackConfig>.unmodifiable(
        (stacksJson is List ? stacksJson : _defaultStacks).map(
          (entry) => InsightFeedStackConfig.fromMap(
            Map<String, dynamic>.from(entry as Map),
          ),
        ),
      ),
      rules: List<InsightFeedRule>.unmodifiable(
        rulesJson.map(
          (entry) =>
              InsightFeedRule.fromMap(Map<String, dynamic>.from(entry as Map)),
        ),
      ),
    );
  }
}

const List<Map<String, Object?>> _defaultStacks = [
  {
    'id': 'recent_trends',
    'title': 'Insights',
    'enabled': true,
    'priority': 100,
    'minCompletedWorkouts': 1,
    'maxCards': 5,
  },
];

String _readString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing or invalid "$key" for InsightFeed');
}

String _readOptionalString(
  Map<String, dynamic> map,
  String key,
  String fallback,
) {
  final value = map[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return fallback;
}

int _readInt(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is int) {
    return value;
  }
  throw FormatException('Missing or invalid "$key" for InsightFeed');
}

int _readOptionalInt(Map<String, dynamic> map, String key, int fallback) {
  final value = map[key];
  if (value is int) {
    return value;
  }
  return fallback;
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
