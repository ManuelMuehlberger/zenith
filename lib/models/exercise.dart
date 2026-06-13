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
  final Map<MuscleGroup, double> muscleActivation;
  final double exerciseIntensity;
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
    Map<MuscleGroup, double> muscleActivation = const {},
    this.exerciseIntensity = 1.0,
    this.isBodyWeightExercise = false,
    this.isCustom = false,
    this.type = ExerciseType.strength,
  }) : secondaryMuscleGroups = List.unmodifiable(secondaryMuscleGroups),
       instructions = List.unmodifiable(instructions),
       muscleActivation = Map.unmodifiable(muscleActivation);

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
      muscleActivation: _readMuscleActivation(map),
      exerciseIntensity: _readExerciseIntensity(map),
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
      'muscle_activation': jsonEncode(
        muscleActivation.map((key, value) => MapEntry(key.name, value)),
      ),
      'exercise_intensity': exerciseIntensity,
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

Map<MuscleGroup, double> _readMuscleActivation(Map<String, dynamic> map) {
  for (final key in const [
    'muscleActivation',
    'muscle_activation',
    'muscleActivationJson',
  ]) {
    final value = map[key];
    if (value == null) {
      continue;
    }
    final decoded = _readDynamicMap(value, key);
    return Map.unmodifiable(
      decoded.map(
        (muscleName, intensity) => MapEntry(
          MuscleGroup.fromName(muscleName),
          _readIntensity(intensity, muscleName),
        ),
      ),
    );
  }
  return const {};
}

double _readExerciseIntensity(Map<String, dynamic> map) {
  for (final key in const [
    'exerciseIntensity',
    'exercise_intensity',
    'exerciseIntensityValue',
  ]) {
    final value = map[key];
    if (value == null) {
      continue;
    }
    return _readIntensity(value, key);
  }
  return 1.0;
}

List<String> _readStringList(Map<String, dynamic> map, List<String> keys) {
  final values = _readDynamicList(map, keys);
  return List<String>.unmodifiable(values.map((value) => value.toString()));
}

Map<String, dynamic> _readDynamicMap(Object value, String key) {
  if (value is Map) {
    return value.map(
      (mapKey, mapValue) => MapEntry(mapKey.toString(), mapValue),
    );
  }
  if (value is String) {
    if (value.trim().isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(value);
    if (decoded is Map) {
      return decoded.map(
        (mapKey, mapValue) => MapEntry(mapKey.toString(), mapValue),
      );
    }
    throw FormatException('Expected map payload for "$key"');
  }
  throw FormatException('Invalid "$key": expected Map or JSON string');
}

double _readIntensity(Object? value, String muscleName) {
  if (value is num) {
    return value.toDouble();
  }
  throw FormatException('Invalid intensity for "$muscleName": expected number');
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
