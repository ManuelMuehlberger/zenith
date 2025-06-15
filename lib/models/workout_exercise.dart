import 'package:uuid/uuid.dart';
import 'exercise.dart'; // Still needed for in-memory representation if fetched
import 'workout_set.dart'; // Still needed for in-memory representation

// Represents an exercise within a Workout template
class WorkoutExercise {
  final String id;
  final String workoutId; // Foreign key to Workouts table
  String exerciseSlug; // Identifier for the Exercise
  String? notes;
  int? orderIndex;

  // Exercise object, loaded from ExerciseService using exerciseSlug
  // This is for in-memory use after fetching, not stored in WorkoutExercises table directly
  Exercise? exerciseDetail;

  // Sets are not part of the 'WorkoutExercises' table directly.
  // They will be loaded separately from 'WorkoutSets' table and associated in memory.
  List<WorkoutSet> sets;

  WorkoutExercise({
    String? id,
    required this.workoutId,
    required this.exerciseSlug,
    this.notes,
    this.orderIndex,
    this.exerciseDetail, // Can be loaded post-initialization
    this.sets = const [], // Default to empty list, to be populated after fetching from DB
  }) : id = id ?? const Uuid().v4();

  // Computed properties
  int get totalSets => sets.length;
  // completedSets and totalWeight are more relevant for WorkoutHistory_Exercises
  // For a template, totalWeight might not be as meaningful if target weights vary.

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    // Note: 'sets' and 'exerciseDetail' are not in the map from the 'WorkoutExercises' table.
    // They need to be fetched/populated separately.
    return WorkoutExercise(
      id: map['id'] as String,
      workoutId: map['workoutId'] as String,
      exerciseSlug: map['exerciseSlug'] as String,
      notes: map['notes'] as String?,
      orderIndex: map['orderIndex'] as int?,
      sets: [], // Initialize as empty, to be loaded by service layer
      // exerciseDetail will be loaded by service layer using exerciseSlug
    );
  }

  Map<String, dynamic> toMap() {
    // Note: 'sets' and 'exerciseDetail' are not part of the 'WorkoutExercises' table.
    return {
      'id': id,
      'workoutId': workoutId,
      'exerciseSlug': exerciseSlug,
      'notes': notes,
      'orderIndex': orderIndex,
    };
  }

  WorkoutExercise copyWith({
    String? id,
    String? workoutId,
    String? exerciseSlug,
    String? notes,
    int? orderIndex,
    Exercise? exerciseDetail, // Allow exerciseDetail to be explicitly nulled
    bool setExerciseDetailNull = false,
    List<WorkoutSet>? sets,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseSlug: exerciseSlug ?? this.exerciseSlug,
      notes: notes ?? this.notes,
      orderIndex: orderIndex ?? this.orderIndex,
      exerciseDetail: setExerciseDetailNull ? null : (exerciseDetail ?? this.exerciseDetail),
      sets: sets ?? this.sets,
    );
  }

  // Helper method to add a new set (for in-memory manipulation)
  WorkoutExercise addSet({int? targetReps, double? targetWeight, String? type, int? targetRestSeconds}) {
    final newSet = WorkoutSet(
      workoutExerciseId: id, // Link to this WorkoutExercise instance
      setNumber: sets.isNotEmpty ? sets.map((s) => s.setNumber).reduce((a, b) => a > b ? a : b) + 1 : 1, // Ensure unique setNumber
      type: type,
      targetReps: targetReps,
      targetWeight: targetWeight,
      targetRestSeconds: targetRestSeconds,
      orderIndex: sets.length, // Simple order for now
    );
    return copyWith(sets: [...sets, newSet]);
  }

  // Helper method to remove a set (for in-memory manipulation)
  WorkoutExercise removeSet(String setId) {
    return copyWith(sets: sets.where((set) => set.id != setId).toList());
  }

  // Helper method to update a set (for in-memory manipulation)
  WorkoutExercise updateSet(String setId, {int? targetReps, double? targetWeight, String? type, int? targetRestSeconds, int? setNumber, int? orderIndex}) {
    final updatedSets = sets.map((set) {
      if (set.id == setId) {
        return set.copyWith(
          targetReps: targetReps,
          targetWeight: targetWeight,
          type: type,
          targetRestSeconds: targetRestSeconds,
          setNumber: setNumber,
          orderIndex: orderIndex,
        );
      }
      return set;
    }).toList();
    
    return copyWith(sets: updatedSets);
  }
}
