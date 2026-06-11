import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/exercise.dart';
import '../screens/custom_exercise_creator_screen.dart';
import '../screens/exercise_image_gallery_screen.dart';
import '../services/exercise_service.dart';
import '../services/insights/exercise_trend_provider.dart';
import '../services/insights_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/exercise_media.dart';
import '../utils/unit_converter.dart';
import '../widgets/exercise_info/exercise_image_section.dart';
import '../widgets/exercise_info/exercise_summary_card.dart';
import '../widgets/insights/general_graph_card.dart';
import '../widgets/insights/large_trend_card.dart';

class ExerciseInfoScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseInfoScreen({super.key, required this.exercise});

  @override
  State<ExerciseInfoScreen> createState() => _ExerciseInfoScreenState();
}

class _ExerciseInfoScreenState extends State<ExerciseInfoScreen>
    with SingleTickerProviderStateMixin {
  ExerciseInsights? _exerciseInsights;
  bool _isLoadingInsights = false;
  int _selectedMonths = 6;
  String _selectedTimeframe = '6M';
  bool _useKg = true;
  late Exercise _exercise;

  // Instructions expansion
  bool _isInstructionsExpanded = false;
  late AnimationController _instructionsController;
  late Animation<double> _instructionsAnimation;

  final List<Map<String, dynamic>> _timeframeOptions = [
    {'label': '3M', 'months': 3},
    {'label': '6M', 'months': 6},
    {'label': '1Y', 'months': 12},
    {'label': 'All', 'months': 999},
  ];

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
    _instructionsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _instructionsAnimation = CurvedAnimation(
      parent: _instructionsController,
      curve: Curves.easeInOut,
    );

    _loadSettings();
    _loadExerciseInsights();
  }

  @override
  void dispose() {
    UserService.instance.removeListener(_onUserProfileChanged);
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final profile = UserService.instance.currentProfile;
    if (profile != null) {
      setState(() {
        _useKg = profile.units == Units.metric;
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _useKg = prefs.getBool('use_kg') ?? true;
      });
    }

    UserService.instance.addListener(_onUserProfileChanged);
  }

  void _onUserProfileChanged() {
    final profile = UserService.instance.currentProfile;
    if (profile != null && mounted) {
      setState(() {
        _useKg = profile.units == Units.metric;
      });
    }
  }

  Future<void> _loadExerciseInsights() async {
    setState(() {
      _isLoadingInsights = true;
    });

    try {
      final insights = await InsightsService.instance.getExerciseInsights(
        exerciseName: _exercise.slug,
        monthsBack: _selectedMonths,
      );
      setState(() {
        _exerciseInsights = insights;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInsights = false;
        });
      }
    }
  }

  Future<void> _editCustomExercise() async {
    final updated = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (context) => CustomExerciseCreatorScreen(exercise: _exercise),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _exercise = updated);
    await _loadExerciseInsights();
  }

  Future<void> _deleteCustomExercise() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete exercise?'),
        content: Text('Delete ${_exercise.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ExerciseService.instance.deleteCustomExercise(_exercise);
    if (!mounted) return;
    Navigator.of(context).pop<Exercise>(_exercise);
  }

  Future<void> _showCustomExerciseActions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.appColors.transparent,
      elevation: 0,
      builder: (context) => const _ExerciseActionSheet(),
    );
    if (!mounted || action == null) return;

    if (action == 'edit') {
      await _editCustomExercise();
    } else if (action == 'delete') {
      await _deleteCustomExercise();
    }
  }

  Future<void> _openExerciseGallery() async {
    final imagePaths = decodeExerciseImagePaths(_exercise.image);
    if (imagePaths.isEmpty) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => ExerciseImageGalleryScreen(
          imagePaths: imagePaths,
          title: _exercise.name,
        ),
      ),
    );
  }

  void _onTimeframeChanged(String label, int months) {
    setState(() {
      _selectedTimeframe = label;
      _selectedMonths = months;
    });
    _loadExerciseInsights();
  }

  void _toggleInstructions() {
    setState(() {
      _isInstructionsExpanded = !_isInstructionsExpanded;
      if (_isInstructionsExpanded) {
        _instructionsController.forward();
      } else {
        _instructionsController.reverse();
      }
    });
  }

  String _formatWeight(double weight) {
    final units = _useKg ? 'metric' : 'imperial';
    final unitLabel = UnitConverter.getWeightUnit(units);
    return '${weight.toStringAsFixed(1)} $unitLabel';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.PAGE_HORIZONTAL_PADDING,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: ExerciseImageSection(
                          exercise: _exercise,
                          height: 140,
                          onTap: _openExerciseGallery,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(flex: 6, child: _buildExerciseDetailsSection()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInstructionsSection(),
                  const SizedBox(height: 32),
                  _buildStatsHeader(),
                  const SizedBox(height: 12), // Reduced gap
                  _buildStatsContent(),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final textTheme = context.appText;
    final colors = context.appColors;
    final transparentSurface = context.appScheme.surface.withValues(alpha: 0);

    return SliverAppBar(
      pinned: true,
      stretch: true,
      backgroundColor: transparentSurface,
      elevation: 0,
      expandedHeight: 120.0,
      leading: IconButton(
        icon: Icon(CupertinoIcons.back, color: context.appScheme.onSurface),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (_exercise.isCustom)
          IconButton(
            tooltip: 'Exercise actions',
            icon: Icon(Icons.more_horiz, color: context.appScheme.onSurface),
            onPressed: _showCustomExerciseActions,
          ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                    sigmaY: AppConstants.GLASS_BLUR_SIGMA,
                  ),
                  child: Container(color: colors.overlayStrong),
                ),
              ),
              FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 16),
                title: Text(_exercise.name, style: textTheme.titleMedium),
                background: Container(color: transparentSurface),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExerciseDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
          'Target',
          _exercise.primaryMuscleGroup.name,
          isPrimary: true,
        ),
        if (_exercise.secondaryMuscleGroups.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildDetailRow(
            'Synergists',
            _exercise.secondaryMuscleGroups.map((m) => m.name).join(', '),
          ),
        ],
        if (_exercise.equipment.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildDetailRow('Equipment', _exercise.equipment),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPrimary = false}) {
    final textTheme = context.appText;
    final colorScheme = context.appScheme;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall?.copyWith(fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(
            color: isPrimary ? colorScheme.primary : colors.textPrimary,
            fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    final textTheme = context.appText;
    final colorScheme = context.appScheme;
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: AppConstants.CARD_STROKE_WIDTH,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggleInstructions,
            borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Instructions', style: textTheme.titleMedium),
                  AnimatedRotation(
                    turns: _isInstructionsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _instructionsAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Theme.of(context).dividerColor, height: 1),
                  const SizedBox(height: 16),
                  if (_exercise.instructions.isNotEmpty)
                    ..._exercise.instructions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final instruction = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                instruction,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  else
                    Text(
                      'No instructions available.',
                      style: textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final textTheme = context.appText;
    final colorScheme = context.appScheme;
    final colors = context.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Statistics',
          style: textTheme.headlineSmall?.copyWith(fontSize: 22),
        ),
        PullDownButton(
          itemBuilder: (context) => _timeframeOptions
              .map(
                (option) => PullDownMenuItem.selectable(
                  title: option['label'],
                  selected: _selectedTimeframe == option['label'],
                  onTap: () =>
                      _onTimeframeChanged(option['label'], option['months']),
                ),
              )
              .toList(),
          buttonBuilder: (context, showMenu) => CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: showMenu,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedTimeframe,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsContent() {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    if (_isLoadingInsights) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    if (_exerciseInsights == null || _exerciseInsights!.totalSessions == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                CupertinoIcons.chart_bar,
                size: 48,
                color: colors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'No data available',
                style: textTheme.titleSmall?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete workouts with this exercise to see stats.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final filters = {'timeframe': _selectedTimeframe};

    return Column(
      children: [
        // Top Row: Summary Card and Frequency Graph
        Row(
          children: [
            Expanded(child: ExerciseSummaryCard(insights: _exerciseInsights!)),
            const SizedBox(width: 12),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: GeneralGraphCard(
                  title: 'Frequency',
                  value: _exerciseInsights!.averageSets.toStringAsFixed(1),
                  unit: 'sessions',
                  icon: CupertinoIcons.graph_square_fill,
                  color: colors.success,
                  data: _exerciseInsights!.monthlyFrequency,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TrendInsightCard(
          title: 'Volume',
          color: colorScheme.primary,
          unit: _useKg ? 'kg' : 'lbs',
          icon: CupertinoIcons.chart_bar_fill,
          filters: filters,
          provider: ExerciseTrendProvider(
            _exercise.slug,
            ExerciseTrendType.volume,
          ),
          subLabelBuilder: (_) => _useKg ? 'kg' : 'lbs',
        ),
        const SizedBox(height: 16),
        TrendInsightCard(
          title: 'Max Weight',
          color: colors.warning,
          unit: _useKg ? 'kg' : 'lbs',
          icon: CupertinoIcons.arrow_up_circle_fill,
          filters: filters,
          provider: ExerciseTrendProvider(
            _exercise.slug,
            ExerciseTrendType.maxWeight,
          ),
          mainValueBuilder: (data) {
            if (data.isEmpty) return "0";
            final max = data
                .map((e) => e.value)
                .reduce((a, b) => a > b ? a : b);
            return max.toStringAsFixed(1);
          },
          subLabelBuilder: (_) => _useKg ? 'kg' : 'lbs',
        ),
        const SizedBox(height: 16),
        _buildAveragesCard(),
      ],
    );
  }

  Widget _buildAveragesCard() {
    final textTheme = context.appText;
    final colorScheme = context.appScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: AppConstants.CARD_STROKE_WIDTH,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Averages', style: textTheme.titleMedium),
          const SizedBox(height: 16),
          _buildAverageRow(
            'Weight per Set',
            _formatWeight(_exerciseInsights!.averageWeight),
          ),
          Divider(color: Theme.of(context).dividerColor, height: 24),
          _buildAverageRow(
            'Reps per Set',
            _exerciseInsights!.averageReps.toStringAsFixed(1),
          ),
          Divider(color: Theme.of(context).dividerColor, height: 24),
          _buildAverageRow(
            'Sets per Session',
            _exerciseInsights!.averageSets.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageRow(String label, String value) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
        ),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ExerciseActionSheet extends StatelessWidget {
  const _ExerciseActionSheet();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    Widget actionTile({
      required String value,
      required String label,
      required IconData icon,
      Color? color,
    }) {
      return Material(
        color: colors.field.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key('exercise_action_$value'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).pop(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.42,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.SHEET_RADIUS),
            ),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.18),
              width: AppConstants.CARD_STROKE_WIDTH,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXERCISE ACTIONS',
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose what you want to do with this custom exercise.',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  actionTile(
                    value: 'edit',
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                  ),
                  const SizedBox(height: 8),
                  actionTile(
                    value: 'delete',
                    label: 'Delete',
                    icon: Icons.delete_outline,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
