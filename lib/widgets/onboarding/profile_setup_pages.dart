import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../models/user_data.dart';
import '../../theme/app_theme.dart';
import '../weight_picker_wheel.dart';
import 'onboarding_common.dart';

class NamePage extends StatefulWidget {
  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const NamePage({
    super.key,
    required this.nameController,
    required this.nameFocusNode,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;
    final theme = Theme.of(context);

    return OnboardingStepLayout(
      current: 1,
      total: 5,
      onBack: widget.onBack,
      title: 'What should we call you?',
      subtitle:
          'This name labels your profile and stays on this device unless you export a backup.',
      footer: OnboardingNavigationButtons(
        canContinue: widget.nameController.text.trim().isNotEmpty,
        onNext: widget.onNext,
      ),
      child: CupertinoTextField(
        placeholder: 'Enter your name',
        textAlign: TextAlign.center,
        style: textTheme.titleLarge,
        placeholderStyle: textTheme.titleLarge?.copyWith(
          color: colors.textTertiary,
        ),
        decoration: BoxDecoration(
          color: colors.field,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        padding: const EdgeInsets.all(16),
        controller: widget.nameController,
        focusNode: widget.nameFocusNode,
        onChanged: (_) {
          setState(() {});
        },
      ),
    );
  }
}

class AgePage extends StatelessWidget {
  final int age;
  final ValueChanged<int> onAgeChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const AgePage({
    super.key,
    required this.age,
    required this.onAgeChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final theme = Theme.of(context);

    return OnboardingStepLayout(
      current: 2,
      total: 5,
      onBack: onBack,
      title: 'How old are you?',
      subtitle:
          'This keeps your training stats and age-based context accurate on this device.',
      footer: OnboardingNavigationButtons(canContinue: true, onNext: onNext),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: context.appScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: CupertinoPicker(
          itemExtent: 50,
          scrollController: FixedExtentScrollController(initialItem: age - 13),
          onSelectedItemChanged: (index) {
            onAgeChanged(index + 13);
          },
          children: List.generate(88, (index) {
            final ageValue = index + 13;
            return Center(
              child: Text('$ageValue years old', style: textTheme.titleMedium),
            );
          }),
        ),
      ),
    );
  }
}

// policy: allow-public-api onboarding step reused by screen-level flow tests.
class GenderPage extends StatelessWidget {
  final Gender? gender;
  final ValueChanged<Gender> onGenderChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const GenderPage({
    super.key,
    required this.gender,
    required this.onGenderChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      current: 3,
      total: 5,
      onBack: onBack,
      title: 'Gender',
      subtitle: 'Optional. Pick what fits your profile, or skip the detail.',
      footer: OnboardingNavigationButtons(
        canContinue: gender != null,
        onNext: onNext,
      ),
      child: Column(
        children: [
          UnitOption(
            title: 'Female',
            isSelected: gender == Gender.female,
            onTap: () => onGenderChanged(Gender.female),
          ),
          const SizedBox(height: 16),
          UnitOption(
            title: 'Male',
            isSelected: gender == Gender.male,
            onTap: () => onGenderChanged(Gender.male),
          ),
          const SizedBox(height: 16),
          UnitOption(
            title: 'Rather not say',
            isSelected: gender == Gender.ratherNotSay,
            onTap: () => onGenderChanged(Gender.ratherNotSay),
          ),
        ],
      ),
    );
  }
}

class UnitsPage extends StatelessWidget {
  final Units? units;
  final ValueChanged<Units> onUnitsChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const UnitsPage({
    super.key,
    required this.units,
    required this.onUnitsChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      current: 4,
      total: 5,
      onBack: onBack,
      title: 'Preferred units',
      subtitle:
          'Choose how weights and measurements should appear throughout the app.',
      footer: OnboardingNavigationButtons(
        canContinue: units != null,
        onNext: onNext,
      ),
      child: Column(
        children: [
          UnitOption(
            title: 'Metric',
            subtitle: 'Kilograms, centimeters',
            isSelected: units == Units.metric,
            onTap: () => onUnitsChanged(Units.metric),
          ),
          const SizedBox(height: 16),
          UnitOption(
            title: 'Imperial',
            subtitle: 'Pounds, feet, and inches',
            isSelected: units == Units.imperial,
            onTap: () => onUnitsChanged(Units.imperial),
          ),
        ],
      ),
    );
  }
}

class WeightPage extends StatelessWidget {
  final double weight;
  final Units units;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const WeightPage({
    super.key,
    required this.weight,
    required this.units,
    required this.onWeightChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingStepLayout(
      current: 5,
      total: 5,
      onBack: onBack,
      title: 'Current weight',
      subtitle:
          'Store a starting point on this device so you can look back on progress later.',
      footer: OnboardingNavigationButtons(canContinue: true, onNext: onNext),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: context.appScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: WeightPickerWheel(
          weight: weight,
          units: units,
          onWeightChanged: onWeightChanged,
        ),
      ),
    );
  }
}

class UnitOption extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const UnitOption({
    super.key,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? colorScheme.primary : theme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    color: colorScheme.primary,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
