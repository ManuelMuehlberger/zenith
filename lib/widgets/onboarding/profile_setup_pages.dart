import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../models/user_data.dart';
import '../../theme/app_theme.dart';
import '../weight_tumbler_picker.dart';
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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingProgressIndicator(
            current: 1,
            total: 4,
            onBack: widget.onBack,
          ),
          const SizedBox(height: 32),

          Text('What\'s your name?', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'We\'ll use this to personalize your experience',
            style: textTheme.bodyLarge?.copyWith(color: colors.textTertiary),
          ),

          const SizedBox(height: 40),

          CupertinoTextField(
            placeholder: 'Enter your name',
            style: textTheme.titleMedium,
            placeholderStyle: textTheme.titleMedium?.copyWith(
              color: colors.textTertiary,
            ),
            decoration: BoxDecoration(
              color: colors.field,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            padding: const EdgeInsets.all(16),
            controller: widget.nameController,
            focusNode: widget.nameFocusNode,
            onChanged: (text) {
              setState(() {});
            },
          ),

          const Spacer(),

          OnboardingNavigationButtons(
            canContinue: widget.nameController.text.isNotEmpty,
            onNext: widget.onNext,
            onBack: widget.onBack,
          ),
        ],
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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OnboardingProgressIndicator(
                    current: 2,
                    total: 5,
                    onBack: onBack,
                  ),
                  const SizedBox(height: 32),
                  Text('How old are you?', style: textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'This helps us provide better insights',
                    style: textTheme.bodyLarge?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: context.appScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CupertinoPicker(
                      itemExtent: 50,
                      scrollController: FixedExtentScrollController(
                        initialItem: age - 13,
                      ),
                      onSelectedItemChanged: (index) {
                        onAgeChanged(index + 13);
                      },
                      children: List.generate(88, (index) {
                        final ageValue = index + 13;
                        return Center(
                          child: Text(
                            '$ageValue years old',
                            style: textTheme.titleMedium,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          OnboardingNavigationButtons(
            canContinue: true,
            onNext: onNext,
            onBack: onBack,
          ),
        ],
      ),
    );
  }
}

class GenderPage extends StatelessWidget {
  final Gender gender;
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
    final textTheme = context.appText;
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingProgressIndicator(current: 3, total: 5, onBack: onBack),
          const SizedBox(height: 32),
          Text('Gender?', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'We use this to choose a sensible starting weight for the picker',
            style: textTheme.bodyLarge?.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: 40),
          UnitOption(
            title: 'Female',
            subtitle: 'Starts at 60 kg',
            value: Gender.female.storageValue,
            isSelected: gender == Gender.female,
            onTap: () => onGenderChanged(Gender.female),
          ),
          const SizedBox(height: 16),
          UnitOption(
            title: 'Male',
            subtitle: 'Starts at 75 kg',
            value: Gender.male.storageValue,
            isSelected: gender == Gender.male,
            onTap: () => onGenderChanged(Gender.male),
          ),
          const SizedBox(height: 16),
          UnitOption(
            title: 'Rather not say',
            subtitle: 'Starts at 60 kg',
            value: Gender.ratherNotSay.storageValue,
            isSelected: gender == Gender.ratherNotSay,
            onTap: () => onGenderChanged(Gender.ratherNotSay),
          ),
          const Spacer(),
          OnboardingNavigationButtons(
            canContinue: true,
            onNext: onNext,
            onBack: onBack,
          ),
        ],
      ),
    );
  }
}

class UnitsPage extends StatelessWidget {
  final Units units;
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
    final textTheme = context.appText;
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingProgressIndicator(current: 4, total: 5, onBack: onBack),
          const SizedBox(height: 32),

          Text('Preferred units?', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Choose your measurement system',
            style: textTheme.bodyLarge?.copyWith(color: colors.textTertiary),
          ),

          const SizedBox(height: 40),

          UnitOption(
            title: 'Metric',
            subtitle: 'Kilograms, Centimeters',
            value: 'metric',
            isSelected: units == Units.metric,
            onTap: () => onUnitsChanged(Units.metric),
          ),

          const SizedBox(height: 16),

          UnitOption(
            title: 'Imperial',
            subtitle: 'Pounds, Feet & Inches',
            value: 'imperial',
            isSelected: units == Units.imperial,
            onTap: () => onUnitsChanged(Units.imperial),
          ),

          const Spacer(),

          OnboardingNavigationButtons(
            canContinue: true,
            onNext: onNext,
            onBack: onBack,
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
    final textTheme = context.appText;
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingProgressIndicator(current: 5, total: 5, onBack: onBack),
          const SizedBox(height: 32),

          Text('Current weight?', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'This helps track your progress over time',
            style: textTheme.bodyLarge?.copyWith(color: colors.textTertiary),
          ),

          const SizedBox(height: 40),

          Container(
            height: 200,
            decoration: BoxDecoration(
              color: context.appScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: WeightTumblerPicker(
              weight: weight,
              units: units,
              onWeightChanged: onWeightChanged,
            ),
          ),

          const Spacer(),

          OnboardingNavigationButtons(
            canContinue: true,
            onNext: onNext,
            onBack: onBack,
          ),
        ],
      ),
    );
  }
}

class UnitOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const UnitOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? colorScheme.primary : theme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
