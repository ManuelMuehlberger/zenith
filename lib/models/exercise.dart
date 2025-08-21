import 'dart:convert';
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
      secondaryMuscleGroups: map['secondary_muscle_groups'] != null
          ? (map['secondary_muscle_groups'] is String
              ? List<MuscleGroup>.from(
                  (jsonDecode(map['secondary_muscle_groups']) as List)
                      .map((e) => MuscleGroup.fromName(e.toString())))
              : List<MuscleGroup>.from(
                  (map['secondary_muscle_groups'] as List)
                      .map((e) => MuscleGroup.fromName(e.toString()))))
          : [],
      instructions: map['instructions'] != null
          ? (map['instructions'] is String
              ? List<String>.from(jsonDecode(map['instructions']) as List)
              : List<String>.from(map['instructions'] as List))
          : [],
      image: map['image'] ?? '',
      animation: map['animation'] ?? '',
      isBodyWeightExercise: map['is_bodyweight_exercise'] is int 
          ? map['is_bodyweight_exercise'] == 1 
          : map['is_bodyweight_exercise'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slug': slug,
      'name': name,
      'primary_muscle_group': primaryMuscleGroup.name,
      'secondary_muscle_groups': jsonEncode(
          secondaryMuscleGroups.map((e) => e.name).toList()),
      'instructions': jsonEncode(instructions),
      'image': image,
      'animation': animation,
      'is_bodyweight_exercise': isBodyWeightExercise ? 1 : 0,
    };
  }
}
