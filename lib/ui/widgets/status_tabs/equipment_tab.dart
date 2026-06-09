import 'package:flutter/material.dart';

import '../../../game/core/game_state.dart';

class EquipmentTab extends StatelessWidget {
  const EquipmentTab({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    if (state.equippedItems.isEmpty) {
      return const Text('当前未装备物品。');
    }
    return ListView(
      children: state.equippedItems.entries.map((entry) {
        final item = state.definitions?.items[entry.value];
        return Text('${entry.key}：${item?.name ?? entry.value}');
      }).toList(),
    );
  }
}
