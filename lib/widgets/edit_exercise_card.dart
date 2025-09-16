import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';
import '../screens/exercise_info_screen.dart';
import 'set_edit_options_sheet.dart';

class EditExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;
  final bool isNotesExpanded;
  final Function(int) onToggleNotes;
  final Function(int) onRemoveExercise;
  final Function(int) onAddSet;
  final Function(int, int) onRemoveSet;
  final Function(int, int, {int? targetReps, double? targetWeight, String? type, int? targetRestSeconds}) onUpdateSet;
  final Function(int, String) onUpdateNotes;
  final Function(int, int) onToggleRepRange; // This will likely need to be removed or changed
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

  @override
  State<EditExerciseCard> createState() => _EditExerciseCardState();
}

class _EditExerciseCardState extends State<EditExerciseCard> {
  late Map<String, TextEditingController> _repsControllers;
  late Map<String, TextEditingController> _weightControllers;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _repsControllers = {};
    _weightControllers = {};
    
    for (final set in widget.exercise.sets) {
      final repsKey = 'reps_${widget.exercise.id}_${set.id}';
      final weightKey = 'weight_${widget.exercise.id}_${set.id}';
      
      _repsControllers[repsKey] = TextEditingController(
        text: set.targetReps?.toString() ?? '',
      );
      _weightControllers[weightKey] = TextEditingController(
        text: set.targetWeight?.toString() ?? '',
      );
    }
    
    _notesController = TextEditingController(text: widget.exercise.notes ?? '');
  }

  @override
  void didUpdateWidget(EditExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.exercise.id != widget.exercise.id) {
      _disposeControllers();
      _initializeControllers();
      return;
    }

    final oldSetIds = oldWidget.exercise.sets.map((s) => s.id).toSet();
    final newSets = widget.exercise.sets;

    // Dispose controllers for removed sets
    final newSetIds = newSets.map((s) => s.id).toSet();
    final removedSetIds = oldSetIds.difference(newSetIds);
    for (final setId in removedSetIds) {
      final repsKey = 'reps_${oldWidget.exercise.id}_$setId';
      _repsControllers.remove(repsKey)?.dispose();

      final weightKey = 'weight_${oldWidget.exercise.id}_$setId';
      _weightControllers.remove(weightKey)?.dispose();
    }

    // Add or update controllers for all current sets
    for (final set in newSets) {
      final repsKey = 'reps_${widget.exercise.id}_${set.id}';
      if (_repsControllers.containsKey(repsKey)) {
        // Update existing controller if text differs
        final controller = _repsControllers[repsKey]!;
        final newText = set.targetReps?.toString() ?? '';
        if (controller.text != newText) {
          controller.text = newText;
        }
      } else {
        // Add new controller
        _repsControllers[repsKey] = TextEditingController(text: set.targetReps?.toString() ?? '');
      }

      final weightKey = 'weight_${widget.exercise.id}_${set.id}';
      if (_weightControllers.containsKey(weightKey)) {
        // Update existing controller if text differs
        final controller = _weightControllers[weightKey]!;
        final newText = set.targetWeight?.toString() ?? '';
        if (controller.text != newText) {
          controller.text = newText;
        }
      } else {
        // Add new controller
        _weightControllers[weightKey] = TextEditingController(text: set.targetWeight?.toString() ?? '');
      }
    }
    
    // Update notes controller if needed
    if (_notesController.text != (widget.exercise.notes ?? '')) {
        _notesController.text = widget.exercise.notes ?? '';
    }
  }

  void _disposeControllers() {
    for (final controller in _repsControllers.values) {
      controller.dispose();
    }
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    _notesController.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _showExerciseInfo(BuildContext context, Exercise? exerciseDetail) {
    if (exerciseDetail == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseInfoScreen(exercise: exerciseDetail),
      ),
    );
  }

  void _showSetEditOptions(BuildContext context, int setIndex) {
    final set = widget.exercise.sets[setIndex];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SetEditOptionsSheet(
        set: set,
        setIndex: setIndex,
        canRemoveSet: widget.exercise.sets.length > 1,
        onToggleRepRange: () => widget.onToggleRepRange(widget.exerciseIndex, setIndex),
        onRemoveSet: widget.exercise.sets.length > 1 
          ? () => widget.onRemoveSet(widget.exerciseIndex, setIndex)
          : null,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Remove Exercise'),
        content: Text('Are you sure you want to remove "${widget.exercise.exerciseDetail?.name ?? widget.exercise.exerciseSlug}" from this workout?'),
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
              widget.onRemoveExercise(widget.exerciseIndex);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(widget.exercise.id),
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
          if (widget.isNotesExpanded) _buildNotesSection(),
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
                    widget.exercise.exerciseDetail?.name ?? widget.exercise.exerciseSlug, // Use exerciseDetail or fallback to slug
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
Text(
  widget.exercise.exerciseDetail?.primaryMuscleGroup.name ?? 'N/A', // Use exerciseDetail
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
                onPressed: () => widget.onToggleNotes(widget.exerciseIndex),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.isNotesExpanded 
                        ? Colors.amber.withAlpha((255 * 0.2).round())
                        : Colors.grey.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    widget.isNotesExpanded 
                        ? Icons.sticky_note_2 
                        : Icons.sticky_note_2_outlined,
                    color: widget.isNotesExpanded 
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
                onPressed: () => _showExerciseInfo(context, widget.exercise.exerciseDetail), // Pass exerciseDetail
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
        controller: _notesController,
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
        onChanged: (value) => widget.onUpdateNotes(widget.exerciseIndex, value),
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
          ...widget.exercise.sets.asMap().entries.map((entry) {
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
          child: _buildTargetRepsField(setIndex, set),
        ),
        const SizedBox(width: 8),
        
        // Weight field
        Expanded(
          flex: 3,
          child: _buildTargetWeightField(setIndex, set),
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

  Widget _buildTargetRepsField(int setIndex, WorkoutSet set) {
    final key = 'reps_${widget.exercise.id}_${set.id}';
    final controller = _repsControllers[key];
    
    if (controller == null) return const SizedBox.shrink();
    
    return SizedBox(
      height: 36,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: Colors.white, fontSize: 15),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 1),
          ),
        ),
        onChanged: (value) {
          final reps = int.tryParse(value);
          if (value.isEmpty || (reps != null && reps >= 0)) {
            widget.onUpdateSet(widget.exerciseIndex, setIndex, targetReps: value.isEmpty ? null : reps);
          }
        },
      ),
    );
  }

  Widget _buildTargetWeightField(int setIndex, WorkoutSet set) {
    final key = 'weight_${widget.exercise.id}_${set.id}';
    final controller = _weightControllers[key];
    
    if (controller == null) return const SizedBox.shrink();
    
    return SizedBox(
      height: 36,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        style: const TextStyle(color: Colors.white, fontSize: 15),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: Colors.grey[800],
          suffixText: widget.weightUnit,
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
        onChanged: (value) {
          final weight = double.tryParse(value);
          if (value.isEmpty || (weight != null && weight >= 0)) {
            widget.onUpdateSet(widget.exerciseIndex, setIndex, targetWeight: value.isEmpty ? null : weight);
          }
        },
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
                onPressed: () => widget.onAddSet(widget.exerciseIndex),
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
