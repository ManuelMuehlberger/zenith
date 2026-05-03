import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../constants/app_constants.dart';
import '../models/user_data.dart';
import '../services/database_service.dart';
import '../services/debug_data_service.dart';
import '../services/user_service.dart';
import '../services/workout_service.dart';
import '../services/workout_template_service.dart';
import '../theme/app_theme.dart';
import '../widgets/settings/settings_data_section.dart';
import '../widgets/settings/settings_profile_section.dart';
import '../widgets/settings/settings_theme_section.dart';
import '../widgets/settings/settings_timeline_section.dart';
import '../widgets/settings/settings_units_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final Logger _logger = Logger('SettingsScreen');
  UserData? _userProfile;
  bool _isLoading = true;
  bool _showDebugMenu = true;
  int _versionTapCount = 0;

  @override
  void initState() {
    super.initState();
    _logger.info('Opening settings screen');
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    _logger.info('Loading settings profile data');
    try {
      final profile = UserService.instance.currentProfile;
      if (profile != null) {
        _logger.fine('Loaded settings profile for ${profile.name}');
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      } else {
        _logger.warning('No profile available for settings screen');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to load settings profile data', e, stackTrace);
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load profile: ${e.toString()}');
    }
  }

  Future<void> _updateUnits(Units newUnits) async {
    if (_userProfile == null) {
      _logger.warning('Skipping unit update because no profile is loaded');
      return;
    }

    try {
      _logger.info('Updating units from ${_userProfile!.units} to $newUnits');
      final updatedProfile = _userProfile!.copyWith(units: newUnits);
      await UserService.instance.saveUserProfile(updatedProfile);
      setState(() {
        _userProfile = updatedProfile;
      });

      if (mounted) {
        _showCupertinoToast('Units updated');
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to update units', e, stackTrace);
      if (mounted) {
        _showErrorDialog('Failed to update units: ${e.toString()}');
      }
    }
  }

  Future<void> _updateThemePreference(AppThemePreference newPreference) async {
    if (_userProfile == null) {
      _logger.warning('Skipping theme update because no profile is loaded');
      return;
    }

    try {
      _logger.info(
        'Updating theme from ${_userProfile!.theme} to ${newPreference.storageValue}',
      );
      final updatedProfile = _userProfile!.copyWith(
        theme: newPreference.storageValue,
      );
      await UserService.instance.saveUserProfile(updatedProfile);
      setState(() {
        _userProfile = updatedProfile;
      });

      if (mounted) {
        _showCupertinoToast('Appearance updated');
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to update theme preference', e, stackTrace);
      if (mounted) {
        _showErrorDialog('Failed to update appearance: ${e.toString()}');
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
            opacity: 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceAlt.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16.0),
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
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
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

    if (confirmed == true) {
      _logger.warning('Confirmed full local data deletion');
      await DatabaseService.instance.clearAllData();
      await UserService.instance.clearUserData();
      await WorkoutService.instance.clearUserWorkouts();
      await WorkoutTemplateService.instance.clearUserTemplatesAndFolders();
      if (mounted) {
        _showCupertinoToast('All data cleared');
        await Future.delayed(const Duration(seconds: 1));
        exit(0);
      }
    } else {
      _logger.fine('Cancelled full local data deletion');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = topPadding + kToolbarHeight;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(child: _buildMainContent(headerHeight)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                  sigmaY: AppConstants.GLASS_BLUR_SIGMA,
                ),
                child: Container(
                  height: headerHeight,
                  color: context.appColors.overlayMedium,
                  child: SafeArea(bottom: false, child: _buildHeaderContent()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent() {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;

    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              child: Icon(
                CupertinoIcons.back,
                color: colorScheme.onSurface,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('Settings', style: textTheme.titleLarge)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(double headerHeight) {
    if (_isLoading) {
      return Column(
        children: [
          SizedBox(height: headerHeight),
          const Expanded(
            child: Center(child: CupertinoActivityIndicator(radius: 15)),
          ),
        ],
      );
    }

    if (_userProfile == null) {
      final textTheme = context.appText;

      return Column(
        children: [
          SizedBox(height: headerHeight),
          Expanded(
            child: Center(
              child: Text('No profile found', style: textTheme.bodyLarge),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: headerHeight)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SettingsTimelineSection(),
                const SizedBox(height: 16),
                SettingsProfileSection(
                  userProfile: _userProfile,
                  onProfileUpdated: _loadUserProfile,
                ),
                const SizedBox(height: 16),
                SettingsUnitsSection(
                  userProfile: _userProfile,
                  onUnitsChanged: _updateUnits,
                ),
                const SizedBox(height: 16),
                SettingsThemeSection(
                  userProfile: _userProfile,
                  onThemeChanged: _updateThemePreference,
                ),
                const SizedBox(height: 16),
                const SettingsDataSection(),
                const SizedBox(height: 16),
                if (_showDebugMenu) ...[
                  _buildDebugSection(),
                  const SizedBox(height: 16),
                ],
                _buildAboutSection(),
                const SizedBox(height: 16),
                _buildDataManagementSection(),
              ],
            ),
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
              child: Text('Debug Menu', style: textTheme.titleLarge),
            ),
            ListTile(
              leading: Icon(
                CupertinoIcons.hammer_fill,
                color: colors.warning,
                size: 22,
              ),
              title: Text('Generate History Data', style: textTheme.bodyLarge),
              subtitle: Text(
                'Fill last 2 years with random workouts',
                style: textTheme.bodyMedium,
              ),
              trailing: Icon(
                CupertinoIcons.chevron_right,
                color: colors.textSecondary,
                size: 16,
              ),
              onTap: _generateDebugData,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateDebugData() async {
    _logger.info('Showing debug data generation confirmation');
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Generate Data'),
        content: const Text(
          'This will add ~300-400 workouts to your history over the last 2 years. This operation cannot be easily undone.',
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

    if (confirmed == true) {
      _logger.info('Starting debug data generation');
      setState(() => _isLoading = true);
      try {
        await DebugDataService.instance.generateDebugData();
        _logger.info('Debug data generation completed successfully');
        if (mounted) {
          _showCupertinoToast('Debug data generated');
        }
      } catch (e, stackTrace) {
        _logger.severe('Failed to generate debug data', e, stackTrace);
        if (mounted) {
          _showErrorDialog('Failed to generate data: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      _logger.fine('Cancelled debug data generation');
    }
  }

  Widget _buildDataManagementSection() {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
              child: Text('Danger Zone', style: textTheme.titleLarge),
            ),
            ListTile(
              leading: Icon(
                CupertinoIcons.trash_fill,
                color: colorScheme.error,
                size: 22,
              ),
              title: Text(
                'Clear All Data',
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
              ),
              subtitle: Text(
                'Permanently delete all data and profile',
                style: textTheme.bodyMedium,
              ),
              trailing: Icon(
                CupertinoIcons.chevron_right,
                color: context.appColors.textSecondary,
                size: 16,
              ),
              onTap: _clearAllData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Card(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  CupertinoIcons.lock_shield_fill,
                  color: colors.success,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Privacy First', style: textTheme.titleSmall),
                      Text(
                        'All data stays on your device\nNo cloud, no tracking, no ads',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                setState(() {
                  _versionTapCount++;
                  _logger.finer(
                    'Version easter-egg tap count=$_versionTapCount',
                  );
                  if (_versionTapCount >= 5) {
                    _showDebugMenu = !_showDebugMenu;
                    _versionTapCount = 0;
                    _logger.info('Debug menu toggled: enabled=$_showDebugMenu');
                    _showCupertinoToast(
                      _showDebugMenu
                          ? 'Debug menu enabled'
                          : 'Debug menu disabled',
                    );
                  }
                });
              },
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle_fill,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Workout Tracker', style: textTheme.titleSmall),
                        Text(
                          'Version 1.0.0\nTrack your fitness journey',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  CupertinoIcons.flame_fill,
                  color: colors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Exercise Database', style: textTheme.titleSmall),
                      Text(
                        '312 exercises available',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
