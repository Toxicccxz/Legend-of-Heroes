import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/models/dialogue_definition.dart';
import 'package:legend_of_heroes/game/models/event_definition.dart';
import 'package:legend_of_heroes/game/models/item_definition.dart';
import 'package:legend_of_heroes/game/models/npc_definition.dart';
import 'package:legend_of_heroes/game/models/room_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('asset game definitions pass integrity validation', () async {
    final definitions = await AssetGameDefinitionRepository().load();

    expect(definitions.rooms, isNotEmpty);
  });

  test('validateIntegrity reports missing content references', () {
    final definitions = GameDefinitions(
      rooms: {
        'room': _room(
          zoneId: 'missing_zone',
          exits: const {'north': 'missing_room'},
          npcs: const ['missing_npc'],
          onEnterEvents: const ['missing_enter_event'],
          investigateEvents: const ['missing_investigate_event'],
          restEvents: const ['missing_rest_event'],
        ),
      },
      zones: const {},
      npcs: const {
        'npc': NpcDefinition(
          id: 'npc',
          name: 'Npc',
          description: '',
          dialogueId: 'missing_dialogue',
        ),
      },
      items: const {
        'item': ItemDefinition(
          id: 'item',
          name: 'Item',
          description: '',
          type: ItemType.consumable,
          effects: {},
          useEvents: ['missing_use_event'],
        ),
      },
      quests: const {},
      dialogues: const {
        'dialogue': DialogueDefinition(
          id: 'dialogue',
          lines: [],
          events: ['missing_dialogue_event'],
        ),
      },
      events: const {
        'event': EventDefinition(
          id: 'event',
          type: 'investigate',
          message: '',
          logType: 'system',
          effects: {'questId': 'missing_quest'},
        ),
      },
      sects: const {},
      skills: const {},
    );

    expect(
      definitions.validateIntegrity,
      throwsA(
        isA<StateError>()
            .having(
              (error) => error.message,
              'message',
              contains('Room room references missing zoneId "missing_zone".'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('Event event references missing effects.questId'),
            ),
      ),
    );
  });

  test('validateIntegrity rejects oversized equipment effects', () {
    const definitions = GameDefinitions(
      rooms: {},
      npcs: {},
      items: {
        'artifact': ItemDefinition(
          id: 'artifact',
          name: 'Artifact',
          description: '',
          type: ItemType.equipment,
          effects: {'attack': 99},
          slot: 'weapon',
        ),
      },
      quests: {},
      dialogues: {},
      events: {},
      sects: {},
      skills: {},
    );

    expect(
      definitions.validateIntegrity,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('above cap'),
        ),
      ),
    );
  });
}

RoomDefinition _room({
  required String zoneId,
  required Map<String, String> exits,
  required List<String> npcs,
  required List<String> onEnterEvents,
  required List<String> investigateEvents,
  required List<String> restEvents,
}) {
  return RoomDefinition(
    id: 'room',
    name: 'Room',
    description: '',
    zoneId: zoneId,
    tags: const [],
    exits: exits,
    npcs: npcs,
    onEnterEvents: onEnterEvents,
    investigateEvents: investigateEvents,
    restEvents: restEvents,
    mapX: 0,
    mapY: 0,
  );
}
