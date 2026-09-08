import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:techmission/app/app.dart';

void main() {
  testWidgets('TechMission arranca y muestra la pantalla principal', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const ProviderScope(child: TechMissionApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
