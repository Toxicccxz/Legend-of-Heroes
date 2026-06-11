import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_state.dart';
import 'package:legend_of_heroes/game/models/room_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';
import 'package:legend_of_heroes/game/systems/map_system.dart';

void main() {
  test(
    'getVisibleRooms keeps the map focused on the current zone and radius',
    () {
      const mapSystem = MapSystem();
      final state = GameState.initial(
        GameDefinitions(
          rooms: {
            'current': _room('current', zoneId: 'village', mapX: 10, mapY: 10),
            'nearby': _room('nearby', zoneId: 'village', mapX: 12, mapY: 10),
            'far': _room('far', zoneId: 'village', mapX: 20, mapY: 10),
            'other_zone': _room(
              'other_zone',
              zoneId: 'forest',
              mapX: 10,
              mapY: 10,
            ),
          },
          npcs: const {},
          items: const {},
          quests: const {},
          dialogues: const {},
          events: const {},
          sects: const {},
          skills: const {},
        ),
      ).copyWith(currentRoomId: 'current');

      final visibleIds = mapSystem
          .getVisibleRooms(state, radius: 3)
          .map((room) => room.id);

      expect(visibleIds, containsAll(<String>['current', 'nearby']));
      expect(visibleIds, isNot(contains('far')));
      expect(visibleIds, isNot(contains('other_zone')));
    },
  );
}

RoomDefinition _room(
  String id, {
  required String zoneId,
  required int mapX,
  required int mapY,
}) {
  return RoomDefinition(
    id: id,
    name: id,
    description: '',
    zoneId: zoneId,
    tags: const [],
    exits: const {},
    npcs: const [],
    onEnterEvents: const [],
    investigateEvents: const [],
    restEvents: const [],
    mapX: mapX,
    mapY: mapY,
  );
}
