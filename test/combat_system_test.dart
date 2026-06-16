import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_state.dart';
import 'package:legend_of_heroes/game/models/dialogue_definition.dart';
import 'package:legend_of_heroes/game/models/npc_definition.dart';
import 'package:legend_of_heroes/game/models/skill_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';
import 'package:legend_of_heroes/game/systems/combat_system.dart';

void main() {
  const system = CombatSystem();

  test('fightNpc uses mapped skill and awards experience on victory', () {
    final initialState = GameState.initial(_definitions());
    final state = initialState.copyWith(
      player: initialState.player.copyWith(
        skillLevels: const {'sword': 1, 'basic_sword': 4},
        mappedSkillIds: const {'sword': 'basic_sword'},
      ),
    );

    final result = system.fightNpc(state, 'bandit', spar: false);

    expect(result.state.player.exp, state.player.exp + 10);
    expect(result.logs.any((log) => log.contains('Qingyun Sword')), isTrue);
    expect(result.logs.any((log) => log.contains('获得 10 点经验')), isTrue);
  });

  test('spar cannot reduce player hp below one', () {
    final initialState = GameState.initial(_definitions());
    final state = initialState.copyWith(
      player: initialState.player.copyWith(hp: 2),
    );

    final result = system.fightNpc(state, 'strong_bandit', spar: true);

    expect(result.state.player.hp, 1);
    expect(result.logs.first, contains('点到即止'));
    expect(result.logs.any((log) => log.contains('Wolf Claw')), isTrue);
  });

  test('fightNpc can use non-sword attack slots', () {
    final initialState = GameState.initial(_definitions());
    final state = initialState.copyWith(
      player: initialState.player.copyWith(
        skillLevels: const {'hand': 1, 'iron_palm': 5},
        mappedSkillIds: const {'hand': 'iron_palm'},
      ),
    );

    final result = system.fightNpc(state, 'monk', spar: true);

    expect(result.logs.any((log) => log.contains('Iron Palm')), isTrue);
    expect(result.logs.any((log) => log.contains('Arhat Fist')), isTrue);
  });
}

GameDefinitions _definitions() {
  return const GameDefinitions(
    rooms: {},
    zones: {},
    npcs: {
      'bandit': NpcDefinition(
        id: 'bandit',
        name: 'Bandit',
        description: '',
        dialogueId: 'dialogue_bandit',
        combat: NpcCombatDefinition(
          maxHp: 10,
          attack: 1,
          defense: 1,
          dodge: 1,
          expReward: 10,
          skillLevels: {'sword': 1},
          mappedSkillIds: {'sword': 'sword'},
        ),
      ),
      'strong_bandit': NpcDefinition(
        id: 'strong_bandit',
        name: 'Strong Bandit',
        description: '',
        dialogueId: 'dialogue_bandit',
        combat: NpcCombatDefinition(
          maxHp: 200,
          attack: 50,
          defense: 1,
          dodge: 1,
          skillLevels: {'sword': 3, 'wolf_claw': 3},
          mappedSkillIds: {'sword': 'wolf_claw'},
        ),
      ),
      'monk': NpcDefinition(
        id: 'monk',
        name: 'Monk',
        description: '',
        dialogueId: 'dialogue_bandit',
        combat: NpcCombatDefinition(
          maxHp: 200,
          attack: 10,
          defense: 1,
          dodge: 1,
          attackSkillSlot: 'hand',
          skillLevels: {'hand': 3, 'arhat_fist': 3},
          mappedSkillIds: {'hand': 'arhat_fist'},
        ),
      ),
    },
    items: {},
    quests: {},
    dialogues: {
      'dialogue_bandit': DialogueDefinition(
        id: 'dialogue_bandit',
        lines: [],
        events: [],
      ),
    },
    events: {},
    sects: {},
    skills: {
      'sword': SkillDefinition(
        id: 'sword',
        name: 'Basic Sword',
        description: '',
        category: 'basic',
        kind: SkillKind.basic,
      ),
      'basic_sword': SkillDefinition(
        id: 'basic_sword',
        name: 'Qingyun Sword',
        description: '',
        category: 'sword',
        baseSkillId: 'sword',
        mappedSlots: ['sword'],
      ),
      'wolf_claw': SkillDefinition(
        id: 'wolf_claw',
        name: 'Wolf Claw',
        description: '',
        category: 'claw',
        baseSkillId: 'sword',
        mappedSlots: ['sword'],
      ),
      'iron_palm': SkillDefinition(
        id: 'iron_palm',
        name: 'Iron Palm',
        description: '',
        category: 'hand',
        baseSkillId: 'hand',
        mappedSlots: ['hand'],
      ),
      'arhat_fist': SkillDefinition(
        id: 'arhat_fist',
        name: 'Arhat Fist',
        description: '',
        category: 'hand',
        baseSkillId: 'hand',
        mappedSlots: ['hand'],
      ),
    },
  );
}
