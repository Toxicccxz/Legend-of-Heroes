import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/models/item_definition.dart';
import 'package:legend_of_heroes/game/models/room_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';

void main() {
  test('new optional fields keep model constructors source-compatible', () {
    const definitions = GameDefinitions(
      rooms: {},
      npcs: {},
      items: {},
      quests: {},
      dialogues: {},
      events: {},
      sects: {},
      skills: {},
    );
    const room = RoomDefinition(
      id: 'room',
      name: '房间',
      description: '',
      tags: [],
      exits: {},
      npcs: [],
      onEnterEvents: [],
      investigateEvents: [],
      mapX: 0,
      mapY: 0,
    );
    const item = ItemDefinition(
      id: 'item',
      name: '物品',
      description: '',
      type: ItemType.quest,
      effects: {},
    );

    expect(definitions.zones, isEmpty);
    expect(room.zoneId, 'default');
    expect(room.restEvents, isEmpty);
    expect(item.useEvents, isEmpty);
  });
}
