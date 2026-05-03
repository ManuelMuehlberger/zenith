import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import 'typedefs.dart';

class WeightEntry {
  final String id;
  final DateTime timestamp;
  final double value;

  WeightEntry({String? id, required this.timestamp, required this.value})
    : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {'id': id, 'timestamp': timestamp.toIso8601String(), 'value': value};
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
    required List<WeightEntry> weightHistory,
    required this.createdAt,
    required this.theme,
  }) : id = id ?? const Uuid().v4(),
       weightHistory = List.unmodifiable(weightHistory);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birthdate': birthdate.toIso8601String(),
      'units': units.name, // Convert enum to string for storage
      'createdAt': createdAt.toIso8601String(),
      'theme': theme,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      id: _readNullableString(map, 'id') ?? const Uuid().v4(),
      name: _readNullableString(map, 'name') ?? '',
      birthdate: _readRequiredDateTime(map, 'birthdate'),
      units: Units.fromString(_readNullableString(map, 'units') ?? 'metric'),
      weightHistory:
          [], // Weight history will be loaded separately from WeightEntry table
      createdAt: _readNullableDateTime(map, 'createdAt') ?? DateTime.now(),
      theme: _readNullableString(map, 'theme') ?? 'system',
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

  int get age => ageAt(DateTime.now());

  int ageAt(DateTime referenceDate) {
    int age = referenceDate.year - birthdate.year;
    if (referenceDate.month < birthdate.month ||
        (referenceDate.month == birthdate.month &&
            referenceDate.day < birthdate.day)) {
      age--;
    }
    return age;
  }
}

String? _readNullableString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw FormatException('Invalid "$key" for UserData: expected String');
}

DateTime _readRequiredDateTime(Map<String, dynamic> map, String key) {
  final value = _readNullableDateTime(map, key);
  if (value != null) {
    return value;
  }
  throw FormatException('Missing "$key" for UserData');
}

DateTime? _readNullableDateTime(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return DateTime.parse(value);
  }
  throw FormatException('Invalid "$key" for UserData: expected ISO8601 string');
}
