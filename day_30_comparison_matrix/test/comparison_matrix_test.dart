import 'package:comparison_matrix_demo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double offsetOf(WidgetTester tester, String key) =>
    tester.state<ScrollableState>(find.descendant(of: find.byKey(Key(key)), matching: find.byType(Scrollable))).position.pixels;

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 1500); // 390 x 750 logical
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const DemoApp());
  }

  testWidgets('shows property names and values', (tester) async {
    await pumpApp(tester);
    expect(find.text('Property A'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text(r'$2.1k'), findsOneWidget);
  });

  testWidgets('dragging the body sideways moves the header with it', (tester) async {
    await pumpApp(tester);
    expect(offsetOf(tester, 'header-scroll'), 0);
    await tester.drag(find.byKey(const Key('body-scroll')), const Offset(-200, 0));
    await tester.pumpAndSettle();
    final body = offsetOf(tester, 'body-scroll');
    expect(body, greaterThan(0));
    expect(offsetOf(tester, 'header-scroll'), body);
  });

  testWidgets('dragging the header sideways moves the body with it', (tester) async {
    await pumpApp(tester);
    await tester.drag(find.byKey(const Key('header-scroll')), const Offset(-150, 0));
    await tester.pumpAndSettle();
    final header = offsetOf(tester, 'header-scroll');
    expect(header, greaterThan(0));
    expect(offsetOf(tester, 'body-scroll'), header);
  });

  testWidgets('the label column stays put while columns scroll sideways', (tester) async {
    await pumpApp(tester);
    final before = tester.getTopLeft(find.text('Rent'));
    await tester.drag(find.byKey(const Key('body-scroll')), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Rent')), before);
  });

  testWidgets('the header stays visible while the rows scroll down', (tester) async {
    await pumpApp(tester);
    final headerTop = tester.getTopLeft(find.text('Property A'));
    final rentBefore = tester.getTopLeft(find.text('Rent')).dy;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Property A'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Property A')), headerTop, reason: 'the header did not move');
    expect(tester.getTopLeft(find.text('Rent')).dy, lessThan(rentBefore - 100), reason: 'the rows did scroll up');
  });

  testWidgets('a column keeps its value under its own property after scrolling', (tester) async {
    await pumpApp(tester);
    await tester.drag(find.byKey(const Key('body-scroll')), const Offset(-1000, 0));
    await tester.pumpAndSettle();
    final headerX = tester.getCenter(find.text('Property D')).dx;
    final valueX = tester.getCenter(find.text(r'$1.6k')).dx; // Property D's rent
    expect((headerX - valueX).abs(), lessThan(1));
  });
}
