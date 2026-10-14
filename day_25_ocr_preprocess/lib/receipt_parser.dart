class ReceiptData {
  const ReceiptData({this.total, this.merchant, this.date});
  final double? total;
  final String? merchant;
  final DateTime? date;
}

const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12, //
};

/// Step 3 of the Reel: turn raw OCR text into structured data with regular expressions.
///
/// Handles lines like `Total: $42.50`, `Merchant: Blue Bottle` and dates like `1 Oct 2026` or `2026-10-01`.
/// If there is no "Merchant:" label, the first line that isn't numbers or a keyword is used. That fallback
/// is my addition. It is a guess, and real receipts vary a lot.
ReceiptData parseReceipt(String ocrText) {
  final lines = ocrText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  return ReceiptData(total: _total(lines), merchant: _merchant(lines), date: _date(ocrText));
}

double? _total(List<String> lines) {
  // "Total" but not "Subtotal". The last one on the receipt is usually the final amount.
  final re = RegExp(r'(?<![a-z])total\s*[:\-]?\s*[$₹€£]?\s*(\d+(?:[.,]\d{1,2})?)', caseSensitive: false);
  double? found;
  for (final line in lines) {
    final m = re.firstMatch(line);
    if (m != null) found = double.tryParse(m.group(1)!.replaceAll(',', '.'));
  }
  return found;
}

String? _merchant(List<String> lines) {
  final labeled = RegExp(r'^merchant\s*[:\-]\s*(.+)$', caseSensitive: false);
  for (final line in lines) {
    final m = labeled.firstMatch(line);
    if (m != null) return m.group(1)!.trim();
  }
  final keyword = RegExp(r'total|date|tax|amount|thank', caseSensitive: false);
  for (final line in lines) {
    if (RegExp(r'[A-Za-z]').hasMatch(line) && !keyword.hasMatch(line)) return line;
  }
  return null;
}

DateTime? _date(String text) {
  final iso = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
  if (iso != null) {
    return DateTime(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!));
  }
  final named = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})[a-z]*\.?,?\s+(\d{4})').firstMatch(text);
  if (named != null) {
    final month = _months[named.group(2)!.toLowerCase()];
    if (month != null) return DateTime(int.parse(named.group(3)!), month, int.parse(named.group(1)!));
  }
  return null;
}
