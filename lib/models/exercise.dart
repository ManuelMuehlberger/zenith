import 'dart:convert';
import 'muscle_group.dart';
import 'typedefs.dart';

class Exercise {
  final ExerciseSlug slug; //unique identifier
  final String name;
  final MuscleGroup primaryMuscleGroup;
  final List<MuscleGroup> secondaryMuscleGroups;
  final List<String> instructions;
  final String equipment;
  final String image;
  final String animation;
  final bool isBodyWeightExercise; // bodyweight exercises do not have a "weight" associated to them in the active workout page.

  Exercise({
    required this.slug,
    required this.name,
    required this.primaryMuscleGroup,
    required this.secondaryMuscleGroups,
    required this.instructions,
    this.equipment = '',
    required this.image,
    required this.animation,
    this.isBodyWeightExercise = false,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    // Support both snake_case and camelCase keys for backward compatibility
    final String primaryMgName =
        (map['primaryMuscleGroup'] ?? map['primary_muscle_group'] ?? '').toString();

    // Secondary muscle groups can be a JSON string or a List, and under two different keys
    final dynamic secondaryRaw = map.containsKey('secondaryMuscleGroups')
        ? map['secondaryMuscleGroups']
        : map['secondary_muscle_groups'];

    List<MuscleGroup> secondaryMuscleGroups;
    if (secondaryRaw == null) {
      secondaryMuscleGroups = [];
    } else if (secondaryRaw is String) {
      try {
        final list = jsonDecode(secondaryRaw) as List;
        secondaryMuscleGroups = List<MuscleGroup>.from(
            list.map((e) => MuscleGroup.fromName(e.toString())));
      } catch (_) {
        secondaryMuscleGroups = [];
      }
    } else if (secondaryRaw is List) {
      secondaryMuscleGroups = List<MuscleGroup>.from(
          secondaryRaw.map((e) => MuscleGroup.fromName(e.toString())));
    } else {
      secondaryMuscleGroups = [];
    }

    // Instructions can be a JSON string or a List (key is 'instructions' in tests)
    final dynamic instructionsRaw = map['instructions'];
    List<String> instructions;
    if (instructionsRaw == null) {
      instructions = [];
    } else if (instructionsRaw is String) {
      try {
        instructions = List<String>.from(jsonDecode(instructionsRaw) as List);
      } catch (_) {
        instructions = [];
      }
    } else if (instructionsRaw is List) {
      instructions = List<String>.from(instructionsRaw);
    } else {
      instructions = [];
    }

    // Bodyweight flag across multiple possible keys/types
    bool isBodyWeightExercise = false;
    if (map.containsKey('bodyweight')) {
      final v = map['bodyweight'];
      if (v is bool) {
        isBodyWeightExercise = v;
      } else if (v is int) {
        isBodyWeightExercise = v == 1;
      } else {
        isBodyWeightExercise = (v ?? false) as bool;
      }
    } else if (map.containsKey('is_bodyweight_exercise')) {
      final v = map['is_bodyweight_exercise'];
      if (v is bool) {
        isBodyWeightExercise = v;
      } else if (v is int) {
        isBodyWeightExercise = v == 1;
      } else {
        isBodyWeightExercise = (v ?? false) as bool;
      }
    } else if (map.containsKey('isBodyWeightExercise')) {
      final v = map['isBodyWeightExercise'];
      if (v is bool) {
        isBodyWeightExercise = v;
      } else if (v is int) {
        isBodyWeightExercise = v == 1;
      } else {
        isBodyWeightExercise = (v ?? false) as bool;
      }
    }

    return Exercise(
      slug: map['slug'] ?? '',
      name: map['name'] ?? '',
      primaryMuscleGroup: MuscleGroup.fromName(primaryMgName),
      secondaryMuscleGroups: secondaryMuscleGroups,
      instructions: instructions,
      equipment: map['equipment'] ?? '',
      image: map['image'] ?? '',
      animation: map['animation'] ?? '',
      isBodyWeightExercise: isBodyWeightExercise,
    );
  }

  Map<String, dynamic> toMap() {
    // Emit snake_case keys to match existing tests/serialized format
    return {
      'slug': slug,
      'name': name,
      'primary_muscle_group': primaryMuscleGroup.name,
      'secondary_muscle_groups':
          jsonEncode(secondaryMuscleGroups.map((e) => e.name).toList()),
      'instructions': jsonEncode(instructions),
      'equipment': equipment,
      'image': image,
      'animation': animation,
      'is_bodyweight_exercise': isBodyWeightExercise ? 1 : 0,
    };
  }
}
