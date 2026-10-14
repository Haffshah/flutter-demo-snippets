import 'package:test/test.dart';
import 'package:thermal_print_demo/chunked_writer.dart';
import 'package:thermal_print_demo/escpos.dart';

void main() {
  group('padRow', () {
    test('fills the line to the width', () {
      final row = padRow('ITEM A', r'$42.00');
      expect(row.length, 32);
      expect(row.startsWith('ITEM A'), isTrue);
      expect(row.endsWith(r'$42.00'), isTrue);
    });

    test('long text does not throw and keeps one space before the price', () {
      final row = padRow('A VERY LONG ITEM NAME THAT DOES NOT FIT ON ONE LINE', r'$42.00');
      expect(row.length, 32);
      expect(row.endsWith(r' $42.00'), isTrue);
    });

    test('respects a different paper width', () {
      expect(padRow('A', 'B', width: 48).length, 48);
    });
  });

  group('ReceiptBuilder', () {
    test('starts with the initialize command', () {
      final bytes = ReceiptBuilder().title('SHOP').build();
      expect(bytes.take(2), initializePrinter);
    });

    test('title is centered, double size, then reset', () {
      final bytes = ReceiptBuilder().title('HI').build();
      final s = bytes.join(',');
      expect(s, contains(alignCenter.join(',')));
      expect(s, contains(charSizeDouble.join(',')));
      expect(s, contains(charSizeNormal.join(',')));
    });

    test('non-ASCII becomes ? instead of throwing', () {
      final bytes = ReceiptBuilder().row('Café', '₹5').build();
      expect(bytes.contains(0x3f), isTrue);
      expect(bytes.every((b) => b < 256), isTrue);
    });
  });

  group('chunking', () {
    test('splits into 20-byte chunks', () {
      final data = List<int>.generate(45, (i) => i);
      final sizes = chunk(data).map((c) => c.length).toList();
      expect(sizes, [20, 20, 5]);
    });

    test('chunks reassemble to the original bytes', () {
      final data = List<int>.generate(101, (i) => i % 256);
      expect(chunk(data).expand((c) => c).toList(), data);
    });

    test('writer sends every chunk in order and pauses between them, not after the last', () async {
      final written = <List<int>>[];
      final delays = <Duration>[];
      final writer = ChunkedWriter(
        (c) async => written.add(c),
        delay: (d) async => delays.add(d),
      );
      await writer.send(List<int>.generate(45, (i) => i));
      expect(written.length, 3);
      expect(delays, [const Duration(milliseconds: 10), const Duration(milliseconds: 10)]);
    });

    test('empty payload writes nothing', () async {
      var calls = 0;
      await ChunkedWriter((c) async => calls++, delay: (_) async {}).send([]);
      expect(calls, 0);
    });
  });
}
