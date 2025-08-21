import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/reorder_service.dart';

void main() {
  group('ReorderService Tests', () {
    late ReorderService reorderService;

    setUp(() {
      // Get the singleton instance of the reorder service
      reorderService = ReorderService.instance;
    });

    test('should initialize reorder service', () {
      // Verify reorder service is initialized
      expect(reorderService, isNotNull);
    });
  });
}
