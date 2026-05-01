import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/utils/unit_converter.dart';

void main() {
  group('UnitConverter.formatWeight', () {
    test('formats metric weights with the requested precision', () {
      expect(UnitConverter.formatWeight(72.456, 'metric'), '72.5 kg');
      expect(
        UnitConverter.formatWeight(72.456, 'metric', decimals: 2),
        '72.46 kg',
      );
    });

    test('formats imperial weights and defaults non-metric units to lbs', () {
      expect(UnitConverter.formatWeight(180, 'imperial'), '180.0 lbs');
      expect(
        UnitConverter.formatWeight(180, 'unknown', decimals: 0),
        '180 lbs',
      );
    });
  });

  group('UnitConverter.getWeightUnit', () {
    test('returns kg for metric units', () {
      expect(UnitConverter.getWeightUnit('metric'), 'kg');
    });

    test('returns lbs for imperial and unsupported units', () {
      expect(UnitConverter.getWeightUnit('imperial'), 'lbs');
      expect(UnitConverter.getWeightUnit('unsupported'), 'lbs');
    });
  });
}
