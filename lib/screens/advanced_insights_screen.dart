import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../screens/exercise_browser_screen.dart';
import '../screens/insights/insights_view_data.dart';
import '../services/insights_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/unit_converter.dart';
import '../widgets/insights/insights_screen_sections.dart';
import '../widgets/main_dock_spacer.dart';

// policy: allow-public-api dedicated route for the existing advanced insights dashboard.
class AdvancedInsightsScreen extends StatefulWidget {
  const AdvancedInsightsScreen({super.key});

  @override
  State<AdvancedInsightsScreen> createState() => _AdvancedInsightsScreenState();
}

class _AdvancedInsightsScreenState extends State<AdvancedInsightsScreen> {
  String _selectedTimeframe = '6M';
  String? _selectedWorkoutName;
  String? _selectedMuscleGroup;
  String? _selectedEquipment;
  bool? _selectedBodyWeight;
  List<String> _availableWorkoutNames = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableWorkouts();
  }

  Future<void> _loadAvailableWorkouts() async {
    final names = await InsightsService.instance.getAvailableWorkoutNames();
    if (mounted) {
      setState(() {
        _availableWorkoutNames = names;
      });
    }
  }

  void _onTimeframeChanged(String label, int months) {
    setState(() {
      _selectedTimeframe = label;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedWorkoutName = null;
      _selectedMuscleGroup = null;
      _selectedEquipment = null;
      _selectedBodyWeight = null;
    });
  }

  Future<void> _showExercisePicker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseBrowserScreen()),
    );
  }

  Future<void> _refreshInsights() async {
    await InsightsService.instance.clearCache();
    await _loadAvailableWorkouts();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = InsightsFilterSnapshot(
      timeframe: _selectedTimeframe,
      workoutName: _selectedWorkoutName,
      muscleGroup: _selectedMuscleGroup,
      equipment: _selectedEquipment,
      isBodyWeight: _selectedBodyWeight,
    );

    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _refreshInsights,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  centerTitle: true,
                  title: const Text('Advanced Insights'),
                  leading: IconButton(
                    icon: Icon(
                      CupertinoIcons.chevron_back,
                      color: context.appScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: InsightsFilterHeaderDelegate(
                    timeframeOptions: insightsTimeframeOptions,
                    selectedTimeframe: _selectedTimeframe,
                    selectedWorkoutName: _selectedWorkoutName,
                    selectedMuscleGroup: _selectedMuscleGroup,
                    selectedEquipment: _selectedEquipment,
                    selectedBodyWeight: _selectedBodyWeight,
                    availableWorkoutNames: _availableWorkoutNames,
                    onWorkoutChanged: (value) {
                      setState(() {
                        _selectedWorkoutName = value;
                      });
                    },
                    onMuscleChanged: (value) {
                      setState(() {
                        _selectedMuscleGroup = value;
                      });
                    },
                    onEquipmentChanged: (value) {
                      setState(() {
                        _selectedEquipment = value;
                      });
                    },
                    onBodyWeightChanged: () {
                      setState(() {
                        _selectedBodyWeight = _selectedBodyWeight == true
                            ? null
                            : true;
                      });
                    },
                    onClearAll: _clearAllFilters,
                    onTimeframeChanged: _onTimeframeChanged,
                  ),
                ),
                SliverToBoxAdapter(
                  child: InsightsGraphCardsGrid(filters: filters),
                ),
                SliverToBoxAdapter(
                  child: InsightsQuickActionsCard(
                    onBrowseExercises: _showExercisePicker,
                  ),
                ),
                SliverToBoxAdapter(
                  child: InsightsTrendsSection(
                    filters: filters,
                    weightUnitLabel: _getWeightUnitLabel(),
                  ),
                ),
                const SliverToBoxAdapter(child: MainDockSpacer(extraSpace: 20)),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getWeightUnitLabel() {
    final units = UserService.instance.currentProfile?.units ?? Units.metric;
    return UnitConverter.getWeightUnit(units.name);
  }
}
