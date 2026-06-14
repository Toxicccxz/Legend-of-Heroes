import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_action.dart';
import 'package:legend_of_heroes/game/core/game_controller.dart';
import 'package:legend_of_heroes/game/models/event_definition.dart';
import 'package:legend_of_heroes/game/models/room_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';
import 'package:legend_of_heroes/game/repositories/save_repository.dart';

void main() {
  test('combat logs switch the message filter to combat', () {
    final controller = GameController(
      definitions: const GameDefinitions(
        rooms: {
          'village_entrance': RoomDefinition(
            id: 'village_entrance',
            name: 'Entrance',
            description: '',
            tags: [],
            exits: {},
            npcs: [],
            onEnterEvents: ['event_auto_combat'],
            investigateEvents: [],
            mapX: 0,
            mapY: 0,
          ),
        },
        npcs: {},
        items: {},
        quests: {},
        dialogues: {},
        events: {
          'event_auto_combat': EventDefinition(
            id: 'event_auto_combat',
            type: 'enterRoom',
            message: 'A wolf attacks.',
            logType: 'combat',
            effects: {},
          ),
        },
        sects: {},
        skills: {},
      ),
      saveRepository: InMemorySaveRepository(),
    );

    expect(controller.state.selectedMessageFilter, MessageFilter.combat);
  });
}
