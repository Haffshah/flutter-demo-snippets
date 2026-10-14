import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_ui_demo/main.dart';

void main() {
  testWidgets('shows coupons and filters by search', (tester) async {
    await tester.pumpWidget(const DemoApp());
    expect(find.text('My Coupons'), findsOneWidget);
    expect(find.text('SWIGGY250'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'myntra');
    await tester.pump();
    expect(find.text('MYNTRA15'), findsOneWidget);
    expect(find.text('SWIGGY250'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('No coupons match'), findsOneWidget);
  });
}
