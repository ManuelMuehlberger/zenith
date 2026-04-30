import 'package:uuid/uuid.dart';
import 'exercise.dart'; // Still needed for in-memory representation if fetched
import 'workout_set.dart'; // Still needed for in-memory representation
import 'typedefs.dart';

// Sentinel object to distinguish between null and undefined
const Object _undefined = Object();

// Represents an exercise within a Workout template or session
class WorkoutExercise {
  final WorkoutExerciseId id;
  final WorkoutTemplateId?
  workoutTemplateId; // Foreign key to WorkoutTemplate table (for template exercises)
  final WorkoutId?
  workoutId; // Foreign key to Workout table (for session exercises)
  final ExerciseSlug exerciseSlug; // Identifier for the Exercise
  final String? notes;
  final int? orderIndex;

  // Exercise object, loaded from ExerciseService using exerciseSlug
  // This is for in-memory use after fetching, not stored in WorkoutExercises table directly
  final Exercise? exerciseDetail;

  // Sets are not part of the 'WorkoutExercises' table directly.
  // They will be loaded separately from 'WorkoutSets' table and associated in memory.
  final List<WorkoutSet> sets;

  WorkoutExercise({
    WorkoutExerciseId? id,
    this.workoutTemplateId,
    this.workoutId,
    required this.exerciseSlug,
    this.notes,
    this.orderIndex,
    this.exerciseDetail, // Can be loaded post-initialization
    List<WorkoutSet> sets =
        const [], // Default to empty list, to be populated after fetching from DB
  }) : id = id ?? const Uuid().v4(),
       sets = List.unmodifiable(sets) {
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
    return WorkoutExercise(
      id: _readRequiredString(map, 'id'),
      workoutTemplateId: _readNullableString(map, 'workoutTemplateId'),
      workoutId: _readNullableString(map, 'workoutId'),
      exerciseSlug: _readRequiredString(map, 'exerciseSlug'),
      notes: _readNullableString(map, 'notes'),
      orderIndex: _readNullableInt(map, 'orderIndex'),
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
    Object? orderIndex = _undefined,
    Object? exerciseDetail = _undefined,
    List<WorkoutSet>? sets,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      workoutTemplateId: workoutTemplateId == _undefined
          ? this.workoutTemplateId
          : workoutTemplateId as WorkoutTemplateId?,
      workoutId: workoutId == _undefined
          ? this.workoutId
          : workoutId as WorkoutId?,
      exerciseSlug: exerciseSlug ?? this.exerciseSlug,
      notes: notes == _undefined ? this.notes : notes as String?,
      orderIndex: orderIndex == _undefined
          ? this.orderIndex
          : orderIndex as int?,
      exerciseDetail: exerciseDetail == _undefined
          ? this.exerciseDetail
          : exerciseDetail as Exercise?,
      sets: sets ?? this.sets,
    );
  }

  // Helper method to add a new set (for in-memory manipulation)
  WorkoutExercise addSet({
    int? targetReps,
    double? targetWeight,
    int? targetRestSeconds,
  }) {
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
  WorkoutExercise updateSet(
    String setId, {
    int? targetReps,
    double? targetWeight,
    int? targetRestSeconds,
    int? setIndex,
  }) {
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

String _readRequiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing or invalid "$key" for WorkoutExercise');
}

String? _readNullableString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw FormatException('Invalid "$key" for WorkoutExercise: expected String');
}

int? _readNullableInt(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  throw FormatException('Invalid "$key" for WorkoutExercise: expected int');
}
