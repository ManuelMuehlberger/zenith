import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_down_button/pull_down_button.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../services/user_service.dart';
import '../services/workout_session_service.dart';
import '../screens/exercise_info_screen.dart';
import '../constants/app_constants.dart';

class ReorderableExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final Function(String exerciseId) onAddSet;
  final Function(String exerciseId, String setId) onRemoveSet;
  final Function(String exerciseId, String setId, {int? reps, double? weight}) onUpdateSet;
  final VoidCallback? onRemoveExercise;
  final VoidCallback? onDuplicateExercise;
  final bool isBeingDragged;
  final bool isOtherCardDragging;
  final int exerciseIndex;

  const ReorderableExerciseCard({
    super.key,
    required this.exercise,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onUpdateSet,
    this.onRemoveExercise,
    this.onDuplicateExercise,
    this.isBeingDragged = false,
    this.isOtherCardDragging = false,
    required this.exerciseIndex,
  });

  @override
  State<ReorderableExerciseCard> createState() => _ReorderableExerciseCardState();
}

class _ReorderableExerciseCardState extends State<ReorderableExerciseCard>
    with TickerProviderStateMixin {
  late AnimationController _dragController;
  late Animation<double> _dragOpacityAnimation;
  late Animation<double> _dragScaleAnimation;
  final Map<String, TextEditingController> _controllers = {};
  final Set<int> _expandedNotes = {};

  @override
  void initState() {
    super.initState();
    
    _dragController = AnimationController(
      duration: AppConstants.DRAG_ANIMATION_DURATION,
      vsync: this,
    );

    _dragOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _dragController,
      curve: AppConstants.DRAG_ANIMATION_CURVE,
    ));

    _dragScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _dragController,
      curve: AppConstants.DRAG_ANIMATION_CURVE,
    ));

    // Initialize animation state
    if (widget.isOtherCardDragging) {
      _dragController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ReorderableExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isOtherCardDragging != oldWidget.isOtherCardDragging) {
      if (widget.isOtherCardDragging) {
        _dragController.forward();
      } else {
        _dragController.reverse();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _dragController.dispose();
    super.dispose();
  }

  TextEditingController _getController(String controllerKey, String textToInitializeWith) {
    if (!_controllers.containsKey(controllerKey)) {
      _controllers[controllerKey] = TextEditingController(text: textToInitializeWith);
    }
    return _controllers[controllerKey]!;
  }

  String get _weightUnit {
    return UserService.instance.currentProfile?.units == Units.imperial ? 'lbs' : 'kg';
  }

  void _toggleNotesExpansion() {
    setState(() {
      if (_expandedNotes.contains(widget.exerciseIndex)) {
        _expandedNotes.remove(widget.exerciseIndex);
      } else {
        _expandedNotes.add(widget.exerciseIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dragController,
      builder: (context, child) {
        return Transform.scale(
          scale: _dragScaleAnimation.value,
          child: Opacity(
            opacity: widget.isBeingDragged ? 0.5 : (_dragOpacityAnimation.value),
            child: Container(
              margin: const EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP),
              decoration: BoxDecoration(
                color: AppConstants.EXERCISE_CARD_BG_COLOR,
                borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
                border: Border.all(
                  color: Colors.grey[800]!.withAlpha((255 * 0.15).round()),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  _buildSetsList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exercise.exerciseDetail?.name ?? widget.exercise.exerciseSlug,
                      style: AppConstants.IOS_TITLE_TEXT_STYLE.copyWith(
                        color: AppConstants.ACCENT_COLOR,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.exercise.notes?.isNotEmpty ?? false)
                    IconButton(
                      onPressed: _toggleNotesExpansion,
                      icon: Icon(
                        _expandedNotes.contains(widget.exerciseIndex)
                          ? Icons.sticky_note_2
                          : Icons.sticky_note_2_outlined,
                        color: _expandedNotes.contains(widget.exerciseIndex)
                          ? Colors.amber
                          : Colors.grey[500],
                        size: 24,
                      ),
                      tooltip: _expandedNotes.contains(widget.exerciseIndex) ? 'Hide notes' : 'Show notes',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  const SizedBox(width: 8),
                  PullDownButton(
                    itemBuilder: (context) => [
                      PullDownMenuItem(
                        onTap: () => _showExerciseInfo(context),
                        title: 'Exercise Info',
                        icon: Icons.info_outline,
                      ),
                      if (widget.onRemoveExercise != null)
                        PullDownMenuItem(
                          onTap: widget.onRemoveExercise!,
                          title: 'Remove Exercise',
                          icon: Icons.delete_outline,
                          isDestructive: true,
                        ),
                    ],
                    buttonBuilder: (context, showMenu) => IconButton(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: showMenu,
                      icon: Icon(
                        Icons.more_horiz,
                        color: AppConstants.TEXT_SECONDARY_COLOR,
                        size: 28,
                      ),
                      tooltip: 'Exercise Options',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.ACCENT_COLOR_ORANGE.withAlpha((255 * 0.2).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.drag_handle,
                      color: AppConstants.ACCENT_COLOR_ORANGE,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_expandedNotes.contains(widget.exerciseIndex) &&
              widget.exercise.notes != null && widget.exercise.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[600]!, width: 1),
              ),
              child: Text(
                widget.exercise.notes ?? "",
                style: AppConstants.IOS_SUBTEXT_STYLE,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetsList() {
    final isBodyWeight = widget.exercise.exerciseDetail?.isBodyWeightExercise ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
            child: Row(
              children: [
                const SizedBox(width: 28), // Set number space
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Reps',
                    textAlign: TextAlign.center,
                    style: AppConstants.IOS_SUBTEXT_STYLE,
                  ),
                ),
                if (!isBodyWeight) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Weight',
                      textAlign: TextAlign.center,
                      style: AppConstants.IOS_SUBTEXT_STYLE,
                    ),
                  ),
                ],
                const SizedBox(width: 16),
                const SizedBox(width: 32), // Action button space
              ],
            ),
          ),
          // Sets
          ...widget.exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 4.0),
              child: _buildSetRow(set, setIndex + 1),
            );
          }),
          // Add set button
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                widget.onAddSet(widget.exercise.id);
                HapticFeedback.lightImpact();
              },
              style: TextButton.styleFrom(
                backgroundColor: AppConstants.ACCENT_COLOR.withAlpha((255 * 0.8).round()),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(0, 44), // iOS standard touch target
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Add Set',
                    style: AppConstants.HEADER_BUTTON_TEXT_STYLE.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(WorkoutSet set, int setNumber) {
    final isBodyWeight = widget.exercise.exerciseDetail?.isBodyWeightExercise ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Set number
          Container(
            width: 28,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                setNumber.toString(),
                style: AppConstants.IOS_NORMAL_TEXT_STYLE.copyWith(
                  color: AppConstants.TEXT_PRIMARY_COLOR,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Reps input
          Expanded(
            child: _buildSetInput(
              controllerKey: '${widget.exercise.id}_${set.id}_reps',
              initialText: (set.targetReps ?? 0) > 0 ? set.targetReps.toString() : "",
              onChanged: (value) {
                final reps = int.tryParse(value);
                widget.onUpdateSet(widget.exercise.id, set.id, reps: reps ?? (value.isEmpty ? 0 : null));
              },
            ),
          ),
          const SizedBox(width: 16),
          // Weight input (if not bodyweight)
          if (!isBodyWeight) ...[
            Expanded(
              child: _buildSetInput(
                controllerKey: '${widget.exercise.id}_${set.id}_weight',
                initialText: (set.targetWeight ?? 0.0) > 0.0 
                    ? WorkoutSessionService.instance.formatWeight(set.targetWeight!) 
                    : "",
                onChanged: (value) {
                  final weight = double.tryParse(value);
                  widget.onUpdateSet(widget.exercise.id, set.id, weight: weight ?? (value.isEmpty ? 0.0 : null));
                },
                showWeightSuffix: true,
              ),
            ),
            const SizedBox(width: 16),
          ],
          // Remove set button
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 24),
              onPressed: () {
                widget.onRemoveSet(widget.exercise.id, set.id);
                HapticFeedback.lightImpact();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetInput({
    required String controllerKey,
    required String initialText,
    required Function(String) onChanged,
    bool showWeightSuffix = false,
  }) {
    return TextField(
      controller: _getController(controllerKey, initialText),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          showWeightSuffix ? RegExp(r'^\d*\.?\d{0,2}') : RegExp(r'^\d*')
        )
      ],
      textAlign: TextAlign.center,
      style: AppConstants.IOS_TITLE_TEXT_STYLE.copyWith(
        color: AppConstants.TEXT_PRIMARY_COLOR,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[800]!.withAlpha((255 * 0.5).round()),
        suffixText: showWeightSuffix ? _weightUnit : null,
        suffixStyle: AppConstants.IOS_SUBTEXT_STYLE,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.blue.withAlpha((255 * 0.5).round()),
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: onChanged,
      onTap: () {
        if (_controllers.containsKey(controllerKey)) {
          final controller = _controllers[controllerKey]!;
          if (controller.text.isNotEmpty) {
            Future.delayed(Duration.zero, () {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            });
          }
        }
      },
    );
  }

  void _showExerciseInfo(BuildContext context) {
    if (widget.exercise.exerciseDetail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExerciseInfoScreen(
            exercise: widget.exercise.exerciseDetail!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exercise details not available for ${widget.exercise.exerciseSlug}'),
        ),
      );
    }
  }
}
