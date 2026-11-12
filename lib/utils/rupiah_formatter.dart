import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatter untuk merubah input angka menjadi format Rupiah real-time.
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Hanya ambil karakter angka
    final String cleanString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanString.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final double value = double.parse(cleanString);
    // Format menggunakan locale Indonesia (titik sebagai pemisah ribuan)
    final formatter = NumberFormat.decimalPattern('id_ID');
    final String newText = formatter.format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
