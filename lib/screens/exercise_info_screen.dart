import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../services/insights_service.dart';
import '../services/user_service.dart';
import '../widgets/exercise_info/exercise_image_section.dart';
import '../widgets/exercise_info/exercise_muscle_groups_section.dart';
import '../widgets/exercise_info/exercise_instructions_section.dart';
import '../widgets/exercise_info/exercise_stats_section.dart';
import '../constants/app_constants.dart';

class ExerciseInfoScreen extends StatefulWidget {
  final Exercise exercise;
  final int? initialTabIndex;

  const ExerciseInfoScreen({
    super.key,
    required this.exercise,
    this.initialTabIndex,
  });

  @override
  State<ExerciseInfoScreen> createState() => _ExerciseInfoScreenState();
}

class _ExerciseInfoScreenState extends State<ExerciseInfoScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  ExerciseInsights? _exerciseInsights;
  bool _isLoadingInsights = false;
  int _selectedMonths = 6;
  bool _useKg = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 0,
    );
    _loadSettings();
    _loadExerciseInsights();
  }

  @override
  void dispose() {
    UserService.instance.removeListener(_onUserProfileChanged);
    _tabController.dispose();
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

  void _showTimePeriodPicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Select Time Period'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedMonths = 3;
              });
              _loadExerciseInsights();
            },
            child: const Text('3 months'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedMonths = 6;
              });
              _loadExerciseInsights();
            },
            child: const Text('6 months'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedMonths = 12;
              });
              _loadExerciseInsights();
            },
            child: const Text('1 year'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Widget _buildInfoTab(double headerHeight) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: headerHeight),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.PAGE_HORIZONTAL_PADDING),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExerciseImageSection(exercise: widget.exercise),
                SizedBox(height: AppConstants.SECTION_VERTICAL_GAP),
                ExerciseMuscleGroupsSection(exercise: widget.exercise),
                SizedBox(height: AppConstants.SECTION_VERTICAL_GAP),
                ExerciseInstructionsSection(exercise: widget.exercise),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab(double headerHeight) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: headerHeight),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.PAGE_HORIZONTAL_PADDING),
            child: ExerciseStatsSection(
              exerciseInsights: _exerciseInsights,
              isLoading: _isLoadingInsights,
              useKg: _useKg,
              selectedMonths: _selectedMonths,
              onTimePeriodPressed: _showTimePeriodPicker,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(double headerHeight) {
    return TabBarView(
      controller: _tabController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildInfoTab(headerHeight),
        _buildStatsTab(headerHeight),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = topPadding + kToolbarHeight + AppConstants.HEADER_EXTRA_HEIGHT;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildMainContent(headerHeight),
          ),
          // Glass header overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
                child: Container(
                  height: headerHeight,
                  color: AppConstants.HEADER_BG_COLOR_STRONG,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // AppBar content
                        SizedBox(
                          height: kToolbarHeight,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(CupertinoIcons.back, color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              Expanded(
                                child: Text(
                                  widget.exercise.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        // Segmented control
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppConstants.PAGE_HORIZONTAL_PADDING, vertical: 8.0),
                          child: CupertinoSlidingSegmentedControl<int>(
                            children: <int, Widget>{
                              0: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                                child: Text(
                                  'Info',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: _tabController.index == 0 ? CupertinoColors.white : CupertinoColors.secondaryLabel.resolveFrom(context),
                                      ),
                                ),
                              ),
                              1: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                                child: Text(
                                  'Stats',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: _tabController.index == 1 ? CupertinoColors.white : CupertinoColors.secondaryLabel.resolveFrom(context),
                                      ),
                                ),
                              ),
                            },
                            onValueChanged: (int? index) {
                              if (index != null) {
                                setState(() {
                                  _tabController.index = index;
                                });
                              }
                            },
                            groupValue: _tabController.index,
                            backgroundColor: CupertinoColors.systemGrey5.resolveFrom(context),
                            thumbColor: CupertinoColors.activeBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
