import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';
import '../screens/exercise_info_screen.dart';
import 'set_edit_options_sheet.dart';

class EditExerciseCard extends StatelessWidget {
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
  final String weightUnit;

  const EditExerciseCard({
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
    required this.weightUnit,
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

  void _showDeleteConfirmation(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Remove Exercise'),
        content: Text('Are you sure you want to remove "${exercise.exercise.name}" from this workout?'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Remove'),
            onPressed: () {
              Navigator.of(context).pop();
              onRemoveExercise(exerciseIndex);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(exercise.id),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExerciseHeader(context),
          if (isNotesExpanded) _buildNotesSection(),
          _buildSetsSection(),
          _buildAddSetButton(),
        ],
      ),
    );
  }

  Widget _buildExerciseHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Drag handle
          Icon(
            Icons.drag_handle,
            color: Colors.grey[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          
          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exercise.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  exercise.exercise.primaryMuscleGroup,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notes toggle
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => onToggleNotes(exerciseIndex),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isNotesExpanded 
                        ? Colors.amber.withAlpha((255 * 0.2).round())
                        : Colors.grey.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isNotesExpanded 
                        ? Icons.sticky_note_2 
                        : Icons.sticky_note_2_outlined,
                    color: isNotesExpanded 
                        ? Colors.amber 
                        : Colors.grey[500],
                    size: 24,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Info button
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showExerciseInfo(context, exercise.exercise),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Delete button
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showDeleteConfirmation(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: TextFormField(
        initialValue: exercise.notes,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 3,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.all(12),
          hintText: 'Add notes for this exercise...',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => onUpdateNotes(exerciseIndex, value),
      ),
    );
  }

  Widget _buildSetsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sets header
          Row(
            children: [
              const SizedBox(width: 32),
              const Expanded(
                flex: 3,
                child: Text(
                  'Reps',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
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
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Sets list
          ...exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Builder(
                builder: (context) => _buildSetRow(setIndex, set, context),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSetRow(int setIndex, WorkoutSet set, BuildContext context) {
    return Row(
      children: [
        // Set number
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${setIndex + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // Reps field(s)
        Expanded(
          flex: 3,
          child: set.isRepRange 
              ? _buildRepRangeFields(setIndex, set)
              : _buildSingleRepField(setIndex, set),
        ),
        const SizedBox(width: 8),
        
        // Weight field
        Expanded(
          flex: 3,
          child: _buildWeightField(setIndex, set),
        ),
        const SizedBox(width: 8),
        
        // Options button
        SizedBox(
          width: 32,
          height: 32,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showSetEditOptions(context, setIndex),
            child: Icon(
              Icons.more_horiz,
              color: Colors.grey[400],
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepRangeFields(int setIndex, WorkoutSet set) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            initialValue: set.repRangeMin.toString(),
            onChanged: (value) {
              final repMin = int.tryParse(value);
              if (repMin != null && repMin > 0) {
                onUpdateSet(exerciseIndex, setIndex, repRangeMin: repMin);
              }
            },
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '-',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildTextField(
            initialValue: set.repRangeMax.toString(),
            onChanged: (value) {
              final repMax = int.tryParse(value);
              if (repMax != null && repMax > 0) {
                onUpdateSet(exerciseIndex, setIndex, repRangeMax: repMax);
              }
            },
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleRepField(int setIndex, WorkoutSet set) {
    return _buildTextField(
      initialValue: set.reps.toString(),
      onChanged: (value) {
        final reps = int.tryParse(value);
        if (reps != null && reps > 0) {
          onUpdateSet(exerciseIndex, setIndex, reps: reps);
        }
      },
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _buildWeightField(int setIndex, WorkoutSet set) {
    return _buildTextField(
      initialValue: set.weight.toString(),
      onChanged: (value) {
        final weight = double.tryParse(value);
        if (weight != null && weight >= 0) {
          onUpdateSet(exerciseIndex, setIndex, weight: weight);
        }
      },
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      suffix: weightUnit,
    );
  }

  Widget _buildTextField({
    required String initialValue,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? suffix,
  }) {
    return SizedBox(
      height: 36,
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: Colors.grey[800],
          suffixText: suffix,
          suffixStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 1),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAddSetButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: CupertinoButton(
          color: Colors.blue.withAlpha((255 * 0.1).round()),
          borderRadius: BorderRadius.circular(8),
          padding: EdgeInsets.zero,
          onPressed: () => onAddSet(exerciseIndex),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add,
                color: Colors.blue,
              
              ),
              const SizedBox(width: 8),
              const Text(
                'Add Set',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
