import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_controller.dart';
import 'package:legend_of_heroes/game/repositories/save_repository.dart';
import 'package:legend_of_heroes/main.dart';

void main() {
  testWidgets('App menu starts and enters game without layout overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saveRepositoryProvider.overrideWithValue(InMemorySaveRepository()),
        ],
        child: const LegendOfHeroesApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Legend of Heroes'), findsOneWidget);
    expect(find.text('继续游戏'), findsOneWidget);
    expect(find.text('新的冒险'), findsOneWidget);

    await tester.tap(find.text('新的冒险'));
    await tester.pumpAndSettle();

    expect(find.text('姓名： 冒险者'), findsOneWidget);
    expect(find.text('可互动'), findsOneWidget);
    expect(find.text('出口'), findsOneWidget);
    expect(find.textContaining('废弃村口'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
