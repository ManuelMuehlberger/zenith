import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/exercise.dart';
import '../widgets/exercise_list_widget.dart';
import '../constants/app_constants.dart';

class ExercisePickerScreen extends StatefulWidget {
  final bool multiSelect;

  const ExercisePickerScreen({super.key, this.multiSelect = false});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  final List<Exercise> _selectedExercises = [];

  void _toggleExerciseSelection(Exercise exercise) {
    setState(() {
      if (_selectedExercises.contains(exercise)) {
        _selectedExercises.remove(exercise);
      } else {
        _selectedExercises.add(exercise);
      }
    });
  }

  void _selectExercise(BuildContext context, Exercise exercise) {
    if (widget.multiSelect) {
      _toggleExerciseSelection(exercise);
    } else {
      Navigator.of(context).pop(exercise);
    }
  }

  void _done() {
    Navigator.of(context).pop(_selectedExercises);
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double screenHeaderHeight = topPadding + kToolbarHeight;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ExerciseListWidget(
            onExerciseSelected: (exercise) => _selectExercise(context, exercise),
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
                filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
                child: Container(
                  color: AppConstants.HEADER_BG_COLOR_MEDIUM,
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, color: AppConstants.HEADER_TITLE_COLOR),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: AppConstants.BACK_BUTTON_TOOLTIP,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              AppConstants.SELECT_EXERCISE_TITLE,
                              textAlign: TextAlign.center,
                              style: AppConstants.HEADER_SMALL_TITLE_TEXT_STYLE,
                            ),
                          ),
                          if (widget.multiSelect)
                            TextButton(
                              onPressed: _done,
                              child: Text(
                                AppConstants.DONE_BUTTON_TEXT,
                                style: AppConstants.HEADER_BUTTON_TEXT_STYLE,
                              ),
                            )
                          else
                            const SizedBox(width: 56),
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
