import '../core/game_state.dart';
import '../models/item_definition.dart';

class InventorySystem {
  const InventorySystem();

  GameState addItem(GameState state, String itemId, int count) {
    final entries = List<InventoryEntry>.from(state.inventory);
    final index = entries.indexWhere((entry) => entry.itemId == itemId);
    if (index == -1) {
      entries.add(InventoryEntry(itemId: itemId, count: count));
    } else {
      entries[index] = entries[index].copyWith(
        count: entries[index].count + count,
      );
    }
    return state.copyWith(inventory: entries);
  }

  GameState removeItem(GameState state, String itemId, int count) {
    final entries = List<InventoryEntry>.from(state.inventory);
    final index = entries.indexWhere((entry) => entry.itemId == itemId);
    if (index == -1) {
      return state;
    }
    final remaining = entries[index].count - count;
    if (remaining <= 0) {
      entries.removeAt(index);
    } else {
      entries[index] = entries[index].copyWith(count: remaining);
    }
    return state.copyWith(inventory: entries);
  }

  GameState useItem(GameState state, String itemId) {
    final item = state.definitions?.items[itemId];
    if (item == null || item.type != ItemType.consumable) {
      return state;
    }
    return removeItem(state, itemId, 1);
  }

  int getItemCount(GameState state, String itemId) {
    for (final entry in state.inventory) {
      if (entry.itemId == itemId) {
        return entry.count;
      }
    }
    return 0;
  }
}
