import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../constants/app_constants.dart';
import '../models/exercise.dart';
import '../screens/custom_exercise_creator_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_list_widget.dart';

class ExercisePickerScreen extends StatefulWidget {
  final bool multiSelect;

  const ExercisePickerScreen({super.key, this.multiSelect = false});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  static final Logger _logger = Logger('ExercisePickerScreen');
  final List<Exercise> _selectedExercises = [];
  int _exerciseListVersion = 0;

  void _toggleExerciseSelection(Exercise exercise) {
    setState(() {
      if (_selectedExercises.contains(exercise)) {
        _selectedExercises.remove(exercise);
        _logger.fine('Deselected exercise ${exercise.slug}');
      } else {
        _selectedExercises.add(exercise);
        _logger.fine('Selected exercise ${exercise.slug}');
      }
    });
  }

  void _selectExercise(BuildContext context, Exercise exercise) {
    if (widget.multiSelect) {
      _toggleExerciseSelection(exercise);
    } else {
      _logger.info('Picked exercise ${exercise.slug} in single-select mode');
      Navigator.of(context).pop(exercise);
    }
  }

  void _done() {
    _logger.info(
      'Completing multi-select exercise picker with ${_selectedExercises.length} exercise(s)',
    );
    Navigator.of(context).pop(_selectedExercises);
  }

  Future<void> _openCustomExerciseCreator() async {
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (context) => const CustomExerciseCreatorScreen(),
      ),
    );
    if (exercise == null || !mounted) return;

    if (widget.multiSelect) {
      setState(() {
        _exerciseListVersion++;
        if (!_selectedExercises.any(
          (selected) => selected.slug == exercise.slug,
        )) {
          _selectedExercises.add(exercise);
        }
      });
      return;
    }

    Navigator.of(context).pop(exercise);
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double screenHeaderHeight = topPadding + kToolbarHeight;
    final theme = Theme.of(context);
    final textTheme = context.appText;
    final colorScheme = context.appScheme;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ExerciseListWidget(
            key: ValueKey(_exerciseListVersion),
            onExerciseSelected: (exercise) =>
                _selectExercise(context, exercise),
            selectedExercises: widget.multiSelect ? _selectedExercises : null,
            additionalTopPadding: screenHeaderHeight,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeaderHeight,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                  sigmaY: AppConstants.GLASS_BLUR_SIGMA,
                ),
                child: Container(
                  color: colors.overlayMedium,
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: colorScheme.onSurface,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: AppConstants.BACK_BUTTON_TOOLTIP,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              AppConstants.SELECT_EXERCISE_TITLE,
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: const Key('create_custom_exercise_button'),
                                onPressed: _openCustomExerciseCreator,
                                icon: Icon(
                                  CupertinoIcons.plus,
                                  color: colorScheme.primary,
                                ),
                                tooltip: 'Create custom exercise',
                              ),
                              if (widget.multiSelect)
                                TextButton(
                                  onPressed: _done,
                                  child: Text(
                                    AppConstants.DONE_BUTTON_TEXT,
                                    style: textTheme.labelLarge,
                                  ),
                                )
                              else
                                const SizedBox(width: 8),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
