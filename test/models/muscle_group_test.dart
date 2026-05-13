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
      expect(MuscleGroup.fromName('Front Deltoids'), MuscleGroup.frontDeltoids);
      expect(
        MuscleGroup.fromName('Lateral Deltoids'),
        MuscleGroup.lateralDeltoids,
      );
      expect(MuscleGroup.fromName('Rear Deltoids'), MuscleGroup.rearDeltoids);
      expect(MuscleGroup.fromName('Shoulders'), MuscleGroup.shoulders);
      expect(MuscleGroup.fromName('Rotator Cuffs'), MuscleGroup.rotatorCuff);
      expect(MuscleGroup.fromName('Biceps'), MuscleGroup.biceps);
      expect(MuscleGroup.fromName('Quads'), MuscleGroup.quads);
      expect(MuscleGroup.fromName('Hamstrings'), MuscleGroup.hamstrings);
      expect(MuscleGroup.fromName('Glutes'), MuscleGroup.glutes);
      expect(MuscleGroup.fromName('Adductors'), MuscleGroup.adductors);
      expect(MuscleGroup.fromName('Abductors'), MuscleGroup.abductors);
      expect(MuscleGroup.fromName('Lower Back'), MuscleGroup.lowerBack);
      expect(MuscleGroup.fromName('Trapezius'), MuscleGroup.trapezius);
      expect(
        MuscleGroup.fromName('Forearm Flexors'),
        MuscleGroup.forearmFlexors,
      );
      expect(MuscleGroup.fromName('Forearms'), MuscleGroup.forearms);
      expect(MuscleGroup.fromName('Calves'), MuscleGroup.calves);
      expect(MuscleGroup.fromName('Abs'), MuscleGroup.abs);
      expect(MuscleGroup.fromName('Obliques'), MuscleGroup.obliques);
      expect(MuscleGroup.fromName('Back'), MuscleGroup.back);
      expect(MuscleGroup.fromName('Lats'), MuscleGroup.lats);
      expect(MuscleGroup.fromName('Legs'), MuscleGroup.legs);
      expect(MuscleGroup.fromName('Cardio'), MuscleGroup.cardio);
    });

    test('fromName is case insensitive', () {
      expect(MuscleGroup.fromName('chest'), MuscleGroup.chest);
      expect(MuscleGroup.fromName('CHEST'), MuscleGroup.chest);
      expect(MuscleGroup.fromName('ChEsT'), MuscleGroup.chest);
      expect(MuscleGroup.fromName('triceps'), MuscleGroup.triceps);
      expect(MuscleGroup.fromName('FRONT DELTOIDS'), MuscleGroup.frontDeltoids);
      expect(MuscleGroup.fromName('rotator cuffs'), MuscleGroup.rotatorCuff);
      expect(MuscleGroup.fromName('ROTATOR CUFFs'), MuscleGroup.rotatorCuff);
    });

    test('fromName throws exception for invalid name', () {
      expect(
        () => MuscleGroup.fromName('Nonexistent Muscle'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('MuscleGroup not found'),
          ),
        ),
      );
      expect(
        () => MuscleGroup.fromName(''),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('MuscleGroup not found'),
          ),
        ),
      );
      expect(
        () => MuscleGroup.fromName('Unknown'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('MuscleGroup not found'),
          ),
        ),
      );
    });

    test('toMap serializes the display name', () {
      expect(MuscleGroup.lowerBack.toMap(), {'name': 'Lower Back'});
      expect(MuscleGroup.na.toMap(), {'name': 'NA'});
    });

    test('fromMap parses exact display names', () {
      expect(
        MuscleGroup.fromMap({'name': 'Lower Back'}),
        MuscleGroup.lowerBack,
      );
      expect(MuscleGroup.fromMap({'name': 'Lats'}), MuscleGroup.lats);
      expect(MuscleGroup.fromMap({'name': 'NA'}), MuscleGroup.na);
    });

    test('fromMap falls back to case-insensitive parsing', () {
      expect(
        MuscleGroup.fromMap({'name': 'lower back'}),
        MuscleGroup.lowerBack,
      );
      expect(
        MuscleGroup.fromMap({'name': 'rotator cuffs'}),
        MuscleGroup.rotatorCuff,
      );
    });

    test('fromMap surfaces the invalid muscle group name', () {
      expect(
        () => MuscleGroup.fromMap({'name': 'Not a muscle group'}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Not a muscle group'),
          ),
        ),
      );
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
