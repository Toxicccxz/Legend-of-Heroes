import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_action.dart';
import 'package:legend_of_heroes/game/core/game_controller.dart';
import 'package:legend_of_heroes/game/models/dialogue_definition.dart';
import 'package:legend_of_heroes/game/models/npc_definition.dart';
import 'package:legend_of_heroes/game/models/sect_definition.dart';
import 'package:legend_of_heroes/game/models/skill_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';
import 'package:legend_of_heroes/game/repositories/save_repository.dart';

void main() {
  test('NPC joinSect interaction joins the configured sect', () {
    final controller = GameController(
      definitions: _definitions(),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(
      const InteractWithNpcAction('sword_instructor', 'joinSect'),
    );

    expect(controller.state.player.sectId, 'qingyun_sect');
    expect(controller.state.player.sectRank, 'outer_disciple');
  });

  test('NPC learn interaction requires matching sect membership', () {
    final controller = GameController(
      definitions: _definitions(),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(
      const InteractWithNpcAction('sword_instructor', 'learn'),
    );

    expect(controller.state.logs.last.message, contains('尚非本门弟子'));
  });
}

GameDefinitions _definitions() {
  return const GameDefinitions(
    rooms: {},
    zones: {},
    npcs: {
      'sword_instructor': NpcDefinition(
        id: 'sword_instructor',
        name: 'Sword Instructor',
        description: '',
        dialogueId: 'dialogue_sword_instructor',
        interactions: [
          NpcInteractionOption(
            type: 'joinSect',
            label: '拜师',
            sectId: 'qingyun_sect',
          ),
          NpcInteractionOption(
            type: 'learn',
            label: '请教',
            sectId: 'qingyun_sect',
            requiresSectId: 'qingyun_sect',
          ),
        ],
      ),
    },
    items: {},
    quests: {},
    dialogues: {
      'dialogue_sword_instructor': DialogueDefinition(
        id: 'dialogue_sword_instructor',
        lines: [],
        events: [],
      ),
    },
    events: {},
    sects: {
      'qingyun_sect': SectDefinition(
        id: 'qingyun_sect',
        name: 'Qingyun',
        description: '',
        ranks: ['outer_disciple'],
        skills: ['basic_sword'],
      ),
    },
    skills: {
      'basic_sword': SkillDefinition(
        id: 'basic_sword',
        name: 'Basic Sword',
        description: '',
        category: 'martial',
      ),
    },
  );
}
