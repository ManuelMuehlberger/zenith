import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/services/dao/user_dao.dart';

void main() {
  group('UserDao', () {
    late UserDao dao;

    setUp(() {
      dao = UserDao();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'UserData');
    });

    test('should convert user data to map', () {
      final now = DateTime.now();
      final userData = UserData(
        id: 'user123',
        name: 'John Doe',
        birthdate: DateTime(1990, 1, 1),
        units: Units.metric,
        weightHistory: [],
        createdAt: now,
        theme: 'dark',
      );

      final map = dao.toMap(userData);

      expect(map['id'], 'user123');
      expect(map['name'], 'John Doe');
      expect(map['birthdate'], '1990-01-01T00:00:00.000');
      expect(map['units'], 'metric');
      expect(map['createdAt'], now.toIso8601String());
      expect(map['theme'], 'dark');
    });

    test('should convert map to user data', () {
      final now = DateTime.now();
      final map = {
        'id': 'user456',
        'name': 'Jane Smith',
        'birthdate': '1995-05-15T00:00:00.000',
        'units': 'imperial',
        'createdAt': now.toIso8601String(),
        'theme': 'light',
      };

      final userData = dao.fromMap(map);

      expect(userData.id, 'user456');
      expect(userData.name, 'Jane Smith');
      expect(userData.birthdate, DateTime(1995, 5, 15));
      expect(userData.units, Units.imperial);
      expect(userData.weightHistory, isEmpty);
      expect(userData.createdAt, now);
      expect(userData.theme, 'light');
    });
  });
}
