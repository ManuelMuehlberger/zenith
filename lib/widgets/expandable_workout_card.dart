import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout.dart';
import '../models/workout_template.dart';
import '../models/workout_exercise.dart';
import '../services/workout_session_service.dart';
import '../services/workout_template_service.dart';
import '../utils/navigation_helper.dart';

class ExpandableWorkoutCard extends StatefulWidget {
  // Unified: support either a concrete Workout (legacy usage) or a WorkoutTemplate (preferred)
  final Workout? workout;
  final WorkoutTemplate? template;
  final Future<List<WorkoutExercise>> Function(String templateId)? loadTemplateExercises;

  final VoidCallback onEditPressed;
  final VoidCallback onMorePressed;
  final int index;
  final VoidCallback? onDragStartedCallback;
  final VoidCallback? onDragEndCallback;

  const ExpandableWorkoutCard({
    super.key,
    this.workout,
    this.template,
    this.loadTemplateExercises,
    required this.onEditPressed,
    required this.onMorePressed,
    required this.index,
    this.onDragStartedCallback,
    this.onDragEndCallback,
  }) : assert(
          (workout != null) != (template != null),
          'Provide exactly one of workout or template',
        );

  @override
  State<ExpandableWorkoutCard> createState() => _ExpandableWorkoutCardState();
}

class _ExpandableWorkoutCardState extends State<ExpandableWorkoutCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  // For template mode: lazily loaded exercises preview
  List<WorkoutExercise>? _templateExercises;
  bool _loadingTemplateExercises = false;

  bool get _isTemplate => widget.template != null;

  String get _displayName =>
      _isTemplate ? widget.template!.name : widget.workout!.name;

  IconData get _displayIcon =>
      _isTemplate ? _iconFromCodePoint(widget.template!.iconCodePoint) : widget.workout!.icon;

  Color get _displayColor => _isTemplate
      ? Color(widget.template!.colorValue ?? 0xFF2196F3)
      : widget.workout!.color;

  List<WorkoutExercise> get _effectiveExercises =>
      _isTemplate ? (_templateExercises ?? const []) : widget.workout!.exercises;

  int get _exerciseCount => _effectiveExercises.length;

  int get _totalSets =>
      _effectiveExercises.fold(0, (sum, e) => sum + e.sets.length);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isTemplate) {
      _loadTemplateExercises();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplateExercises() async {
    if (_loadingTemplateExercises || !_isTemplate) return;
    setState(() {
      _loadingTemplateExercises = true;
    });
    try {
      final items = await (widget.loadTemplateExercises != null
          ? widget.loadTemplateExercises!(widget.template!.id)
          : WorkoutTemplateService.instance.getTemplateExercises(widget.template!.id));
      if (mounted) {
        setState(() {
          _templateExercises = items;
        });
      }
    } catch (_) {
      // Fail silently for preview
      if (mounted) {
        setState(() {
          _templateExercises = const [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingTemplateExercises = false;
        });
      }
    }
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        if (_isTemplate && _templateExercises == null) {
          _loadTemplateExercises();
        }
      } else {
        _animationController.reverse();
      }
    });
    HapticFeedback.lightImpact();
  }

  int _estimateWorkoutDuration(int sets, int exerciseCount) {
    // Estimate 2-3 minutes per set plus 1 minute per exercise for setup
    return (sets * 3 + exerciseCount * 1).round();
  }

  Widget _buildWorkoutStat(String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Future<void> _startWorkout() async {
    try {
      if (_isTemplate) {
        // Ensure exercises are loaded
        if (_templateExercises == null) {
          await _loadTemplateExercises();
        }
        final exercises = _templateExercises ?? const <WorkoutExercise>[];

        // Build a transient Workout from the template to start the session
        final template = widget.template!;
        final templateAsWorkout = Workout(
          id: template.id, // use template id as linkage
          name: template.name,
          description: template.description,
          iconCodePoint: template.iconCodePoint,
          colorValue: template.colorValue,
          folderId: template.folderId,
          notes: template.notes,
          status: WorkoutStatus.template,
          exercises: exercises,
        );

        await WorkoutSessionService.instance.startWorkout(templateAsWorkout);
      } else {
        // Backward compatibility: start from a Workout if provided
        await WorkoutSessionService.instance.startWorkout(widget.workout!);
      }

      HapticFeedback.mediumImpact();

      if (mounted) {
        // Navigate to the Workouts tab (index 1)
        // The WorkoutBuilderScreen on that tab will then display the ActiveWorkoutScreen
        NavigationHelper.goToTab(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start workout: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseCount = _exerciseCount;
    final totalSets = _totalSets;
    final isTemplate = _isTemplate;

    return LongPressDraggable<Map<String, dynamic>>(
      key: ValueKey(isTemplate ? widget.template!.id : widget.workout!.id),
      data: isTemplate
          ? {
              'templateId': widget.template!.id,
              'index': widget.index,
              'type': 'template',
            }
          : {
              'workoutId': widget.workout!.id,
              'index': widget.index,
              'type': 'workout',
            },
      delay: const Duration(milliseconds: 500),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
        widget.onDragStartedCallback?.call();
      },
      onDragEnd: (details) {
        widget.onDragEndCallback?.call();
      },
      feedback: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha((255 * 0.9).round()),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _displayIcon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$exerciseCount exercise${exerciseCount != 1 ? 's' : ''} • $totalSets sets',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: Colors.grey[800]?.withAlpha((255 * 0.5).round()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[700]!, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$exerciseCount exercise${exerciseCount != 1 ? 's' : ''} • $totalSets sets',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isExpanded ? Colors.blue.withAlpha((255 * 0.5).round()) : Colors.grey[800]!,
            width: _isExpanded ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggleExpansion,
            child: Column(
              children: [
                // Main card content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _displayColor.withAlpha((255 * 0.2).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _displayIcon,
                          color: _displayColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _displayName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.fitness_center_outlined,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$exerciseCount ${exerciseCount == 1 ? "exercise" : "exercises"}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.layers_outlined,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$totalSets ${totalSets == 1 ? "set" : "sets"}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onPressed: widget.onMorePressed,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Expandable content
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Workout stats
                          Text(
                            'Workout Details',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildWorkoutStat(
                                  '$exerciseCount',
                                  exerciseCount == 1 ? 'exercise' : 'exercises',
                                ),
                              ),
                              Expanded(
                                child: _buildWorkoutStat(
                                  '$totalSets',
                                  totalSets == 1 ? 'set' : 'sets',
                                ),
                              ),
                              Expanded(
                                child: _buildWorkoutStat(
                                  '~${_estimateWorkoutDuration(totalSets, exerciseCount)}',
                                  'min',
                                ),
                              ),
                            ],
                          ),

                          // Exercise list preview (only build when expanded to avoid offstage duplicates in tests)
                          if (_isExpanded && _effectiveExercises.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Exercises',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._effectiveExercises.take(3).map((exercise) => 
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        exercise.exerciseDetail?.name ?? exercise.exerciseSlug,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${exercise.sets.length} ${exercise.sets.length == 1 ? "set" : "sets"}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_effectiveExercises.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '+${_effectiveExercises.length - 3} more ${_effectiveExercises.length - 3 == 1 ? "exercise" : "exercises"}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],

                          const SizedBox(height: 24),

                          // Start workout button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _startWorkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Start Workout',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Map code point to a constant IconData when known, otherwise fallback to dynamic IconData
  IconData _iconFromCodePoint(int? codePoint) {
    if (codePoint == null) return Icons.fitness_center;
    switch (codePoint) {
      case 0xe1a3: // fitness_center
        return Icons.fitness_center;
      case 0xe02f: // directions_run
        return Icons.directions_run;
      case 0xe047: // pool
        return Icons.pool;
      case 0xe52f: // sports
        return Icons.sports;
      case 0xe531: // sports_gymnastics
        return Icons.sports_gymnastics;
      case 0xe532: // sports_handball
        return Icons.sports_handball;
      case 0xe533: // sports_martial_arts
        return Icons.sports_martial_arts;
      case 0xe534: // sports_mma
        return Icons.sports_mma;
      case 0xe535: // sports_motorsports
        return Icons.sports_motorsports;
      case 0xe536: // sports_score
        return Icons.sports_score;
      default:
        // Fallback so arbitrary Material icons render correctly for templates
        return IconData(codePoint, fontFamily: 'MaterialIcons');
    }
  }
}
