import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:logging/logging.dart';

import 'workout_service.dart';

/// Service to manage reordering state for workout exercises.
/// This service helps to decouple reorder logic from the UI widgets.
class ReorderService extends ChangeNotifier {
  static final ReorderService _instance = ReorderService._internal();
  final Logger _logger = Logger('ReorderService');

  factory ReorderService({WorkoutService? workoutService}) {
    _instance._workoutService = workoutService ?? WorkoutService.instance;
    return _instance;
  }
  ReorderService._internal();

  static ReorderService get instance => _instance;

  late WorkoutService _workoutService;

  bool _isReorderMode = false;
  int? _draggingIndex; // Index of the item currently being dragged
  bool _isDragConfirmed = false; // True if drag has met delay and threshold

  Timer? _dragStartDelayTimer;
  Timer? _dragCompletionTimeoutTimer;

  // Drag sensitivity settings
  static const Duration _initialDragDelay = Duration(milliseconds: 1000);
  static const Duration _completionTimeout = Duration(seconds: 10);

  bool get isReorderMode => _isReorderMode;
  int? get draggingIndex => _isDragConfirmed ? _draggingIndex : null;
  bool get isAnyItemPotentiallyDragging => _draggingIndex != null;

  void toggleReorderMode() {
    _isReorderMode = !_isReorderMode;
    _logger.info('Reorder mode toggled: $_isReorderMode');
    if (!_isReorderMode) {
      _resetDragState();
    }
    notifyListeners();
  }

  void onDragStarted(int index) {
    if (!_isReorderMode || _isDragConfirmed) return;

    _logger.fine('Drag started on index: $index');
    _draggingIndex = index;
    _dragStartDelayTimer?.cancel();
    _dragStartDelayTimer = Timer(_initialDragDelay, () {
      if (_draggingIndex == index) {
        _logger.info('Drag confirmed for index: $index');
        _isDragConfirmed = true;
        HapticFeedback.selectionClick();
        
        _dragCompletionTimeoutTimer?.cancel();
        _dragCompletionTimeoutTimer = Timer(_completionTimeout, () {
          _logger.warning('Drag completion timeout reached. Resetting state.');
          _resetDragState();
        });
        
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void onDragUpdated() {
    if (_isDragConfirmed) {
      _dragCompletionTimeoutTimer?.cancel();
      _dragCompletionTimeoutTimer = Timer(_completionTimeout, () {
        _logger.warning('Drag completion timeout reached during update. Resetting state.');
        _resetDragState();
      });
    }
  }

  void onReorderCompleted(String workoutId, int oldIndex, int newIndex) {
    _logger.info('Reorder completed for workout: $workoutId, from $oldIndex to $newIndex');
    if (_isDragConfirmed) {
      HapticFeedback.mediumImpact();
      
      _logger.fine('Persisting reorder to database');
      _workoutService.reorderExercisesInWorkout(workoutId, oldIndex, newIndex);
    }
    _resetDragState();
  }

  void onDragCancelled() {
    _logger.fine('Drag cancelled');
    _resetDragState();
  }

  void _resetDragState() {
    _logger.fine('Resetting drag state');
    bool needsNotify = _draggingIndex != null || _isDragConfirmed;
    _dragStartDelayTimer?.cancel();
    _dragCompletionTimeoutTimer?.cancel();
    _draggingIndex = null;
    _isDragConfirmed = false;
    if (needsNotify) {
      notifyListeners();
    }
  }

  // Helper to check if a specific item is the one being actively dragged
  bool isItemBeingActivelyDragged(int index) {
    return _isDragConfirmed && _draggingIndex == index;
  }

  // Helper to check if any item is being dragged (for styling other items)
  bool isAnotherItemBeingActivelyDragged(int currentIndex) {
    return _isDragConfirmed && _draggingIndex != null && _draggingIndex != currentIndex;
  }

  @override
  void dispose() {
    _dragStartDelayTimer?.cancel();
    _dragCompletionTimeoutTimer?.cancel();
    super.dispose();
  }
}
