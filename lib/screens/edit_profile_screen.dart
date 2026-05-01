import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../constants/app_constants.dart';
import '../models/user_data.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static final Logger _logger = Logger('EditProfileScreen');
  UserData? _userProfile;
  bool _isLoading = true;
  bool _hasChanges = false;

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _weightController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    _logger.info('Loading profile for edit screen');
    try {
      final profile = UserService.instance.currentProfile;
      if (profile != null) {
        _logger.fine('Loaded profile for ${profile.name}');
        setState(() {
          _userProfile = profile;
          _nameController.text = profile.name;
          _ageController.text = profile.age.toString();
          if (profile.weightHistory.isNotEmpty) {
            _weightController.text = profile.weightHistory.last.value
                .toStringAsFixed(1);
          }
          _isLoading = false;
        });
      } else {
        _logger.warning('No profile available to edit');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to load profile for edit screen', e, stackTrace);
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load profile: ${e.toString()}');
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveUserProfile() async {
    if (_userProfile == null) {
      _logger.warning('Skipping profile save because no profile is loaded');
      return;
    }

    try {
      _logger.info('Saving edited profile for ${_userProfile!.name}');
      final currentWeight =
          double.tryParse(_weightController.text) ??
          _userProfile!.weightHistory.last.value;
      final weightHistory = List<WeightEntry>.from(_userProfile!.weightHistory);
      weightHistory.add(
        WeightEntry(timestamp: DateTime.now(), value: currentWeight),
      );

      final updatedProfile = UserData(
        name: _nameController.text.trim(),
        birthdate: _calculateBirthdate(
          int.tryParse(_ageController.text) ?? _userProfile!.age,
        ),
        units: _userProfile!.units,
        weightHistory: weightHistory,
        createdAt: _userProfile!.createdAt,
        theme: _userProfile!.theme,
      );

      await UserService.instance.saveUserProfile(updatedProfile);
      _logger.info('Profile saved successfully for ${updatedProfile.name}');
      setState(() {
        _userProfile = updatedProfile;
        _hasChanges = false;
      });

      if (mounted) {
        _showCupertinoToast('Profile updated');
        Navigator.of(
          context,
        ).pop(true); // Return true to indicate changes were saved
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to save edited profile', e, stackTrace);
      if (mounted) {
        _showErrorDialog('Failed to update profile: ${e.toString()}');
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
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: colors.overlayStrong.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
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

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldDiscard = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to go back?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Discard'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  Future<void> _confirmAndPopIfNeeded() async {
    final shouldPop = await _onWillPop();
    if (!mounted || !shouldPop) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = topPadding + kToolbarHeight;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !_hasChanges) {
          return;
        }

        unawaited(_confirmAndPopIfNeeded());
      },
      child: Scaffold(
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
                    child: SafeArea(
                      bottom: false,
                      child: _buildHeaderContent(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
              onPressed: () async {
                final shouldPop = await _onWillPop();
                if (shouldPop && mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Icon(
                CupertinoIcons.back,
                color: colorScheme.onSurface,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('Edit Profile', style: textTheme.titleLarge)),
            if (_hasChanges)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _saveUserProfile,
                child: Text('Save', style: textTheme.labelLarge),
              ),
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
        SliverToBoxAdapter(child: SizedBox(height: headerHeight + 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildProfileSection(),
                const SizedBox(height: 24),
                _buildUnitsSection(),
                const SizedBox(height: 32),
                if (_hasChanges) _buildSaveButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
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
              child: Text('Personal Information', style: textTheme.titleLarge),
            ),
            _buildEditableTextField(
              controller: _nameController,
              placeholder: 'Enter your name',
              label: 'Name',
              prefixIcon: CupertinoIcons.person_fill,
            ),
            _buildDivider(),
            _buildEditableTextField(
              controller: _ageController,
              placeholder: 'Enter your age',
              label: 'Age',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: CupertinoIcons.calendar,
            ),
            _buildDivider(),
            _buildEditableTextField(
              controller: _weightController,
              placeholder: 'Enter your weight',
              label: 'Weight (${_userProfile?.weightUnit})',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              prefixIcon: CupertinoIcons.gauge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsSection() {
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
              child: Text('Units', style: textTheme.titleLarge),
            ),
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: Icon(
                  CupertinoIcons.gauge,
                  color: colors.textSecondary,
                  size: 24,
                ),
                title: Text('Weight Units', style: textTheme.titleSmall),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: colors.field,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CupertinoSlidingSegmentedControl<Units>(
                    backgroundColor: colors.field,
                    thumbColor: colorScheme.primary,
                    groupValue: _userProfile?.units ?? Units.metric,
                    children: {
                      Units.metric: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          Units.metric.weightUnit,
                          style: textTheme.labelMedium,
                        ),
                      ),
                      Units.imperial: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          Units.imperial.weightUnit,
                          style: textTheme.labelMedium,
                        ),
                      ),
                    },
                    onValueChanged: (value) {
                      if (value != null) {
                        _updateUnits(value);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUnits(Units newUnits) async {
    if (_userProfile == null) return;

    try {
      final updatedProfile = _userProfile!.copyWith(units: newUnits);
      await UserService.instance.saveUserProfile(updatedProfile);
      setState(() {
        _userProfile = updatedProfile;
        _weightController.text = _userProfile!.weightHistory.last.value
            .toStringAsFixed(1);
        _hasChanges = true;
      });

      if (mounted) {
        _showCupertinoToast('Units updated');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to update units: ${e.toString()}');
      }
    }
  }

  Widget _buildEditableTextField({
    required TextEditingController controller,
    required String placeholder,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    IconData? prefixIcon,
  }) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(prefixIcon, color: colors.textSecondary, size: 24),
                  const SizedBox(width: 12),
                ],
                Text(label, style: textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              placeholderStyle: textTheme.bodyLarge?.copyWith(
                color: colors.textTertiary,
              ),
              style: textTheme.bodyLarge,
              decoration: BoxDecoration(
                color: colors.field,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              onChanged: (_) => _onFieldChanged(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final textTheme = context.appText;

    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: context.appScheme.primary,
        borderRadius: BorderRadius.circular(12),
        onPressed: _saveUserProfile,
        child: Text(
          'Save Changes',
          style: textTheme.labelLarge?.copyWith(
            color: context.appScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: Theme.of(context).dividerColor,
      indent: 16,
      endIndent: 16,
    );
  }

  DateTime _calculateBirthdate(int age) {
    final now = DateTime.now();
    return DateTime(now.year - age, now.month, now.day);
  }
}
