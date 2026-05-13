import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zenith/services/database_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Active workout state', () {
    test(
      'saveActiveWorkoutState and getActiveWorkoutState round-trip',
      () async {
        final state = {'id': 'active123', 'status': 'inProgress'};
        await DatabaseService.instance.saveActiveWorkoutState(state);
        final loaded = await DatabaseService.instance.getActiveWorkoutState();
        expect(loaded, isNotNull);
        expect(loaded!['id'], 'active123');
        expect(loaded['status'], 'inProgress');
      },
    );

    test('clearActiveWorkoutState removes state', () async {
      await DatabaseService.instance.saveActiveWorkoutState({'foo': 'bar'});
      await DatabaseService.instance.clearActiveWorkoutState();
      final loaded = await DatabaseService.instance.getActiveWorkoutState();
      expect(loaded, isNull);
    });
  });

  group('App settings', () {
    test('getAppSettings returns defaults when none saved', () async {
      final settings = await DatabaseService.instance.getAppSettings();
      expect(settings['units'], 'metric');
      expect(settings['theme'], 'system');
    });

    test('saveAppSettings persists and getAppSettings returns saved', () async {
      final saved = {'units': 'imperial', 'theme': 'light', 'custom': 1};
      await DatabaseService.instance.saveAppSettings(saved);
      final settings = await DatabaseService.instance.getAppSettings();
      expect(settings['units'], 'imperial');
      expect(settings['theme'], 'light');
      expect(settings['custom'], 1);
    });
  });

  group('Data clearing', () {
    test(
      'clearAllData removes legacy workouts, settings, and active state',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('workouts', ['{}']);
        await prefs.setString(
          'app_settings',
          '{"units":"imperial","theme":"light"}',
        );
        await prefs.setString('active_workout', '{"id":"active"}');

        await DatabaseService.instance.clearAllData();

        expect(prefs.getStringList('workouts'), isNull);
        expect(prefs.getString('app_settings'), isNull);
        expect(prefs.getString('active_workout'), isNull);
      },
    );
  });

  // Additional varied-data robustness tests
  group('Robustness and varied data', () {
    test('getAppSettings returns defaults on corrupt JSON', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_settings', '{invalid-json');
      final settings = await DatabaseService.instance.getAppSettings();
      expect(settings['units'], 'metric');
      expect(settings['theme'], 'system');
    });

    test('getActiveWorkoutState returns null on corrupt JSON', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_workout', '{invalid-json');
      final state = await DatabaseService.instance.getActiveWorkoutState();
      expect(state, isNull);
    });
  });
}
