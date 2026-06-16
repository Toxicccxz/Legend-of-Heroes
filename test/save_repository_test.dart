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
    final initialState = GameState.initial(
      const GameDefinitions(
        rooms: {},
        zones: {},
        npcs: {},
        items: {},
        quests: {},
        dialogues: {},
        events: {},
        sects: {},
        skills: {},
      ),
    );
    final state = initialState.copyWith(
      currentRoomId: 'old_well',
      player: initialState.player.copyWith(
        sectId: 'qingyun_sect',
        sectRank: '青云门弟子',
        masterNpcId: 'sword_instructor',
        learnedSectSkillIds: ['basic_sword'],
        skillLevels: {'sword': 1, 'basic_sword': 1},
        mappedSkillIds: {'sword': 'basic_sword'},
      ),
      logs: [],
    );

    await repository.save(state);
    final loaded = await repository.load();

    expect(loaded, isNotNull);
    expect(loaded?.currentRoomId, 'old_well');
    expect(loaded?.player.name, '冒险者');
    expect(loaded?.player.sectId, 'qingyun_sect');
    expect(loaded?.player.sectRank, '青云门弟子');
    expect(loaded?.player.masterNpcId, 'sword_instructor');
    expect(loaded?.player.learnedSectSkillIds, ['basic_sword']);
    expect(loaded?.player.skillLevels, {'sword': 1, 'basic_sword': 1});
    expect(loaded?.player.mappedSkillIds, {'sword': 'basic_sword'});
    expect(loaded?.definitions, isNull);
  });
}
