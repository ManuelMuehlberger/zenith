import 'package:flutter/cupertino.dart';

import '../constants/app_constants.dart';
import '../models/user_data.dart';
import '../theme/app_theme.dart';

// policy: allow-public-api shared picker overlay sizing tokens used by onboarding and workout completion.
class PickerSelectionStyle {
  const PickerSelectionStyle._();

  static const double defaultRadius = 8;
  static const double emphasizedRadius = AppConstants.SHEET_RADIUS;
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
  });

  final double itemExtent;
  final FixedExtentScrollController scrollController;
  final ValueChanged<int> onSelectedItemChanged;
  final List<Widget> children;
  final double selectionOverlayRadius;

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      itemExtent: itemExtent,
      scrollController: scrollController,
      selectionOverlay: PickerSelectionOverlay(radius: selectionOverlayRadius),
      onSelectedItemChanged: onSelectedItemChanged,
      children: children,
    );
  }
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
  final double weight;
  final Units units;
  final ValueChanged<double> onWeightChanged;
  final Key? pickerKey;
  final double selectionOverlayRadius;

  const WeightPickerWheel({
    super.key,
    required this.weight,
    required this.units,
    required this.onWeightChanged,
    this.pickerKey,
    this.selectionOverlayRadius = PickerSelectionStyle.defaultRadius,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final spec = WeightPickerWheelSpec.forUnits(units);
    final initialWeight = spec.clamp(weight);
    var selectedWhole = initialWeight.floor();
    var selectedDecimal = spec.decimalIndexForWeight(initialWeight);

    return Row(
      key: pickerKey,
      children: [
        Expanded(
          flex: 4,
          child: AppCupertinoPicker(
            itemExtent: 50,
            scrollController: FixedExtentScrollController(
              initialItem: spec.wholeIndexForWeight(initialWeight),
            ),
            selectionOverlayRadius: selectionOverlayRadius,
            onSelectedItemChanged: (index) {
              selectedWhole = spec.wholeForIndex(index);
              onWeightChanged(
                spec.weightForParts(selectedWhole, selectedDecimal),
              );
            },
            children: List.generate(spec.wholeItemCount, (index) {
              final wholeValue = spec.wholeForIndex(index);
              return Center(
                child: Text(
                  '$wholeValue ${spec.unitLabel}',
                  style: textTheme.titleMedium,
                ),
              );
            }),
          ),
        ),
        Expanded(
          flex: 2,
          child: AppCupertinoPicker(
            itemExtent: 50,
            scrollController: FixedExtentScrollController(
              initialItem: selectedDecimal,
            ),
            selectionOverlayRadius: selectionOverlayRadius,
            onSelectedItemChanged: (index) {
              selectedDecimal = index;
              onWeightChanged(
                spec.weightForParts(selectedWhole, selectedDecimal),
              );
            },
            children: List.generate(10, (index) {
              return Center(
                child: Text('.$index', style: textTheme.titleMedium),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// policy: allow-public-api shared picker overlay used by the app's Cupertino wheel wrappers.
class PickerSelectionOverlay extends StatelessWidget {
  const PickerSelectionOverlay({super.key, required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: 9),
      decoration: ShapeDecoration(
        color: context.appColors.field,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
