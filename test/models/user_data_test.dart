import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/models/typedefs.dart';
import 'package:zenith/constants/app_constants.dart';

void main() {
  group('WeightEntry', () {
    test('toMap and fromMap should be consistent', () {
      final entry = WeightEntry(
        timestamp: DateTime(2023, 1, 15),
        value: 75.5,
      );
      
      final map = entry.toMap();
      final fromMap = WeightEntry.fromMap(map);
      
      expect(fromMap.timestamp, entry.timestamp);
      expect(fromMap.value, entry.value);
    });

    test('fromMap handles missing values', () {
      final map = <String, dynamic>{};
      final entry = WeightEntry.fromMap(map);
      
      expect(entry.value, 0.0);
    });
  });

  group('UserData', () {
    final testDate = DateTime(2023, 1, 15);
    final weightHistory = [
      WeightEntry(timestamp: testDate, value: 70.0),
      WeightEntry(timestamp: testDate.add(const Duration(days: 7)), value: 71.5),
    ];

    final userData = UserData(
      name: 'John Doe',
      birthdate: DateTime(1990, 5, 15),
      units: Units.metric,
      weightHistory: weightHistory,
      createdAt: testDate,
      theme: 'dark',
    );
    test('toMap and fromMap should be consistent', () {
      final map = userData.toMap();
      final fromMap = UserData.fromMap(map);
      
      expect(fromMap.name, userData.name);
      expect(fromMap.birthdate, userData.birthdate);
      expect(fromMap.units, userData.units);
      expect(fromMap.weightHistory.length, userData.weightHistory.length);
      expect(fromMap.createdAt, userData.createdAt);
    });

    test('fromMap handles empty weightHistory', () {
      final map = {
        'name': 'Test',
        'birthdate': '1990-05-15T00:00:00.000',
        'units': 'metric',
        'weightHistory': [],
        'createdAt': '2023-01-15T00:00:00.000',
        'theme': 'dark',
        'other_settings_json': '{}',
      };
      
      final userData = UserData.fromMap(map);
      expect(userData.weightHistory, isEmpty);
    });

    test('fromMap handles null weightHistory', () {
      final map = {
        'name': 'Test',
        'birthdate': '1990-05-15T00:00:00.000',
        'units': 'metric',
        'createdAt': '2023-01-15T00:00:00.000',
        'theme': 'dark',
        'other_settings_json': '{}',
      };
      
      final userData = UserData.fromMap(map);
      expect(userData.weightHistory, isEmpty);
      expect(userData.name, 'Test');
      expect(userData.birthdate.year, 1990);
      expect(userData.birthdate.month, 5);
      expect(userData.birthdate.day, 15);
      expect(userData.units, Units.metric);
    });

    test('copyWith creates new instance with updated values', () {
      final updated = userData.copyWith(name: 'Jane Doe', units: Units.imperial);
      expect(updated.theme, userData.theme);
      
      expect(updated.name, 'Jane Doe');
      expect(updated.units, Units.imperial);
      expect(updated.birthdate, userData.birthdate);
      expect(updated.weightHistory, userData.weightHistory);
      expect(updated.createdAt, userData.createdAt);
    });

    test('weightUnit returns correct unit', () {
      expect(userData.weightUnit, 'kg');
      
      final imperialUser = userData.copyWith(units: Units.imperial);
      expect(imperialUser.weightUnit, 'lbs');
    });

    group('age calculation', () {
      test('returns correct age when birthday has passed this year', () {
        final today = DateTime(2023, 6, 1);
        final userData = UserData(
          name: 'Test',
          birthdate: DateTime(1990, 5, 15),
          units: Units.metric,
          weightHistory: [],
          createdAt: today,
          theme: 'dark',
        );
        expect(userData.age, 35);
      });

      test('returns correct age when birthday has not passed this year', () {
        final today = DateTime(2023, 4, 1);
        final userData = UserData(
          name: 'Test',
          birthdate: DateTime(1990, 5, 15),
          units: Units.metric,
          weightHistory: [],
          createdAt: today,
          theme: 'dark',
        );
        expect(userData.age, 35);
      });

      test('handles leap year birthday', () {
        final today = DateTime(2024, 3, 1);
        final userData = UserData(
          name: 'Test',
          birthdate: DateTime(2000, 2, 29),
          units: Units.metric,
          weightHistory: [],
          createdAt: today,
          theme: 'dark',
        );
        expect(userData.age, 25);
      });
    });
  });
}
