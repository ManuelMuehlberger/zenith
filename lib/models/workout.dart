import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import 'workout_exercise.dart';
import 'typedefs.dart';

enum WorkoutStatus { template, inProgress, completed }

class Workout {
  final WorkoutId id;
  final String name;
  final String? description;
  final int? iconCodePoint;
  final int? colorValue;
  final WorkoutFolderId? folderId;
  final String? notes;
  final String? lastUsed; // ISO8601 string
  final int? orderIndex;
  final List<WorkoutExercise> exercises;

  // New fields for sessions and history
  final WorkoutStatus status;
  final WorkoutId? templateId; // Links a session to its template
  final DateTime? startedAt;
  final DateTime? completedAt;

  Workout({
    WorkoutId? id,
    required this.name,
    this.description,
    this.iconCodePoint,
    this.colorValue,
    this.folderId,
    this.notes,
    this.lastUsed,
    this.orderIndex,
    List<WorkoutExercise> exercises = const [],
    this.status = WorkoutStatus.template,
    this.templateId,
    this.startedAt,
    this.completedAt,
  }) : id = id ?? const Uuid().v4(),
       exercises = List.unmodifiable(exercises);

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: _readRequiredString(map, 'id'),
      name: _readRequiredString(map, 'name'),
      description: _readNullableString(map, 'description'),
      iconCodePoint: _readNullableInt(map, 'iconCodePoint'),
      colorValue: _readNullableInt(map, 'colorValue'),
      folderId: _readNullableString(map, 'folderId'),
      notes: _readNullableString(map, 'notes'),
      lastUsed: _readNullableString(map, 'lastUsed'),
      orderIndex: _readNullableInt(map, 'orderIndex'),
      status: _readWorkoutStatus(map['status']),
      templateId: _readNullableString(map, 'templateId'),
      startedAt: _readNullableDateTime(map, 'startedAt'),
      completedAt: _readNullableDateTime(map, 'completedAt'),
      exercises: [], // To be loaded separately
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'folderId': folderId,
      'notes': notes,
      'lastUsed': lastUsed,
      'orderIndex': orderIndex,
      'status': status.index,
      'templateId': templateId,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  Workout copyWith({
    WorkoutId? id,
    String? name,
    Object? description = _undefined,
    Object? iconCodePoint = _undefined,
    Object? colorValue = _undefined,
    Object? folderId = _undefined,
    Object? notes = _undefined,
    Object? lastUsed = _undefined,
    Object? orderIndex = _undefined,
    List<WorkoutExercise>? exercises,
    WorkoutStatus? status,
    Object? templateId = _undefined,
    Object? startedAt = _undefined,
    Object? completedAt = _undefined,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description == _undefined
          ? this.description
          : description as String?,
      iconCodePoint: iconCodePoint == _undefined
          ? this.iconCodePoint
          : iconCodePoint as int?,
      colorValue: colorValue == _undefined
          ? this.colorValue
          : colorValue as int?,
      folderId: folderId == _undefined
          ? this.folderId
          : folderId as WorkoutFolderId?,
      notes: notes == _undefined ? this.notes : notes as String?,
      lastUsed: lastUsed == _undefined ? this.lastUsed : lastUsed as String?,
      orderIndex: orderIndex == _undefined
          ? this.orderIndex
          : orderIndex as int?,
      exercises: exercises ?? this.exercises,
      status: status ?? this.status,
      templateId: templateId == _undefined
          ? this.templateId
          : templateId as WorkoutId?,
      startedAt: startedAt == _undefined
          ? this.startedAt
          : startedAt as DateTime?,
      completedAt: completedAt == _undefined
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }

  int get totalSets {
    return exercises.fold(0, (sum, exercise) => sum + exercise.totalSets);
  }

  int get completedSets {
    return exercises.fold(
      0,
      (sum, exercise) =>
          sum + exercise.sets.where((set) => set.isCompleted).length,
    );
  }

  double get totalWeight {
    return exercises.fold(0.0, (sum, exercise) {
      return sum +
          exercise.sets.fold(0.0, (setSum, set) {
            if (set.isCompleted &&
                set.actualReps != null &&
                set.actualWeight != null) {
              return setSum + (set.actualReps! * set.actualWeight!);
            }
            return setSum;
          });
    });
  }

  IconData get icon {
    return WorkoutIcons.getIconDataFromCodePoint(iconCodePoint);
  }

  Color get color {
    return Color(colorValue ?? 0xFF2196F3);
  }
}

// Sentinel object to distinguish between null and undefined
const Object _undefined = Object();

String _readRequiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing or invalid "$key" for Workout');
}

String? _readNullableString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw FormatException('Invalid "$key" for Workout: expected String');
}

int? _readNullableInt(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  throw FormatException('Invalid "$key" for Workout: expected int');
}

DateTime? _readNullableDateTime(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return DateTime.parse(value);
  }
  throw FormatException('Invalid "$key" for Workout: expected ISO8601 string');
}

WorkoutStatus _readWorkoutStatus(Object? value) {
  if (value is int && value >= 0 && value < WorkoutStatus.values.length) {
    return WorkoutStatus.values[value];
  }
  throw FormatException('Invalid "status" for Workout');
}
