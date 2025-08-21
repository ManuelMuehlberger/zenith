
import 'package:uuid/uuid.dart';
import 'typedefs.dart';
import '../constants/app_constants.dart';

class WeightEntry {
  final String id;
  final DateTime timestamp;
  final double value;

  WeightEntry({
    String? id,
    required this.timestamp,
    required this.value,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'value': value,
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as String? ?? const Uuid().v4(),
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      value: map['value']?.toDouble() ?? 0.0,
    );
  }
}

class UserData {
  final UserDataId id;
  final String name;
  final DateTime birthdate;
  final Units units; // metric or imperial
  final List<WeightEntry> weightHistory;
  final DateTime createdAt;
  final String theme;

  UserData({
    UserDataId? id,
    required this.name,
    required this.birthdate,
    required this.units,
    required this.weightHistory,
    required this.createdAt,
    required this.theme,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birthdate': birthdate.toIso8601String(),
      'units': units.name, // Convert enum to string for storage
      'weightHistory': weightHistory.map((entry) => entry.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'theme': theme,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    final weightHistoryList = map['weightHistory'] as List?;
    final weightHistory = weightHistoryList
            ?.map((e) => WeightEntry.fromMap(e))
            .toList() ??
        [];

    return UserData(
      id: map['id'] as String? ?? const Uuid().v4(),
      name: map['name'] as String? ?? '',
      birthdate: DateTime.parse(map['birthdate'] as String),
      units: Units.fromString(map['units'] as String? ?? 'metric'),
      weightHistory: weightHistory,
      createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      theme: map['theme'] as String? ?? 'dark',
    );
  }

  UserData copyWith({
    UserDataId? id,
    String? name,
    DateTime? birthdate,
    Units? units,
    List<WeightEntry>? weightHistory,
    DateTime? createdAt,
    String? theme,
  }) {
    return UserData(
      id: id ?? this.id,
      name: name ?? this.name,
      birthdate: birthdate ?? this.birthdate,
      units: units ?? this.units,
      weightHistory: weightHistory ?? this.weightHistory,
      createdAt: createdAt ?? this.createdAt,
      theme: theme ?? this.theme,
    );
  }

  String get weightUnit => units.weightUnit;

  int get age {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }
}
