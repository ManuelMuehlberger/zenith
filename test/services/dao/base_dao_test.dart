import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/dao/base_dao.dart';

// Mock implementation of BaseDao for testing
class MockDao extends BaseDao<Map<String, dynamic>> {
  @override
  String get tableName => 'test_table';

  @override
  Map<String, dynamic> fromMap(Map<String, dynamic> map) {
    return map;
  }

  @override
  Map<String, dynamic> toMap(Map<String, dynamic> model) {
    return model;
  }
}

void main() {
  group('BaseDao', () {
    late MockDao dao;

    setUp(() {
      dao = MockDao();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'test_table');
    });

    test('should convert model to map', () {
      final model = {'id': 1, 'name': 'Test'};
      final map = dao.toMap(model);
      expect(map, model);
    });

    test('should convert map to model', () {
      final map = {'id': 1, 'name': 'Test'};
      final model = dao.fromMap(map);
      expect(model, map);
    });
  });
}
