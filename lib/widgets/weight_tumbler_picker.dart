import 'package:flutter/cupertino.dart';

import '../constants/app_constants.dart';
import '../models/user_data.dart';
import '../theme/app_theme.dart';

class WeightTumblerSpec {
  const WeightTumblerSpec({
    required this.minimum,
    required this.itemCount,
    required this.step,
    required this.unitLabel,
  });

  final double minimum;
  final int itemCount;
  final double step;
  final String unitLabel;

  factory WeightTumblerSpec.forUnits(Units units) {
    return units == Units.metric
        ? const WeightTumblerSpec(
            minimum: 30,
            itemCount: 280,
            step: 0.5,
            unitLabel: 'kg',
          )
        : const WeightTumblerSpec(
            minimum: 66,
            itemCount: 600,
            step: 0.5,
            unitLabel: 'lbs',
          );
  }

  double get maximum => minimum + ((itemCount - 1) * step);

  double clamp(double value) {
    if (value < minimum) {
      return minimum;
    }
    if (value > maximum) {
      return maximum;
    }
    return value;
  }

  int indexForWeight(double value) {
    final clamped = clamp(value);
    return ((clamped - minimum) / step).round();
  }

  double weightForIndex(int index) {
    final safeIndex = index.clamp(0, itemCount - 1);
    return minimum + (safeIndex * step);
  }

  double defaultWeight({Gender gender = Gender.ratherNotSay}) {
    return gender.defaultStartingWeight(
      unitLabel == 'kg' ? Units.metric : Units.imperial,
    );
  }
}

class WeightTumblerPicker extends StatelessWidget {
  final double weight;
  final Units units;
  final ValueChanged<double> onWeightChanged;
  final FixedExtentScrollController? scrollController;
  final Key? pickerKey;

  const WeightTumblerPicker({
    super.key,
    required this.weight,
    required this.units,
    required this.onWeightChanged,
    this.scrollController,
    this.pickerKey,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final spec = WeightTumblerSpec.forUnits(units);
    final initialWeight = spec.clamp(weight);

    return CupertinoPicker(
      key: pickerKey,
      itemExtent: 50,
      scrollController:
          scrollController ??
          FixedExtentScrollController(
            initialItem: spec.indexForWeight(initialWeight),
          ),
      onSelectedItemChanged: (index) {
        onWeightChanged(spec.weightForIndex(index));
      },
      children: List.generate(spec.itemCount, (index) {
        final weightValue = spec.weightForIndex(index);
        return Center(
          child: Text(
            '${weightValue.toStringAsFixed(1)} ${spec.unitLabel}',
            style: textTheme.titleMedium,
          ),
        );
      }),
    );
  }
}
