import 'package:uuid/uuid.dart';
import 'exercise.dart'; // Still needed for in-memory representation if fetched
import 'workout_set.dart'; // Still needed for in-memory representation
import 'typedefs.dart';

// Sentinel object to distinguish between null and undefined
const Object _undefined = Object();

// Represents an exercise within a Workout template or session
class WorkoutExercise {
  final WorkoutExerciseId id;
  final WorkoutTemplateId? workoutTemplateId; // Foreign key to WorkoutTemplate table (for template exercises)
  final WorkoutId? workoutId; // Foreign key to Workout table (for session exercises)
  final ExerciseSlug exerciseSlug; // Identifier for the Exercise
  String? notes;
  int? orderIndex;

  // Exercise object, loaded from ExerciseService using exerciseSlug
  // This is for in-memory use after fetching, not stored in WorkoutExercises table directly
  final Exercise? exerciseDetail;

  // Sets are not part of the 'WorkoutExercises' table directly.
  // They will be loaded separately from 'WorkoutSets' table and associated in memory.
  List<WorkoutSet> sets;

  WorkoutExercise({
    WorkoutExerciseId? id,
    this.workoutTemplateId,
    this.workoutId,
    required this.exerciseSlug,
    this.notes,
    this.orderIndex,
    this.exerciseDetail, // Can be loaded post-initialization
    this.sets = const [], // Default to empty list, to be populated after fetching from DB
  }) : id = id ?? const Uuid().v4() {
    // Ensure exactly one of workoutTemplateId or workoutId is set
    assert(
      (workoutTemplateId != null) != (workoutId != null),
      'Exactly one of workoutTemplateId or workoutId must be set',
    );
  }

  // Computed properties
  int get totalSets => sets.length;
  // completedSets and totalWeight are more relevant for WorkoutHistory_Exercises
  // For a template, totalWeight might not be as meaningful if target weights vary.

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    // Note: 'sets' and 'exerciseDetail' are not in the map from the 'WorkoutExercises' table.
    // They need to be fetched/populated separately.
    return WorkoutExercise(
      id: map['id'] as String,
      workoutTemplateId: map['workoutTemplateId'] as String?,
      workoutId: map['workoutId'] as String?,
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
      'workoutTemplateId': workoutTemplateId,
      'workoutId': workoutId,
      'exerciseSlug': exerciseSlug,
      'notes': notes,
      'orderIndex': orderIndex,
    };
  }

  WorkoutExercise copyWith({
    WorkoutExerciseId? id,
    Object? workoutTemplateId = _undefined,
    Object? workoutId = _undefined,
    ExerciseSlug? exerciseSlug,
    Object? notes = _undefined,
    int? orderIndex,
    Exercise? exerciseDetail, // Allow exerciseDetail to be explicitly nulled
    bool setExerciseDetailNull = false,
    List<WorkoutSet>? sets,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      workoutTemplateId: workoutTemplateId == _undefined ? this.workoutTemplateId : workoutTemplateId as WorkoutTemplateId?,
      workoutId: workoutId == _undefined ? this.workoutId : workoutId as WorkoutId?,
      exerciseSlug: exerciseSlug ?? this.exerciseSlug,
      notes: notes == _undefined ? this.notes : notes as String?,
      orderIndex: orderIndex ?? this.orderIndex,
      exerciseDetail: setExerciseDetailNull ? null : (exerciseDetail ?? this.exerciseDetail),
      sets: sets ?? this.sets,
    );
  }

  // Helper method to add a new set (for in-memory manipulation)
  WorkoutExercise addSet({int? targetReps, double? targetWeight, int? targetRestSeconds}) {
    final newSet = WorkoutSet(
      workoutExerciseId: id, // Link to this WorkoutExercise instance
      setIndex: sets.length, // Simple index for now
      targetReps: targetReps,
      targetWeight: targetWeight,
      targetRestSeconds: targetRestSeconds,
    );
    return copyWith(sets: [...sets, newSet]);
  }

  // Helper method to remove a set (for in-memory manipulation)
  WorkoutExercise removeSet(String setId) {
    return copyWith(sets: sets.where((set) => set.id != setId).toList());
  }

  // Helper method to update a set (for in-memory manipulation)
  WorkoutExercise updateSet(String setId, {int? targetReps, double? targetWeight, int? targetRestSeconds, int? setIndex}) {
    final updatedSets = sets.map((set) {
      if (set.id == setId) {
        return set.copyWith(
          targetReps: targetReps,
          targetWeight: targetWeight,
          targetRestSeconds: targetRestSeconds,
          setIndex: setIndex,
        );
      }
      return set;
    }).toList();
    
    return copyWith(sets: updatedSets);
  }
}
