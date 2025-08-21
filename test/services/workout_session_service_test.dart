import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/workout_session_service.dart';

void main() {
  group('WorkoutSessionService Tests', () {
    late WorkoutSessionService workoutSessionService;

    setUp(() {
      // Initialize the workout session service
      workoutSessionService = WorkoutSessionService();
    });

    test('should initialize workout session service', () {
      // Verify workout session service is initialized
      expect(workoutSessionService, isNotNull);
    });
  });
}
