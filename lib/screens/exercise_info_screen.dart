import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/exercise.dart';
import '../services/insights/exercise_trend_provider.dart';
import '../services/insights_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
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
        exerciseName: widget.exercise.slug,
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
                          exercise: widget.exercise,
                          height: 140,
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

    return SliverAppBar(
      pinned: true,
      stretch: true,
      backgroundColor: AppThemeColors.clear,
      elevation: 0,
      expandedHeight: 120.0,
      leading: IconButton(
        icon: Icon(CupertinoIcons.back, color: context.appScheme.onSurface),
        onPressed: () => Navigator.of(context).pop(),
      ),
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
                title: Text(widget.exercise.name, style: textTheme.titleMedium),
                background: Container(color: AppThemeColors.clear),
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
          widget.exercise.primaryMuscleGroup.name,
          isPrimary: true,
        ),
        if (widget.exercise.secondaryMuscleGroups.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildDetailRow(
            'Synergists',
            widget.exercise.secondaryMuscleGroups.map((m) => m.name).join(', '),
          ),
        ],
        if (widget.exercise.equipment.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildDetailRow('Equipment', widget.exercise.equipment),
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
                  if (widget.exercise.instructions.isNotEmpty)
                    ...widget.exercise.instructions.asMap().entries.map((
                      entry,
                    ) {
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
                  color: AppConstants.ACCENT_COLOR_GREEN,
                  data: _exerciseInsights!.monthlyFrequency,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TrendInsightCard(
          title: 'Volume',
          color: AppConstants.ACCENT_COLOR,
          unit: _useKg ? 'kg' : 'lbs',
          icon: CupertinoIcons.chart_bar_fill,
          filters: filters,
          provider: ExerciseTrendProvider(
            widget.exercise.slug,
            ExerciseTrendType.volume,
          ),
          subLabelBuilder: (_) => _useKg ? 'kg' : 'lbs',
        ),
        const SizedBox(height: 16),
        TrendInsightCard(
          title: 'Max Weight',
          color: AppConstants.ACCENT_COLOR_ORANGE,
          unit: _useKg ? 'kg' : 'lbs',
          icon: CupertinoIcons.arrow_up_circle_fill,
          filters: filters,
          provider: ExerciseTrendProvider(
            widget.exercise.slug,
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
