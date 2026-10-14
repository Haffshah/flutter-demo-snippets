// Regenerates docs/screenshot.png: 10,000 synthetic markers clustered at one zoom level and
// drawn by ClusterPainter.
//
//   SCREENSHOT=1 flutter test test/screenshot_test.dart
//
// Skipped in a normal `flutter test` run. Uses the fonts that ship with the Flutter SDK.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_markers_demo/cluster_engine.dart';
import 'package:map_markers_demo/cluster_painter.dart';

Future<void> _loadSdkFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) throw StateError('FLUTTER_ROOT is not set');
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String name) async => ByteData.sublistView(await File('$dir/$name').readAsBytes());
  final roboto = FontLoader('Roboto')..addFont(read('Roboto-Bold.ttf'));
  await roboto.load();
}

void main() {
  testWidgets(
    'writes docs/screenshot.png',
    (tester) async {
      await tester.runAsync(_loadSdkFonts);
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      const view = BoundingBox(minLat: 10, maxLat: 20, minLng: 70, maxLng: 80);
      final random = Random(7);
      // Three dense areas plus scattered points, so clusters differ in size.
      final centers = [(13.0, 73.0), (17.0, 77.0), (15.5, 71.5)];
      final points = <MarkerPoint>[
        for (var i = 0; i < 10000; i++)
          if (i % 4 == 0)
            MarkerPoint(10 + random.nextDouble() * 10, 70 + random.nextDouble() * 10)
          else
            MarkerPoint(
              centers[i % 3].$1 + (random.nextDouble() - 0.5) * 2.5,
              centers[i % 3].$2 + (random.nextDouble() - 0.5) * 2.5,
            ),
      ];
      final clusters = MapClusterEngine.clusterSync(points: points, zoom: 6, bbox: view);

      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              color: const Color(0xFFEEF2EA),
              child: CustomPaint(
                size: const Size(400, 400),
                painter: ClusterPainter(clusters: clusters, viewport: view, fontFamily: 'Roboto'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      await tester.runAsync(() => File('docs/screenshot.png').writeAsBytes(bytes!));
      // ignore: avoid_print
      print('10,000 markers -> ${clusters.length} circles');
    },
    // Skipped unless SCREENSHOT=1 is set.
    skip: Platform.environment['SCREENSHOT'] == null,
  );
}
