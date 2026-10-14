import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'cluster_engine.dart';

/// Draws every cluster in a single paint pass on one canvas, with no widget per marker.
///
/// [viewport] is the map area being shown. Positions use a simple linear mapping from latitude and
/// longitude to pixels, which is fine for a demo. A real map gives you its own projection.
class ClusterPainter extends CustomPainter {
  ClusterPainter({required this.clusters, required this.viewport});

  final List<ClusterNode> clusters;
  final BoundingBox viewport;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xCC2D5A27);
    final edge = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final c in clusters) {
      final dx = (c.lng - viewport.minLng) / viewport.lngSpan * size.width;
      final dy = (viewport.maxLat - c.lat) / viewport.latSpan * size.height;
      if (dx < -40 || dx > size.width + 40 || dy < -40 || dy > size.height + 40) continue; // off screen
      final center = Offset(dx, dy);
      final radius = 8 + 6 * math.log(c.count + 1) / math.ln10;

      canvas.drawCircle(center, radius, fill);
      canvas.drawCircle(center, radius, edge);

      if (c.count > 1) {
        final text = TextPainter(
          text: TextSpan(
            text: '${c.count}',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant ClusterPainter old) => old.clusters != clusters || old.viewport != viewport;
}
