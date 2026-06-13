import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_action.dart';
import 'package:legend_of_heroes/game/core/game_controller.dart';
import 'package:legend_of_heroes/game/models/event_definition.dart';
import 'package:legend_of_heroes/game/models/item_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';
import 'package:legend_of_heroes/game/repositories/save_repository.dart';

void main() {
  test('UseItemAction applies restore effects through configured events', () {
    final controller = GameController(
      definitions: const GameDefinitions(
        rooms: {},
        npcs: {},
        items: {
          'bread': ItemDefinition(
            id: 'bread',
            name: '面包',
            description: '',
            type: ItemType.consumable,
            effects: {},
            useEvents: ['event_use_bread'],
          ),
        },
        quests: {},
        dialogues: {},
        events: {
          'event_use_bread': EventDefinition(
            id: 'event_use_bread',
            type: 'useItem',
            message: '你吃下了面包，恢复 15 点体力。',
            logType: 'system',
            effects: {'restoreStamina': 15},
          ),
        },
        sects: {},
        skills: {},
      ),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(const UseItemAction('bread'));

    expect(controller.state.player.stamina, 95);
    expect(
      controller.state.inventory
          .singleWhere((entry) => entry.itemId == 'bread')
          .count,
      1,
    );
    expect(
      controller.state.logs.any((log) => log.message.contains('恢复 15 点体力')),
      isTrue,
    );
  });
}
