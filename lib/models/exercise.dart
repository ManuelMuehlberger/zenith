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
  final bool
  isBodyWeightExercise; // bodyweight exercises do not have a "weight" associated to them in the active workout page.
  final bool isCustom;
  final ExerciseType type;

  Exercise({
    required this.slug,
    required this.name,
    required this.primaryMuscleGroup,
    required List<MuscleGroup> secondaryMuscleGroups,
    required List<String> instructions,
    this.equipment = '',
    required this.image,
    required this.animation,
    this.isBodyWeightExercise = false,
    this.isCustom = false,
    this.type = ExerciseType.strength,
  }) : secondaryMuscleGroups = List.unmodifiable(secondaryMuscleGroups),
       instructions = List.unmodifiable(instructions);

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      slug: _readString(map, ['slug']),
      name: _readString(map, ['name']),
      primaryMuscleGroup: _readPrimaryMuscleGroup(map),
      secondaryMuscleGroups: _readMuscleGroups(map, const [
        'secondaryMuscleGroups',
        'secondary_muscle_groups',
      ]),
      instructions: _readStringList(map, const ['instructions']),
      equipment: _readString(map, ['equipment'], fallback: ''),
      image: _readString(map, ['image'], fallback: ''),
      animation: _readString(map, ['animation'], fallback: ''),
      isBodyWeightExercise: _readBool(map, const [
        'bodyweight',
        'is_bodyweight_exercise',
        'isBodyWeightExercise',
      ]),
      isCustom: _readBool(map, const ['custom', 'is_custom', 'isCustom']),
      type: ExerciseType.fromStorage(
        _readString(map, ['type', 'exercise_type', 'exerciseType']),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    // Emit snake_case keys to match existing tests/serialized format
    return {
      'slug': slug,
      'name': name,
      'primary_muscle_group': primaryMuscleGroup.name,
      'secondary_muscle_groups': jsonEncode(
        secondaryMuscleGroups.map((e) => e.name).toList(),
      ),
      'instructions': jsonEncode(instructions),
      'equipment': equipment,
      'image': image,
      'animation': animation,
      'is_bodyweight_exercise': isBodyWeightExercise ? 1 : 0,
      'is_custom': isCustom ? 1 : 0,
      'type': type.storageValue,
    };
  }
}

// policy: allow-public-api exercise type contract persisted across workouts and custom exercises.
enum ExerciseType {
  strength('strength', 'Strength'),
  cardio('cardio', 'Cardio');

  const ExerciseType(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static ExerciseType fromStorage(String value) {
    final normalized = value.trim().toLowerCase();
    return ExerciseType.values.firstWhere(
      (type) => type.storageValue == normalized,
      orElse: () => ExerciseType.strength,
    );
  }
}

String _readString(
  Map<String, dynamic> map,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) {
      continue;
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }
  return fallback;
}

MuscleGroup _readPrimaryMuscleGroup(Map<String, dynamic> map) {
  final name = _readString(map, const [
    'primaryMuscleGroup',
    'primary_muscle_group',
  ]);
  return MuscleGroup.fromName(name);
}

List<MuscleGroup> _readMuscleGroups(
  Map<String, dynamic> map,
  List<String> keys,
) {
  final values = _readDynamicList(map, keys);
  return List<MuscleGroup>.unmodifiable(
    values.map((value) => MuscleGroup.fromName(value.toString())),
  );
}

List<String> _readStringList(Map<String, dynamic> map, List<String> keys) {
  final values = _readDynamicList(map, keys);
  return List<String>.unmodifiable(values.map((value) => value.toString()));
}

List<dynamic> _readDynamicList(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) {
      continue;
    }
    if (value is List) {
      return List<dynamic>.from(value);
    }
    if (value is String) {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return List<dynamic>.from(decoded);
      }
      throw FormatException('Expected list payload for "$key"');
    }
    throw FormatException('Invalid "$key": expected List or JSON string');
  }
  return const [];
}

bool _readBool(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) {
      continue;
    }
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value == 1;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    throw FormatException('Invalid boolean value for "$key"');
  }
  return false;
}
