class UnitConverter {

  // Format weight with appropriate unit label
  static String formatWeight(double weightInKg, String units, {int decimals = 1}) {
    final unit = units == 'metric' ? 'kg' : 'lbs';
    return '${weightInKg.toStringAsFixed(decimals)} $unit';
  }

  // Get the unit label for the current system
  static String getWeightUnit(String units) {
    return units == 'metric' ? 'kg' : 'lbs';
  }
}
