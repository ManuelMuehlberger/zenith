import 'workout.dart';
import 'workout_exercise.dart';
import 'workout_set.dart';

class WorkoutSession {
  final String id;
  final Workout workout;
  final DateTime startTime;
  final List<SessionExercise> exercises;
  final bool isCompleted;
  final DateTime? endTime;
  final String? notes;
  final WorkoutMood? mood;

  WorkoutSession({
    required this.id,
    required this.workout,
    required this.startTime,
    required this.exercises,
    this.isCompleted = false,
    this.endTime,
    this.notes,
    this.mood,
  });

  factory WorkoutSession.fromWorkout(Workout workout) {
    return WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workout: workout,
      startTime: DateTime.now(),
      exercises: workout.exercises.map((e) => SessionExercise.fromWorkoutExercise(e)).toList(),
    );
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'] ?? '',
      workout: Workout.fromMap(map['workout'] ?? {}),
      startTime: DateTime.parse(map['startTime'] ?? DateTime.now().toIso8601String()),
      exercises: (map['exercises'] as List<dynamic>?)
          ?.map((e) => SessionExercise.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      isCompleted: map['isCompleted'] ?? false,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      notes: map['notes'],
      mood: map['mood'] != null ? WorkoutMood.values[map['mood']] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout': workout.toMap(),
      'startTime': startTime.toIso8601String(),
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'isCompleted': isCompleted,
      'endTime': endTime?.toIso8601String(),
      'notes': notes,
      'mood': mood?.index,
    };
  }

  WorkoutSession copyWith({
    String? id,
    Workout? workout,
    DateTime? startTime,
    List<SessionExercise>? exercises,
    bool? isCompleted,
    DateTime? endTime,
    String? notes,
    WorkoutMood? mood,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      workout: workout ?? this.workout,
      startTime: startTime ?? this.startTime,
      exercises: exercises ?? this.exercises,
      isCompleted: isCompleted ?? this.isCompleted,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      mood: mood ?? this.mood,
    );
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  int get completedSets {
    return exercises.fold(0, (sum, exercise) => sum + exercise.completedSets);
  }

  int get totalSets {
    return exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);
  }

  double get totalWeight {
    return exercises.fold(0.0, (sum, exercise) => sum + exercise.totalWeight);
  }

  double get progress {
    if (totalSets == 0) return 0.0;
    return completedSets / totalSets;
  }
}

class SessionExercise {
  final String id;
  final WorkoutExercise workoutExercise;
  final List<SessionSet> sets;

  SessionExercise({
    required this.id,
    required this.workoutExercise,
    required this.sets,
  });

  factory SessionExercise.fromWorkoutExercise(WorkoutExercise workoutExercise) {
    return SessionExercise(
      id: workoutExercise.id,
      workoutExercise: workoutExercise,
      sets: workoutExercise.sets.map((s) => SessionSet.fromWorkoutSet(s)).toList(),
    );
  }

  factory SessionExercise.fromMap(Map<String, dynamic> map) {
    return SessionExercise(
      id: map['id'] ?? '',
      workoutExercise: WorkoutExercise.fromMap(map['workoutExercise'] ?? {}),
      sets: (map['sets'] as List<dynamic>?)
          ?.map((s) => SessionSet.fromMap(s as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutExercise': workoutExercise.toMap(),
      'sets': sets.map((s) => s.toMap()).toList(),
    };
  }

  SessionExercise copyWith({
    String? id,
    WorkoutExercise? workoutExercise,
    List<SessionSet>? sets,
  }) {
    return SessionExercise(
      id: id ?? this.id,
      workoutExercise: workoutExercise ?? this.workoutExercise,
      sets: sets ?? this.sets,
    );
  }

  int get completedSets {
    return sets.where((set) => set.isCompleted).length;
  }

  double get totalWeight {
    return sets.where((set) => set.isCompleted).fold(0.0, (sum, set) => sum + (set.weight * set.reps));
  }
}

class SessionSet {
  final String id;
  final int reps;
  final double weight;
  final bool isCompleted;
  final int? lastReps;
  final double? lastWeight;

  SessionSet({
    required this.id,
    required this.reps,
    required this.weight,
    this.isCompleted = false,
    this.lastReps,
    this.lastWeight,
  });

  factory SessionSet.fromWorkoutSet(WorkoutSet workoutSet) {
    // lastReps and lastWeight will be populated later when fetching workout history
    // Initialize reps/weight of SessionSet from the WorkoutSet's targetReps/targetWeight
    return SessionSet(
      id: workoutSet.id, // This ID is from the template set. A new ID might be needed if SessionSets are independent.
                         // For now, keeping it, assuming SessionSet might be a direct copy for active workout.
      reps: workoutSet.targetReps ?? 0, // Default to 0 if targetReps is null
      weight: workoutSet.targetWeight ?? 0.0, // Default to 0.0 if targetWeight is null
      lastReps: null, 
      lastWeight: null,
    );
  }

  factory SessionSet.fromMap(Map<String, dynamic> map) {
    return SessionSet(
      id: map['id'] ?? '',
      reps: map['reps'] ?? 0,
      weight: (map['weight'] ?? 0.0).toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      lastReps: map['lastReps'] as int?,
      lastWeight: (map['lastWeight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reps': reps,
      'weight': weight,
      'isCompleted': isCompleted,
      'lastReps': lastReps,
      'lastWeight': lastWeight,
    };
  }

  SessionSet copyWith({
    String? id,
    int? reps,
    double? weight,
    bool? isCompleted,
    int? lastReps,
    double? lastWeight,
  }) {
    return SessionSet(
      id: id ?? this.id,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
      lastReps: lastReps ?? this.lastReps,
      lastWeight: lastWeight ?? this.lastWeight,
    );
  }
}

enum WorkoutMood {
  veryHappy,
  happy,
  neutral,
  sad,
  verySad,
}

extension WorkoutMoodExtension on WorkoutMood {
  String get displayName {
    switch (this) {
      case WorkoutMood.veryHappy:
        return 'Very Happy';
      case WorkoutMood.happy:
        return 'Happy';
      case WorkoutMood.neutral:
        return 'Neutral';
      case WorkoutMood.sad:
        return 'Sad';
      case WorkoutMood.verySad:
        return 'Very Sad';
    }
  }

  String get emoji {
    switch (this) {
      case WorkoutMood.veryHappy:
        return '😄';
      case WorkoutMood.happy:
        return '😊';
      case WorkoutMood.neutral:
        return '😐';
      case WorkoutMood.sad:
        return '😔';
      case WorkoutMood.verySad:
        return '😢';
    }
  }
}
