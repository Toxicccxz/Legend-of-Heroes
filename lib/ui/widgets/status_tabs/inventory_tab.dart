import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/core/game_action.dart';
import '../../../game/core/game_controller.dart';
import '../../../game/core/game_state.dart';
import '../../../game/models/item_definition.dart';

class InventoryTab extends StatelessWidget {
  const InventoryTab({super.key, required this.state, required this.ref});

  final GameState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (state.inventory.isEmpty) {
      return const Center(child: Text('背包为空'));
    }
    return ListView(
      children:
          state.inventory.map((entry) {
            final item = state.definitions?.items[entry.itemId];
            final canEquip = item?.type == ItemType.equipment;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item?.name ?? entry.itemId} x${entry.count}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (canEquip)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(42, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed:
                          () => ref
                              .read(gameControllerProvider.notifier)
                              .dispatch(EquipItemAction(entry.itemId)),
                      child: const Text('装备', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
