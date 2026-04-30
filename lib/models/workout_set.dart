import 'package:uuid/uuid.dart';
import 'typedefs.dart';

class WorkoutSet {
  final WorkoutSetId id;
  final WorkoutExerciseId workoutExerciseId;
  final int setIndex;

  // --- Template Fields ---
  final int? targetReps;
  final double? targetWeight;
  final int? targetRestSeconds;

  // --- Logged Fields ---
  final int? actualReps;
  final double? actualWeight;
  final bool isCompleted;

  WorkoutSet({
    WorkoutSetId? id,
    required this.workoutExerciseId,
    required this.setIndex,
    this.targetReps,
    this.targetWeight,
    this.targetRestSeconds,
    this.actualReps,
    this.actualWeight,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutExerciseId': workoutExerciseId,
      'setIndex': setIndex,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'targetRestSeconds': targetRestSeconds,
      'actualReps': actualReps,
      'actualWeight': actualWeight,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: _readRequiredString(map, 'id'),
      workoutExerciseId: _readRequiredString(map, 'workoutExerciseId'),
      setIndex: _readRequiredInt(map, 'setIndex'),
      targetReps: _readNullableInt(map, 'targetReps'),
      targetWeight: _readNullableDouble(map, 'targetWeight'),
      targetRestSeconds: _readNullableInt(map, 'targetRestSeconds'),
      actualReps: _readNullableInt(map, 'actualReps'),
      actualWeight: _readNullableDouble(map, 'actualWeight'),
      isCompleted: _readBool(map, 'isCompleted'),
    );
  }

  WorkoutSet copyWith({
    WorkoutSetId? id,
    WorkoutExerciseId? workoutExerciseId,
    int? setIndex,
    Object? targetReps = _undefined,
    Object? targetWeight = _undefined,
    Object? targetRestSeconds = _undefined,
    Object? actualReps = _undefined,
    Object? actualWeight = _undefined,
    Object? isCompleted = _undefined,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      setIndex: setIndex ?? this.setIndex,
      targetReps: targetReps == _undefined
          ? this.targetReps
          : targetReps as int?,
      targetWeight: targetWeight == _undefined
          ? this.targetWeight
          : targetWeight as double?,
      targetRestSeconds: targetRestSeconds == _undefined
          ? this.targetRestSeconds
          : targetRestSeconds as int?,
      actualReps: actualReps == _undefined
          ? this.actualReps
          : actualReps as int?,
      actualWeight: actualWeight == _undefined
          ? this.actualWeight
          : actualWeight as double?,
      isCompleted: isCompleted == _undefined
          ? this.isCompleted
          : (isCompleted as bool?) ?? this.isCompleted,
    );
  }
}

// Sentinel object to distinguish between null and undefined
const Object _undefined = Object();

String _readRequiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing or invalid "$key" for WorkoutSet');
}

int _readRequiredInt(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is int) {
    return value;
  }
  throw FormatException('Missing or invalid "$key" for WorkoutSet');
}

int? _readNullableInt(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  throw FormatException('Invalid "$key" for WorkoutSet: expected int');
}

double? _readNullableDouble(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  throw FormatException('Invalid "$key" for WorkoutSet: expected num');
}

bool _readBool(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    return false;
  }
  if (value is bool) {
    return value;
  }
  if (value is int) {
    return value == 1;
  }
  throw FormatException('Invalid "$key" for WorkoutSet: expected bool or int');
}
