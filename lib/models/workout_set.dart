class WorkoutSet {
  final String id;
  int reps;
  double weight;
  bool isCompleted;
  // Rep range fields - when these are set, reps field is ignored
  int? repRangeMin;
  int? repRangeMax;
  bool get isRepRange => repRangeMin != null && repRangeMax != null;

  WorkoutSet({
    required this.id,
    required this.reps,
    required this.weight,
    this.isCompleted = false,
    this.repRangeMin,
    this.repRangeMax,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reps': reps,
      'weight': weight,
      'isCompleted': isCompleted,
      'repRangeMin': repRangeMin,
      'repRangeMax': repRangeMax,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] ?? '',
      reps: map['reps'] ?? 0,
      weight: (map['weight'] ?? 0.0).toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      repRangeMin: map['repRangeMin'],
      repRangeMax: map['repRangeMax'],
    );
  }

  WorkoutSet copyWith({
    String? id,
    int? reps,
    double? weight,
    bool? isCompleted,
    int? repRangeMin,
    int? repRangeMax,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
      repRangeMin: repRangeMin ?? this.repRangeMin,
      repRangeMax: repRangeMax ?? this.repRangeMax,
    );
  }
}
