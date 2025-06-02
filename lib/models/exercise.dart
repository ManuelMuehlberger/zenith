class Exercise {
  final String slug;
  final String name;
  final String primaryMuscleGroup;
  final List<String> secondaryMuscleGroups;
  final List<String> instructions;
  final String image;
  final String animation;
  //final bool isBodyWeightExercise; // bodyweight exercises do not have a "weight" associated to them in the active workout page.

  Exercise({
    required this.slug,
    required this.name,
    required this.primaryMuscleGroup,
    required this.secondaryMuscleGroups,
    required this.instructions,
    required this.image,
    required this.animation,
    //required this.isBodyWeightExercise,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      slug: map['slug'] ?? '',
      name: map['name'] ?? '',
      primaryMuscleGroup: map['primary_muscle_group'] ?? '',
      secondaryMuscleGroups: List<String>.from(map['secondary_muscle_groups'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      image: map['image'] ?? '',
      animation: map['animation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slug': slug,
      'name': name,
      'primary_muscle_group': primaryMuscleGroup,
      'secondary_muscle_groups': secondaryMuscleGroups,
      'instructions': instructions,
      'image': image,
      'animation': animation,
    };
  }
}
