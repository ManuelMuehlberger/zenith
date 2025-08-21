import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/services/dao/weight_entry_dao.dart';

void main() {
  group('WeightEntryDao', () {
    late WeightEntryDao dao;

    setUp(() {
      dao = WeightEntryDao();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'WeightEntry');
    });

    test('should convert weight entry to map', () {
      final timestamp = DateTime.now();
      final weightEntry = WeightEntry(
        id: 'weight123',
        timestamp: timestamp,
        value: 75.5,
      );

      final map = dao.toMap(weightEntry);

      expect(map['id'], 'weight123');
      expect(map['timestamp'], timestamp.toIso8601String());
      expect(map['value'], 75.5);
    });

    test('should convert map to weight entry', () {
      final timestamp = DateTime.now();
      final map = {
        'id': 'weight456',
        'timestamp': timestamp.toIso8601String(),
        'value': 80.2,
      };

      final weightEntry = dao.fromMap(map);

      expect(weightEntry.id, 'weight456');
      expect(weightEntry.timestamp, timestamp);
      expect(weightEntry.value, 80.2);
    });
  });
}
