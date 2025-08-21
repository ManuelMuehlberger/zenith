import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';

import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../services/workout_session_service.dart';
import '../services/user_service.dart';
import '../services/workout_service.dart';
import '../services/reorder_service.dart';
import '../widgets/active_workout_app_bar.dart';
import '../widgets/active_exercise_card.dart';
import '../widgets/modular_reorderable_exercise_card.dart';
import '../widgets/custom_reorderable_exercise_list.dart';
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
            child: _buildExercisesList(headerHeight, weightUnit),
          ),
          // Glass header overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  height: headerHeight,
                  color: Colors.black54,
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
    final progress = _currentSession.completedSets / _currentSession.totalSets;
    final duration = _currentSession.completedAt != null 
        ? _currentSession.completedAt!.difference(_currentSession.startedAt ?? DateTime.now()) 
        : DateTime.now().difference(_currentSession.startedAt ?? DateTime.now());
    
    return Column(
      children: [
        // Top row
        SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _currentSession.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
                        backgroundColor: const Color(0xFF222222),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(
                            color: ReorderService.instance.isReorderMode
                                ? Colors.orange.withAlpha((255 * 0.3).round())
                                : Colors.grey.withAlpha((255 * 0.3).round()),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(32, 32),
                      ),
                      icon: Icon(
                        Icons.reorder,
                        color: ReorderService.instance.isReorderMode ? Colors.orange : Colors.grey[400],
                        size: 22,
                      ),
                      tooltip: ReorderService.instance.isReorderMode ? 'Exit reorder mode' : 'Reorder exercises',
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _showFinishWorkoutDialog,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 10, 18, 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(
                            color: Colors.green.withAlpha((255 * 0.3).round()),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Finish',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
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
                ),
                Container(
                  width: 1, height: 20, color: Colors.grey[800],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                _buildInlineStatCard(
                  '${_currentSession.completedSets}/${_currentSession.totalSets}',
                  Icons.fitness_center_outlined,
                ),
                Container(
                  width: 1, height: 20, color: Colors.grey[800],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                _buildInlineStatCard(
                  '${WorkoutSessionService.instance.formatWeight(_currentSession.totalWeight)}$weightUnit',
                  Icons.monitor_weight_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      minHeight: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineStatCard(String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blue, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildExercisesList(double headerHeight, String weightUnit) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: ReorderService.instance.isReorderMode
          ? _buildReorderModeList(headerHeight, weightUnit)
          : _buildNormalModeList(headerHeight, weightUnit),
    );
  }

  Widget _buildReorderModeList(double headerHeight, String weightUnit) {
    return Column(
      key: const ValueKey('reorder_mode'),
      children: [
        // Space for header
        SizedBox(height: headerHeight),
        // Reorder mode indicator
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            final clampedValue = value.clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, -20 * (1 - clampedValue)),
              child: Opacity(
                opacity: clampedValue,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withAlpha((255 * 0.3).round()), width: 1),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                  child: Text('Drag exercises to reorder them',
                      style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
        Expanded(
          child: CustomReorderableExerciseList(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            exercises: _currentSession.exercises,
            onReorder: _onReorderExercises,
            workoutId: _currentSession.id,
            itemExtent: 180.0,
            itemBuilder: (context, index, isDragging, draggingIndex) {
              final exercise = _currentSession.exercises[index];
              return ModularReorderableExerciseCard(
                key: ValueKey(exercise.id),
                exercise: exercise,
                itemIndex: index,
                onAddSet: _addSet,
                onRemoveSet: _removeSet,
                weightUnit: weightUnit,
                isDragging: isDragging,
                draggingIndex: draggingIndex,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: ActiveWorkoutActionButtons(
            onAddExercise: _addExercise,
            onAbortWorkout: _showAbortWorkoutDialog,
            showAbortButton: false,
          ),
        ),
      ],
    );
  }

  Widget _buildNormalModeList(double headerHeight, String weightUnit) {
    return CustomScrollView(
      key: const ValueKey('normal_mode'),
      slivers: [
        // Space for header
        SliverToBoxAdapter(
          child: SizedBox(height: headerHeight),
        ),
        // Exercise list
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == _currentSession.exercises.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: ActiveWorkoutActionButtons(
                    onAddExercise: _addExercise,
                    onAbortWorkout: _showAbortWorkoutDialog,
                    showAbortButton: true,
                  ),
                );
              }
              final exercise = _currentSession.exercises[index];
              return Container(
                margin: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
                child: ActiveExerciseCard(
                  exercise: exercise,
                  weightUnit: weightUnit,
                  expandedNotes: _expandedNotes,
                  exerciseIndex: index,
                  onToggleNotes: _toggleNotesExpansion,
                  onUpdateSet: _updateSet,
                  onToggleSetCompletion: _toggleSetCompletion,
                ),
              );
            },
            childCount: _currentSession.exercises.length + 1,
          ),
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
    final selectedExercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(builder: (context) => const ExercisePickerScreen()),
    );

    if (selectedExercise != null) {
      final newWorkoutExerciseId = DateTime.now().millisecondsSinceEpoch.toString() + "_wex";

      // Create the WorkoutSet template first (though it's immediately wrapped)
      // This part is a bit convoluted due to how SessionSet.fromWorkoutSet works with old fields.
      // Ideally, WorkoutSet for template would be simpler.
      final templateSet = WorkoutSet(
        workoutExerciseId: newWorkoutExerciseId, // Link to the WorkoutExercise being created
        setIndex: 0,
        targetReps: 10,
        targetWeight: 0.0,
      );

      final workoutExercise = WorkoutExercise(
        id: newWorkoutExerciseId,
        workoutId: _currentSession.id, // Link to the parent workout
        exerciseSlug: selectedExercise.slug,
        exerciseDetail: selectedExercise, // Keep for in-memory model if needed
        sets: [templateSet], // The template WorkoutExercise holds template WorkoutSets
        notes: '',
      );
      
      final updatedExercises = List<WorkoutExercise>.from(_currentSession.exercises)..add(workoutExercise);
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
              await WorkoutSessionService.instance.clearActiveSession();
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
    final originalWorkout = _currentSession.templateId != null 
        ? WorkoutService.instance.getWorkoutById(_currentSession.templateId!) 
        : _currentSession;
    
    if (originalWorkout == null) {
      _finishWorkout();
      return;
    }
    
    final sessionExercises = _currentSession.exercises;
    bool hasChanges = sessionExercises.length != originalWorkout.exercises.length;

    if (!hasChanges) {
      for (int i = 0; i < sessionExercises.length; i++) {
        final sEx = sessionExercises[i];
        final oEx = originalWorkout.exercises[i]; // oEx is WorkoutExercise
        // Compare based on exerciseSlug
        if (sEx.exerciseSlug != oEx.exerciseSlug || sEx.sets.length != oEx.sets.length) {
          hasChanges = true;
          break;
        }
        // Further check if sets are different (e.g. reps, weight)
        for (int j = 0; j < sEx.sets.length; j++) {
          final sSet = sEx.sets[j]; // WorkoutSet
          final oSet = oEx.sets[j]; // WorkoutSet (template)
          if (sSet.actualReps != oSet.targetReps || sSet.actualWeight != oSet.targetWeight) {
            hasChanges = true;
            break;
          }
        }
        if (hasChanges) break;
      }
    }
    if (!mounted) return;
    if (hasChanges) {
      _showUpdateRoutineDialog();
    } else {
      _finishWorkout();
    }
  }

  void _showUpdateRoutineDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Update Routine?'),
        content: const Text('Changes detected. Update the original routine?'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('No, Keep Original'),
            onPressed: () {
              Navigator.of(context).pop();
              _finishWorkout();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Yes, Update Routine'),
            onPressed: () {
              Navigator.of(context).pop();
              _updateRoutineAndFinish();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateRoutineAndFinish() async {
    try {
      final updatedWorkoutExercises = _currentSession.exercises.map((sEx) { // sEx is WorkoutExercise
        // Find the original WorkoutExercise template
        final originalWorkoutExerciseTemplate = _currentSession.exercises
            .firstWhere((oEx) => oEx.exerciseSlug == sEx.exerciseSlug, orElse: () => sEx);
        
        final updatedTemplateSets = sEx.sets.asMap().entries.map((entry) { // sEx.sets are WorkoutSet
          int idx = entry.key;
          WorkoutSet sessionSet = entry.value;
          
          // Create a new WorkoutSet (template set) based on the WorkoutSet's performed values
          return WorkoutSet(
            workoutExerciseId: originalWorkoutExerciseTemplate.id, // Link to parent WorkoutExercise template
            setIndex: idx,
            targetReps: sessionSet.actualReps, // Use performed reps as new target
            targetWeight: sessionSet.actualWeight, // Use performed weight as new target
            // targetRestSeconds could be copied if they existed on WorkoutSet or set to defaults
          );
        }).toList();
        // Return a new WorkoutExercise template with updated sets
        return originalWorkoutExerciseTemplate.copyWith(sets: updatedTemplateSets);
      }).toList();

      final updatedWorkout = _currentSession.copyWith(exercises: updatedWorkoutExercises);
      await WorkoutService.instance.updateWorkout(updatedWorkout);
    } catch (e) {
      // Log error or show a message
    } finally {
      if (!mounted) return;
      _finishWorkout();
    }
  }

  void _finishWorkout() async {
    if (!mounted) return;
    if (ReorderService.instance.isReorderMode) {
      ReorderService.instance.toggleReorderMode();
    }
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WorkoutCompletionScreen(session: _currentSession)),
    );
  }
}
