import 'package:flutter/material.dart';

class WorkoutHistory {
  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime startTime;
  final DateTime endTime;
  final List<WorkoutExerciseHistory> exercises;
  final String notes;
  final int mood; // 1-5 scale
  final int totalSets;
  final double totalWeight;
  final int iconCodePoint;
  final int colorValue;

  WorkoutHistory({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.startTime,
    required this.endTime,
    required this.exercises,
    this.notes = '',
    this.mood = 3,
    required this.totalSets,
    required this.totalWeight,
    this.iconCodePoint = 0xe1a3, // Icons.fitness_center.codePoint, better for storing
    this.colorValue = 0xFF2196F3, // Colors.blue.value
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'notes': notes,
      'mood': mood,
      'totalSets': totalSets,
      'totalWeight': totalWeight,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
    };
  }

  factory WorkoutHistory.fromMap(Map<String, dynamic> map) {
    return WorkoutHistory(
      id: map['id'] ?? '',
      workoutId: map['workoutId'] ?? '',
      workoutName: map['workoutName'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] ?? 0),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime'] ?? 0),
      exercises: (map['exercises'] as List<dynamic>?)
          ?.map((e) => WorkoutExerciseHistory.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      notes: map['notes'] ?? '',
      mood: map['mood'] ?? 3,
      totalSets: map['totalSets'] ?? 0,
      totalWeight: (map['totalWeight'] ?? 0.0).toDouble(),
      iconCodePoint: map['iconCodePoint'] ?? 0xe1a3,
      colorValue: map['colorValue'] ?? 0xFF2196F3,
    );
  }

  IconData get icon {
    return IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  }

  Color get color {
    return Color(colorValue);
  }
}

class WorkoutExerciseHistory {
  final String exerciseId;
  final String exerciseName;
  final List<SetHistory> sets;

  WorkoutExerciseHistory({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((s) => s.toMap()).toList(),
    };
  }

  factory WorkoutExerciseHistory.fromMap(Map<String, dynamic> map) {
    return WorkoutExerciseHistory(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      sets: (map['sets'] as List<dynamic>?)
          ?.map((s) => SetHistory.fromMap(s as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class SetHistory {
  final int reps;
  final double weight;
  final bool completed;

  SetHistory({
    required this.reps,
    required this.weight,
    this.completed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'reps': reps,
      'weight': weight,
      'completed': completed,
    };
  }

  factory SetHistory.fromMap(Map<String, dynamic> map) {
    return SetHistory(
      reps: map['reps'] ?? 0,
      weight: (map['weight'] ?? 0.0).toDouble(),
      completed: map['completed'] ?? false,
    );
  }
}
