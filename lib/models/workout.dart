import 'package:flutter/material.dart';
import 'workout_exercise.dart';

class Workout {
  final String id;
  final String name;
  final List<WorkoutExercise> exercises;
  final String? folderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int iconCodePoint;
  final int colorValue;

  Workout({
    required this.id,
    required this.name,
    required this.exercises,
    this.folderId,
    required this.createdAt,
    required this.updatedAt,
    this.iconCodePoint = 0xe1a3, // Icons.fitness_center.codePoint, better for storing
    this.colorValue = 0xFF2196F3, // Colors.blue.value
  });

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      exercises: (map['exercises'] as List<dynamic>?)
          ?.map((e) => WorkoutExercise.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      folderId: map['folderId'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      iconCodePoint: map['iconCodePoint'] ?? 0xe1a3,
      colorValue: map['colorValue'] ?? 0xFF2196F3,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'folderId': folderId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
    };
  }

  Workout copyWith({
    String? id,
    String? name,
    List<WorkoutExercise>? exercises,
    Object? folderId = _undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? iconCodePoint,
    int? colorValue,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      folderId: folderId == _undefined ? this.folderId : folderId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  int get totalSets {
    return exercises.fold(0, (sum, exercise) => sum + exercise.totalSets);
  }

  double get totalWeight {
    return exercises.fold(0.0, (sum, exercise) => sum + exercise.totalWeight);
  }

  IconData get icon {
    return IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  }

  Color get color {
    return Color(colorValue);
  }
}

// Sentinel object to distinguish between null and undefined
const Object _undefined = Object();
