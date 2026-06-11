import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:legend_of_heroes/game/core/game_state.dart';
import 'package:legend_of_heroes/game/repositories/save_repository.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';

void main() {
  test('HiveSaveRepository persists and restores runtime state', () async {
    final tempDir = await Directory.systemTemp.createTemp('legend_save_test_');
    Hive.init(tempDir.path);
    addTearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    final repository = HiveSaveRepository(boxName: 'test_save');
    final state = GameState.initial(
      const GameDefinitions(
        rooms: {},
        npcs: {},
        items: {},
        quests: {},
        dialogues: {},
        events: {},
        sects: {},
        skills: {},
      ),
    ).copyWith(currentRoomId: 'old_well', logs: []);

    await repository.save(state);
    final loaded = await repository.load();

    expect(loaded, isNotNull);
    expect(loaded?.currentRoomId, 'old_well');
    expect(loaded?.player.name, '冒险者');
    expect(loaded?.definitions, isNull);
  });
}
