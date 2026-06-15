import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/core/game_action.dart';
import '../../../game/core/game_controller.dart';
import '../../../game/core/game_state.dart';
import '../../../game/systems/equipment_system.dart';

class EquipmentTab extends StatelessWidget {
  const EquipmentTab({super.key, required this.state, required this.ref});

  final GameState state;
  final WidgetRef ref;

  static const _equipmentSystem = EquipmentSystem();

  @override
  Widget build(BuildContext context) {
    if (state.equippedItems.isEmpty) {
      return const Text('当前未装备物品。');
    }
    final effects = _equipmentSystem.getEquippedEffects(state);
    return ListView(
      children: [
        for (final entry in state.equippedItems.entries)
          _EquipmentRow(
            slot: entry.key,
            itemName:
                state.definitions?.items[entry.value]?.name ?? entry.value,
            ref: ref,
          ),
        if (effects.isNotEmpty) ...[
          const Divider(height: 12),
          Text(
            '属性：${_formatEffects(effects)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String _formatEffects(Map<String, int> effects) {
    return effects.entries
        .map((entry) => '${entry.key} +${entry.value}')
        .join('，');
  }
}

class _EquipmentRow extends StatelessWidget {
  const _EquipmentRow({
    required this.slot,
    required this.itemName,
    required this.ref,
  });

  final String slot;
  final String itemName;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$slot：$itemName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
