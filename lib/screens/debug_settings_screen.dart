import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/workout.dart';
import '../services/database_service.dart';
import '../services/debug_data_service.dart';
import '../services/user_service.dart';
import '../services/workout_service.dart';
import '../services/workout_template_service.dart';
import '../theme/app_theme.dart';

class DebugSettingsScreen extends StatefulWidget {
  const DebugSettingsScreen({super.key});

  static const bool isEnabled = true;

  @override
  State<DebugSettingsScreen> createState() => _DebugSettingsScreenState();
}

class _DebugSettingsScreenState extends State<DebugSettingsScreen> {
  static final Logger _logger = Logger('DebugSettingsScreen');

  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Debug'),
        backgroundColor: colorScheme.surface.withValues(alpha: 0.92),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDebugSection(),
                const SizedBox(height: 16),
                _buildDangerZoneSection(),
                const SizedBox(height: 24),
                Text(
                  'Developer-only tools for seeding and repairing local data.',
                  style: textTheme.bodySmall?.copyWith(
                    color: context.appColors.textTertiary,
                  ),
                ),
              ],
            ),
            if (_isBusy)
              Positioned.fill(
                child: Container(
                  color: colorScheme.scrim.withValues(alpha: 0.18),
                  child: const Center(child: CupertinoActivityIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugSection() {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text('Debug Menu', style: textTheme.titleLarge),
            ),
            _buildActionTile(
              icon: CupertinoIcons.hammer_fill,
              iconColor: colors.warning,
              title: 'Generate History Data',
              subtitle: 'Fill the last 2 years with realistic sample workouts',
              onTap: _generateDebugData,
            ),
            _buildDivider(context),
            _buildActionTile(
              icon: CupertinoIcons.refresh_circled_solid,
              iconColor: colorScheme.primary,
              title: 'Rebuild Workout Achievements',
              subtitle: 'Clear and recalculate achievements for past workouts',
              onTap: _rebuildHistoricalAchievements,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneSection() {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text('Danger Zone', style: textTheme.titleLarge),
            ),
            _buildActionTile(
              icon: CupertinoIcons.trash_fill,
              iconColor: colorScheme.error,
              title: 'Clear All Data',
              titleColor: colorScheme.error,
              subtitle: 'Permanently delete all data and profile',
              onTap: _clearAllData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    final textTheme = context.appText;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _isBusy ? null : onTap,
        child: ListTile(
          leading: Icon(icon, color: iconColor, size: 22),
          title: Text(
            title,
            style: textTheme.bodyLarge?.copyWith(color: titleColor),
          ),
          subtitle: subtitle == null ? null : Text(subtitle),
          trailing: Icon(
            CupertinoIcons.chevron_right,
            color: context.appColors.textSecondary,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: Theme.of(context).dividerColor,
      indent: 58,
    );
  }

  Future<void> _generateDebugData() async {
    _logger.info('Showing debug data generation confirmation');
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Generate Data'),
        content: const Text(
          'This will add roughly 300-400 workouts to your history over the last 2 years.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            child: const Text('Generate'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await _runBusyAction(() async {
      await DebugDataService.instance.generateDebugData();
      if (mounted) {
        _showCupertinoToast('Debug data generated');
      }
    }, onErrorPrefix: 'Failed to generate data');
  }

  Future<void> _rebuildHistoricalAchievements() async {
    final completedCount = WorkoutService.instance.workouts
        .where((workout) => workout.status == WorkoutStatus.completed)
        .length;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Rebuild Achievements'),
        content: Text(
          completedCount == 0
              ? 'No completed workouts are loaded right now. Continue anyway?'
              : 'This will clear and recalculate achievements for $completedCount completed workouts.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            child: const Text('Rebuild'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await _runBusyAction(() async {
      final rebuiltCount =
          await WorkoutService.instance.rebuildAchievementsForCompletedWorkouts();
      if (mounted) {
        _showCupertinoToast('Rebuilt achievements for $rebuiltCount workouts');
      }
    }, onErrorPrefix: 'Failed to rebuild achievements');
  }

  Future<void> _clearAllData() async {
    _logger.warning('Showing clear-all-data confirmation');
    final TextEditingController confirmController = TextEditingController();
    String confirmationText = '';
    const String requiredText = 'DELETE MY DATA';

    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final colors = context.appColors;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return CupertinoAlertDialog(
              title: const Text('Clear All Data'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This will permanently delete all your workout data and profile. This action cannot be undone.',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please type "$requiredText" below to confirm:',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: confirmController,
                    placeholder: requiredText,
                    autocorrect: false,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        confirmationText = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: confirmationText == requiredText
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  child: Text(
                    'Delete All',
                    style: textTheme.bodyLarge?.copyWith(
                      color: confirmationText == requiredText
                          ? colorScheme.error
                          : colors.textTertiary,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    confirmController.dispose();

    if (confirmed != true) {
      return;
    }

    await _runBusyAction(() async {
      await DatabaseService.instance.clearAllData();
      await UserService.instance.clearUserData();
      await WorkoutService.instance.clearUserWorkouts();
      await WorkoutTemplateService.instance.clearUserTemplatesAndFolders();
      if (mounted) {
        _showCupertinoToast('All data cleared');
        await Future.delayed(const Duration(seconds: 1));
        exit(0);
      }
    }, onErrorPrefix: 'Failed to clear all data');
  }

  Future<void> _runBusyAction(
    Future<void> Function() action, {
    required String onErrorPrefix,
  }) async {
    setState(() => _isBusy = true);
    try {
      await action();
    } catch (error, stackTrace) {
      _logger.severe(onErrorPrefix, error, stackTrace);
      if (mounted) {
        _showErrorDialog('$onErrorPrefix: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  void _showCupertinoToast(String message) {
    final colors = context.appColors;
    final textTheme = context.appText;
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom + 80,
        left: MediaQuery.of(context).size.width * 0.15,
        right: MediaQuery.of(context).size.width * 0.15,
        child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceAlt.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  decoration: TextDecoration.none,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), overlayEntry.remove);
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
