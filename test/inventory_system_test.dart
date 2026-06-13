import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_state.dart';
import 'package:legend_of_heroes/game/models/item_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';
import 'package:legend_of_heroes/game/systems/inventory_system.dart';

void main() {
  test(
    'useItem consumes consumables without applying item effects directly',
    () {
      const inventorySystem = InventorySystem();
      const item = ItemDefinition(
        id: 'test_potion',
        name: '测试药水',
        description: '',
        type: ItemType.consumable,
        effects: {'restoreHp': 20},
      );
      final state = GameState.loading().copyWith(
        definitions: const GameDefinitions(
          rooms: {},
          npcs: {},
          items: {'test_potion': item},
          quests: {},
          dialogues: {},
          events: {},
          sects: {},
          skills: {},
        ),
        player: GameState.loading().player.copyWith(hp: 50),
        inventory: const [InventoryEntry(itemId: 'test_potion', count: 1)],
      );

      final nextState = inventorySystem.useItem(state, 'test_potion');

      expect(nextState.player.hp, 50);
      expect(inventorySystem.getItemCount(nextState, 'test_potion'), 0);
    },
  );
}
