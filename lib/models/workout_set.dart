import 'package:uuid/uuid.dart';

// Represents a set within a WorkoutExercise template
class WorkoutSet {
  final String id;
  final String workoutExerciseId; // Foreign key to WorkoutExercises table
  int setNumber;
  String? type; // e.g., 'normal', 'warmup', 'drop', 'failure'
  int? targetReps;
  double? targetWeight;
  String? targetWeightUnit; // e.g., 'kg', 'lbs', 'bodyweight'
  int? targetRestSeconds;
  int? orderIndex; // Order of this set for the exercise

  WorkoutSet({
    String? id,
    required this.workoutExerciseId,
    required this.setNumber,
    this.type,
    this.targetReps,
    this.targetWeight,
    this.targetWeightUnit,
    this.targetRestSeconds,
    this.orderIndex,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutExerciseId': workoutExerciseId,
      'setNumber': setNumber,
      'type': type,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'targetWeightUnit': targetWeightUnit,
      'targetRestSeconds': targetRestSeconds,
      'orderIndex': orderIndex,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] as String,
      workoutExerciseId: map['workoutExerciseId'] as String,
      setNumber: map['setNumber'] as int,
      type: map['type'] as String?,
      targetReps: map['targetReps'] as int?,
      targetWeight: (map['targetWeight'] as num?)?.toDouble(),
      targetWeightUnit: map['targetWeightUnit'] as String?,
      targetRestSeconds: map['targetRestSeconds'] as int?,
      orderIndex: map['orderIndex'] as int?,
    );
  }

  WorkoutSet copyWith({
    String? id,
    String? workoutExerciseId,
    int? setNumber,
    String? type,
    int? targetReps,
    double? targetWeight,
    String? targetWeightUnit,
    int? targetRestSeconds,
    int? orderIndex,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      setNumber: setNumber ?? this.setNumber,
      type: type ?? this.type,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      targetWeightUnit: targetWeightUnit ?? this.targetWeightUnit,
      targetRestSeconds: targetRestSeconds ?? this.targetRestSeconds,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
