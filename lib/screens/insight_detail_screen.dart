import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pull_down_button/pull_down_button.dart';
import '../constants/app_constants.dart';
import '../services/insights_service.dart';

class InsightDetailScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String unit;
  final Map<String, dynamic> initialFilters;
  final Future<dynamic> Function(String timeframe, int months, Map<String, dynamic> filters) dataFetcher;
  final Widget Function(BuildContext context, dynamic data, String timeframe, int months) chartBuilder;
  final Widget? Function(BuildContext context, dynamic data, String timeframe, int months)? axisBuilder;
  final String Function(dynamic data) mainValueBuilder;
  final String Function(dynamic data) subLabelBuilder;
  final int Function(dynamic data)? dataCountBuilder;
  final double Function(String timeframe)? itemWidthBuilder;
  final String? heroTag;

  const InsightDetailScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.unit,
    this.initialFilters = const {},
    required this.dataFetcher,
    required this.chartBuilder,
    this.axisBuilder,
    required this.mainValueBuilder,
    required this.subLabelBuilder,
    this.dataCountBuilder,
    this.itemWidthBuilder,
    this.heroTag,
  });

  @override
  State<InsightDetailScreen> createState() => _InsightDetailScreenState();
}

class _InsightDetailScreenState extends State<InsightDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedTimeframe = '6M';
  int _selectedMonths = 6;
  dynamic _data;
  bool _isLoading = true;

  // Filters
  String? _selectedWorkoutName;
  String? _selectedMuscleGroup;
  String? _selectedEquipment;
  bool? _selectedBodyWeight;
  String? _selectedExerciseName;
  List<String> _availableWorkoutNames = [];

  final List<Map<String, dynamic>> _timeframeOptions = [
    {'label': '1W', 'months': 0},
    {'label': '1M', 'months': 1},
    {'label': '3M', 'months': 3},
    {'label': '6M', 'months': 6},
    {'label': '1Y', 'months': 12},
    {'label': '2Y', 'months': 24},
    {'label': 'All', 'months': 999},
  ];

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _loadAvailableWorkouts();
    _loadData();
  }

  void _initializeFilters() {
    _selectedWorkoutName = widget.initialFilters['workoutName'];
    _selectedMuscleGroup = widget.initialFilters['muscleGroup'];
    _selectedEquipment = widget.initialFilters['equipment'];
    _selectedBodyWeight = widget.initialFilters['isBodyWeight'];
    _selectedExerciseName = widget.initialFilters['exerciseName'];
    
    // Also initialize timeframe if passed in initialFilters (optional, but good for consistency)
    if (widget.initialFilters.containsKey('timeframe')) {
      _selectedTimeframe = widget.initialFilters['timeframe'];
      // Map timeframe to months
      final option = _timeframeOptions.firstWhere(
        (opt) => opt['label'] == _selectedTimeframe,
        orElse: () => {'months': 6},
      );
      _selectedMonths = option['months'];
    }
  }

  Future<void> _loadAvailableWorkouts() async {
    final names = await InsightsService.instance.getAvailableWorkoutNames();
    if (mounted) {
      setState(() {
        _availableWorkoutNames = names;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final filters = {
        'workoutName': _selectedWorkoutName,
        'muscleGroup': _selectedMuscleGroup,
        'equipment': _selectedEquipment,
        'isBodyWeight': _selectedBodyWeight,
        'exerciseName': _selectedExerciseName,
      };
      
      // Always fetch a large history (e.g., 60 months/5 years) to allow scrolling into the past
      // The timeframe parameter is still passed so the fetcher can decide on grouping (weekly vs monthly)
      const int monthsToFetch = 60;

      final data = await widget.dataFetcher(_selectedTimeframe, monthsToFetch, filters);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
        
        // Scroll to the end (most recent data) after the layout is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            // Calculate scroll position based on timeframe
            // We want to show the selected timeframe at the end
            // But allow scrolling back further if data exists
            
            // For now, just jump to end as requested, but we could calculate offset
            // based on item width * number of items in selected timeframe
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _onTimeframeChanged(String label, int months) {
    setState(() {
      _selectedTimeframe = label;
      _selectedMonths = months;
    });
    _loadData();
  }

  void _onWorkoutFilterChanged(String? workoutName) {
    setState(() {
      _selectedWorkoutName = workoutName;
    });
    _loadData();
  }

  void _onMuscleFilterChanged(String? muscleGroup) {
    setState(() {
      _selectedMuscleGroup = muscleGroup;
    });
    _loadData();
  }

  void _onEquipmentFilterChanged(String? equipment) {
    setState(() {
      _selectedEquipment = equipment;
    });
    _loadData();
  }

  void _onBodyWeightFilterChanged() {
    setState(() {
      _selectedBodyWeight = _selectedBodyWeight == true ? null : true;
    });
    _loadData();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedWorkoutName = null;
      _selectedMuscleGroup = null;
      _selectedEquipment = null;
      _selectedBodyWeight = null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Hero(
        tag: widget.heroTag ?? 'insight_card_${widget.title}',
        child: Material(
          color: Colors.black,
          child: Column(
            children: [
              // Filters
              _buildFilters(),
              
              Expanded(
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Icon(widget.icon, color: widget.color, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    color: widget.color,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Main Stats
                      if (_data != null) ...[
                        Text(
                          widget.mainValueBuilder(_data),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          widget.subLabelBuilder(_data),
                          style: const TextStyle(
                            color: AppConstants.TEXT_TERTIARY_COLOR,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                            // Chart
                            if (_data != null)
                              SizedBox(
                                height: 350,
                                child: Row(
                                  children: [
                                    // Fixed Y-Axis
                                    if (widget.axisBuilder != null)
                                      Builder(
                                        builder: (context) {
                                          final axisWidget = widget.axisBuilder!(context, _data, _selectedTimeframe, _selectedMonths);
                                          if (axisWidget == null) return const SizedBox.shrink();
                                          return SizedBox(
                                            width: 40,
                                            child: axisWidget,
                                          );
                                        },
                                      ),
                                    
                                    // Scrollable Chart
                                    Expanded(
                                      child: SingleChildScrollView(
                                        controller: _scrollController,
                                        scrollDirection: Axis.horizontal,
                                        child: Container(
                                          constraints: BoxConstraints(
                                            minWidth: MediaQuery.of(context).size.width - 40 - (widget.axisBuilder?.call(context, _data, _selectedTimeframe, _selectedMonths) != null ? 40 : 0),
                                          ),
                                          alignment: Alignment.center,
                                          child: SizedBox(
                                            width: widget.dataCountBuilder != null
                                                ? widget.dataCountBuilder!(_data) * (widget.itemWidthBuilder?.call(_selectedTimeframe) ?? 50.0)
                                                : MediaQuery.of(context).size.width - 40,
                                            height: 350,
                                            child: widget.chartBuilder(context, _data, _selectedTimeframe, _selectedMonths),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
    );
  }

  Widget _buildFilters() {
    final muscleGroups = AppMuscleGroup.values
        .where((group) => group != AppMuscleGroup.na)
        .map((group) => group.displayName)
        .toList();
    
    final equipmentList = EquipmentType.values
        .map((equipment) => equipment.displayName)
        .toList();

    final bool hasAnyFilter = _selectedWorkoutName != null ||
        _selectedMuscleGroup != null ||
        _selectedEquipment != null ||
        _selectedBodyWeight != null;

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (hasAnyFilter) ...[
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _clearAllFilters,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppConstants.WORKOUT_BUTTON_BG_COLOR,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppConstants.DIVIDER_COLOR, width: 0.5),
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        size: 16,
                        color: AppConstants.TEXT_SECONDARY_COLOR,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Exercise Filter (Read-only/Preselected)
                if (_selectedExerciseName != null) ...[
                  _buildFilterTag(
                    context: context,
                    title: 'Exercise',
                    isSelected: true,
                    items: [_selectedExerciseName!],
                    onItemSelected: (val) {}, // Read-only
                    selectedItem: _selectedExerciseName,
                  ),
                  const SizedBox(width: 8),
                ],
                // Workout Filter
                _buildFilterTag(
                  context: context,
                  title: 'Workout',
                  isSelected: _selectedWorkoutName != null,
                  items: _availableWorkoutNames,
                  onItemSelected: (val) => _onWorkoutFilterChanged(val == _selectedWorkoutName ? null : val),
                  selectedItem: _selectedWorkoutName,
                ),
                const SizedBox(width: 8),
                // Muscle Filter
                _buildFilterTag(
                  context: context,
                  title: 'Muscle',
                  isSelected: _selectedMuscleGroup != null,
                  items: muscleGroups,
                  onItemSelected: (val) => _onMuscleFilterChanged(val == _selectedMuscleGroup ? null : val),
                  selectedItem: _selectedMuscleGroup,
                ),
                const SizedBox(width: 8),
                // Equipment Filter
                _buildFilterTag(
                  context: context,
                  title: 'Equipment',
                  isSelected: _selectedEquipment != null,
                  items: equipmentList,
                  onItemSelected: (val) => _onEquipmentFilterChanged(val == _selectedEquipment ? null : val),
                  selectedItem: _selectedEquipment,
                ),
                const SizedBox(width: 8),
                // Bodyweight Filter
                _buildBodyweightTag(
                  context: context,
                  isSelected: _selectedBodyWeight == true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildTimeframeDropdown(context),
        ],
      ),
    );
  }

  Widget _buildFilterTag({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required List<String> items,
    required Function(String) onItemSelected,
    required String? selectedItem,
  }) {
    return PullDownButton(
      itemBuilder: (context) => items
          .map((item) => PullDownMenuItem.selectable(
                title: item,
                selected: selectedItem == item,
                onTap: () => onItemSelected(item),
              ))
          .toList(),
      buttonBuilder: (context, showMenu) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: showMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.ACCENT_COLOR : AppConstants.WORKOUT_BUTTON_BG_COLOR,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isSelected ? AppConstants.ACCENT_COLOR : AppConstants.DIVIDER_COLOR,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSelected ? selectedItem! : title,
                style: AppConstants.IOS_NORMAL_TEXT_STYLE.copyWith(
                  color: isSelected ? Colors.white : AppConstants.TEXT_SECONDARY_COLOR,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_down,
                size: 12,
                color: isSelected ? Colors.white : AppConstants.TEXT_SECONDARY_COLOR,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyweightTag({
    required BuildContext context,
    required bool isSelected,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _onBodyWeightFilterChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.ACCENT_COLOR : AppConstants.WORKOUT_BUTTON_BG_COLOR,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? AppConstants.ACCENT_COLOR : AppConstants.DIVIDER_COLOR,
            width: 0.5,
          ),
        ),
        child: Text(
          'Bodyweight',
          style: AppConstants.IOS_NORMAL_TEXT_STYLE.copyWith(
            color: isSelected ? Colors.white : AppConstants.TEXT_SECONDARY_COLOR,
            fontWeight: isSelected ? FontWeight.w600 : null,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeDropdown(BuildContext context) {
    return PullDownButton(
      itemBuilder: (context) => _timeframeOptions
          .map((option) => PullDownMenuItem.selectable(
                title: option['label'],
                selected: _selectedTimeframe == option['label'],
                onTap: () => _onTimeframeChanged(option['label'], option['months']),
              ))
          .toList(),
      buttonBuilder: (context, showMenu) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: showMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: AppConstants.WORKOUT_BUTTON_BG_COLOR,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: AppConstants.DIVIDER_COLOR, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedTimeframe,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                CupertinoIcons.chevron_down,
                size: 16,
                color: AppConstants.TEXT_SECONDARY_COLOR,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
