import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// Represents a completed set in a workout history
class SetHistory {
  final String id;
  final String workoutHistoryExerciseId; // FK to WorkoutHistory_Exercises
  final int setNumber;
  final String? type;
  final int? repsPerformed;
  final double? weightLogged;
  final String? weightUnit;
  final bool completed; // Maps to isCompleted (INTEGER 0/1) in DB
  final String? notes;
  final int? durationSeconds;
  final int? restTimeAchievedSeconds;

  SetHistory({
    String? id,
    required this.workoutHistoryExerciseId,
    required this.setNumber,
    this.type,
    this.repsPerformed,
    this.weightLogged,
    this.weightUnit,
    this.completed = false,
    this.notes,
    this.durationSeconds,
    this.restTimeAchievedSeconds,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutHistoryExerciseId': workoutHistoryExerciseId,
      'setNumber': setNumber,
      'type': type,
      'repsPerformed': repsPerformed,
      'weightLogged': weightLogged,
      'weightUnit': weightUnit,
      'isCompleted': completed ? 1 : 0, // Store bool as int
      'notes': notes,
      'durationSeconds': durationSeconds,
      'restTimeAchievedSeconds': restTimeAchievedSeconds,
    };
  }

  factory SetHistory.fromMap(Map<String, dynamic> map) {
    return SetHistory(
      id: map['id'] as String,
      workoutHistoryExerciseId: map['workoutHistoryExerciseId'] as String,
      setNumber: map['setNumber'] as int,
      type: map['type'] as String?,
      repsPerformed: map['repsPerformed'] as int?,
      weightLogged: (map['weightLogged'] as num?)?.toDouble(),
      weightUnit: map['weightUnit'] as String?,
      completed: (map['isCompleted'] as int? ?? 0) == 1, // Read int as bool
      notes: map['notes'] as String?,
      durationSeconds: map['durationSeconds'] as int?,
      restTimeAchievedSeconds: map['restTimeAchievedSeconds'] as int?,
    );
  }
}

// Represents a completed exercise in a workout history
class WorkoutExerciseHistory {
  final String id;
  final String workoutHistoryId; // FK to WorkoutHistory
  final String exerciseSlug;
  final String exerciseName; // Denormalized
  final String? notes;
  final int? orderIndex;

  List<SetHistory> sets; // Loaded separately

  WorkoutExerciseHistory({
    String? id,
    required this.workoutHistoryId,
    required this.exerciseSlug,
    required this.exerciseName,
    this.notes,
    this.orderIndex,
    this.sets = const [],
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutHistoryId': workoutHistoryId,
      'exerciseSlug': exerciseSlug,
      'exerciseName': exerciseName,
      'notes': notes,
      'orderIndex': orderIndex,
      // 'sets' are not stored directly in this table's map
    };
  }

  factory WorkoutExerciseHistory.fromMap(Map<String, dynamic> map) {
    return WorkoutExerciseHistory(
      id: map['id'] as String,
      workoutHistoryId: map['workoutHistoryId'] as String,
      exerciseSlug: map['exerciseSlug'] as String,
      exerciseName: map['exerciseName'] as String,
      notes: map['notes'] as String?,
      orderIndex: map['orderIndex'] as int?,
      sets: [], // Initialize as empty, to be loaded by service layer
    );
  }

  // Calculated property for total completed sets in this exercise
  int get completedSetsCount {
    return sets.where((s) => s.completed).length;
  }
  // Calculated property for total volume in this exercise
  double get totalVolume {
     return sets.fold(0.0, (sum, set) {
        if (set.completed && set.repsPerformed != null && set.weightLogged != null) {
            return sum + (set.repsPerformed! * set.weightLogged!);
        }
        return sum;
    });
  }
}

// Represents a completed workout session
class WorkoutHistory {
  final String id;
  final String? workoutId; // FK to Workouts table (template workout)
  final String workoutName;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds; // Calculated: endTime - startTime
  final String? notes;
  final int? mood; // 1-5 scale
  final int? iconCodePoint;
  final int? colorValue;

  List<WorkoutExerciseHistory> exercises; // Loaded separately

  WorkoutHistory({
    String? id,
    this.workoutId,
    required this.workoutName,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    this.notes,
    this.mood,
    this.iconCodePoint = 0xe1a3, 
    this.colorValue = 0xFF2196F3,
    this.exercises = const [],
  }) : id = id ?? const Uuid().v4();

  Duration? get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    } else if (durationSeconds != null) {
      return Duration(seconds: durationSeconds!);
    }
    return null;
  }
  
  int get totalSets {
    return exercises.fold(0, (sum, ex) => sum + ex.sets.length);
  }

  int get completedSets {
    return exercises.fold(0, (sum, ex) => sum + ex.completedSetsCount);
  }

  double get totalWeight { // Represents total volume (weight * reps)
    return exercises.fold(0.0, (sum, ex) => sum + ex.totalVolume);
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'startTime': startTime.toIso8601String(), // Store as ISO8601 string
      'endTime': endTime?.toIso8601String(),   // Store as ISO8601 string
      'durationSeconds': durationSeconds ?? (endTime != null ? endTime!.difference(startTime).inSeconds : null),
      'notes': notes,
      'mood': mood,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      // 'exercises' are not stored directly in this table's map
    };
  }

  factory WorkoutHistory.fromMap(Map<String, dynamic> map) {
    return WorkoutHistory(
      id: map['id'] as String,
      workoutId: map['workoutId'] as String?,
      workoutName: map['workoutName'] as String,
      startTime: DateTime.parse(map['startTime'] as String), // Parse from ISO8601 string
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null, // Parse from ISO8601 string
      durationSeconds: map['durationSeconds'] as int?,
      notes: map['notes'] as String?,
      mood: map['mood'] as int?,
      iconCodePoint: map['iconCodePoint'] as int? ?? 0xe1a3,
      colorValue: map['colorValue'] as int? ?? 0xFF2196F3,
      exercises: [], // Initialize as empty, to be loaded by service layer
    );
  }

  IconData get icon {
    return IconData(iconCodePoint ?? 0xe1a3, fontFamily: 'MaterialIcons');
  }

  Color get color {
    return Color(colorValue ?? 0xFF2196F3);
  }
}
