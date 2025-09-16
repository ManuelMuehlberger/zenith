import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'workout_exercise.dart';
import 'typedefs.dart';

enum WorkoutStatus { template, inProgress, completed }

class Workout {
  final WorkoutId id;
  String name;
  String? description;
  int? iconCodePoint;
  int? colorValue;
  WorkoutFolderId? folderId;
  String? notes;
  String? lastUsed; // ISO8601 string
  int? orderIndex;
  List<WorkoutExercise> exercises;

  // New fields for sessions and history
  final WorkoutStatus status;
  final WorkoutId? templateId; // Links a session to its template
  DateTime? startedAt;
  DateTime? completedAt;

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
    this.exercises = const [],
    this.status = WorkoutStatus.template,
    this.templateId,
    this.startedAt,
    this.completedAt,
  }) : id = id ?? const Uuid().v4();

  factory Workout.fromMap(Map<String, dynamic> map) {
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
      status: WorkoutStatus.values[map['status'] as int],
      templateId: map['templateId'] as String?,
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt'] as String) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
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
    String? description,
    int? iconCodePoint,
    int? colorValue,
    Object? folderId = _undefined,
    String? notes,
    Object? lastUsed = _undefined,
    int? orderIndex,
    List<WorkoutExercise>? exercises,
    WorkoutStatus? status,
    WorkoutId? templateId,
    DateTime? startedAt,
    DateTime? completedAt,
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
      status: status ?? this.status,
      templateId: templateId ?? this.templateId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  int get totalSets {
    return exercises.fold(0, (sum, exercise) => sum + exercise.totalSets);
  }

  int get completedSets {
    return exercises.fold(0, (sum, exercise) => sum + exercise.sets.where((set) => set.isCompleted).length);
  }

  double get totalWeight {
    return exercises.fold(0.0, (sum, exercise) {
      return sum + exercise.sets.fold(0.0, (setSum, set) {
        if (set.isCompleted && set.actualReps != null && set.actualWeight != null) {
          return setSum + (set.actualReps! * set.actualWeight!);
        }
        return setSum;
      });
    });
  }

  IconData get icon {
    // Use a default icon if iconCodePoint is null
    if (iconCodePoint == null) {
      return Icons.fitness_center; // Default icon
    }
    // Prefer constant mappings (helps tree shaking for common icons)
    switch (iconCodePoint) {
      case 0xe1a3: // fitness_center
        return Icons.fitness_center;
      case 0xe02f: // directions_run
        return Icons.directions_run;
      case 0xe047: // pool
        return Icons.pool;
      case 0xe52f: // sports
        return Icons.sports;
      case 0xe531: // sports_gymnastics
        return Icons.sports_gymnastics;
      case 0xe532: // sports_handball
        return Icons.sports_handball;
      case 0xe533: // sports_martial_arts
        return Icons.sports_martial_arts;
      case 0xe534: // sports_mma
        return Icons.sports_mma;
      case 0xe535: // sports_motorsports
        return Icons.sports_motorsports;
      case 0xe536: // sports_score
        return Icons.sports_score;
      default:
        // Fallback: dynamically construct IconData from code point so arbitrary Material icons render
        return IconData(iconCodePoint!, fontFamily: 'MaterialIcons');
    }
  }

  Color get color {
    return Color(colorValue ?? 0xFF2196F3);
  }
}

// Sentinel object to distinguish between null and undefined
const Object _undefined = Object();
