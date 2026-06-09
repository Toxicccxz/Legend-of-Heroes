import '../core/game_state.dart';
import '../models/item_definition.dart';
import '../models/player_state.dart';

class EquipmentSystem {
  const EquipmentSystem();

  GameState equipItem(GameState state, String itemId) {
    final item = state.definitions?.items[itemId];
    final slot = item?.slot;
    if (item == null || item.type != ItemType.equipment || slot == null) {
      return state;
    }
    final nextEquipped = Map<String, String>.from(state.equippedItems);
    nextEquipped[slot] = itemId;
    return state.copyWith(equippedItems: nextEquipped);
  }

  GameState unequipItem(GameState state, String slot) {
    final nextEquipped = Map<String, String>.from(state.equippedItems)
      ..remove(slot);
    return state.copyWith(equippedItems: nextEquipped);
  }

  PlayerState calculatePlayerStats(GameState state) {
    return state.player;
  }
}
