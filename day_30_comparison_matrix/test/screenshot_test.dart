// Regenerates docs/screenshot.png from the demo's fake data, scrolled sideways a little so the fixed
// label column and the pinned header are visible.
//
//   SCREENSHOT=1 flutter test test/screenshot_test.dart
//
// Skipped in a normal `flutter test` run. Uses the fonts that ship with the Flutter SDK.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:comparison_matrix_demo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadSdkFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) throw StateError('FLUTTER_ROOT is not set');
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String name) async => ByteData.sublistView(await File('$dir/$name').readAsBytes());

  final roboto = FontLoader('Roboto')
    ..addFont(read('Roboto-Regular.ttf'))
    ..addFont(read('Roboto-Medium.ttf'))
    ..addFont(read('Roboto-Bold.ttf'));
  await roboto.load();
  final icons = FontLoader('MaterialIcons')..addFont(read('MaterialIcons-Regular.otf'));
  await icons.load();
}

void main() {
  testWidgets(
    'writes docs/screenshot.png',
    (tester) async {
      await tester.runAsync(_loadSdkFonts);
      tester.view.physicalSize = const Size(780, 1200); // 390 x 600 logical at 2x
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: key, child: const DemoApp()));
      await tester.drag(find.byKey(const Key('body-scroll')), const Offset(-110, 0));
      await tester.pumpAndSettle();

      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      await tester.runAsync(() => File('docs/screenshot.png').writeAsBytes(bytes!));
    },
    // Skipped unless SCREENSHOT=1 is set.
    skip: Platform.environment['SCREENSHOT'] == null,
  );
}
