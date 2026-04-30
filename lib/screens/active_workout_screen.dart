import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/workout.dart';
import '../models/workout_template.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../services/workout_session_service.dart';
import '../services/user_service.dart';
import '../services/workout_template_service.dart';
import '../services/reorder_service.dart';
import '../widgets/active_workout/active_workout_sections.dart';
import 'exercise_picker_screen.dart';
import 'workout_completion_screen.dart';
import '../utils/navigation_helper.dart';
import '../constants/app_constants.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Workout session;

  const ActiveWorkoutScreen({super.key, required this.session});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  static final Logger _logger = Logger('ActiveWorkoutScreen');
  final Set<int> _expandedNotes = {};
  late Workout _currentSession;
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    // Use the latest active session if available, otherwise fall back to widget.session
    final activeSession = WorkoutSessionService.instance.currentSession;
    _currentSession = activeSession ?? widget.session;
    _logger.info(
      'Opening active workout session '
      'sessionId=${_currentSession.id} '
      'exercises=${_currentSession.exercises.length} '
      'source=${activeSession != null ? 'service' : 'widget'}',
    );
    ReorderService.instance.addListener(_onReorderServiceChange);
  }

  void _onReorderServiceChange() {
    if (mounted) {
      _logger.fine(
        'Reorder service updated: isReorderMode=${ReorderService.instance.isReorderMode}',
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _logger.fine(
      'Disposing active workout screen for session ${_currentSession.id}',
    );
    ReorderService.instance.removeListener(_onReorderServiceChange);
    if (ReorderService.instance.isReorderMode) {
      ReorderService.instance.toggleReorderMode();
    }
    super.dispose();
  }

  void _toggleNotesExpansion(int exerciseIndex) {
    setState(() {
      if (_expandedNotes.contains(exerciseIndex)) {
        _expandedNotes.remove(exerciseIndex);
        _logger.finer('Collapsed notes for exercise index $exerciseIndex');
      } else {
        _expandedNotes.add(exerciseIndex);
        _logger.finer('Expanded notes for exercise index $exerciseIndex');
      }
    });
  }

  void _toggleReorderMode() {
    _logger.info(
      'Toggling reorder mode for session ${_currentSession.id}: '
      'current=${ReorderService.instance.isReorderMode}',
    );
    ReorderService.instance.toggleReorderMode();
  }

  @override
  Widget build(BuildContext context) {
    final String weightUnit =
        (UserService.instance.currentProfile?.units == Units.imperial)
        ? 'lbs'
        : 'kg';

    return Scaffold(
      backgroundColor: Colors.black,
      body: ActiveWorkoutScaffoldBody(
        session: _currentSession,
        expandedNotes: _expandedNotes,
        draggingIndex: _draggingIndex,
        weightUnit: weightUnit,
        onToggleNotes: _toggleNotesExpansion,
        onUpdateSet: _updateSet,
        onToggleSetCompletion: _toggleSetCompletion,
        onAddSet: _addSet,
        onRemoveSet: _removeSet,
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
        onToggleReorderMode: _toggleReorderMode,
        onFinishWorkout: _showFinishWorkoutDialog,
        onAddExercise: _addExercise,
        onAbortWorkout: _showAbortWorkoutDialog,
      ),
    );
  }

  void _updateSet(
    String exerciseId,
    String setId, {
    int? reps,
    double? weight,
    bool? isCompleted,
  }) async {
    _logger.fine(
      'Updating set $setId for exercise $exerciseId '
      'reps=$reps weight=$weight isCompleted=$isCompleted',
    );
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
    _logger.fine('Toggling completion for set $setId in exercise $exerciseId');
    await WorkoutSessionService.instance.toggleSetCompletion(exerciseId, setId);
    final updatedSession = WorkoutSessionService.instance.currentSession;
    if (updatedSession != null && mounted) {
      setState(() => _currentSession = updatedSession);
    }
  }

  void _addSet(String exerciseId) async {
    final exerciseIndex = _currentSession.exercises.indexWhere(
      (e) => e.id == exerciseId,
    );
    if (exerciseIndex == -1) {
      _logger.warning('Cannot add set. Exercise $exerciseId was not found');
      return;
    }

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
    final updatedExercises = List<WorkoutExercise>.from(
      _currentSession.exercises,
    )..[exerciseIndex] = updatedExercise;
    final updatedSession = _currentSession.copyWith(
      exercises: updatedExercises,
    );

    _logger.info(
      'Adding set to exercise $exerciseId. '
      'newSetIndex=${newSet.setIndex} totalSets=${updatedSets.length}',
    );
    await WorkoutSessionService.instance.updateSession(updatedSession);
    if (mounted) {
      setState(() => _currentSession = updatedSession);
    }
  }

  void _removeSet(String exerciseId, String setId) async {
    final exerciseIndex = _currentSession.exercises.indexWhere(
      (e) => e.id == exerciseId,
    );
    if (exerciseIndex == -1) {
      _logger.warning('Cannot remove set. Exercise $exerciseId was not found');
      return;
    }

    final exercise = _currentSession.exercises[exerciseIndex];

    // If this is the last set, remove the entire exercise instead
    if (exercise.sets.length <= 1) {
      _logger.info(
        'Removing last set $setId from exercise $exerciseId; exercise will be removed',
      );
      final updatedExercises = List<WorkoutExercise>.from(
        _currentSession.exercises,
      )..removeAt(exerciseIndex);
      final updatedSession = _currentSession.copyWith(
        exercises: updatedExercises,
      );

      await WorkoutSessionService.instance.updateSession(updatedSession);
      if (mounted) {
        setState(() => _currentSession = updatedSession);
      }
      return;
    }

    // Remove the specific set
    _logger.info('Removing set $setId from exercise $exerciseId');
    final updatedSets = List<WorkoutSet>.from(exercise.sets)
      ..removeWhere((s) => s.id == setId);
    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedExercises = List<WorkoutExercise>.from(
      _currentSession.exercises,
    )..[exerciseIndex] = updatedExercise;
    final updatedSession = _currentSession.copyWith(
      exercises: updatedExercises,
    );

    await WorkoutSessionService.instance.updateSession(updatedSession);
    if (mounted) {
      setState(() => _currentSession = updatedSession);
    }
  }

  void _onReorderExercises(int oldIndex, int newIndex) async {
    _logger.info(
      'Reordering exercises in session ${_currentSession.id}: '
      'oldIndex=$oldIndex newIndex=$newIndex',
    );
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
    _logger.info('Opening exercise picker for session ${_currentSession.id}');
    final selectedExercises = await Navigator.push<List<Exercise>>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExercisePickerScreen(multiSelect: true),
      ),
    );

    if (selectedExercises != null && selectedExercises.isNotEmpty) {
      _logger.info(
        'Adding ${selectedExercises.length} exercise(s) to session ${_currentSession.id}',
      );
      final newWorkoutExercises = selectedExercises.map((selectedExercise) {
        final newWorkoutExerciseId =
            "${DateTime.now().millisecondsSinceEpoch}_${selectedExercise.slug}_wex";

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

      final updatedExercises = List<WorkoutExercise>.from(
        _currentSession.exercises,
      )..addAll(newWorkoutExercises);
      final updatedSession = _currentSession.copyWith(
        exercises: updatedExercises,
      );

      await WorkoutSessionService.instance.updateSession(updatedSession);
      if (mounted) {
        setState(() => _currentSession = updatedSession);
      }
    } else {
      _logger.fine('Exercise picker closed without selecting exercises');
    }
  }

  void _showFinishWorkoutDialog() {
    _logger.fine(
      'Showing finish workout dialog for session ${_currentSession.id}',
    );
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Finish Workout'),
        content: const Text('Are you sure you want to finish this workout?'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
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
    _logger.warning(
      'Showing abort workout dialog for session ${_currentSession.id}',
    );
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Abort Workout'),
        content: const Text('Are you sure? All progress will be lost.'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Abort'),
            onPressed: () async {
              Navigator.pop(context);
              _logger.warning(
                'Aborting active workout session ${_currentSession.id}',
              );
              await WorkoutSessionService.instance.clearActiveSession(
                deleteFromDb: true,
              );
              if (mounted) {
                // Navigate back to home and clear the entire navigation stack
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
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
    _logger.info('Preparing to finish workout session ${_currentSession.id}');
    WorkoutTemplate? originalTemplate;

    if (_currentSession.templateId != null) {
      _logger.fine(
        'Loading source template ${_currentSession.templateId} before finish',
      );
      originalTemplate = await WorkoutTemplateService.instance
          .getWorkoutTemplateById(_currentSession.templateId!);
    }

    if (originalTemplate == null) {
      _logger.fine(
        'No source template found. Proceeding directly to completion',
      );
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
    if (!mounted) {
      _logger.fine('Skipping finish workout because widget is unmounted');
      return;
    }

    _logger.info(
      'Navigating to workout completion for session ${_currentSession.id}',
    );
    if (ReorderService.instance.isReorderMode) {
      ReorderService.instance.toggleReorderMode();
    }
    if (!mounted) {
      _logger.fine(
        'Skipping workout completion navigation after reorder cleanup',
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutCompletionScreen(session: _currentSession),
      ),
    );

    _logger.fine(
      'Returned from workout completion flow for session ${_currentSession.id}',
    );
  }
}
