import 'dart:typed_data';

import 'package:binarization_demo/binarize.dart';
import 'package:test/test.dart';

/// A page whose lighting fades from bright (left) to shadowed (right), with dark vertical "ink" strokes.
({GrayImage image, Set<int> ink}) shadowedPage() {
  const w = 96;
  const h = 32;
  final px = Uint8List(w * h);
  final ink = <int>{};
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final background = (255 - (255 - 90) * x / (w - 1)).round(); // 255 -> 90
      final isInk = x % 12 == 5 || x % 12 == 6; // 2px strokes every 12px
      px[y * w + x] = isInk ? (background - 80).clamp(0, 255) : background;
      if (isInk) ink.add(y * w + x);
    }
  }
  return (image: GrayImage(w, h, px), ink: ink);
}

/// Share of non-ink pixels that came out white. Only columns from [fromX] onward are counted.
double whiteShareOfBackground(BitImage bits, Set<int> ink, {int fromX = 0, int width = 96}) {
  var bg = 0, white = 0;
  for (var i = 0; i < bits.length; i++) {
    if (ink.contains(i) || i % width < fromX) continue;
    bg++;
    if (bits[i] == 1) white++;
  }
  return white / bg;
}

double blackShareOfInk(BitImage bits, Set<int> ink) =>
    ink.where((i) => bits[i] == 0).length / ink.length;

void main() {
  test('global threshold turns the shadowed edge of the paper black', () {
    final page = shadowedPage();
    final bits = globalThreshold(page.image);
    // Columns 80+ have paper values below the 128 cutoff, so none of the paper there stays white.
    expect(whiteShareOfBackground(bits, page.ink, fromX: 80), 0);
    expect(whiteShareOfBackground(bits, page.ink, fromX: 0), lessThan(0.9));
  });

  test('adaptive threshold keeps paper white and ink black across the whole page', () {
    final page = shadowedPage();
    final bits = adaptiveThreshold(page.image);
    expect(whiteShareOfBackground(bits, page.ink, fromX: 80), greaterThan(0.97)); // the shadowed edge
    expect(whiteShareOfBackground(bits, page.ink), greaterThan(0.97));
    expect(blackShareOfInk(bits, page.ink), greaterThan(0.97));
  });

  test('a uniformly white image stays white', () {
    final g = GrayImage(20, 20, Uint8List(400)..fillRange(0, 400, 255));
    expect(adaptiveThreshold(g).every((b) => b == 1), isTrue);
  });

  test('works when the window is bigger than the image', () {
    final g = GrayImage(5, 5, Uint8List(25)..fillRange(0, 25, 200));
    expect(() => adaptiveThreshold(g, windowSize: 51), returnsNormally);
  });

  group('packBits', () {
    test('packs 8 pixels into one byte, most significant bit first', () {
      final bits = Uint8List.fromList([1, 0, 1, 0, 0, 0, 0, 1]);
      expect(packBits(bits, 8, 1), [0xA1]);
    });

    test('pads each row to a byte boundary', () {
      final bits = Uint8List.fromList([1, 1, 1, 1, 1, 1, 1, 1, 1, 1]); // 10 px wide, 1 row
      expect(packBits(bits, 10, 1), [0xFF, 0xC0]);
    });

    test('packed size is 1 bit per pixel, rounded up per row', () {
      final page = shadowedPage();
      final packed = packBits(adaptiveThreshold(page.image), page.image.width, page.image.height);
      expect(packed.length, ((page.image.width + 7) ~/ 8) * page.image.height);
      expect(packed.length, lessThan(page.image.pixels.length));
    });
  });
}
