import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// Service to manage reordering state for workout exercises.
/// This service helps to decouple reorder logic from the UI widgets.
class ReorderService extends ChangeNotifier {
  static final ReorderService _instance = ReorderService._internal();
  static ReorderService get instance => _instance;

  ReorderService._internal();

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
    if (!_isReorderMode) {
      _resetDragState();
    }
    notifyListeners();
  }

  void onDragStarted(int index) {
    if (!_isReorderMode || _isDragConfirmed) return;

    _draggingIndex = index;
    _dragStartDelayTimer?.cancel();
    _dragStartDelayTimer = Timer(_initialDragDelay, () {
      if (_draggingIndex == index) { // Check if still the same item
        _isDragConfirmed = true;
        HapticFeedback.selectionClick();
        
        // Fallback timer to clear state if drag gets stuck
        _dragCompletionTimeoutTimer?.cancel();
        _dragCompletionTimeoutTimer = Timer(_completionTimeout, _resetDragState);
        
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void onDragUpdated() {
    // If drag wasn't confirmed, and user moves, cancel the confirmation timer
    if (!_isDragConfirmed) {
       _dragStartDelayTimer?.cancel();
    }
    // If drag is confirmed, we might want to refresh the timeout
    if(_isDragConfirmed) {
        _dragCompletionTimeoutTimer?.cancel();
        _dragCompletionTimeoutTimer = Timer(_completionTimeout, _resetDragState);
    }
  }

  // Called when an item is dropped after reordering
  void onReorderCompleted() {
    if (_isDragConfirmed) {
      HapticFeedback.mediumImpact(); // Feedback for successful reorder
    }
    _resetDragState();
  }

  // Called if a drag is cancelled (e.g., finger lifted before reorder)
  void onDragCancelled() {
    _resetDragState();
  }

  void _resetDragState() {
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
