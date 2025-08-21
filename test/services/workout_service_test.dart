import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/workout_service.dart';

void main() {
  group('WorkoutService Tests', () {
    late WorkoutService workoutService;

    setUp(() {
      // Initialize the workout service
      workoutService = WorkoutService();
    });

    test('should initialize workout service', () {
      // Verify workout service is initialized
      expect(workoutService, isNotNull);
    });
  });
}
