import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_action.dart';
import 'package:legend_of_heroes/game/core/game_controller.dart';
import 'package:legend_of_heroes/game/models/event_definition.dart';
import 'package:legend_of_heroes/game/models/room_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';
import 'package:legend_of_heroes/game/repositories/save_repository.dart';

void main() {
  test('room command can move the player through an event effect', () {
    final controller = GameController(
      definitions: _definitions(),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(
      const ExecuteRoomCommandAction('open', targetId: 'cellar'),
    );

    expect(controller.state.currentRoomId, 'cellar_door');
    expect(
      controller.state.logs.map((log) => log.message),
      containsAll(['你推开半掩的木门。', '潮湿的冷气从地下涌出。', '你来到地窖门口。']),
    );
  });

  test('typed room command can resolve verb and target', () {
    final controller = GameController(
      definitions: _definitions(),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(const ExecuteCommandAction('open cellar'));

    expect(controller.state.currentRoomId, 'cellar_door');
  });
}

GameDefinitions _definitions() {
  return const GameDefinitions(
    rooms: {
      'village_entrance': RoomDefinition(
        id: 'village_entrance',
        name: '废屋',
        description: '',
        zoneId: 'zone',
        tags: [],
        exits: {},
        npcs: [],
        commands: [
          RoomCommandDefinition(
            verb: 'open',
            label: '推开地窖门',
            description: '你推开半掩的木门。',
            targetId: 'cellar',
            eventIds: ['event_open_cellar_door'],
          ),
        ],
        onEnterEvents: [],
        investigateEvents: [],
        mapX: 0,
        mapY: 0,
      ),
      'cellar_door': RoomDefinition(
        id: 'cellar_door',
        name: '地窖门口',
        description: '',
        zoneId: 'zone',
        tags: [],
        exits: {},
        npcs: [],
        onEnterEvents: [],
        investigateEvents: [],
        mapX: 0,
        mapY: 1,
      ),
    },
    zones: {},
    npcs: {},
    items: {},
    quests: {},
    dialogues: {},
    events: {
      'event_open_cellar_door': EventDefinition(
        id: 'event_open_cellar_door',
        type: 'roomCommand',
        message: '潮湿的冷气从地下涌出。',
        logType: 'system',
        effects: {'moveToRoomId': 'cellar_door'},
      ),
    },
    sects: {},
    skills: {},
  );
}
