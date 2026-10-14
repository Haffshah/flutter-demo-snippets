import 'dart:typed_data';

class Point {
  const Point(this.x, this.y);
  final double x;
  final double y;
}

/// 8-bit grayscale image, row by row. 0 = black, 255 = white.
class GrayImage {
  GrayImage(this.width, this.height, this.pixels) : assert(pixels.length == width * height);

  final int width;
  final int height;
  final Uint8List pixels;

  int at(int x, int y) => pixels[y * width + x];

  /// Bilinear sample at a fractional position, clamped to the image edges.
  double sample(double x, double y) {
    final cx = x.clamp(0, width - 1).toDouble();
    final cy = y.clamp(0, height - 1).toDouble();
    final x0 = cx.floor(), y0 = cy.floor();
    final x1 = x0 + 1 < width ? x0 + 1 : x0;
    final y1 = y0 + 1 < height ? y0 + 1 : y0;
    final fx = cx - x0, fy = cy - y0;
    final top = at(x0, y0) * (1 - fx) + at(x1, y0) * fx;
    final bottom = at(x0, y1) * (1 - fx) + at(x1, y1) * fx;
    return top * (1 - fy) + bottom * fy;
  }
}

/// Maps the corners of an upright rectangle (0,0), (w-1,0), (w-1,h-1), (0,h-1) onto [quad], given as
/// top-left, top-right, bottom-right, bottom-left. Returns the 8 homography parameters, which are
/// enough to compute the matching source position for any output pixel.
List<double> solveHomography(List<Point> quad, int outW, int outH) {
  if (quad.length != 4) throw ArgumentError('quad needs 4 corners');
  final dst = [Point(0, 0), Point(outW - 1.0, 0), Point(outW - 1.0, outH - 1.0), Point(0, outH - 1.0)];

  // Solve for h0..h7 in:  X = (h0 x + h1 y + h2) / (h6 x + h7 y + 1),  Y = (h3 x + h4 y + h5) / (h6 x + h7 y + 1)
  final a = List.generate(8, (_) => List<double>.filled(9, 0)); // augmented 8x8 system
  for (var i = 0; i < 4; i++) {
    final x = dst[i].x, y = dst[i].y, X = quad[i].x, Y = quad[i].y;
    a[2 * i] = [x, y, 1, 0, 0, 0, -X * x, -X * y, X];
    a[2 * i + 1] = [0, 0, 0, x, y, 1, -Y * x, -Y * y, Y];
  }
  return _gauss(a);
}

List<double> _gauss(List<List<double>> a) {
  const n = 8;
  for (var col = 0; col < n; col++) {
    var pivot = col;
    for (var r = col + 1; r < n; r++) {
      if (a[r][col].abs() > a[pivot][col].abs()) pivot = r;
    }
    if (a[pivot][col].abs() < 1e-9) throw ArgumentError('the four corners do not form a valid quadrilateral');
    final tmp = a[col];
    a[col] = a[pivot];
    a[pivot] = tmp;
    for (var r = 0; r < n; r++) {
      if (r == col) continue;
      final f = a[r][col] / a[col][col];
      for (var c = col; c <= n; c++) {
        a[r][c] -= f * a[col][c];
      }
    }
  }
  return [for (var i = 0; i < n; i++) a[i][n] / a[i][i]];
}

/// Position in the source image for output pixel (x, y).
Point mapPoint(List<double> h, double x, double y) {
  final w = h[6] * x + h[7] * y + 1;
  return Point((h[0] * x + h[1] * y + h[2]) / w, (h[3] * x + h[4] * y + h[5]) / w);
}

/// Flattens the area inside [quad] (top-left, top-right, bottom-right, bottom-left, in source pixels)
/// into an upright [outW] x [outH] image. You supply the four corners. Finding them is not done here.
GrayImage warpQuadToRect(GrayImage src, List<Point> quad, int outW, int outH) {
  final h = solveHomography(quad, outW, outH);
  final out = Uint8List(outW * outH);
  for (var y = 0; y < outH; y++) {
    for (var x = 0; x < outW; x++) {
      final p = mapPoint(h, x.toDouble(), y.toDouble());
      out[y * outW + x] = src.sample(p.x, p.y).round().clamp(0, 255);
    }
  }
  return GrayImage(outW, outH, out);
}
