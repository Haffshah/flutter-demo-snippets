import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_markers_demo/cluster_engine.dart';
import 'package:map_markers_demo/cluster_painter.dart';

const view = BoundingBox(minLat: 10, maxLat: 20, minLng: 70, maxLng: 80);

List<MarkerPoint> randomPoints(int n, {int seed = 1}) {
  final r = Random(seed);
  return [for (var i = 0; i < n; i++) MarkerPoint(10 + r.nextDouble() * 10, 70 + r.nextDouble() * 10)];
}

int total(List<ClusterNode> c) => c.fold(0, (a, n) => a + n.count);

void main() {
  test('expand adds 10% of the box size on every side', () {
    final e = view.expand(0.10);
    expect(e.minLat, closeTo(9, 1e-9));
    expect(e.maxLat, closeTo(21, 1e-9));
    expect(e.minLng, closeTo(69, 1e-9));
    expect(e.maxLng, closeTo(81, 1e-9));
  });

  test('nearby points share a cluster and the count adds up', () {
    final pts = [const MarkerPoint(15, 75), const MarkerPoint(15.0001, 75.0001), const MarkerPoint(15.0002, 75)];
    final clusters = MapClusterEngine.clusterSync(points: pts, zoom: 8, bbox: view);
    expect(clusters, hasLength(1));
    expect(clusters.single.count, 3);
  });

  test('far apart points stay separate', () {
    final pts = [const MarkerPoint(11, 71), const MarkerPoint(19, 79)];
    expect(MapClusterEngine.clusterSync(points: pts, zoom: 8, bbox: view), hasLength(2));
  });

  test('only markers inside the padded viewport are clustered', () {
    final pts = [
      const MarkerPoint(15, 75), // inside
      const MarkerPoint(20.5, 75), // outside the box but inside the 10% padding
      const MarkerPoint(30, 75), // far outside
    ];
    final clusters = MapClusterEngine.clusterSync(points: pts, zoom: 8, bbox: view);
    expect(total(clusters), 2);
  });

  test('zooming in produces more, smaller clusters', () {
    final pts = randomPoints(2000);
    final low = MapClusterEngine.clusterSync(points: pts, zoom: 4, bbox: view).length;
    final high = MapClusterEngine.clusterSync(points: pts, zoom: 9, bbox: view).length;
    expect(high, greaterThan(low));
  });

  test('10,000 points collapse into far fewer circles and none are lost', () {
    final pts = randomPoints(10000, seed: 7);
    final clusters = MapClusterEngine.clusterSync(points: pts, zoom: 6, bbox: view);
    expect(clusters.length, lessThan(2000));
    expect(total(clusters), 10000); // all points are inside the viewport
  });

  test('the isolate version gives the same answer as the sync version', () async {
    final pts = randomPoints(3000, seed: 3);
    final sync = MapClusterEngine.clusterSync(points: pts, zoom: 7, bbox: view);
    final async = await MapClusterEngine.computeClusters(points: pts, zoom: 7, bbox: view);
    expect(async.length, sync.length);
    expect(total(async), total(sync));
  });

  testWidgets('painter draws clusters onto a canvas without errors', (tester) async {
    final clusters = MapClusterEngine.clusterSync(points: randomPoints(500), zoom: 6, bbox: view);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 400,
          child: CustomPaint(painter: ClusterPainter(clusters: clusters, viewport: view)),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  test('painter repaints only when its inputs change', () {
    final a = ClusterPainter(clusters: const [], viewport: view);
    expect(a.shouldRepaint(ClusterPainter(clusters: const [], viewport: view)), isFalse);
    expect(a.shouldRepaint(ClusterPainter(clusters: [const ClusterNode(15, 75, 1)], viewport: view)), isTrue);
  });
}
