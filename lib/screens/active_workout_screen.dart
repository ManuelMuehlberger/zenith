import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';

import '../models/workout.dart';
import '../models/workout_template.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../services/workout_session_service.dart';
import '../services/user_service.dart';
import '../services/workout_template_service.dart';
import '../services/reorder_service.dart';
import '../widgets/active_workout_app_bar.dart';
import '../widgets/reorderable_active_exercise_card.dart';
import '../widgets/active_workout_action_buttons.dart';
import 'exercise_picker_screen.dart';
import 'workout_completion_screen.dart';
import '../utils/navigation_helper.dart';
import '../constants/app_constants.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Workout session;

  const ActiveWorkoutScreen({
    super.key,
    required this.session,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  Timer? _timer;
  final Set<int> _expandedNotes = {};
  late Workout _currentSession;
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    // Use the latest active session if available, otherwise fall back to widget.session
    final activeSession = WorkoutSessionService.instance.currentSession;
    _currentSession = activeSession ?? widget.session;
    _startTimer();
    ReorderService.instance.addListener(_onReorderServiceChange);
  }
  
  void _onReorderServiceChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    ReorderService.instance.removeListener(_onReorderServiceChange);
    if (ReorderService.instance.isReorderMode) {
      ReorderService.instance.toggleReorderMode();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _toggleNotesExpansion(int exerciseIndex) {
    setState(() {
      if (_expandedNotes.contains(exerciseIndex)) {
        _expandedNotes.remove(exerciseIndex);
      } else {
        _expandedNotes.add(exerciseIndex);
      }
    });
  }

  void _toggleReorderMode() {
    ReorderService.instance.toggleReorderMode();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = topPadding + ActiveWorkoutAppBar.getContentHeight();
    final String weightUnit = (UserService.instance.currentProfile?.units == Units.imperial) ? 'lbs' : 'kg';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content - allow scrolling behind header
          Positioned.fill(
            child: _buildUnifiedExercisesList(headerHeight, weightUnit),
          ),
          // Glass header overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
                child: Container(
                  height: headerHeight,
                  color: AppConstants.HEADER_BG_COLOR_MEDIUM,
                  child: SafeArea(
                    bottom: false,
                    child: _buildHeaderContent(weightUnit),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent(String weightUnit) {
    final totalSets = _currentSession.totalSets;
    final progress = totalSets > 0 ? _currentSession.completedSets / totalSets : 0.0;
    final isCompleted = progress >= 1.0;
    final duration = _currentSession.completedAt != null
        ? _currentSession.completedAt!.difference(_currentSession.startedAt ?? DateTime.now())
        : DateTime.now().difference(_currentSession.startedAt ?? DateTime.now());
    final workoutColor = _currentSession.color;
    final mutedWorkoutColor = workoutColor.withAlpha((255 * 0.15).round());
    final semiTransparentWorkoutColor = workoutColor.withAlpha((255 * 0.6).round());

    return Column(
      children: [
        // Top row
        SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                // Workout icon container
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: mutedWorkoutColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: workoutColor.withAlpha((255 * 0.3).round()),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    _currentSession.icon,
                    color: workoutColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentSession.name,
                    style: AppConstants.HEADER_TITLE_TEXT_STYLE,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        _toggleReorderMode();
                        HapticFeedback.lightImpact();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: AppConstants.WORKOUT_BUTTON_BG_COLOR,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(
                            color: ReorderService.instance.isReorderMode
                                ? workoutColor.withAlpha((255 * 0.3).round())
                                : AppConstants.TEXT_TERTIARY_COLOR.withAlpha((255 * 0.3).round()),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(32, 32),
                      ),
                      icon: Icon(
                        Icons.reorder,
                        color: ReorderService.instance.isReorderMode ? workoutColor : AppConstants.TEXT_TERTIARY_COLOR,
                        size: 22,
                      ),
                      tooltip: ReorderService.instance.isReorderMode ? 'Exit reorder mode' : 'Reorder exercises',
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _showFinishWorkoutDialog,
                      style: TextButton.styleFrom(
                        backgroundColor: isCompleted ? AppConstants.ACCENT_COLOR_GREEN : AppConstants.FINISH_BUTTON_BG_COLOR,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: isCompleted
                              ? BorderSide.none
                              : BorderSide(
                                  color: AppConstants.ACCENT_COLOR_GREEN.withAlpha((255 * 0.3).round()),
                                  width: 1,
                                ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        'Finish',
                        style: AppConstants.HEADER_BUTTON_TEXT_STYLE.copyWith(
                          color: isCompleted ? Colors.white : AppConstants.ACCENT_COLOR_GREEN,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Stats and progress row
        SizedBox(
          height: 36.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildInlineStatCard(
                  WorkoutSessionService.instance.formatDuration(duration),
                  Icons.timer_outlined,
                  workoutColor,
                ),
                Container(
                  width: 1, height: 20, color: AppConstants.DIVIDER_COLOR,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                _buildInlineStatCard(
                  '${_currentSession.completedSets}/${_currentSession.totalSets}',
                  Icons.fitness_center_outlined,
                  workoutColor,
                ),
                Container(
                  width: 1, height: 20, color: AppConstants.DIVIDER_COLOR,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                _buildInlineStatCard(
                  '${WorkoutSessionService.instance.formatWeight(_currentSession.totalWeight)}$weightUnit',
                  Icons.monitor_weight_outlined,
                  workoutColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppConstants.DIVIDER_COLOR,
                      valueColor: AlwaysStoppedAnimation<Color>(semiTransparentWorkoutColor),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: AppConstants.IOS_SUBTITLE_FONT_SIZE,
                    fontWeight: FontWeight.bold,
                    color: semiTransparentWorkoutColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineStatCard(String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppConstants.IOS_SUBTITLE_TEXT_STYLE.copyWith(
            fontWeight: FontWeight.bold,
            color: AppConstants.TEXT_PRIMARY_COLOR,
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedExercisesList(double headerHeight, String weightUnit) {
    final isReorderMode = ReorderService.instance.isReorderMode;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: headerHeight)),
        SliverReorderableList(
          itemBuilder: (context, index) {
            final exercise = _currentSession.exercises[index];
            final isDragging = _draggingIndex == index;
            final isOtherDragging = _draggingIndex != null && _draggingIndex != index;

            return ReorderableDelayedDragStartListener(
              key: ValueKey(exercise.id),
              index: index,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
                child: ReorderableActiveExerciseCard(
                  exercise: exercise,
                  weightUnit: weightUnit,
                  expandedNotes: _expandedNotes,
                  exerciseIndex: index,
                  isReorderMode: isReorderMode,
                  isDragging: isDragging,
                  isOtherDragging: isOtherDragging,
                  onToggleNotes: _toggleNotesExpansion,
                  onUpdateSet: _updateSet,
                  onToggleSetCompletion: _toggleSetCompletion,
                  onAddSet: () => _addSet(exercise.id),
                  onRemoveSet: (setId) => _removeSet(exercise.id, setId),
                  workoutColor: _currentSession.color,
                  workoutStartedAt: _currentSession.startedAt,
                ),
              ),
            );
          },
          itemCount: _currentSession.exercises.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              _draggingIndex = null;
            });
            _onReorderExercises(oldIndex, newIndex);
          },
          onReorderStart: (index) {
            setState(() {
              _draggingIndex = index;
            });
          },
          onReorderEnd: (index) {
            setState(() {
              _draggingIndex = null;
            });
          },
          proxyDecorator: (child, index, animation) {
            final exercise = _currentSession.exercises[index];
            final proxyCard = ReorderableActiveExerciseCard(
              key: ValueKey('proxy_${exercise.id}'),
              exercise: exercise,
              weightUnit: weightUnit,
              expandedNotes: _expandedNotes,
              exerciseIndex: index,
              isReorderMode: true,
              isDragging: true,
              isOtherDragging: false,
              onToggleNotes: (_) {},
              onUpdateSet: (_, __, {reps, weight, isCompleted}) {},
              onToggleSetCompletion: (_, __) {},
              onAddSet: () {},
              onRemoveSet: (_) {},
              workoutColor: _currentSession.color,
              workoutStartedAt: _currentSession.startedAt,
            );

            return Material(
              color: Colors.transparent,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final double animValue = Curves.easeInOut.transform(animation.value);
                  final double scale = lerpDouble(1, 1.05, animValue)!;
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: proxyCard,
              ),
            );
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: ActiveWorkoutActionButtons(
              onAddExercise: _addExercise,
              onAbortWorkout: _showAbortWorkoutDialog,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: bottomPadding + 40),
        ),
      ],
    );
  }

  void _updateSet(String exerciseId, String setId, {int? reps, double? weight, bool? isCompleted}) async {
    await WorkoutSessionService.instance.updateSet(
      exerciseId,
      setId,
      actualReps: reps,
      actualWeight: weight,
      isCompleted: isCompleted,
    );
    final updatedSession = WorkoutSessionService.instance.currentSession;
    if (updatedSession != null && mounted) {
      setState(() => _currentSession = updatedSession);
    }
  }

  void _toggleSetCompletion(String exerciseId, String setId) async {
    await WorkoutSessionService.instance.toggleSetCompletion(exerciseId, setId);
    final updatedSession = WorkoutSessionService.instance.currentSession;
    if (updatedSession != null && mounted) {
      setState(() => _currentSession = updatedSession);
    }
  }

  void _addSet(String exerciseId) async {
    final exerciseIndex = _currentSession.exercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIndex == -1) return;

    final exercise = _currentSession.exercises[exerciseIndex];
    final lastSet = exercise.sets.isNotEmpty ? exercise.sets.last : null;
    final newSet = WorkoutSet(
      workoutExerciseId: exerciseId,
      setIndex: exercise.sets.length,
      actualReps: lastSet?.actualReps ?? 10,
      actualWeight: lastSet?.actualWeight ?? 0.0,
      isCompleted: false,
    );

    final updatedSets = List<WorkoutSet>.from(exercise.sets)..add(newSet);
    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedExercises = List<WorkoutExercise>.from(_currentSession.exercises)
      ..[exerciseIndex] = updatedExercise;
    final updatedSession = _currentSession.copyWith(exercises: updatedExercises);

    await WorkoutSessionService.instance.updateSession(updatedSession);
    if (mounted) {
      setState(() => _currentSession = updatedSession);
    }
  }

  void _removeSet(String exerciseId, String setId) async {
    final exerciseIndex = _currentSession.exercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIndex == -1) return;

    final exercise = _currentSession.exercises[exerciseIndex];
    
    // If this is the last set, remove the entire exercise instead
    if (exercise.sets.length <= 1) {
      final updatedExercises = List<WorkoutExercise>.from(_currentSession.exercises)
        ..removeAt(exerciseIndex);
      final updatedSession = _currentSession.copyWith(exercises: updatedExercises);

      await WorkoutSessionService.instance.updateSession(updatedSession);
      if (mounted) {
        setState(() => _currentSession = updatedSession);
      }
      return;
    }

    // Remove the specific set
    final updatedSets = List<WorkoutSet>.from(exercise.sets)..removeWhere((s) => s.id == setId);
    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedExercises = List<WorkoutExercise>.from(_currentSession.exercises)
      ..[exerciseIndex] = updatedExercise;
    final updatedSession = _currentSession.copyWith(exercises: updatedExercises);

    await WorkoutSessionService.instance.updateSession(updatedSession);
    if (mounted) {
      setState(() => _currentSession = updatedSession);
    }
  }

  void _onReorderExercises(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final exercises = List<WorkoutExercise>.from(_currentSession.exercises);
    final exercise = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, exercise);

    final updatedSession = _currentSession.copyWith(exercises: exercises);
    await WorkoutSessionService.instance.updateSession(updatedSession);

    if (mounted) {
      setState(() {
        _currentSession = updatedSession;
      });
    }
  }

  void _addExercise() async {
    final selectedExercises = await Navigator.push<List<Exercise>>(
      context,
      MaterialPageRoute(builder: (context) => const ExercisePickerScreen(multiSelect: true)),
    );

    if (selectedExercises != null && selectedExercises.isNotEmpty) {
      final newWorkoutExercises = selectedExercises.map((selectedExercise) {
        final newWorkoutExerciseId = "${DateTime.now().millisecondsSinceEpoch}_${selectedExercise.slug}_wex";
        
        final templateSet = WorkoutSet(
          workoutExerciseId: newWorkoutExerciseId,
          setIndex: 0,
          targetReps: 10,
          targetWeight: 0.0,
        );

        return WorkoutExercise(
          id: newWorkoutExerciseId,
          workoutId: _currentSession.id,
          exerciseSlug: selectedExercise.slug,
          exerciseDetail: selectedExercise,
          sets: [templateSet],
          notes: '',
        );
      }).toList();
      
      final updatedExercises = List<WorkoutExercise>.from(_currentSession.exercises)..addAll(newWorkoutExercises);
      final updatedSession = _currentSession.copyWith(exercises: updatedExercises);
      
      await WorkoutSessionService.instance.updateSession(updatedSession);
      if (mounted) {
        setState(() => _currentSession = updatedSession);
      }
    }
  }

  void _showFinishWorkoutDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Finish Workout'),
        content: const Text('Are you sure you want to finish this workout?'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Finish'),
            onPressed: () {
              Navigator.pop(context);
              if (mounted) _checkForRoutineUpdatesAndFinish();
            },
          ),
        ],
      ),
    );
  }

  void _showAbortWorkoutDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Abort Workout'),
        content: const Text('Are you sure? All progress will be lost.'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Abort'),
            onPressed: () async {
              Navigator.pop(context);
              await WorkoutSessionService.instance.clearActiveSession(deleteFromDb: true);
              if (mounted) {
                // Navigate back to home and clear the entire navigation stack
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                // Ensure we go to the home tab
                NavigationHelper.goToHomeTab();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _checkForRoutineUpdatesAndFinish() async {
    WorkoutTemplate? originalTemplate;
    
    if (_currentSession.templateId != null) {
      originalTemplate = await WorkoutTemplateService.instance.getWorkoutTemplateById(_currentSession.templateId!);
    }
    
    if (originalTemplate == null) {
      _finishWorkout();
      return;
    }
    
    // TODO: Implement template comparison logic
    // This would require loading the template's exercises from WorkoutExerciseDao
    // and comparing them with the current session's exercises
    // For now, we'll just finish the workout without the update dialog
    _finishWorkout();
  }

  void _finishWorkout() async {
    if (!mounted) return;
    if (ReorderService.instance.isReorderMode) {
      ReorderService.instance.toggleReorderMode();
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WorkoutCompletionScreen(session: _currentSession)),
    );
  }
}
