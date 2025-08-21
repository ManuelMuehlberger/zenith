import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/muscle_group.dart';

void main() {
  group('MuscleGroup enum', () {
    test('all enum values have non-null names', () {
      for (final muscleGroup in MuscleGroup.values) {
        expect(muscleGroup.name, isNotNull);
        expect(muscleGroup.name, isNotEmpty);
      }
    });

    test('fromName returns correct enum for valid name', () {
      expect(MuscleGroup.fromName('Chest'), MuscleGroup.chest);
      expect(MuscleGroup.fromName('Triceps'), MuscleGroup.triceps);
      expect(MuscleGroup.fromName('Front Deltoid'), MuscleGroup.frontDeltoid);
      expect(MuscleGroup.fromName('Lateral Deltoid'), MuscleGroup.lateralDeltoid);
      expect(MuscleGroup.fromName('Rear Deltoid'), MuscleGroup.rearDeltoid);
      expect(MuscleGroup.fromName('Shoulders'), MuscleGroup.shoulders);
      expect(MuscleGroup.fromName('Rotator Cuff (posterior)'), MuscleGroup.rotatorCuffPosterior);
      expect(MuscleGroup.fromName('Rotator Cuff (anterior)'), MuscleGroup.rotatorCuffAnterior);
      expect(MuscleGroup.fromName('Biceps'), MuscleGroup.biceps);
      expect(MuscleGroup.fromName('Quads'), MuscleGroup.quads);
      expect(MuscleGroup.fromName('Hamstrings'), MuscleGroup.hamstrings);
      expect(MuscleGroup.fromName('Glutes'), MuscleGroup.glutes);
      expect(MuscleGroup.fromName('Adductors'), MuscleGroup.adductors);
      expect(MuscleGroup.fromName('Lower Back'), MuscleGroup.lowerBack);
      expect(MuscleGroup.fromName('Trapezius'), MuscleGroup.trapezius);
      expect(MuscleGroup.fromName('Forearm Flexors'), MuscleGroup.forearmFlexors);
      expect(MuscleGroup.fromName('Calves'), MuscleGroup.calves);
      expect(MuscleGroup.fromName('Abs'), MuscleGroup.abs);
      expect(MuscleGroup.fromName('Obliques'), MuscleGroup.obliques);
      expect(MuscleGroup.fromName('Back'), MuscleGroup.back);
      expect(MuscleGroup.fromName('Legs'), MuscleGroup.legs);
      expect(MuscleGroup.fromName('Cardio'), MuscleGroup.cardio);
    });

    test('fromName is case insensitive', () {
      expect(MuscleGroup.fromName('chest'), MuscleGroup.chest);
      expect(MuscleGroup.fromName('CHEST'), MuscleGroup.chest);
      expect(MuscleGroup.fromName('ChEsT'), MuscleGroup.chest);
      expect(MuscleGroup.fromName('triceps'), MuscleGroup.triceps);
      expect(MuscleGroup.fromName('FRONT DELTOID'), MuscleGroup.frontDeltoid);
      expect(MuscleGroup.fromName('rotator cuff (posterior)'), MuscleGroup.rotatorCuffPosterior);
      expect(MuscleGroup.fromName('ROTATOR CUFF (ANTERIOR)'), MuscleGroup.rotatorCuffAnterior);
    });

    test('fromName throws exception for invalid name', () {
      expect(() => MuscleGroup.fromName('Nonexistent Muscle'), 
          throwsA(isA<Exception>().having((e) => e.toString(), 'toString', contains('MuscleGroup not found'))));
      expect(() => MuscleGroup.fromName(''), 
          throwsA(isA<Exception>().having((e) => e.toString(), 'toString', contains('MuscleGroup not found'))));
      expect(() => MuscleGroup.fromName('Unknown'), 
          throwsA(isA<Exception>().having((e) => e.toString(), 'toString', contains('MuscleGroup not found'))));
    });

    test('enum values are unique', () {
      final names = <String>{};
      for (final muscleGroup in MuscleGroup.values) {
        expect(names.contains(muscleGroup.name), isFalse);
        names.add(muscleGroup.name);
      }
      expect(names.length, MuscleGroup.values.length);
    });
  });
}
