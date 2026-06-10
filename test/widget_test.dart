import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/main.dart';

void main() {
  testWidgets('App starts without layout overflow on a narrow phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: LegendOfHeroesApp()));
    await tester.pumpAndSettle();

    expect(find.text('人物状态'), findsOneWidget);
    expect(find.text('地图'), findsOneWidget);
    expect(find.text('行动与消息'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
