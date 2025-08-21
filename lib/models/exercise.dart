import 'muscle_group.dart';
import 'typedefs.dart';

class Exercise {
  final ExerciseSlug slug; //unique identifier
  final String name;
  final MuscleGroup primaryMuscleGroup;
  final List<MuscleGroup> secondaryMuscleGroups;
  final List<String> instructions;
  final String image;
  final String animation;
  final bool isBodyWeightExercise; // bodyweight exercises do not have a "weight" associated to them in the active workout page.

  Exercise({
    required this.slug,
    required this.name,
    required this.primaryMuscleGroup,
    required this.secondaryMuscleGroups,
    required this.instructions,
    required this.image,
    required this.animation,
    this.isBodyWeightExercise = false,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      slug: map['slug'] ?? '',
      name: map['name'] ?? '',
      primaryMuscleGroup: MuscleGroup.fromName(map['primary_muscle_group'] ?? ''),
      secondaryMuscleGroups: List<MuscleGroup>.from((map['secondary_muscle_groups'] ?? []).map((e) => MuscleGroup.fromName(e.toString()))),
      instructions: List<String>.from(map['instructions'] ?? []),
      image: map['image'] ?? '',
      animation: map['animation'] ?? '',
      isBodyWeightExercise: map['is_bodyweight_exercise'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slug': slug,
      'name': name,
      'primary_muscle_group': primaryMuscleGroup.name.toLowerCase(),
      'secondary_muscle_groups':
          secondaryMuscleGroups.map((e) => e.name.toLowerCase()).toList(),
      'instructions': instructions,
      'image': image,
      'animation': animation,
      'is_bodyweight_exercise': isBodyWeightExercise,
    };
  }
}
