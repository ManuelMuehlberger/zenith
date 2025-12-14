import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pull_down_button/pull_down_button.dart';
import '../models/workout.dart';
import '../models/workout_template.dart';
import '../models/workout_exercise.dart';
import '../services/workout_session_service.dart';
import '../services/workout_template_service.dart';
import '../utils/navigation_helper.dart';
import '../utils/workout_metrics.dart';
import '../constants/app_constants.dart';

class ExpandableWorkoutCard extends StatefulWidget {
  // Unified: support either a concrete Workout (legacy usage) or a WorkoutTemplate (preferred)
  final Workout? workout;
  final WorkoutTemplate? template;
  final Future<List<WorkoutExercise>> Function(String templateId)? loadTemplateExercises;

  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;
  final int index;

  const ExpandableWorkoutCard({
    super.key,
    this.workout,
    this.template,
    this.loadTemplateExercises,
    required this.onEditPressed,
    required this.onDeletePressed,
    required this.index,
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
      _isTemplate ? WorkoutIcons.getIconDataFromCodePoint(widget.template!.iconCodePoint) : widget.workout!.icon;

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
  void didUpdateWidget(covariant ExpandableWorkoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool wasTemplate = oldWidget.template != null;
    final bool isTemplate = widget.template != null;

    // If switching between modes (template vs workout), reset and (re)load as needed
    if (wasTemplate != isTemplate) {
      setState(() {
        _templateExercises = null;
        _loadingTemplateExercises = false;
      });
      if (isTemplate) {
        _loadTemplateExercises();
      }
      return;
    }

    // In template mode, refresh the lazily-cached exercises when the template instance changes
    if (isTemplate) {
      final oldId = oldWidget.template!.id;
      final newId = widget.template!.id;

      // Reload if the id changed or we received a new template instance (e.g., after editing)
      if (oldId != newId || oldWidget.template != widget.template) {
        setState(() {
          _templateExercises = null;
          _loadingTemplateExercises = false;
        });
        _loadTemplateExercises();
      }
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP),
      decoration: BoxDecoration(
        color: AppConstants.CARD_BG_COLOR,
        borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
        border: Border.all(
          color: _isExpanded
              ? AppConstants.ACCENT_COLOR.withAlpha((255 * 0.6).round())
              : AppConstants.CARD_STROKE_COLOR,
          width: _isExpanded ? 1.5 : AppConstants.CARD_STROKE_WIDTH,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.15).round()),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
          onTap: _toggleExpansion,
          child: Column(
            children: [
              // Main card content
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.CARD_PADDING,
                  AppConstants.CARD_PADDING,
                  AppConstants.CARD_PADDING,
                  0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon container with rounded modern iOS styling
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _displayColor.withAlpha((255 * 0.15).round()),
                        borderRadius: BorderRadius.circular(26), // Fully rounded
                        border: Border.all(
                          color: _displayColor.withAlpha((255 * 0.3).round()),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        _displayIcon,
                        color: _displayColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppConstants.ITEM_HORIZONTAL_GAP),
                    Expanded(
                      child: Text(
                        _displayName,
                        style: AppConstants.CARD_TITLE_TEXT_STYLE,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Expand/collapse button without background
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppConstants.TEXT_SECONDARY_COLOR,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Menu button without background
                        PullDownButton(
                          itemBuilder: (context) => [
                            PullDownMenuItem(
                              onTap: widget.onEditPressed,
                              title: 'Edit Workout',
                              icon: CupertinoIcons.pencil,
                            ),
                            PullDownMenuItem(
                              onTap: widget.onDeletePressed,
                              title: 'Delete Workout',
                              isDestructive: true,
                              icon: CupertinoIcons.delete,
                            ),
                          ],
                          buttonBuilder: (context, showMenu) => CupertinoButton(
                            onPressed: showMenu,
                            padding: EdgeInsets.zero,
                            child: Icon(
                              CupertinoIcons.ellipsis,
                              color: AppConstants.TEXT_SECONDARY_COLOR,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Indicators Section (Transitions between collapsed and expanded states)
              AnimatedPadding(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: _isExpanded
                    ? const EdgeInsets.fromLTRB(20, 20, 20, 10)
                    : const EdgeInsets.fromLTRB(
                        AppConstants.CARD_PADDING + 52 + AppConstants.ITEM_HORIZONTAL_GAP,
                        4,
                        AppConstants.CARD_PADDING,
                        AppConstants.CARD_PADDING,
                      ),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  firstCurve: Curves.easeInOut,
                  secondCurve: Curves.easeInOut,
                  crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: Row(
                    children: [
                      // Exercise count with icon
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.TEXT_TERTIARY_COLOR.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fitness_center_outlined,
                              size: 12,
                              color: AppConstants.TEXT_SECONDARY_COLOR,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$exerciseCount',
                              style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sets count with icon
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.TEXT_TERTIARY_COLOR.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: 12,
                              color: AppConstants.TEXT_SECONDARY_COLOR,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalSets',
                              style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Duration estimate
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.ACCENT_COLOR.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 12,
                              color: AppConstants.ACCENT_COLOR,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              WorkoutMetrics.getFormattedDuration(_effectiveExercises),
                              style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.ACCENT_COLOR,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  secondChild: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildExpandedStatItem(
                        icon: Icons.fitness_center_outlined,
                        value: '$exerciseCount',
                        label: 'Exercises',
                      ),
                      _buildExpandedStatItem(
                        icon: Icons.layers_outlined,
                        value: '$totalSets',
                        label: 'Sets',
                      ),
                      _buildExpandedStatItem(
                        icon: Icons.schedule_outlined,
                        value: WorkoutMetrics.getFormattedDuration(_effectiveExercises).replaceAll('~', ''),
                        label: 'Minutes',
                      ),
                    ],
                  ),
                ),
              ),

              // Expandable content
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Transparent to blend with card
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppConstants.CARD_RADIUS),
                      bottomRight: Radius.circular(AppConstants.CARD_RADIUS),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isExpanded) ...[
                          // Last performed date
                          if (_isTemplate && widget.template?.lastUsed != null)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  'Last performed: ${DateFormat.yMMMd().format(DateTime.parse(widget.template!.lastUsed!))}',
                                  style: AppConstants.IOS_SUBTEXT_STYLE.copyWith(
                                    fontSize: 12,
                                    color: AppConstants.TEXT_TERTIARY_COLOR,
                                  ),
                                ),
                              ),
                            ),

                          // Exercise list
                          if (_effectiveExercises.isNotEmpty) ...[
                            Text(
                              'Exercises',
                              style: AppConstants.IOS_TITLE_TEXT_STYLE.copyWith(
                                fontSize: 16,
                                color: AppConstants.TEXT_PRIMARY_COLOR,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._effectiveExercises.map((exercise) => 
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _displayColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        exercise.exerciseDetail?.name ?? exercise.exerciseSlug,
                                        style: AppConstants.IOS_BODY_TEXT_STYLE.copyWith(
                                          fontSize: 14,
                                          color: AppConstants.TEXT_PRIMARY_COLOR,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppConstants.TEXT_SECONDARY_COLOR.withAlpha((255 * 0.15).round()),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${exercise.sets.length} sets',
                                        style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.TEXT_SECONDARY_COLOR,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],

                        // Start workout button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _startWorkout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.ACCENT_COLOR,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Start Workout',
                                  style: AppConstants.IOS_BODY_TEXT_STYLE.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
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
    );
  }

  Widget _buildExpandedStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.ACCENT_COLOR.withAlpha((255 * 0.1).round()),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppConstants.ACCENT_COLOR,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppConstants.IOS_TITLE_TEXT_STYLE.copyWith(
            fontSize: 18,
            color: AppConstants.TEXT_PRIMARY_COLOR,
          ),
        ),
        Text(
          label,
          style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
            fontSize: 12,
            color: AppConstants.TEXT_SECONDARY_COLOR,
          ),
        ),
      ],
    );
  }

}
