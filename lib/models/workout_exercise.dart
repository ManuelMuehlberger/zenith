import 'exercise.dart';
import 'workout_set.dart';

class WorkoutExercise {
  final String id;
  final Exercise exercise;
  final List<WorkoutSet> sets;
  final String notes;

  WorkoutExercise({
    required this.id,
    required this.exercise,
    required this.sets,
    this.notes = '',
  });

  // Computed properties for backward compatibility
  int get totalSets => sets.length;
  int get completedSets => sets.where((set) => set.isCompleted).length;
  double get totalWeight => sets.fold(0.0, (sum, set) => sum + (set.weight * set.reps));

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      id: map['id'] ?? '',
      exercise: Exercise.fromMap(map['exercise'] ?? {}),
      sets: (map['sets'] as List<dynamic>?)
          ?.map((setMap) => WorkoutSet.fromMap(setMap as Map<String, dynamic>))
          .toList() ?? [],
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise': exercise.toMap(),
      'sets': sets.map((set) => set.toMap()).toList(),
      'notes': notes,
    };
  }

  WorkoutExercise copyWith({
    String? id,
    Exercise? exercise,
    List<WorkoutSet>? sets,
    String? notes,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }

  // Helper method to add a new set
  WorkoutExercise addSet({int reps = 10, double weight = 0.0}) {
    final newSet = WorkoutSet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reps: reps,
      weight: weight,
    );
    return copyWith(sets: [...sets, newSet]);
  }

  // Helper method to remove a set
  WorkoutExercise removeSet(String setId) {
    return copyWith(sets: sets.where((set) => set.id != setId).toList());
  }

  // Helper method to update a set
  WorkoutExercise updateSet(String setId, {int? reps, double? weight, bool? isCompleted}) {
    final updatedSets = sets.map((set) {
      if (set.id == setId) {
        return set.copyWith(
          reps: reps,
          weight: weight,
          isCompleted: isCompleted,
        );
      }
      return set;
    }).toList();
    
    return copyWith(sets: updatedSets);
  }
}
