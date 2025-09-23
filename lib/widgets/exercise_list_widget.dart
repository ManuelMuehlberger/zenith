import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../constants/app_constants.dart';

class ExerciseListWidget extends StatefulWidget {
  final Function(Exercise) onExerciseSelected;
  final String? title;
  final Widget? trailing;
  final double additionalTopPadding;

  const ExerciseListWidget({
    super.key,
    required this.onExerciseSelected,
    this.title,
    this.trailing,
    this.additionalTopPadding = 0.0,
  });

  @override
  State<ExerciseListWidget> createState() => _ExerciseListWidgetState();
}

class _ExerciseListWidgetState extends State<ExerciseListWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMuscleGroup = '';
  List<Exercise> _filteredExercises = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_filterExercises);
  }

  Future<void> _loadExercises() async {
    await ExerciseService.instance.loadExercises();
    setState(() {
      _filteredExercises = ExerciseService.instance.exercises;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildMuscleGroupChip(BuildContext context, String muscleGroup, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.blue.withAlpha((255 * 0.2).round()) : Colors.grey[800],
        border: Border.all(
          color: isPrimary ? Colors.blue : Colors.grey[600]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        muscleGroup,
        style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
              color: isPrimary ? Colors.blue : AppConstants.TEXT_SECONDARY_COLOR,
              fontWeight: isPrimary ? FontWeight.w600 : AppConstants.IOS_LABEL_FONT_WEIGHT,
            ),
      ),
    );
  }

  void _filterExercises() {
    setState(() {
      List<Exercise> exercises = ExerciseService.instance.exercises;
      
      if (_searchController.text.isNotEmpty) {
        exercises = ExerciseService.instance.searchExercises(_searchController.text);
      }
      
      if (_selectedMuscleGroup.isNotEmpty) {
        exercises = exercises.where((exercise) =>
            exercise.primaryMuscleGroup.name.toLowerCase() == _selectedMuscleGroup.toLowerCase()
        ).toList();
      }
      
      _filteredExercises = exercises;
    });
  }

  void _selectMuscleGroup(String muscleGroup) {
    setState(() {
      _selectedMuscleGroup = _selectedMuscleGroup == muscleGroup ? '' : muscleGroup;
      _filterExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    final muscleGroups = ExerciseService.instance.allMuscleGroups
        .where((group) => group.trim().isNotEmpty)
        .toList();

    // Calculate internal header height for ExerciseListWidget's own search/filter bars
    double internalHeaderHeight = 0;
    if (widget.title != null || widget.trailing != null) {
      // This title/trailing is for the ExerciseListWidget itself, if provided.
      // Currently, ExercisePickerScreen doesn't pass these, so this might be 0.
      internalHeaderHeight += 48; 
    }
    internalHeaderHeight += 68;
    if (muscleGroups.isNotEmpty) {
      internalHeaderHeight += 52;
    }

    return Stack(
      children: [
        // Exercise list (behind everything)
        _filteredExercises.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 64,
                      color: AppConstants.TEXT_TERTIARY_COLOR,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No exercises found',
                      style: AppConstants.IOS_TITLE_TEXT_STYLE.copyWith(
                        color: AppConstants.TEXT_SECONDARY_COLOR,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search or filters',
                      style: AppConstants.IOS_BODY_TEXT_STYLE.copyWith(
                        color: AppConstants.TEXT_TERTIARY_COLOR,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.only(
                  left: AppConstants.PAGE_HORIZONTAL_PADDING,
                  right: AppConstants.PAGE_HORIZONTAL_PADDING,
                  // Add space for ExerciseListWidget's own headers AND any additional top padding from parent
                  top: internalHeaderHeight + widget.additionalTopPadding + 20, 
                  bottom: AppConstants.PAGE_HORIZONTAL_PADDING,
                ),
                itemCount: _filteredExercises.length,
                itemBuilder: (context, index) {
                  final exercise = _filteredExercises[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => widget.onExerciseSelected(exercise),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppConstants.CARD_BG_COLOR,
                          borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
                          border: Border.all(
                            color: AppConstants.CARD_STROKE_COLOR,
                            width: AppConstants.CARD_STROKE_WIDTH,
                          ),
                        ),
                        padding: EdgeInsets.all(AppConstants.CARD_PADDING),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: AppConstants.IOS_TITLE_TEXT_STYLE,
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildMuscleGroupChip(context, exercise.primaryMuscleGroup.name, true),
                                      ...exercise.secondaryMuscleGroups.map(
                                        (g) => _buildMuscleGroupChip(context, g.name, false),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              CupertinoIcons.chevron_right,
                              color: AppConstants.TEXT_SECONDARY_COLOR,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

        // Glass header overlay for search/filter bars (on top of the list, but below screen header)
        // This Column itself is positioned at the top of the ExerciseListWidget's Stack.
        // If additionalTopPadding is > 0, this whole Column needs to be pushed down.
        Positioned(
          top: widget.additionalTopPadding,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Optional Title/Trailing for ExerciseListWidget itself (currently not used by ExercisePickerScreen)
              if (widget.title != null || widget.trailing != null)
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
                    child: Container(
                      color: AppConstants.HEADER_BG_COLOR_MEDIUM,
                      padding: EdgeInsets.symmetric(horizontal: AppConstants.PAGE_HORIZONTAL_PADDING, vertical: 8.0),
                      child: Row(
                        children: [
                          if (widget.title != null)
                            Expanded(
                              child: Text(
                                widget.title!,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          if (widget.trailing != null) widget.trailing!,
                        ],
                      ),
                    ),
                  ),
                ),

              // Search bar with glass effect
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
                  child: Container(
                    color: AppConstants.HEADER_BG_COLOR_MEDIUM,
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.PAGE_HORIZONTAL_PADDING, vertical: 12.0),
                    child: CupertinoSearchTextField(
                      controller: _searchController,
                      placeholder: 'Search exercises...',
                      placeholderStyle: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(color: AppConstants.TEXT_SECONDARY_COLOR),
                      style: AppConstants.IOS_BODY_TEXT_STYLE,
                      decoration: BoxDecoration(
                        color: Colors.grey[900]?.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
              ),

              // Muscle group filter chips with glass effect
              if (muscleGroups.isNotEmpty)
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
                    child: Container(
                      height: 52,
                      color: AppConstants.HEADER_BG_COLOR_MEDIUM,
                      padding: EdgeInsets.symmetric(horizontal: AppConstants.PAGE_HORIZONTAL_PADDING, vertical: 10.0),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: muscleGroups.length,
                        itemBuilder: (context, index) {
                          final muscleGroup = muscleGroups[index];
                          final isSelected = _selectedMuscleGroup == muscleGroup;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                              color: isSelected ? Colors.blue : Colors.grey[800]?.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12.0),
                              onPressed: () => _selectMuscleGroup(muscleGroup),
                              child: Text(
                                muscleGroup,
                                style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
                                  color: isSelected ? AppConstants.TEXT_PRIMARY_COLOR : AppConstants.TEXT_SECONDARY_COLOR,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
