import 'typedefs.dart';

enum MuscleGroup {
  chest('Chest'),
  triceps('Triceps'),
  frontDeltoids('Front Deltoids'),
  core('Core'),
  lateralDeltoids('Lateral Deltoids'),
  rearDeltoids('Rear Deltoids'),
  shoulders('Shoulders'),
  biceps('Biceps'),
  lats('Lats'),
  rotatorCuff('Rotator Cuffs'),
  quads('Quads'),
  hamstrings('Hamstrings'),
  glutes('Glutes'),
  abductors('Abductors'),
  adductors('Adductors'),
  lowerBack('Lower Back'),
  trapezius('Trapezius'),
  forearmFlexors('Forearm Flexors'),
  forearms('Forearms'),
  calves('Calves'),
  abs('Abs'),
  obliques('Obliques'),
  back('Back'),
  legs('Legs'),
  cardio('Cardio'),
  na('NA');  // Musclegroup not found

  final MuscleGroupName name;
  const MuscleGroup(this.name);

  static MuscleGroup fromName(String name) {
    // First try exact match
    try {
      return values.firstWhere((e) => e.name == name);
    } catch (e) {
      // If exact match fails, try case-insensitive match
      return values.firstWhere(
        (e) => e.name.toLowerCase() == name.toLowerCase(), 
        orElse: () => throw Exception('MuscleGroup not found for name: $name')
      );
    }
  }
  
  // Database serialization methods
  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }

  factory MuscleGroup.fromMap(Map<String, dynamic> map) {
    return MuscleGroup.fromName(map['name'] as String);
  }
}
