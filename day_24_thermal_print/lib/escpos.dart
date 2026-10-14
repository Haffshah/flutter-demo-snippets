/// Raw ESC/POS commands used when a plugin's text formatting isn't enough.
const initializePrinter = [0x1b, 0x40];
const alignCenter = [0x1b, 0x61, 0x01];
const charSizeDouble = [0x1d, 0x21, 0x11];

// Not shown in the carousel, but needed to undo the two commands above.
const alignLeft = [0x1b, 0x61, 0x00];
const charSizeNormal = [0x1d, 0x21, 0x00];
const lineFeed = [0x0a];

/// Puts [left] and [right] on one line of [width] characters, padding the gap with spaces.
///
/// The carousel version computes `' ' * (width - left.length - right.length)`, which throws in Dart
/// when the text is longer than the line (negative repeat count). This version keeps at least one
/// space and shortens [left] when needed.
String padRow(String left, String right, {int width = 32}) {
  if (right.length >= width - 1) return right.substring(0, width); // nothing sensible fits next to it
  final maxLeft = width - right.length - 1;
  final l = left.length > maxLeft ? left.substring(0, maxLeft) : left;
  return l + ' ' * (width - l.length - right.length) + right;
}

/// Builds the byte stream for a small receipt.
class ReceiptBuilder {
  ReceiptBuilder({this.width = 32});

  final int width;
  final List<int> _bytes = [...initializePrinter];

  ReceiptBuilder title(String text) {
    _bytes
      ..addAll(alignCenter)
      ..addAll(charSizeDouble)
      ..addAll(_text(text))
      ..addAll(lineFeed)
      ..addAll(charSizeNormal)
      ..addAll(alignLeft);
    return this;
  }

  ReceiptBuilder row(String left, String right) {
    _bytes
      ..addAll(_text(padRow(left, right, width: width)))
      ..addAll(lineFeed);
    return this;
  }

  List<int> build() => List.unmodifiable(_bytes);

  /// ASCII only. Anything else becomes '?'. Real code-page / charset handling is NOT covered here.
  List<int> _text(String s) => s.codeUnits.map((c) => c < 128 ? c : 0x3f).toList();
}
