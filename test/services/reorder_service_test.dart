import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:zenith/services/reorder_service.dart';
import 'package:zenith/services/workout_service.dart';
import 'package:fake_async/fake_async.dart';

import 'reorder_service_test.mocks.dart';

@GenerateMocks([WorkoutService])
void main() {
  group('ReorderService', () {
    late ReorderService reorderService;
    late MockWorkoutService mockWorkoutService;

    // Mock haptic feedback
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'HapticFeedback.vibrate') {
          return;
        }
        if (methodCall.method == 'HapticFeedback.selectionClick') {
          return;
        }
        if (methodCall.method == 'HapticFeedback.mediumImpact') {
          return;
        }
      });
    });

    tearDownAll(() {
      SystemChannels.platform.setMockMethodCallHandler(null);
    });

    setUp(() {
      mockWorkoutService = MockWorkoutService();
      reorderService = ReorderService(workoutService: mockWorkoutService);

      // Reset the service state before each test
      if (reorderService.isReorderMode) {
        reorderService.toggleReorderMode();
      }
      reorderService.onDragCancelled();
    });

    group('Initialization', () {
      test('should initialize with correct default state', () {
        expect(reorderService.isReorderMode, isFalse);
        expect(reorderService.draggingIndex, isNull);
        expect(reorderService.isAnyItemPotentiallyDragging, isFalse);
      });
    });

    group('Reorder Mode Toggle', () {
      test('should toggle reorder mode on and off', () {
        expect(reorderService.isReorderMode, isFalse);
        reorderService.toggleReorderMode();
        expect(reorderService.isReorderMode, isTrue);
        reorderService.toggleReorderMode();
        expect(reorderService.isReorderMode, isFalse);
      });

      test('should reset drag state when turning off reorder mode', () {
        fakeAsync((async) {
          reorderService.toggleReorderMode(); // Turn on
          reorderService.onDragStarted(0);
          async.elapse(const Duration(seconds: 2)); // Confirm drag

          expect(reorderService.isAnyItemPotentiallyDragging, isTrue);
          expect(reorderService.draggingIndex, 0);

          reorderService.toggleReorderMode(); // Turn off
          expect(reorderService.isReorderMode, isFalse);
          expect(reorderService.isAnyItemPotentiallyDragging, isFalse);
          expect(reorderService.draggingIndex, isNull);
        });
      });

      test('should notify listeners when toggling reorder mode', () {
        bool notified = false;
        reorderService.addListener(() => notified = true);

        reorderService.toggleReorderMode();
        expect(notified, isTrue);
      });
    });

    group('Drag Operations', () {
      setUp(() {
        reorderService.toggleReorderMode(); // Enable reorder mode
      });

      test('should not start drag when not in reorder mode', () {
        reorderService.toggleReorderMode(); // Disable
        reorderService.onDragStarted(0);
        expect(reorderService.isAnyItemPotentiallyDragging, isFalse);
      });

      test('should start potential drag immediately', () {
        reorderService.onDragStarted(2);
        expect(reorderService.isAnyItemPotentiallyDragging, isTrue);
        expect(reorderService.draggingIndex, isNull); // Not confirmed yet
      });

      test('should confirm drag after delay', () {
        fakeAsync((async) {
          reorderService.onDragStarted(1);
          expect(reorderService.draggingIndex, isNull);

          async.elapse(const Duration(milliseconds: 1001));
          expect(reorderService.draggingIndex, 1);
        });
      });

      test('should not confirm drag if cancelled before delay', () {
        fakeAsync((async) {
          reorderService.onDragStarted(1);
          expect(reorderService.isAnyItemPotentiallyDragging, isTrue);

          reorderService.onDragCancelled();
          async.elapse(const Duration(milliseconds: 1001));

          expect(reorderService.draggingIndex, isNull);
          expect(reorderService.isAnyItemPotentiallyDragging, isFalse);
        });
      });

      test('should only confirm the last drag start after multiple rapid starts', () {
        fakeAsync((async) {
          reorderService.onDragStarted(0);
          async.elapse(const Duration(milliseconds: 100));
          reorderService.onDragStarted(1);
          async.elapse(const Duration(milliseconds: 100));
          reorderService.onDragStarted(2);

          async.elapse(const Duration(milliseconds: 1001));
          expect(reorderService.draggingIndex, 2);
        });
      });

      test('should not start new drag when another is already confirmed', () {
        fakeAsync((async) {
          reorderService.onDragStarted(0);
          async.elapse(const Duration(milliseconds: 1001));
          expect(reorderService.draggingIndex, 0);

          reorderService.onDragStarted(1); // Try to start another drag
          expect(reorderService.draggingIndex, 0); // Should be unchanged
        });
      });

      test('should reset drag state on cancellation', () {
        reorderService.onDragStarted(1);
        expect(reorderService.isAnyItemPotentiallyDragging, isTrue);

        reorderService.onDragCancelled();
        expect(reorderService.isAnyItemPotentiallyDragging, isFalse);
        expect(reorderService.draggingIndex, isNull);
      });

      test('should notify listeners on drag state changes', () {
        fakeAsync((async) {
          int notificationCount = 0;
          reorderService.addListener(() => notificationCount++);

          reorderService.onDragStarted(0);
          expect(notificationCount, 1); // Potential drag started

          async.elapse(const Duration(milliseconds: 1001));
          expect(notificationCount, 2); // Drag confirmed

          reorderService.onDragCancelled();
          expect(notificationCount, 3); // Drag cancelled
        });
      });
    });

    group('Drag Update and Timeout', () {
      setUp(() {
        reorderService.toggleReorderMode();
      });

      test('should not affect confirmation timer when updated before confirmation', () {
        fakeAsync((async) {
          reorderService.onDragStarted(0);
          reorderService.onDragUpdated(); // Should be ignored
          async.elapse(const Duration(milliseconds: 1001));
          expect(reorderService.draggingIndex, 0);
        });
      });

      test('should refresh completion timeout when updated after confirmation', () {
        fakeAsync((async) {
          reorderService.onDragStarted(0);
          async.elapse(const Duration(milliseconds: 1001)); // Confirm
          expect(reorderService.draggingIndex, 0);

          async.elapse(const Duration(seconds: 6)); // Elapse 6s
          reorderService.onDragUpdated(); // Refresh timeout

          async.elapse(const Duration(seconds: 5)); // Elapse another 5s
          // Total > 10s, but it was refreshed
          expect(reorderService.draggingIndex, 0);

          async.elapse(const Duration(seconds: 11)); // Finally time out
          expect(reorderService.draggingIndex, isNull);
        });
      });

      test('should reset drag state after completion timeout', () {
        fakeAsync((async) {
          reorderService.onDragStarted(0);
          async.elapse(const Duration(milliseconds: 1001));
          expect(reorderService.draggingIndex, 0);

          async.elapse(const Duration(seconds: 11)); // Timeout
          expect(reorderService.draggingIndex, isNull);
          expect(reorderService.isAnyItemPotentiallyDragging, isFalse);
        });
      });
    });

    group('Reorder Completion', () {
      setUp(() {
        reorderService.toggleReorderMode();
      });

      test('should complete reorder and call WorkoutService when drag is confirmed', () {
        fakeAsync((async) {
          when(mockWorkoutService.reorderExercisesInWorkout(any, any, any))
              .thenAnswer((_) async {});

          reorderService.onDragStarted(0);
          async.elapse(const Duration(milliseconds: 1001));
          expect(reorderService.draggingIndex, 0);

          reorderService.onReorderCompleted('workout123', 0, 2);

          verify(mockWorkoutService.reorderExercisesInWorkout('workout123', 0, 2)).called(1);
          expect(reorderService.draggingIndex, isNull);
          expect(reorderService.isAnyItemPotentiallyDragging, isFalse);
        });
      });

      test('should not call WorkoutService when drag is not confirmed', () {
        reorderService.onDragStarted(0);
        // Don't wait for confirmation

        reorderService.onReorderCompleted('workout123', 0, 2);

        verifyNever(mockWorkoutService.reorderExercisesInWorkout(any, any, any));
        expect(reorderService.draggingIndex, isNull);
        expect(reorderService.isAnyItemPotentiallyDragging, isFalse);
      });
    });

    group('Helper Methods', () {
      setUp(() {
        reorderService.toggleReorderMode();
      });

      test('should correctly identify actively dragged item', () {
        fakeAsync((async) {
          reorderService.onDragStarted(2);
          async.elapse(const Duration(milliseconds: 1001));

          expect(reorderService.isItemBeingActivelyDragged(2), isTrue);
          expect(reorderService.isItemBeingActivelyDragged(1), isFalse);
        });
      });

      test('should correctly identify other items when one is being dragged', () {
        fakeAsync((async) {
          reorderService.onDragStarted(2);
          async.elapse(const Duration(milliseconds: 1001));

          expect(reorderService.isAnotherItemBeingActivelyDragged(2), isFalse);
          expect(reorderService.isAnotherItemBeingActivelyDragged(1), isTrue);
        });
      });

      test('should return false for helpers when no drag is active', () {
        expect(reorderService.isItemBeingActivelyDragged(0), isFalse);
        expect(reorderService.isAnotherItemBeingActivelyDragged(0), isFalse);
      });

      test('should return false for helpers when drag is not confirmed', () {
        reorderService.onDragStarted(1);
        expect(reorderService.isItemBeingActivelyDragged(1), isFalse);
        expect(reorderService.isAnotherItemBeingActivelyDragged(0), isFalse);
      });
    });
  });
}
