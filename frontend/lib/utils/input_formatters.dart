import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats numeric input to Indian Numbering System (e.g., 5,00,000)
class CommaTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    // Remove all non-digit characters to get the raw number
    String rawText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (rawText.isEmpty) return newValue.copyWith(text: '');

    // Use 'en_IN' locale for the Lakhs/Crores format (2,2,3 grouping)
    final formatter = NumberFormat.decimalPattern('en_IN');
    String formattedText = formatter.format(int.parse(rawText));

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
