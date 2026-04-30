import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  final Set<int> _expandedNotes = {};
  late Workout _currentSession;
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    // Use the latest active session if available, otherwise fall back to widget.session
    final activeSession = WorkoutSessionService.instance.currentSession;
    _currentSession = activeSession ?? widget.session;
    ReorderService.instance.addListener(_onReorderServiceChange);
  }

  void _onReorderServiceChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
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
    final exerciseIndex = _currentSession.exercises.indexWhere(
      (e) => e.id == exerciseId,
    );
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

  void _removeSet(String exerciseId, String setId) async {
    final exerciseIndex = _currentSession.exercises.indexWhere(
      (e) => e.id == exerciseId,
    );
    if (exerciseIndex == -1) return;

    final exercise = _currentSession.exercises[exerciseIndex];

    // If this is the last set, remove the entire exercise instead
    if (exercise.sets.length <= 1) {
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
      MaterialPageRoute(
        builder: (context) => const ExercisePickerScreen(multiSelect: true),
      ),
    );

    if (selectedExercises != null && selectedExercises.isNotEmpty) {
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
    }
  }

  void _showFinishWorkoutDialog() {
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
    WorkoutTemplate? originalTemplate;

    if (_currentSession.templateId != null) {
      originalTemplate = await WorkoutTemplateService.instance
          .getWorkoutTemplateById(_currentSession.templateId!);
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
      MaterialPageRoute(
        builder: (context) => WorkoutCompletionScreen(session: _currentSession),
      ),
    );
  }
}
