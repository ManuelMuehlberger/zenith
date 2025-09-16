import 'package:uuid/uuid.dart';
import 'typedefs.dart';

class WorkoutSet {
  final WorkoutSetId id;
  final WorkoutExerciseId workoutExerciseId;
  final int setIndex;

  // --- Template Fields ---
  int? targetReps;
  double? targetWeight;
  int? targetRestSeconds;

  // --- Logged Fields ---
  int? actualReps;
  double? actualWeight;
  bool isCompleted;

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
      id: map['id'] as String,
      workoutExerciseId: map['workoutExerciseId'] as String,
      setIndex: map['setIndex'] as int,
      targetReps: map['targetReps'] as int?,
      targetWeight: (map['targetWeight'] as num?)?.toDouble(),
      targetRestSeconds: map['targetRestSeconds'] as int?,
      actualReps: map['actualReps'] as int?,
      actualWeight: (map['actualWeight'] as num?)?.toDouble(),
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
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
      targetReps: targetReps == _undefined ? this.targetReps : targetReps as int?,
      targetWeight: targetWeight == _undefined ? this.targetWeight : targetWeight as double?,
      targetRestSeconds: targetRestSeconds == _undefined ? this.targetRestSeconds : targetRestSeconds as int?,
      actualReps: actualReps == _undefined ? this.actualReps : actualReps as int?,
      actualWeight: actualWeight == _undefined ? this.actualWeight : actualWeight as double?,
      isCompleted: isCompleted == _undefined ? this.isCompleted : (isCompleted as bool?) ?? this.isCompleted,
    );
  }
}

// Sentinel object to distinguish between null and undefined
const Object _undefined = Object();
