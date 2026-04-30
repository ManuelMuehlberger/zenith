import 'package:flutter/services.dart';

/// Text input formatter for entering a weight value.
///
/// Requirements:
/// - Range: 0 to 999 (inclusive), with up to 2 decimal places
/// - Accepts either dot or comma as decimal separator
/// - Normalizes comma to dot
/// - Prevents multiple separators and too many digits
class WeightTextInputFormatter extends TextInputFormatter {
  WeightTextInputFormatter({
    this.maxIntegerDigits = 3,
    this.maxDecimalDigits = 2,
  });

  final int maxIntegerDigits;
  final int maxDecimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Normalize decimal separator.
    final normalized = newValue.text.replaceAll(',', '.');

    if (normalized.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Allow user to type just the separator (e.g. "."), intermediate state.
    if (normalized == '.') {
      return newValue.copyWith(text: '.', selection: newValue.selection);
    }

    final dotCount = '.'.allMatches(normalized).length;
    if (dotCount > 1) return oldValue;

    final parts = normalized.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';

    // Allow empty integer part only if there is a decimal separator (e.g. ".5").
    if (intPart.isNotEmpty && !_isDigits(intPart)) return oldValue;
    if (decPart.isNotEmpty && !_isDigits(decPart)) return oldValue;

    if (intPart.length > maxIntegerDigits) return oldValue;
    if (decPart.length > maxDecimalDigits) return oldValue;

    // If there is an integer part, ensure it is <= 999.
    if (intPart.isNotEmpty) {
      final intValue = int.tryParse(intPart);
      if (intValue == null) return oldValue;
      if (intValue > 999) return oldValue;
    }

    // If no integer part, we still allow (e.g. ".25").
    // We don't clamp here; clamping happens on blur / commit.

    // Keep selection consistent after normalization.
    final selection = newValue.selection;
    return TextEditingValue(
      text: normalized,
      selection: selection,
      composing: TextRange.empty,
    );
  }

  bool _isDigits(String s) => RegExp(r'^\d+$').hasMatch(s);
}
