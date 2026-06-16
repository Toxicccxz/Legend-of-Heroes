import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_state.dart';
import 'package:legend_of_heroes/game/models/skill_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';
import 'package:legend_of_heroes/game/systems/skill_system.dart';

void main() {
  const system = SkillSystem();

  test('learnSkill records special skill and its base skill', () {
    final state = GameState.initial(_definitions());

    final learned = system.learnSkill(state, 'basic_sword');

    expect(learned.player.skillLevels['basic_sword'], 1);
    expect(learned.player.skillLevels['sword'], 1);
  });

  test('mapSkill requires the player to know the skill', () {
    final state = GameState.initial(_definitions());

    final result = system.mapSkill(
      state,
      slot: 'sword',
      skillId: 'basic_sword',
    );

    expect(result.success, isFalse);
    expect(result.state.player.mappedSkillIds, isEmpty);
  });

  test('mapSkill maps a learned special skill to an allowed slot', () {
    final state = system.learnSkill(
      GameState.initial(_definitions()),
      'basic_sword',
    );

    final result = system.mapSkill(
      state,
      slot: 'sword',
      skillId: 'basic_sword',
    );

    expect(result.success, isTrue);
    expect(result.state.player.mappedSkillIds['sword'], 'basic_sword');
  });
}

GameDefinitions _definitions() {
  return const GameDefinitions(
    rooms: {},
    zones: {},
    npcs: {},
    items: {},
    quests: {},
    dialogues: {},
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
        mappedSlots: ['sword', 'parry'],
      ),
    },
  );
}
