import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_controller.dart';
import 'package:legend_of_heroes/game/models/npc_definition.dart';
import 'package:legend_of_heroes/game/models/room_definition.dart';
import 'package:legend_of_heroes/game/models/zone_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';
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
          gameDefinitionsProvider.overrideWith((ref) async => _definitions()),
          saveRepositoryProvider.overrideWithValue(InMemorySaveRepository()),
        ],
        child: const LegendOfHeroesApp(),
      ),
    );
    await _pumpUntilFound(tester, find.text('侠客行'));

    expect(find.text('侠客行'), findsOneWidget);
    expect(find.text('继续游戏'), findsOneWidget);
    expect(find.text('新的冒险'), findsOneWidget);

    await tester.tap(find.text('新的冒险'));
    await _pumpUntilFound(tester, find.text('江湖消息'));

    expect(find.text('区域：village。打谷场'), findsOneWidget);
    expect(find.text('小孩'), findsOneWidget);
    expect(find.text('问：谷堆'), findsOneWidget);
    expect(find.text('话题'), findsNothing);
    expect(find.text('切磋'), findsNothing);
    expect(find.text('江湖消息'), findsOneWidget);
    expect(find.text('角色菜单'), findsOneWidget);
    expect(find.text('侠客行 · 江湖终端'), findsNothing);
    expect(find.text('角色'), findsNothing);
    expect(find.text('出口'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 100,
}) async {
  for (var i = 0; i < maxPumps; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  await tester.pump();
}

GameDefinitions _definitions() {
  return const GameDefinitions(
    rooms: {
      'xkx_village_square': RoomDefinition(
        id: 'xkx_village_square',
        name: '打谷场',
        description: '这里是村子的中心。',
        zoneId: 'xkx_village',
        tags: ['xkx100', 'village'],
        exits: {},
        npcs: ['xkx_village_npc_kid'],
        onEnterEvents: [],
        investigateEvents: [],
        mapX: 0,
        mapY: 0,
      ),
    },
    zones: {
      'xkx_village': ZoneDefinition(
        id: 'xkx_village',
        name: 'village',
        description: '',
        visibleRadius: 4,
      ),
    },
    npcs: {
      'xkx_village_npc_kid': NpcDefinition(
        id: 'xkx_village_npc_kid',
        name: '小孩',
        description: '村里的小孩。',
        dialogueId: 'dialogue_xkx_village_kid',
        inquiries: [
          NpcInquiryDefinition(
            id: 'gudui',
            label: '谷堆',
            response: '谷堆里好像能钻进去。',
          ),
        ],
      ),
    },
    items: {},
    quests: {},
    dialogues: {},
    events: {},
    sects: {},
    skills: {},
  );
}
