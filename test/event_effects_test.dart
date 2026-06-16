import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_action.dart';
import 'package:legend_of_heroes/game/core/game_controller.dart';
import 'package:legend_of_heroes/game/models/event_definition.dart';
import 'package:legend_of_heroes/game/models/item_definition.dart';
import 'package:legend_of_heroes/game/models/room_definition.dart';
import 'package:legend_of_heroes/game/models/sect_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';
import 'package:legend_of_heroes/game/repositories/save_repository.dart';

void main() {
  test('event effects can grant and remove items', () {
    final controller = GameController(
      definitions: _definitions(
        eventEffects: const {
          'giveItemId': 'healing_herb',
          'giveItemCount': 2,
          'removeItemId': 'bread',
          'removeItemCount': 1,
        },
      ),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(const InvestigateAction());

    expect(
      controller.state.inventory
          .singleWhere((entry) => entry.itemId == 'healing_herb')
          .count,
      3,
    );
    expect(
      controller.state.inventory
          .singleWhere((entry) => entry.itemId == 'bread')
          .count,
      1,
    );
  });

  test('event effects can join a sect', () {
    final controller = GameController(
      definitions: _definitions(
        eventEffects: const {'joinSectId': 'qingyun_sect'},
      ),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(const InvestigateAction());

    expect(controller.state.player.sectId, 'qingyun_sect');
    expect(controller.state.player.sectRank, 'outer_disciple');
  });

  test('event effects can emit combat logs', () {
    final controller = GameController(
      definitions: _definitions(
        eventEffects: const {'combatLogMessage': 'A wolf lunges.'},
      ),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(const InvestigateAction());

    expect(
      controller.state.logs.any((log) => log.message == 'A wolf lunges.'),
      isTrue,
    );
    expect(controller.state.selectedMessageFilter, MessageFilter.combat);
  });
}

GameDefinitions _definitions({required Map<String, dynamic> eventEffects}) {
  return GameDefinitions(
    rooms: const {
      'village_entrance': RoomDefinition(
        id: 'village_entrance',
        name: 'Entrance',
        description: '',
        tags: [],
        exits: {},
        npcs: [],
        onEnterEvents: [],
        investigateEvents: ['event_test'],
        mapX: 0,
        mapY: 0,
      ),
    },
    npcs: const {},
    items: const {
      'bread': ItemDefinition(
        id: 'bread',
        name: 'Bread',
        description: '',
        type: ItemType.consumable,
        effects: {},
      ),
      'healing_herb': ItemDefinition(
        id: 'healing_herb',
        name: 'Herb',
        description: '',
        type: ItemType.quest,
        effects: {},
      ),
    },
    quests: const {},
    dialogues: const {},
    events: {
      'event_test': EventDefinition(
        id: 'event_test',
        type: 'investigate',
        message: '',
        logType: 'system',
        effects: eventEffects,
      ),
    },
    sects: const {
      'qingyun_sect': SectDefinition(
        id: 'qingyun_sect',
        name: 'Qingyun',
        description: '',
        ranks: ['outer_disciple'],
        skills: [],
        masters: [
          SectMasterDefinition(
            npcId: 'entry_master',
            level: 0,
            title: 'Entry',
            rank: 'outer_disciple',
            skillIds: [],
          ),
          SectMasterDefinition(
            npcId: 'advanced_master',
            level: 1,
            title: 'Advanced',
            rank: 'outer_disciple',
            skillIds: [],
          ),
          SectMasterDefinition(
            npcId: 'elder_master',
            level: 2,
            title: 'Elder',
            rank: 'outer_disciple',
            skillIds: [],
          ),
        ],
      ),
    },
    skills: const {},
  );
}
