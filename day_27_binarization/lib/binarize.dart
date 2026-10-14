import 'dart:typed_data';

/// 8-bit grayscale image, row by row. 0 = black, 255 = white.
class GrayImage {
  GrayImage(this.width, this.height, this.pixels)
      : assert(pixels.length == width * height, 'pixels must be width * height');

  final int width;
  final int height;
  final Uint8List pixels;

  int at(int x, int y) => pixels[y * width + x];
}

/// One value per pixel: 1 = white (paper), 0 = black (ink).
typedef BitImage = Uint8List;

/// One cutoff for the whole page. Fails when lighting is uneven (a shadow turns paper black).
BitImage globalThreshold(GrayImage g, {int threshold = 128}) {
  final out = Uint8List(g.pixels.length);
  for (var i = 0; i < out.length; i++) {
    out[i] = g.pixels[i] >= threshold ? 1 : 0;
  }
  return out;
}

/// Adaptive threshold (Bradley and Roth style). Each pixel is compared with the average of the
/// [windowSize] x [windowSize] area around it, so a shadowed page area is judged against its own
/// surroundings. A pixel becomes black when it is more than [sensitivity] darker than that average.
///
/// Uses an integral image, so the cost does not grow with the window size.
BitImage adaptiveThreshold(GrayImage g, {int windowSize = 15, double sensitivity = 0.15}) {
  final w = g.width;
  final h = g.height;
  final half = windowSize ~/ 2;

  // integral[(y+1)*(w+1) + (x+1)] = sum of all pixels above and left of (x, y), inclusive.
  final integral = List<int>.filled((w + 1) * (h + 1), 0);
  for (var y = 0; y < h; y++) {
    var rowSum = 0;
    for (var x = 0; x < w; x++) {
      rowSum += g.at(x, y);
      integral[(y + 1) * (w + 1) + (x + 1)] = integral[y * (w + 1) + (x + 1)] + rowSum;
    }
  }

  final out = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    final y0 = y - half < 0 ? 0 : y - half;
    final y1 = y + half >= h ? h - 1 : y + half;
    for (var x = 0; x < w; x++) {
      final x0 = x - half < 0 ? 0 : x - half;
      final x1 = x + half >= w ? w - 1 : x + half;
      final count = (x1 - x0 + 1) * (y1 - y0 + 1);
      final sum = integral[(y1 + 1) * (w + 1) + (x1 + 1)] -
          integral[y0 * (w + 1) + (x1 + 1)] -
          integral[(y1 + 1) * (w + 1) + x0] +
          integral[y0 * (w + 1) + x0];
      // black if value is below (1 - sensitivity) * average
      out[y * w + x] = g.at(x, y) * count <= sum * (1 - sensitivity) ? 0 : 1;
    }
  }
  return out;
}

/// Packs a [BitImage] into 1 bit per pixel, most significant bit first. Each row starts on a byte
/// boundary. Bit value 1 = white.
Uint8List packBits(BitImage bits, int width, int height) {
  final bytesPerRow = (width + 7) ~/ 8;
  final out = Uint8List(bytesPerRow * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (bits[y * width + x] == 1) {
        out[y * bytesPerRow + (x >> 3)] |= 0x80 >> (x & 7);
      }
    }
  }
  return out;
}
