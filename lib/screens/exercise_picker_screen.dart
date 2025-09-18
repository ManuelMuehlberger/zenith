import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/exercise.dart';
import '../widgets/exercise_list_widget.dart';
import '../constants/app_constants.dart';

class ExercisePickerScreen extends StatelessWidget {
  const ExercisePickerScreen({super.key});

  void _selectExercise(BuildContext context, Exercise exercise) {
    Navigator.of(context).pop(exercise);
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double screenHeaderHeight = topPadding + kToolbarHeight; // Height of the "Select Exercise" header

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand, 
        children: [
          // Main content: ExerciseListWidget
          // It's placed directly in the Stack.
          // Its internal ListView will be padded by screenHeaderHeight (for the "Select Exercise" bar)
          // PLUS its own internalHeaderHeight (for its search/filter bars).
          ExerciseListWidget(
            onExerciseSelected: (exercise) => _selectExercise(context, exercise),
            additionalTopPadding: screenHeaderHeight, // Pass the height of the screen's custom header
          ),
          
          // Custom glass "Select Exercise" header overlay
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
                          Expanded( // Removed const
                            child: Text(
                              'Select Exercise',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 56), // This can remain const
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
