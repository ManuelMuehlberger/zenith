import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';
import '../screens/exercise_info_screen.dart';
import '../theme/app_theme.dart';
import 'set_edit_options_sheet.dart';

class ExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;
  final bool isNotesExpanded;
  final Function(int) onToggleNotes;
  final Function(int) onRemoveExercise;
  final Function(int) onAddSet;
  final Function(int, int) onRemoveSet;
  final Function(
    int,
    int, {
    int? targetReps,
    double? targetWeight,
    String? type,
    int? targetRestSeconds,
  })
  onUpdateSet;
  final Function(int, String) onUpdateNotes;
  final Function(int, int)
  onToggleRepRange; // Keep for now, SetEditOptionsSheet might still expect it

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.isNotesExpanded,
    required this.onToggleNotes,
    required this.onRemoveExercise,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onUpdateSet,
    required this.onUpdateNotes,
    required this.onToggleRepRange,
  });

  void _showExerciseInfo(BuildContext context, Exercise? exerciseDetail) {
    if (exerciseDetail == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseInfoScreen(exercise: exerciseDetail),
      ),
    );
  }

  void _showSetEditOptions(BuildContext context, int setIndex) {
    final set = exercise.sets[setIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: context.appScheme.surface.withValues(alpha: 0),
      builder: (context) => SetEditOptionsSheet(
        set: set,
        setIndex: setIndex,
        canRemoveSet: exercise.sets.length > 1,
        onToggleRepRange: () => onToggleRepRange(exerciseIndex, setIndex),
        onRemoveSet: exercise.sets.length > 1
            ? () => onRemoveSet(exerciseIndex, setIndex)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: colors.overlaySoft, width: 1),
    );

    return Card(
      key: ValueKey(exercise.id),
      color: colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise header section with integrated notes
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  // Top row with exercise info and buttons
                  Row(
                    children: [
                      // Drag handle
                      Icon(
                        Icons.drag_handle,
                        color: colors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.exerciseDetail?.name ??
                                  exercise.exerciseSlug,
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              exercise
                                      .exerciseDetail
                                      ?.primaryMuscleGroup
                                      .name ??
                                  'N/A',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notes toggle button
                      IconButton(
                        onPressed: () => onToggleNotes(exerciseIndex),
                        icon: Icon(
                          isNotesExpanded
                              ? Icons.sticky_note_2
                              : Icons.sticky_note_2_outlined,
                          color: isNotesExpanded
                              ? colors.warning
                              : colors.textSecondary,
                          size: 18,
                        ),
                        tooltip: isNotesExpanded ? 'Hide notes' : 'Add notes',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      // Info button
                      IconButton(
                        onPressed: () =>
                            _showExerciseInfo(context, exercise.exerciseDetail),
                        icon: Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                        tooltip: 'Exercise Info',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      // Delete button
                      IconButton(
                        onPressed: () => onRemoveExercise(exerciseIndex),
                        icon: Icon(
                          Icons.delete,
                          color: colorScheme.error,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),

                  // Notes field integrated in header
                  if (isNotesExpanded) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: exercise.notes,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(8),
                        hintText: 'Add notes for this exercise...',
                        hintStyle: textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                        filled: true,
                        fillColor: colors.field,
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder.copyWith(
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1,
                          ),
                        ),
                      ),
                      onChanged: (value) => onUpdateNotes(exerciseIndex, value),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Sets header
            Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Reps',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Weight',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),

            const SizedBox(height: 6),

            // Sets list
            ...exercise.sets.asMap().entries.map((entry) {
              final setIndex = entry.key;
              final set = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colors.field,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${setIndex + 1}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Reps field(s)
                    Expanded(
                      flex: 3,
                      // Rep range logic removed, using targetReps
                      child: SizedBox(
                        height: 32,
                        child: TextFormField(
                          initialValue: set.targetReps?.toString() ?? '',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            filled: true,
                            fillColor: colors.field,
                            border: inputBorder,
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder.copyWith(
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            final reps = int.tryParse(value);
                            if (value.isEmpty || (reps != null && reps >= 0)) {
                              onUpdateSet(
                                exerciseIndex,
                                setIndex,
                                targetReps: value.isEmpty ? null : reps,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Weight field
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 32,
                        child: TextFormField(
                          initialValue: set.targetWeight?.toString() ?? '',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            filled: true,
                            fillColor: colors.field,
                            suffixText: 'kg',
                            suffixStyle: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                            border: inputBorder,
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder.copyWith(
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            final weight = double.tryParse(value);
                            if (value.isEmpty ||
                                (weight != null && weight >= 0)) {
                              onUpdateSet(
                                exerciseIndex,
                                setIndex,
                                targetWeight: value.isEmpty ? null : weight,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Edit set button
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        onPressed: () => _showSetEditOptions(context, setIndex),
                        icon: Icon(
                          Icons.more_vert,
                          color: colors.textSecondary,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Edit set options',
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 4),

            // Add set button
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () => onAddSet(exerciseIndex),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Add Set',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
