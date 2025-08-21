import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/workout_exercise.dart';

class ModularReorderableExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final int itemIndex;
  final Function(String exerciseId) onAddSet;
  final Function(String exerciseId, String setId) onRemoveSet;
  final String weightUnit;
  final bool isDragging;
  final int? draggingIndex;

  const ModularReorderableExerciseCard({
    super.key,
    required this.exercise,
    required this.itemIndex,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.weightUnit,
    this.isDragging = false,
    this.draggingIndex,
  });

  @override
  State<ModularReorderableExerciseCard> createState() =>
      _ModularReorderableExerciseCardState();
}

class _ModularReorderableExerciseCardState
    extends State<ModularReorderableExerciseCard> with TickerProviderStateMixin {
  late AnimationController _contentVisibilityController;
  late AnimationController _dragStateController;

  late Animation<double> _contentAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();

    _contentVisibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dragStateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _contentAnimation = CurvedAnimation(
      parent: _contentVisibilityController,
      curve: Curves.easeInOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _dragStateController, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _dragStateController, curve: Curves.easeInOut),
    );
    _borderColorAnimation = ColorTween(
      begin: Colors.orange.withAlpha((255 * 0.5).round()),
      end: Colors.blue.withAlpha((255 * 0.8).round()),
    ).animate(CurvedAnimation(parent: _dragStateController, curve: Curves.easeInOut));

    // Initial animation state based on initial widget properties
    // Call _updateAnimations directly if widget is already built,
    // otherwise, schedule it for after the first frame.
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateAnimations();
      });
    } else {
       WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateAnimations();
      });
    }
  }

  @override
  void didUpdateWidget(ModularReorderableExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only call _updateAnimations if relevant properties have changed
    if (widget.isDragging != oldWidget.isDragging || widget.draggingIndex != oldWidget.draggingIndex) {
      if (mounted) {
        _updateAnimations();
      }
    }
  }

  void _updateAnimations() {
    if (!mounted) return;

    final bool isSelfDragging = widget.isDragging;
    final bool isOtherDragging = widget.draggingIndex != null &&
        widget.draggingIndex != widget.itemIndex;

    // Content collapses if this item is being dragged or another item is being dragged
    if (isSelfDragging || isOtherDragging) {
      if (_contentVisibilityController.status != AnimationStatus.dismissed &&
          _contentVisibilityController.status != AnimationStatus.reverse) {
        _contentVisibilityController.reverse();
      }
    } else {
      if (_contentVisibilityController.status != AnimationStatus.completed &&
          _contentVisibilityController.status != AnimationStatus.forward) {
        _contentVisibilityController.forward();
      }
    }

    // _dragStateController drives animations based on drag state
    if (isSelfDragging || isOtherDragging) {
      if (_dragStateController.status != AnimationStatus.completed &&
          _dragStateController.status != AnimationStatus.forward) {
        _dragStateController.forward();
      }
    } else {
      if (_dragStateController.status != AnimationStatus.dismissed &&
          _dragStateController.status != AnimationStatus.reverse) {
        _dragStateController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _contentVisibilityController.dispose();
    _dragStateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelfDragging = widget.isDragging;
    final bool isOtherDragging = widget.draggingIndex != null &&
        widget.draggingIndex != widget.itemIndex;

    double currentScale = 1.0;
    double currentOpacity = 1.0;
    Color? currentBorderColor;

    if (isSelfDragging) {
      currentBorderColor = _borderColorAnimation.value; // Blue
    } else if (isOtherDragging) {
      currentScale = _scaleAnimation.value;
      currentOpacity = _opacityAnimation.value;
      currentBorderColor = Colors.grey[700]!.withAlpha((255 * 0.6).round());
    } else {
      currentBorderColor = _borderColorAnimation.value; // Orange (controller reversed)
    }

    return Container(
      key: widget.key,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Transform.scale(
        scale: currentScale,
        child: Opacity(
          opacity: currentOpacity.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[850]?.withAlpha((255 * 0.9).round()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: currentBorderColor ?? Colors.orange.withAlpha((255 * 0.5).round()),
                width: 2,
              ),
              boxShadow: isSelfDragging
                  ? [
                      BoxShadow(
                        color: Colors.blue.withAlpha((255 * 0.25).round()),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, isSelfDragging),
                SizeTransition(
                  sizeFactor: _contentAnimation,
                  axisAlignment: -1.0,
                  child: FadeTransition(
                    opacity: _contentAnimation,
                    child: _buildFullSetsView(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSelfDragging) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 16.0, 16.0, 12.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0, left: 4.0),
            child: Icon(
              CupertinoIcons.line_horizontal_3,
              color: isSelfDragging ? Colors.blue : Colors.orange,
              size: 24,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exercise.exerciseDetail?.name ?? widget.exercise.exerciseSlug,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.exercise.exerciseDetail?.primaryMuscleGroup.name ?? "N/A",
                  style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullSetsView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: Colors.white24, indent: 16, endIndent: 16),
        if (widget.exercise.sets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
            child: Column(
              children: List.generate(widget.exercise.sets.length, (index) {
                final set = widget.exercise.sets[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Text(
                        'Set ${index + 1}: ',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                      Expanded(
                        child: Text(
                          '${set.actualReps ?? set.targetReps ?? 0} reps, ${(set.actualWeight ?? set.targetWeight ?? 0.0).toStringAsFixed(1)} ${widget.weightUnit}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 30,
                        child: Icon(CupertinoIcons.minus_circle_fill,
                            color: Colors.redAccent[100], size: 22),
                        onPressed: () =>
                            widget.onRemoveSet(widget.exercise.id, set.id),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        if (widget.exercise.sets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text('No sets added yet.',
                style: TextStyle(
                    color: Colors.grey[500], fontStyle: FontStyle.italic),
                textAlign: TextAlign.center),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          color: Colors.orange.withAlpha((255 * 0.8).round()),
          borderRadius: BorderRadius.circular(8.0),
            onPressed: () => widget.onAddSet(widget.exercise.id),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.add, size: 20, color: Colors.white),
                SizedBox(width: 8),
                Text('Add Set',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
