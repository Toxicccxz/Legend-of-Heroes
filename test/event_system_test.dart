import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_state.dart';
import 'package:legend_of_heroes/game/models/event_definition.dart';
import 'package:legend_of_heroes/game/models/room_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';
import 'package:legend_of_heroes/game/systems/event_system.dart';

void main() {
  test('processRestEvents only reads events configured on the current room', () {
    final definitions = GameDefinitions(
      rooms: {
        'village_entrance': RoomDefinition.fromJson({
          'id': 'village_entrance',
          'name': '废弃村口',
          'description': '入口',
          'restEvents': ['event_rest'],
        }),
        'old_well': RoomDefinition.fromJson({
          'id': 'old_well',
          'name': '老井',
          'description': '井边',
        }),
      },
      npcs: const {},
      items: const {},
      quests: const {},
      dialogues: const {},
      events: const {
        'event_rest': EventDefinition(
          id: 'event_rest',
          type: 'rest',
          message: '休息',
          logType: 'system',
          effects: {},
        ),
      },
      sects: const {},
      skills: const {},
    );
    const eventSystem = EventSystem();

    final entranceState = GameState.initial(definitions);
    final wellState = entranceState.copyWith(currentRoomId: 'old_well');

    expect(eventSystem.processRestEvents(entranceState), hasLength(1));
    expect(eventSystem.processRestEvents(wellState), isEmpty);
  });
}
