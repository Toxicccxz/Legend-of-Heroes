import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_action.dart';
import 'package:legend_of_heroes/game/core/game_controller.dart';
import 'package:legend_of_heroes/game/models/dialogue_definition.dart';
import 'package:legend_of_heroes/game/models/event_definition.dart';
import 'package:legend_of_heroes/game/models/item_definition.dart';
import 'package:legend_of_heroes/game/models/npc_definition.dart';
import 'package:legend_of_heroes/game/models/quest_definition.dart';
import 'package:legend_of_heroes/game/models/quest_progress.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';
import 'package:legend_of_heroes/game/repositories/save_repository.dart';

void main() {
  test('giving an accepted item removes it and applies events', () {
    final controller = GameController(
      definitions: _definitions(),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(const GiveItemToNpcAction('guard', 'healing_herb'));

    expect(
      controller.state.inventory.any((entry) => entry.itemId == 'healing_herb'),
      isFalse,
    );
    expect(
      controller.state.questProgress['side_guard_herb']?.status,
      QuestStatus.completed,
    );
    expect(
      controller.state.logs.map((log) => log.message),
      containsAll(['你将止血草交给守卫。', '守卫接过止血草，神色终于缓和下来。']),
    );
  });

  test('giving an unavailable item leaves inventory unchanged', () {
    final controller = GameController(
      definitions: _definitions(),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(const GiveItemToNpcAction('guard', 'wooden_token'));

    expect(
      controller.state.inventory.any((entry) => entry.itemId == 'healing_herb'),
      isTrue,
    );
    expect(controller.state.logs.last.message, '守卫摆了摆手，并不需要木制令牌。');
  });
}

GameDefinitions _definitions() {
  return const GameDefinitions(
    rooms: {},
    zones: {},
    npcs: {
      'guard': NpcDefinition(
        id: 'guard',
        name: '守卫',
        description: '',
        dialogueId: 'dialogue_guard',
        acceptedItems: [
          NpcAcceptedItemDefinition(
            itemId: 'healing_herb',
            label: '交出止血草',
            eventIds: ['event_give_guard_herb'],
          ),
        ],
      ),
    },
    items: {
      'healing_herb': ItemDefinition(
        id: 'healing_herb',
        name: '止血草',
        description: '',
        type: ItemType.quest,
        effects: {},
      ),
      'wooden_token': ItemDefinition(
        id: 'wooden_token',
        name: '木制令牌',
        description: '',
        type: ItemType.quest,
        effects: {},
      ),
    },
    quests: {
      'side_guard_herb': QuestDefinition(
        id: 'side_guard_herb',
        title: '给守卫送止血草',
        category: '支线',
        description: '',
        objectives: [],
        initialProgress: {'collected': 1, 'required': 1},
      ),
    },
    dialogues: {
      'dialogue_guard': DialogueDefinition(
        id: 'dialogue_guard',
        lines: [],
        events: [],
      ),
    },
    events: {
      'event_give_guard_herb': EventDefinition(
        id: 'event_give_guard_herb',
        type: 'giveItem',
        message: '守卫接过止血草，神色终于缓和下来。',
        logType: 'quest',
        effects: {'completeQuestId': 'side_guard_herb'},
      ),
    },
    sects: {},
    skills: {},
  );
}
