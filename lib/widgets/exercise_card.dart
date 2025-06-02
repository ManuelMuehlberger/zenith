import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_exercise.dart';
import '../models/exercise.dart';
import '../screens/exercise_info_screen.dart';
import 'set_edit_options_sheet.dart';

class ExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;
  final bool isNotesExpanded;
  final Function(int) onToggleNotes;
  final Function(int) onRemoveExercise;
  final Function(int) onAddSet;
  final Function(int, int) onRemoveSet;
  final Function(int, int, {int? reps, double? weight, int? repRangeMin, int? repRangeMax}) onUpdateSet;
  final Function(int, String) onUpdateNotes;
  final Function(int, int) onToggleRepRange;

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

  void _showExerciseInfo(BuildContext context, Exercise exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseInfoScreen(exercise: exercise),
      ),
    );
  }

  void _showSetEditOptions(BuildContext context, int setIndex) {
    final set = exercise.sets[setIndex];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
    return Card(
      key: ValueKey(exercise.id),
      color: Colors.grey[900],
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
                color: Colors.grey[850],
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
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.exercise.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              exercise.exercise.primaryMuscleGroup,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
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
                            ? Colors.amber 
                            : Colors.grey[500],
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
                        onPressed: () => _showExerciseInfo(context, exercise.exercise),
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
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
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
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
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 2,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(8),
                        hintText: 'Add notes for this exercise...',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Colors.grey[600]!, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Colors.grey[600]!, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Colors.blue, width: 1),
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
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Reps',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Weight',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
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
                        color: Colors.grey[700],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${setIndex + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Reps field(s)
                    Expanded(
                      flex: 3,
                      child: set.isRepRange 
                        ? Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 32,
                                  child: TextFormField(
                                    initialValue: set.repRangeMin.toString(),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                      filled: true,
                                      fillColor: Colors.grey[700],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(color: Colors.grey[600]!, width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(color: Colors.grey[600]!, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: Colors.blue, width: 1),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value.isEmpty) return;
                                      final repMin = int.tryParse(value);
                                      if (repMin != null && repMin > 0) {
                                        onUpdateSet(exerciseIndex, setIndex, repRangeMin: repMin);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('-', style: TextStyle(color: Colors.white, fontSize: 13)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: SizedBox(
                                  height: 32,
                                  child: TextFormField(
                                    initialValue: set.repRangeMax.toString(),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                      filled: true,
                                      fillColor: Colors.grey[700],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(color: Colors.grey[600]!, width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(color: Colors.grey[600]!, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: Colors.blue, width: 1),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value.isEmpty) return;
                                      final repMax = int.tryParse(value);
                                      if (repMax != null && repMax > 0) {
                                        onUpdateSet(exerciseIndex, setIndex, repRangeMax: repMax);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            height: 32,
                            child: TextFormField(
                              initialValue: set.reps.toString(),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                filled: true,
                                fillColor: Colors.grey[700],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: Colors.grey[600]!, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: Colors.grey[600]!, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: Colors.blue, width: 1),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isEmpty) return;
                                final reps = int.tryParse(value);
                                if (reps != null && reps > 0) {
                                  onUpdateSet(exerciseIndex, setIndex, reps: reps);
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
                          initialValue: set.weight.toString(),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            filled: true,
                            fillColor: Colors.grey[700],
                            suffixText: 'kg',
                            suffixStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: Colors.grey[600]!, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: Colors.grey[600]!, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Colors.blue, width: 1),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isEmpty) return;
                            final weight = double.tryParse(value);
                            if (weight != null && weight >= 0) {
                              onUpdateSet(exerciseIndex, setIndex, weight: weight);
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
                          color: Colors.grey[400],
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
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  'Add Set',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.withAlpha((255 * 0.8).round()),
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
