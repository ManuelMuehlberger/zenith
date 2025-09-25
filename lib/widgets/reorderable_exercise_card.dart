import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/workout_exercise.dart';

class ReorderableExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final Function(String exerciseId) onAddSet;
  final Function(String exerciseId, String setId) onRemoveSet;
  final String weightUnit;
  final bool isBeingDragged;
  final bool isOtherCardDragging;

  const ReorderableExerciseCard({
    super.key,
    required this.exercise,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.weightUnit,
    this.isBeingDragged = false,
    this.isOtherCardDragging = false,
  });

  @override
  State<ReorderableExerciseCard> createState() => _ReorderableExerciseCardState();
}

class _ReorderableExerciseCardState extends State<ReorderableExerciseCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _contentController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _contentAnimation;

  bool _wasCompact = false;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Scale animation with bounce effect
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Opacity animation for smooth fade
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Content animation for height changes
    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeInOutCubic,
    );

    // Initialize based on current state
    final bool showCompact = widget.isOtherCardDragging || widget.isBeingDragged;
    if (showCompact) {
      _scaleController.value = 1.0;
      _contentController.value = 0.0;
      _wasCompact = true;
    } else {
      _scaleController.value = 0.0;
      _contentController.value = 1.0;
      _wasCompact = false;
    }
  }

  @override
  void didUpdateWidget(ReorderableExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final bool showCompact = widget.isOtherCardDragging || widget.isBeingDragged;
    
    if (showCompact != _wasCompact) {
      if (showCompact) {
        // Animate to compact state
        _scaleController.forward();
        _contentController.reverse();
      } else {
        // Animate to full state
        _scaleController.reverse();
        _contentController.forward();
      }
      _wasCompact = showCompact;
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showCompact = widget.isOtherCardDragging || widget.isBeingDragged;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _contentController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[850]?.withAlpha((255 * 0.8).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: showCompact 
                      ? Colors.red.withAlpha((255 * 0.8).round())  // Red when compact
                      : Colors.orange.withAlpha((255 * 0.5).round()), // Orange normally
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Exercise header with drag handle
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 16.0, 16.0, 8.0),
                    child: Row(
                      children: [
                        // Drag handle
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(
                            CupertinoIcons.line_horizontal_3,
                            color: Colors.orange,
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
                              ),
                              const SizedBox(height: 4),
Text(
  widget.exercise.exerciseDetail?.primaryMuscleGroup.name ?? "N/A",
  style: TextStyle(
    color: Colors.blue[300],
    fontSize: 14,
    fontWeight: FontWeight.w500,
  ),
),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Animated content area
                  ClipRect(
                    child: SizeTransition(
                      sizeFactor: _contentAnimation,
                      child: FadeTransition(
                        opacity: _contentAnimation,
                        child: _buildFullSetsView(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullSetsView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.exercise.sets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: List.generate(widget.exercise.sets.length, (index) {
                final set = widget.exercise.sets[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Text(
                        'Set ${index + 1}: ',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${set.actualReps ?? set.targetReps ?? 0} reps, ${(set.actualWeight ?? set.targetWeight ?? 0).toStringAsFixed(1)} ${widget.weightUnit}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => widget.onRemoveSet(widget.exercise.id, set.id),
                        minimumSize: const Size(30, 30),
                        child: Icon(
                          CupertinoIcons.minus_circle_fill,
                          color: Colors.redAccent[100],
                          size: 22,
                        ),
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
            child: Text(
              'No sets added yet.',
              style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
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
                Text(
                  'Add Set',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
