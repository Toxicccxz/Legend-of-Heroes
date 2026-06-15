import '../core/game_state.dart';
import '../models/item_definition.dart';
import '../models/player_state.dart';
import 'inventory_system.dart';

class EquipmentSystem {
  const EquipmentSystem();

  static const _inventorySystem = InventorySystem();

  GameState equipItem(GameState state, String itemId) {
    final item = state.definitions?.items[itemId];
    final slot = item?.slot;
    if (item == null || item.type != ItemType.equipment || slot == null) {
      return state;
    }
    if (_inventorySystem.getItemCount(state, itemId) <= 0) {
      return state;
    }
    final previouslyEquipped = state.equippedItems[slot];
    var nextState = _inventorySystem.removeItem(state, itemId, 1);
    if (previouslyEquipped != null) {
      nextState = _inventorySystem.addItem(nextState, previouslyEquipped, 1);
    }
    final nextEquipped = Map<String, String>.from(state.equippedItems);
    nextEquipped[slot] = itemId;
    return nextState.copyWith(equippedItems: nextEquipped);
  }

  GameState unequipItem(GameState state, String slot) {
    final itemId = state.equippedItems[slot];
    if (itemId == null) {
      return state;
    }
    final nextEquipped = Map<String, String>.from(state.equippedItems)
      ..remove(slot);
    final nextState = state.copyWith(equippedItems: nextEquipped);
    return _inventorySystem.addItem(nextState, itemId, 1);
  }

  Map<String, int> getEquippedEffects(GameState state) {
    final effects = <String, int>{};
    final items = state.definitions?.items;
    if (items == null) {
      return effects;
    }
    for (final itemId in state.equippedItems.values) {
      final item = items[itemId];
      if (item == null) {
        continue;
      }
      for (final effect in item.effects.entries) {
        effects.update(
          effect.key,
          (value) => value + effect.value,
          ifAbsent: () => effect.value,
        );
      }
    }
    return effects;
  }

  PlayerState calculatePlayerStats(GameState state) {
    return state.player;
  }
}
