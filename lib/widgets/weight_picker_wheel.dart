import 'package:flutter/cupertino.dart';

import '../constants/app_constants.dart';
import '../models/user_data.dart';
import '../theme/app_theme.dart';

// policy: allow-public-api shared picker overlay sizing tokens used by onboarding and workout completion.
class PickerSelectionStyle {
  const PickerSelectionStyle._();

  static const double defaultRadius = 8;
  static const double emphasizedRadius = 28;
}

// policy: allow-public-api shared Cupertino picker wrapper used by common weight-entry flows.
class AppCupertinoPicker extends StatelessWidget {
  const AppCupertinoPicker({
    super.key,
    required this.itemExtent,
    required this.scrollController,
    required this.onSelectedItemChanged,
    required this.children,
    this.selectionOverlayRadius = PickerSelectionStyle.defaultRadius,
    this.selectionOverlayLabel,
  });

  final double itemExtent;
  final FixedExtentScrollController scrollController;
  final ValueChanged<int> onSelectedItemChanged;
  final List<Widget> children;
  final double selectionOverlayRadius;
  final String? selectionOverlayLabel;

  @override
  Widget build(BuildContext context) {
    final pickerTextStyle = context.appText.titleMedium?.copyWith(
      color: context.appColors.textPrimary,
    );
    final cupertinoTheme = CupertinoTheme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        PickerSelectionBackground(
          itemExtent: itemExtent,
          radius: selectionOverlayRadius,
        ),
        CupertinoTheme(
          data: cupertinoTheme.copyWith(
            textTheme: cupertinoTheme.textTheme.copyWith(
              pickerTextStyle: pickerTextStyle,
            ),
          ),
          child: CupertinoPicker(
            itemExtent: itemExtent,
            scrollController: scrollController,
            selectionOverlay: PickerSelectionOverlay(
              radius: selectionOverlayRadius,
              label: selectionOverlayLabel,
            ),
            onSelectedItemChanged: onSelectedItemChanged,
            children: children,
          ),
        ),
      ],
    );
  }
}

Widget _buildPickerColumn({
  required BuildContext context,
  required int initialItem,
  required int itemCount,
  required double selectionOverlayRadius,
  required ValueChanged<int> onSelectedItemChanged,
  required String Function(int index) labelBuilder,
  String? selectionOverlayLabel,
}) {
  final textTheme = context.appText;

  return AppCupertinoPicker(
    itemExtent: 50,
    scrollController: FixedExtentScrollController(initialItem: initialItem),
    selectionOverlayRadius: selectionOverlayRadius,
    selectionOverlayLabel: selectionOverlayLabel,
    onSelectedItemChanged: onSelectedItemChanged,
    children: List.generate(itemCount, (index) {
      return Center(
        child: Text(labelBuilder(index), style: textTheme.titleMedium),
      );
    }),
  );
}

// policy: allow-public-api shared weight-wheel contract used by onboarding and workout completion flows.
class WeightPickerWheelSpec {
  const WeightPickerWheelSpec({
    required this.minimum,
    required this.maximum,
    required this.unitLabel,
  });

  final double minimum;
  final double maximum;
  final String unitLabel;

  factory WeightPickerWheelSpec.forUnits(Units units) {
    return units == Units.metric
        ? const WeightPickerWheelSpec(
            minimum: 30,
            maximum: 170,
            unitLabel: 'kg',
          )
        : const WeightPickerWheelSpec(
            minimum: 66,
            maximum: 366,
            unitLabel: 'lbs',
          );
  }

  int get minimumWhole => minimum.floor();

  int get maximumWhole => maximum.floor();

  int get wholeItemCount => maximumWhole - minimumWhole + 1;

  double clamp(double value) {
    final roundedToTenths = (value * 10).round() / 10;
    if (value < minimum) {
      return minimum;
    }
    if (value > maximum) {
      return maximum;
    }
    return roundedToTenths;
  }

  int wholeIndexForWeight(double value) {
    final clamped = clamp(value);
    return clamped.floor() - minimumWhole;
  }

  int decimalIndexForWeight(double value) {
    final clamped = clamp(value);
    final whole = clamped.floorToDouble();
    final decimal = ((clamped - whole) * 10).round();
    return decimal.clamp(0, 9);
  }

  int wholeForIndex(int index) {
    final safeIndex = index.clamp(0, wholeItemCount - 1);
    return minimumWhole + safeIndex;
  }

  double weightForParts(int whole, int decimalIndex) {
    return clamp(whole + (decimalIndex / 10));
  }

  double defaultWeight({Gender gender = Gender.ratherNotSay}) {
    return gender.defaultStartingWeight(
      unitLabel == 'kg' ? Units.metric : Units.imperial,
    );
  }
}

// policy: allow-public-api shared weight input widget reused across onboarding and workout completion.
class WeightPickerWheel extends StatelessWidget {
  const WeightPickerWheel({
    super.key,
    required this.weight,
    required this.units,
    required this.onWeightChanged,
    this.pickerKey,
    this.selectionOverlayRadius = PickerSelectionStyle.defaultRadius,
  });

  final double weight;
  final Units units;
  final ValueChanged<double> onWeightChanged;
  final Key? pickerKey;
  final double selectionOverlayRadius;

  @override
  Widget build(BuildContext context) {
    final spec = WeightPickerWheelSpec.forUnits(units);
    final initialWeight = spec.clamp(weight);
    var selectedWhole = initialWeight.floor();
    var selectedDecimal = spec.decimalIndexForWeight(initialWeight);

    return Row(
      key: pickerKey,
      children: [
        Expanded(
          flex: 5,
          child: _buildPickerColumn(
            context: context,
            initialItem: spec.wholeIndexForWeight(initialWeight),
            itemCount: spec.wholeItemCount,
            selectionOverlayRadius: selectionOverlayRadius,
            onSelectedItemChanged: (index) {
              selectedWhole = spec.wholeForIndex(index);
              onWeightChanged(
                spec.weightForParts(selectedWhole, selectedDecimal),
              );
            },
            labelBuilder: (index) {
              final wholeValue = spec.wholeForIndex(index);
              return '$wholeValue';
            },
          ),
        ),
        Expanded(
          flex: 5,
          child: _buildPickerColumn(
            context: context,
            initialItem: selectedDecimal,
            itemCount: 10,
            selectionOverlayRadius: selectionOverlayRadius,
            onSelectedItemChanged: (index) {
              selectedDecimal = index;
              onWeightChanged(
                spec.weightForParts(selectedWhole, selectedDecimal),
              );
            },
            labelBuilder: (index) => '.$index',
            selectionOverlayLabel: spec.unitLabel,
          ),
        ),
      ],
    );
  }
}

// policy: allow-public-api shared duration-wheel contract used by workout completion flows.
class DurationPickerWheelSpec {
  const DurationPickerWheelSpec({
    this.minimum = Duration.zero,
    this.maximum = const Duration(hours: 12, minutes: 59),
  });

  final Duration minimum;
  final Duration maximum;

  int get minimumMinutes => minimum.inMinutes;

  int get maximumMinutes => maximum.inMinutes;

  int get hourItemCount => maximum.inHours - minimum.inHours + 1;

  Duration clamp(Duration value) {
    final minutes = value.inMinutes.clamp(minimumMinutes, maximumMinutes);
    return Duration(minutes: minutes);
  }

  int hourIndexForDuration(Duration value) {
    final clamped = clamp(value);
    return clamped.inHours - minimum.inHours;
  }

  int minuteIndexForDuration(Duration value) {
    return clamp(value).inMinutes.remainder(60);
  }

  int hourForIndex(int index) {
    final safeIndex = index.clamp(0, hourItemCount - 1);
    return minimum.inHours + safeIndex;
  }

  Duration durationForParts(int hours, int minutes) {
    return clamp(Duration(hours: hours, minutes: minutes));
  }
}

// policy: allow-public-api shared duration input widget reused across workout flows.
class DurationPickerWheel extends StatelessWidget {
  const DurationPickerWheel({
    super.key,
    required this.duration,
    required this.onDurationChanged,
    this.pickerKey,
    this.spec = const DurationPickerWheelSpec(),
    this.selectionOverlayRadius = PickerSelectionStyle.defaultRadius,
  });

  final Duration duration;
  final ValueChanged<Duration> onDurationChanged;
  final Key? pickerKey;
  final DurationPickerWheelSpec spec;
  final double selectionOverlayRadius;

  @override
  Widget build(BuildContext context) {
    final initialDuration = spec.clamp(duration);
    var selectedHours = initialDuration.inHours;
    var selectedMinutes = spec.minuteIndexForDuration(initialDuration);

    return Row(
      key: pickerKey,
      children: [
        Expanded(
          child: _buildPickerColumn(
            context: context,
            initialItem: spec.hourIndexForDuration(initialDuration),
            itemCount: spec.hourItemCount,
            selectionOverlayRadius: selectionOverlayRadius,
            onSelectedItemChanged: (index) {
              selectedHours = spec.hourForIndex(index);
              onDurationChanged(
                spec.durationForParts(selectedHours, selectedMinutes),
              );
            },
            labelBuilder: (index) => '${spec.hourForIndex(index)}',
            selectionOverlayLabel: 'h',
          ),
        ),
        Expanded(
          child: _buildPickerColumn(
            context: context,
            initialItem: selectedMinutes,
            itemCount: 60,
            selectionOverlayRadius: selectionOverlayRadius,
            onSelectedItemChanged: (index) {
              selectedMinutes = index;
              onDurationChanged(
                spec.durationForParts(selectedHours, selectedMinutes),
              );
            },
            labelBuilder: (index) => index.toString().padLeft(2, '0'),
            selectionOverlayLabel: 'min',
          ),
        ),
      ],
    );
  }
}

// policy: allow-public-api shared picker overlay used by the app's Cupertino wheel wrappers.
class PickerSelectionBackground extends StatelessWidget {
  const PickerSelectionBackground({
    super.key,
    required this.itemExtent,
    required this.radius,
  });

  final double itemExtent;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth - 18;

          return Center(
            child: SizedBox(
              width: availableWidth > 0 ? availableWidth : 0,
              height: itemExtent,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: context.appColors.field.withValues(alpha: 0.68),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PickerSelectionOverlay extends StatelessWidget {
  const PickerSelectionOverlay({super.key, required this.radius, this.label});

  final double radius;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: 9),
      decoration: ShapeDecoration(
        color: context.appColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      child: label == null
          ? null
          : Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 20),
                child: Text(label!, style: context.appText.titleMedium),
              ),
            ),
    );
  }
}
