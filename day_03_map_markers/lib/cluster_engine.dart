import 'dart:math' as math;

import 'package:flutter/foundation.dart';

class MarkerPoint {
  const MarkerPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

class BoundingBox {
  const BoundingBox({required this.minLat, required this.maxLat, required this.minLng, required this.maxLng});

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  double get latSpan => maxLat - minLat;
  double get lngSpan => maxLng - minLng;

  bool contains(MarkerPoint p) => p.lat >= minLat && p.lat <= maxLat && p.lng >= minLng && p.lng <= maxLng;

  /// Grows the box by [fraction] of its size on every side (0.10 = 10% padding), so markers just
  /// outside the screen are already clustered when the user drags the map.
  BoundingBox expand(double fraction) => BoundingBox(
        minLat: minLat - latSpan * fraction,
        maxLat: maxLat + latSpan * fraction,
        minLng: minLng - lngSpan * fraction,
        maxLng: maxLng + lngSpan * fraction,
      );
}

/// One drawn circle: the average position of the markers in a grid cell, and how many there are.
class ClusterNode {
  const ClusterNode(this.lat, this.lng, this.count);
  final double lat;
  final double lng;
  final int count;
}

class MapClusterEngine {
  /// Clusters [points] that fall inside [bbox] (plus 10% padding) for the given [zoom].
  /// The work runs on a background isolate through `compute`, so the UI thread is not blocked.
  static Future<List<ClusterNode>> computeClusters({
    required List<MarkerPoint> points,
    required double zoom,
    required BoundingBox bbox,
  }) {
    return compute(_heavyClusterAlgorithm, {'points': points, 'zoom': zoom, 'bbox': bbox});
  }

  /// Same algorithm without the isolate. Handy for tests and small lists.
  static List<ClusterNode> clusterSync({
    required List<MarkerPoint> points,
    required double zoom,
    required BoundingBox bbox,
  }) =>
      _heavyClusterAlgorithm({'points': points, 'zoom': zoom, 'bbox': bbox});
}

/// Static grid spacing: the cell size depends only on the zoom level, so the grid never changes
/// while the user pans at the same zoom.
double cellSizeDegrees(double zoom, {double cellPixels = 60}) => 360 / math.pow(2, zoom) * (cellPixels / 256);

List<ClusterNode> _heavyClusterAlgorithm(Map<String, dynamic> args) {
  final points = args['points'] as List<MarkerPoint>;
  final zoom = args['zoom'] as double;
  final bbox = (args['bbox'] as BoundingBox).expand(0.10);
  final cell = cellSizeDegrees(zoom);

  final sumLat = <(int, int), double>{};
  final sumLng = <(int, int), double>{};
  final count = <(int, int), int>{};

  for (final p in points) {
    if (!bbox.contains(p)) continue; // not visible: skip it
    final key = ((p.lat / cell).floor(), (p.lng / cell).floor());
    sumLat[key] = (sumLat[key] ?? 0) + p.lat;
    sumLng[key] = (sumLng[key] ?? 0) + p.lng;
    count[key] = (count[key] ?? 0) + 1;
  }

  return [
    for (final key in count.keys) ClusterNode(sumLat[key]! / count[key]!, sumLng[key]! / count[key]!, count[key]!),
  ];
}
