import 'typedefs.dart';

enum MuscleGroup {
  chest('Chest'),
  triceps('Triceps'),
  frontDeltoid('Front Deltoid'),
  lateralDeltoid('Lateral Deltoid'),
  rearDeltoid('Rear Deltoid'),
  shoulders('Shoulders'),
  rotatorCuffPosterior('Rotator Cuff (posterior)'),
  rotatorCuffAnterior('Rotator Cuff (anterior)'),
  biceps('Biceps'),
  quads('Quads'),
  hamstrings('Hamstrings'),
  glutes('Glutes'),
  adductors('Adductors'),
  lowerBack('Lower Back'),
  trapezius('Trapezius'),
  forearmFlexors('Forearm Flexors'),
  calves('Calves'),
  abs('Abs'),
  obliques('Obliques'),
  back('Back'),
  legs('Legs'),
  cardio('Cardio');

  final MuscleGroupName name;
  const MuscleGroup(this.name);

  static MuscleGroup fromName(String name) {
    return values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(), 
      orElse: () => throw Exception('MuscleGroup not found for name: $name')
    );
  }
}
