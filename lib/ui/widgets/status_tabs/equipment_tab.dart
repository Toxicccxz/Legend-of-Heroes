import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/core/game_action.dart';
import '../../../game/core/game_controller.dart';
import '../../../game/core/game_state.dart';
import '../../../game/models/item_definition.dart';
import '../../../game/systems/equipment_system.dart';

class EquipmentTab extends StatelessWidget {
  const EquipmentTab({super.key, required this.state, required this.ref});

  final GameState state;
  final WidgetRef ref;

  static const _equipmentSystem = EquipmentSystem();

  @override
  Widget build(BuildContext context) {
    final effects = _equipmentSystem.getEquippedEffects(state);
    return ListView(
      children: [
        for (final slot in EquipmentSystem.slots)
          _EquipmentRow(
            slot: slot,
            itemName: _itemNameFor(slot),
            equipped: state.equippedItems.containsKey(slot),
            ref: ref,
          ),
        if (effects.isNotEmpty) ...[
          const Divider(height: 12),
          Text(
            '属性：${_formatEffects(effects)}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String _itemNameFor(String slot) {
    final itemId = state.equippedItems[slot];
    if (itemId == null) {
      return '未装备';
    }
    return state.definitions?.items[itemId]?.name ?? itemId;
  }

  String _formatEffects(Map<String, int> effects) {
    return effects.entries
        .map((entry) => '${ItemEffectKeys.labelFor(entry.key)} +${entry.value}')
        .join('，');
  }
}

class _EquipmentRow extends StatelessWidget {
  const _EquipmentRow({
    required this.slot,
    required this.itemName,
    required this.equipped,
    required this.ref,
  });

  final String slot;
  final String itemName;
  final bool equipped;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${EquipmentSlotIds.labelFor(slot)}：$itemName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (equipped)
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
                      .dispatch(UnequipItemAction(slot)),
              child: const Text('卸下', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
