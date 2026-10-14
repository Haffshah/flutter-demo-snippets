import 'dart:typed_data';

import 'package:ocr_preprocess_demo/perspective.dart';
import 'package:ocr_preprocess_demo/receipt_parser.dart';
import 'package:test/test.dart';

GrayImage filled(int w, int h, int v) => GrayImage(w, h, Uint8List(w * h)..fillRange(0, w * h, v));

/// Paints a quadrilateral with [inside] on a [outside] background, using a point-in-polygon test.
GrayImage paintQuad(int w, int h, List<Point> quad, {int inside = 200, int outside = 30}) {
  bool contains(double px, double py) {
    var c = false;
    for (var i = 0, j = 3; i < 4; j = i++) {
      final a = quad[i], b = quad[j];
      if ((a.y > py) != (b.y > py) && px < (b.x - a.x) * (py - a.y) / (b.y - a.y) + a.x) c = !c;
    }
    return c;
  }

  final px = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      px[y * w + x] = contains(x + 0.5, y + 0.5) ? inside : outside;
    }
  }
  return GrayImage(w, h, px);
}

void main() {
  group('homography', () {
    test('output corners map exactly onto the quad corners', () {
      const quad = [Point(10, 12), Point(90, 20), Point(95, 70), Point(5, 60)];
      final h = solveHomography(quad, 80, 50);
      for (final (i, corner) in [(0.0, 0.0), (79.0, 0.0), (79.0, 49.0), (0.0, 49.0)].indexed) {
        final p = mapPoint(h, corner.$1, corner.$2);
        expect(p.x, closeTo(quad[i].x, 1e-6));
        expect(p.y, closeTo(quad[i].y, 1e-6));
      }
    });

    test('an upright quad the same size as the output is the identity', () {
      const quad = [Point(0, 0), Point(9, 0), Point(9, 4), Point(0, 4)];
      final h = solveHomography(quad, 10, 5);
      final p = mapPoint(h, 3, 2);
      expect(p.x, closeTo(3, 1e-9));
      expect(p.y, closeTo(2, 1e-9));
    });

    test('four collinear corners are rejected', () {
      const line = [Point(0, 0), Point(1, 1), Point(2, 2), Point(3, 3)];
      expect(() => solveHomography(line, 10, 10), throwsArgumentError);
    });
  });

  group('warpQuadToRect', () {
    test('an axis-aligned quad is just a crop', () {
      final src = GrayImage(20, 10, Uint8List.fromList(List.generate(200, (i) => i % 256)));
      final out = warpQuadToRect(src, const [Point(5, 2), Point(14, 2), Point(14, 7), Point(5, 7)], 10, 6);
      for (var y = 0; y < 6; y++) {
        for (var x = 0; x < 10; x++) {
          expect(out.at(x, y), src.at(5 + x, 2 + y), reason: 'pixel ($x,$y)');
        }
      }
    });

    test('a skewed card becomes an upright, evenly bright rectangle', () {
      const card = [Point(30, 20), Point(170, 40), Point(160, 120), Point(20, 100)];
      final src = paintQuad(200, 150, card);
      final out = warpQuadToRect(src, card, 140, 80);

      // Pixels exactly on the card's edge blend with the background when sampled, so judge the interior,
      // starting 3 pixels in from the output's border.
      var interior = 0, bright = 0;
      for (var y = 3; y < out.height - 3; y++) {
        for (var x = 3; x < out.width - 3; x++) {
          interior++;
          if (out.at(x, y) >= 190) bright++;
        }
      }
      expect(bright / interior, greaterThan(0.999), reason: 'the interior of the output is all card');
    });

    test('without the warp, a skewed card region contains a lot of background', () {
      const card = [Point(30, 20), Point(170, 40), Point(160, 120), Point(20, 100)];
      final src = paintQuad(200, 150, card);
      // Cropping the card's bounding box (no perspective correction) keeps the dark corners.
      var dark = 0, total = 0;
      for (var y = 20; y <= 120; y++) {
        for (var x = 20; x <= 170; x++) {
          total++;
          if (src.at(x, y) < 100) dark++;
        }
      }
      expect(dark / total, greaterThan(0.05));
    });
  });

  group('parseReceipt', () {
    test('the Reel example', () {
      final r = parseReceipt('Merchant: Blue Bottle\nDate: 1 Oct 2026\nTotal: \$42.50');
      expect(r.merchant, 'Blue Bottle');
      expect(r.date, DateTime(2026, 10, 1));
      expect(r.total, 42.50);
    });

    test('subtotal is ignored and the last total wins', () {
      final r = parseReceipt('Blue Bottle\nSubtotal 40.00\nTax 2.50\nTotal 42.50');
      expect(r.total, 42.50);
    });

    test('ISO dates and a comma as the decimal separator', () {
      final r = parseReceipt('Cafe\n2026-10-01\nTOTAL: 12,30');
      expect(r.date, DateTime(2026, 10, 1));
      expect(r.total, 12.30);
    });

    test('without a Merchant label the first text line is used', () {
      expect(parseReceipt('Blue Bottle Coffee\nTotal \$5').merchant, 'Blue Bottle Coffee');
    });

    test('missing fields come back null', () {
      final r = parseReceipt('hello');
      expect(r.total, isNull);
      expect(r.date, isNull);
      expect(parseReceipt('').merchant, isNull);
    });
  });
}
