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

    expect(find.text('姓名： 冒险者'), findsOneWidget);
    expect(find.text('可互动'), findsOneWidget);
    expect(find.text('出口'), findsOneWidget);
    expect(find.textContaining('废弃村口'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
