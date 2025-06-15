import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'workout_exercise.dart'; // This will still be used for the model's in-memory representation

class Workout {
  final String id;
  String name;
  String? description;
  int? iconCodePoint;
  int? colorValue;
  String? folderId;
  String? notes;
  String? lastUsed; // ISO8601 string
  int? orderIndex;

  // Exercises are not part of the 'Workouts' table directly.
  // They will be loaded separately and associated with this model in memory.
  List<WorkoutExercise> exercises;

  Workout({
    String? id,
    required this.name,
    this.description,
    this.iconCodePoint,
    this.colorValue,
    this.folderId,
    this.notes,
    this.lastUsed,
    this.orderIndex,
    this.exercises = const [], // Default to empty list, to be populated after fetching from DB
  }) : id = id ?? const Uuid().v4();

  factory Workout.fromMap(Map<String, dynamic> map) {
    // Note: 'exercises' are not in the map from the 'Workouts' table.
    // They need to be fetched separately.
    return Workout(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      iconCodePoint: map['iconCodePoint'] as int?,
      colorValue: map['colorValue'] as int?,
      folderId: map['folderId'] as String?,
      notes: map['notes'] as String?,
      lastUsed: map['lastUsed'] as String?,
      orderIndex: map['orderIndex'] as int?,
      exercises: [], // Initialize as empty, to be loaded by service layer
    );
  }

  Map<String, dynamic> toMap() {
    // Note: 'exercises' are not part of the 'Workouts' table.
    // They are stored in the 'WorkoutExercises' table.
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
    };
  }

  Workout copyWith({
    String? id,
    String? name,
    String? description,
    int? iconCodePoint,
    int? colorValue,
    Object? folderId = _undefined, // Keep sentinel for nullable fields
    String? notes,
    Object? lastUsed = _undefined, // Keep sentinel for nullable fields
    int? orderIndex,
    List<WorkoutExercise>? exercises,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      folderId: folderId == _undefined ? this.folderId : folderId as String?,
      notes: notes ?? this.notes,
      lastUsed: lastUsed == _undefined ? this.lastUsed : lastUsed as String?,
      orderIndex: orderIndex ?? this.orderIndex,
      exercises: exercises ?? this.exercises,
    );
  }

  int get totalSets {
    return exercises.fold(0, (sum, exercise) => sum + exercise.totalSets);
  }

  // totalWeight for a template is less meaningful as targetWeights can vary.
  // This will be calculated for WorkoutHistory.
  // double get totalWeight {
  //   return exercises.fold(0.0, (sum, exercise) => sum + exercise.totalWeight);
  // }

  IconData get icon {
    // Provide a default icon if iconCodePoint is null
    return IconData(iconCodePoint ?? 0xe1a3, fontFamily: 'MaterialIcons'); // Default: Icons.fitness_center
  }

  Color get color {
    // Provide a default color if colorValue is null
    return Color(colorValue ?? 0xFF2196F3); // Default: Colors.blue.value
  }
}

// Sentinel object to distinguish between null and undefined
const Object _undefined = Object();
