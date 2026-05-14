import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../constants/app_constants.dart';
import '../main.dart';
import '../models/user_data.dart';
import '../models/workout.dart';
import '../services/user_service.dart';
import '../services/workout_session_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import '../widgets/weight_picker_wheel.dart';

class WorkoutCompletionScreen extends StatefulWidget {
  final Workout session;

  const WorkoutCompletionScreen({super.key, required this.session});

  @override
  State<WorkoutCompletionScreen> createState() =>
      _WorkoutCompletionScreenState();
}

class _WorkoutCompletionScreenState extends State<WorkoutCompletionScreen> {
  final _notesController = TextEditingController();
  int? _selectedMood; // Using int for mood (1-5 scale)
  double? _selectedWeight;
  Duration? _editedDuration;
  final Logger _logger = Logger('WorkoutCompletionScreen');
  late ConfettiController _confettiController;
  final GlobalKey _finishButtonKey = GlobalKey();
  Offset? _confettiPosition;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserService.instance,
      builder: _buildAnimatedContent,
    );
  }

  Widget _buildAnimatedContent(BuildContext context, Widget? child) {
    return Stack(
      children: [
        _buildScaffold(context),
        if (_confettiPosition != null) _buildConfettiOverlay(context),
      ],
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final textTheme = context.appText;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Complete Workout', style: textTheme.titleLarge),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkoutSummaryCard(context),
            const SizedBox(height: 32),
            _buildNotesSection(context),
            const SizedBox(height: 32),
            _buildMoodSection(context),
            const SizedBox(height: 32),
            _buildWeightSection(context),
            const SizedBox(height: 40),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutSummaryCard(BuildContext context) {
    final scheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colors.field,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: colors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.session.name, style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('Workout completed!', style: textTheme.labelMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                key: const Key('duration_summary'),
                onTap: _showDurationPicker,
                child: _buildSummaryItem(
                  _formattedSessionDuration(),
                  'Duration',
                  Icons.timer_outlined,
                ),
              ),
              _buildSummaryDivider(context),
              _buildSummaryItem(
                '${widget.session.completedSets}/${widget.session.totalSets}',
                'Sets',
                Icons.fitness_center_outlined,
              ),
              _buildSummaryDivider(context),
              _buildSummaryItem(
                _formattedSessionWeight(),
                'Weight',
                Icons.monitor_weight_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    final scheme = context.appScheme;
    final textTheme = context.appText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'How did the workout feel? Any observations?',
          style: textTheme.labelMedium,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Optional notes...',
              hintStyle: textTheme.bodyMedium,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSection(BuildContext context) {
    final textTheme = context.appText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How are you feeling?', style: textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            5,
            (index) => _buildMoodButton(context, index),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodButton(BuildContext context, int index) {
    final scheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final moodValue = 5 - index;
    final isSelected = _selectedMood == moodValue;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedMood = moodValue;
        });
      },
      child: Container(
        key: Key('mood_$moodValue'),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? colors.field : scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? scheme.primary : Theme.of(context).dividerColor,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_getMoodEmoji(moodValue), style: textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSection(BuildContext context) {
    final scheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Current weight', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Optional. Log your body weight with the picker wheel.',
          style: textTheme.labelMedium,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          key: const Key('weight_summary'),
          onTap: _showWeightPicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.field,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.monitor_weight_outlined,
                    color: scheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedWeightLabel(),
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedWeight == null
                            ? 'Tap to log weight'
                            : 'Logged for this workout',
                        style: textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: colors.textTertiary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: TextButton(
              key: const Key('back_to_workout_btn'),
              onPressed: () => _handleBackToWorkout(context),
              style: TextButton.styleFrom(
                backgroundColor: colors.surfaceAlt,
                foregroundColor: colors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Back to Workout', style: textTheme.titleMedium),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              key: _finishButtonKey,
              onPressed: _completeWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.success,
                foregroundColor: colors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Finish', style: textTheme.titleMedium),
            ),
          ),
        ),
      ],
    );
  }

  void _handleBackToWorkout(BuildContext context) {
    _logger.fine('Back to Workout tapped');
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    _logger.warning('Navigator cannot pop. Routing to MainScreen.');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
    NavigationHelper.goToHomeTab();
  }

  Widget _buildConfettiOverlay(BuildContext context) {
    final scheme = context.appScheme;
    final colors = context.appColors;

    return Positioned(
      left: _confettiPosition!.dx,
      top: _confettiPosition!.dy,
      child: SizedBox(
        width: 1,
        height: 1,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.05,
          numberOfParticles: 30,
          gravity: 0.1,
          shouldLoop: false,
          colors: [
            colors.success,
            scheme.primary,
            colors.warning,
            scheme.error,
            colors.textPrimary,
          ],
        ),
      ),
    );
  }

  String _formattedSessionDuration() {
    final completedDuration = widget.session.completedAt != null
        ? widget.session.completedAt!.difference(
            widget.session.startedAt ?? DateTime.now(),
          )
        : DateTime.now().difference(widget.session.startedAt ?? DateTime.now());
    return _formatDurationNoSeconds(
      _stripSeconds(_editedDuration ?? completedDuration),
    );
  }

  String _formattedSessionWeight() {
    final unitLabel =
        UserService.instance.currentProfile?.units == Units.imperial
        ? 'lbs'
        : 'kg';
    return '${WorkoutSessionService.instance.formatWeight(widget.session.totalWeight)} $unitLabel';
  }

  Widget _buildSummaryItem(String value, String label, IconData icon) {
    final scheme = context.appScheme;
    final textTheme = context.appText;

    return Column(
      children: [
        Icon(icon, color: scheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(value, style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(label, style: textTheme.labelMedium),
      ],
    );
  }

  // Helper method to get emoji for mood (1-5 scale)
  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😔';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '😊';
    }
  }

  Duration _stripSeconds(Duration d) => Duration(minutes: d.inMinutes);

  String _formatDurationNoSeconds(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${d.inMinutes}m';
  }

  Units get _weightUnits =>
      UserService.instance.currentProfile?.units ?? Units.metric;

  double _defaultWeightValue() {
    if (_selectedWeight != null) {
      return _selectedWeight!;
    }

    final history = UserService.instance.currentProfile?.weightHistory;
    if (history != null && history.isNotEmpty) {
      return history.last.value;
    }

    final gender =
        UserService.instance.currentProfile?.gender ?? Gender.ratherNotSay;
    return WeightPickerWheelSpec.forUnits(
      _weightUnits,
    ).defaultWeight(gender: gender);
  }

  String _selectedWeightLabel() {
    if (_selectedWeight != null) {
      return '${_selectedWeight!.toStringAsFixed(1)} ${_weightUnits.weightUnit}';
    }

    final history = UserService.instance.currentProfile?.weightHistory;
    if (history != null && history.isNotEmpty) {
      return 'Latest: ${history.last.value.toStringAsFixed(1)} ${_weightUnits.weightUnit}';
    }

    return 'Log weight';
  }

  void _showDurationPicker() {
    final start = widget.session.startedAt ?? DateTime.now();
    final initial =
        _editedDuration ??
        (widget.session.completedAt != null
            ? widget.session.completedAt!.difference(start)
            : DateTime.now().difference(start));
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        Duration temp = initial;
        return Container(
          height: 320,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              // Header with Cancel / Done
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () {
                        _logger.fine('Duration picker canceled');
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () {
                        setState(() {
                          _editedDuration = _stripSeconds(temp);
                        });
                        _logger.fine(
                          'Duration set to: ${_editedDuration != null ? _formatDurationNoSeconds(_editedDuration!) : 'null'}',
                        );
                        Navigator.of(ctx).pop();
                      },
                      child: Text('Done', style: context.appText.labelLarge),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: _stripSeconds(initial),
                  onTimerDurationChanged: (d) {
                    temp = d;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWeightPicker() {
    final units = _weightUnits;
    final spec = WeightPickerWheelSpec.forUnits(units);
    final initial = spec.clamp(_defaultWeightValue());

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        double temp = initial;
        return Container(
          height: 320,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () {
                        setState(() {
                          _selectedWeight = spec.clamp(temp);
                        });
                        Navigator.of(ctx).pop();
                      },
                      child: Text('Done', style: context.appText.labelLarge),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: WeightPickerWheel(
                  pickerKey: const Key('post_workout_weight_picker'),
                  weight: initial,
                  units: units,
                  onWeightChanged: (value) {
                    temp = value;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _completeWorkout() async {
    try {
      await WorkoutSessionService.instance.completeWorkout(
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        mood: _selectedMood,
        durationOverride: _editedDuration,
        postWorkoutWeight: _selectedWeight,
      );

      unawaited(HapticFeedback.mediumImpact());

      Offset? buttonCenter;
      if (_finishButtonKey.currentContext != null) {
        final RenderBox renderBox =
            _finishButtonKey.currentContext!.findRenderObject() as RenderBox;
        buttonCenter = renderBox.localToGlobal(
          renderBox.size.center(Offset.zero),
        );
        if (mounted) {
          //_triggerConfetti();
        }
      }

      //custom circle reveal transition
      if (mounted) {
        unawaited(
          Navigator.of(context).pushAndRemoveUntil(
            CircleRevealPageRoute(
              page: const MainScreen(),
              centerOffset:
                  buttonCenter, // Pass the button center for the reveal
              transitionDuration: const Duration(milliseconds: 700),
            ),
            (Route<dynamic> route) => false,
          ),
        );

        // Ensure home tab is selected after transition
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            NavigationHelper.goToHomeTab();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete workout: ${e.toString()}'),
            backgroundColor: context.appScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}

// Custom PageRoute for Circle Reveal Transition
class CircleRevealPageRoute<T> extends PageRoute<T> {
  CircleRevealPageRoute({
    required this.page,
    this.centerOffset,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.reverseTransitionDuration = const Duration(milliseconds: 500),
  });

  final Widget page;
  final Offset? centerOffset;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return page;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ClipPath(
      clipper: CircleRevealClipper(
        fraction: animation.value,
        centerOffset: centerOffset,
      ),
      child: child,
    );
  }

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;
}

class CircleRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset? centerOffset;

  CircleRevealClipper({required this.fraction, this.centerOffset});

  @override
  Path getClip(Size size) {
    final center = centerOffset ?? Offset(size.width / 2, size.height / 2);
    final radius = sqrt(pow(size.width, 2) + pow(size.height, 2)) * fraction;

    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(CircleRevealClipper oldClipper) {
    return oldClipper.fraction != fraction ||
        oldClipper.centerOffset != centerOffset;
  }
}
