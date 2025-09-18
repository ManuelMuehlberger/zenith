import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/exercise.dart';
import '../widgets/exercise_list_widget.dart';
import 'exercise_info_screen.dart';
import '../constants/app_constants.dart';

class ExerciseBrowserScreen extends StatelessWidget {
  const ExerciseBrowserScreen({super.key});

  void _showExerciseInfo(BuildContext context, Exercise exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseInfoScreen(exercise: exercise),
      ),
    );
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
            onExerciseSelected: (exercise) => _showExerciseInfo(context, exercise),
            additionalTopPadding: screenHeaderHeight,
          ),
          
          // Custom glass "Exercise Statistics" header overlay
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
                              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: 'Back',
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Exercise Statistics',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 56), // Balance the IconButton
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
