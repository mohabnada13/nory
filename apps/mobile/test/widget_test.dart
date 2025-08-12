// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nory_shop_mobile/main.dart';

void main() {
  testWidgets('Nory Shop app smoke test', (WidgetTester tester) async {
    // Build the app.
    await tester.pumpWidget(const NoryShopApp());

    // Allow initial animations / future microtasks to complete.
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify that the app shows the brand name somewhere (Splash/Onboarding).
    expect(find.text('Nory Shop'), findsWidgets);
  });
}
