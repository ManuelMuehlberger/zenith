import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../services/exercise_service.dart';

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
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No exercises found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search or filters',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  // Add space for ExerciseListWidget's own headers AND any additional top padding from parent
                  top: internalHeaderHeight + widget.additionalTopPadding + 20, 
                  bottom: 16.0,
                ),
                itemCount: _filteredExercises.length,
                itemBuilder: (context, index) {
                  final exercise = _filteredExercises[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => widget.onExerciseSelected(exercise),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900]?.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: Colors.grey[800]?.withOpacity(0.3) ?? Colors.transparent,
                            width: 0.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    exercise.primaryMuscleGroup.name,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (exercise.secondaryMuscleGroups.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      exercise.secondaryMuscleGroups.map((g) => g.name).join(' • '),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[400],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              CupertinoIcons.chevron_right,
                              color: Colors.grey[500],
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
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: CupertinoSearchTextField(
                      controller: _searchController,
                      placeholder: 'Search exercises...',
                      placeholderStyle: TextStyle(color: Colors.grey[400]), // Keep placeholder specific for now
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900]?.withOpacity(0.6),
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
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      height: 52,
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
                              color: isSelected ? Colors.blue : Colors.grey[800]?.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12.0),
                              onPressed: () => _selectMuscleGroup(muscleGroup),
                              child: Text(
                                muscleGroup,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: isSelected ? Colors.white : Colors.grey[300],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
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
