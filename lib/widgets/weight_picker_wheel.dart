import 'package:flutter/cupertino.dart';

import '../constants/app_constants.dart';
import '../models/user_data.dart';
import '../theme/app_theme.dart';

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

  const WeightPickerWheel({
    super.key,
    required this.weight,
    required this.units,
    required this.onWeightChanged,
    this.pickerKey,
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
          child: CupertinoPicker(
            itemExtent: 50,
            scrollController: FixedExtentScrollController(
              initialItem: spec.wholeIndexForWeight(initialWeight),
            ),
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
          child: CupertinoPicker(
            itemExtent: 50,
            scrollController: FixedExtentScrollController(
              initialItem: selectedDecimal,
            ),
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
