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
  test('entry master joins sect and teaches entry skill', () {
    final controller = GameController(
      definitions: _definitions(),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(
      const InteractWithNpcAction('sword_instructor', 'joinSect'),
    );
    controller.dispatch(
      const InteractWithNpcAction('sword_instructor', 'learn'),
    );

    expect(controller.state.player.sectId, 'qingyun_sect');
    expect(controller.state.player.sectRank, 'outer_disciple');
    expect(controller.state.player.masterNpcId, 'sword_instructor');
    expect(controller.state.player.learnedSectSkillIds, ['basic_sword']);
  });

  test('advanced master requires previous learning', () {
    final controller = GameController(
      definitions: _definitions(),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(
      const InteractWithNpcAction('sword_instructor', 'joinSect'),
    );
    controller.dispatch(
      const InteractWithNpcAction('advanced_master', 'joinSect'),
    );

    expect(controller.state.player.masterNpcId, 'sword_instructor');
    expect(controller.state.logs.last.message, contains('须先完成前一阶段学习'));
  });

  test('learning progression unlocks higher masters but blocks stealing', () {
    final controller = GameController(
      definitions: _definitions(),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(
      const InteractWithNpcAction('sword_instructor', 'joinSect'),
    );
    controller.dispatch(
      const InteractWithNpcAction('sword_instructor', 'learn'),
    );
    controller.dispatch(
      const InteractWithNpcAction('advanced_master', 'joinSect'),
    );
    controller.dispatch(const InteractWithNpcAction('elder_master', 'learn'));
    controller.dispatch(
      const InteractWithNpcAction('advanced_master', 'learn'),
    );

    expect(controller.state.player.masterNpcId, 'advanced_master');
    expect(controller.state.player.learnedSectSkillIds, [
      'basic_sword',
      'wind_step',
    ]);
    expect(
      controller.state.logs.any((log) => log.message.contains('不可偷师学艺')),
      isTrue,
    );
  });

  test('joining one sect blocks apprenticeship in another sect', () {
    final controller = GameController(
      definitions: _definitions(),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(
      const InteractWithNpcAction('sword_instructor', 'joinSect'),
    );
    controller.dispatch(
      const InteractWithNpcAction('rival_master', 'joinSect'),
    );

    expect(controller.state.player.sectId, 'qingyun_sect');
    expect(controller.state.player.masterNpcId, 'sword_instructor');
    expect(
      controller.state.logs.any((log) => log.message.contains('不可跨门派拜师')),
      isTrue,
    );
  });
}

GameDefinitions _definitions() {
  return const GameDefinitions(
    rooms: {},
    zones: {},
    npcs: {
      'sword_instructor': NpcDefinition(
        id: 'sword_instructor',
        name: 'Entry Master',
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
      'advanced_master': NpcDefinition(
        id: 'advanced_master',
        name: 'Advanced Master',
        description: '',
        dialogueId: 'dialogue_advanced_master',
        interactions: [
          NpcInteractionOption(
            type: 'joinSect',
            label: '拜师',
            sectId: 'qingyun_sect',
            requiresSectId: 'qingyun_sect',
          ),
          NpcInteractionOption(
            type: 'learn',
            label: '请教',
            sectId: 'qingyun_sect',
            requiresSectId: 'qingyun_sect',
          ),
        ],
      ),
      'elder_master': NpcDefinition(
        id: 'elder_master',
        name: 'Elder Master',
        description: '',
        dialogueId: 'dialogue_elder_master',
        interactions: [
          NpcInteractionOption(
            type: 'joinSect',
            label: '拜师',
            sectId: 'qingyun_sect',
            requiresSectId: 'qingyun_sect',
          ),
          NpcInteractionOption(
            type: 'learn',
            label: '请教',
            sectId: 'qingyun_sect',
            requiresSectId: 'qingyun_sect',
          ),
        ],
      ),
      'rival_master': NpcDefinition(
        id: 'rival_master',
        name: 'Rival Master',
        description: '',
        dialogueId: 'dialogue_rival_master',
        interactions: [
          NpcInteractionOption(
            type: 'joinSect',
            label: '拜师',
            sectId: 'rival_sect',
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
      'dialogue_advanced_master': DialogueDefinition(
        id: 'dialogue_advanced_master',
        lines: [],
        events: [],
      ),
      'dialogue_elder_master': DialogueDefinition(
        id: 'dialogue_elder_master',
        lines: [],
        events: [],
      ),
      'dialogue_rival_master': DialogueDefinition(
        id: 'dialogue_rival_master',
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
        ranks: ['outer_disciple', 'inner_disciple', 'true_disciple'],
        skills: ['basic_sword', 'wind_step', 'ultimate_sword'],
        masters: [
          SectMasterDefinition(
            npcId: 'sword_instructor',
            level: 0,
            title: 'Entry',
            rank: 'outer_disciple',
            skillIds: ['basic_sword'],
          ),
          SectMasterDefinition(
            npcId: 'advanced_master',
            level: 1,
            title: 'Advanced',
            rank: 'inner_disciple',
            skillIds: ['wind_step'],
          ),
          SectMasterDefinition(
            npcId: 'elder_master',
            level: 2,
            title: 'Elder',
            rank: 'true_disciple',
            skillIds: ['ultimate_sword'],
          ),
        ],
      ),
      'rival_sect': SectDefinition(
        id: 'rival_sect',
        name: 'Rival',
        description: '',
        ranks: ['rival_disciple', 'rival_inner', 'rival_true'],
        skills: ['rival_skill', 'rival_step', 'rival_ultimate'],
        masters: [
          SectMasterDefinition(
            npcId: 'rival_master',
            level: 0,
            title: 'Entry',
            rank: 'rival_disciple',
            skillIds: ['rival_skill'],
          ),
          SectMasterDefinition(
            npcId: 'rival_master',
            level: 1,
            title: 'Advanced',
            rank: 'rival_inner',
            skillIds: ['rival_step'],
          ),
          SectMasterDefinition(
            npcId: 'rival_master',
            level: 2,
            title: 'Elder',
            rank: 'rival_true',
            skillIds: ['rival_ultimate'],
          ),
        ],
      ),
    },
    skills: {
      'basic_sword': SkillDefinition(
        id: 'basic_sword',
        name: 'Basic Sword',
        description: '',
        category: 'martial',
      ),
      'wind_step': SkillDefinition(
        id: 'wind_step',
        name: 'Wind Step',
        description: '',
        category: 'martial',
      ),
      'ultimate_sword': SkillDefinition(
        id: 'ultimate_sword',
        name: 'Ultimate Sword',
        description: '',
        category: 'martial',
      ),
      'rival_skill': SkillDefinition(
        id: 'rival_skill',
        name: 'Rival Skill',
        description: '',
        category: 'martial',
      ),
      'rival_step': SkillDefinition(
        id: 'rival_step',
        name: 'Rival Step',
        description: '',
        category: 'martial',
      ),
      'rival_ultimate': SkillDefinition(
        id: 'rival_ultimate',
        name: 'Rival Ultimate',
        description: '',
        category: 'martial',
      ),
    },
  );
}
