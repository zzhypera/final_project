// This is a basic Flutter widget test for the Campus Cafeteria app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_cafeteria/main.dart';

void main() {
  testWidgets('App renders and shows home screen content',
      (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const CampusCafeteriaApp());
    // Wait for async menu load (HTTP returns 400 in tests) to settle.
    await tester.pumpAndSettle();

    // Verify that the home screen shows the welcome banner text.
    expect(find.textContaining('Welcome to'), findsOneWidget);
    expect(find.text('VIEW MENU'), findsOneWidget);

    // Verify that the NavigationBar is present.
    expect(find.byType(NavigationBar), findsOneWidget);

    // Tap the "Menu" navigation destination and trigger a frame.
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();

    // Verify that the menu screen heading is shown.
    expect(find.text('Choose your food'), findsOneWidget);
  });
}
