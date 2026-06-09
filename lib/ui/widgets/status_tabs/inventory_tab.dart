import 'package:flutter/material.dart';

import '../../../game/core/game_state.dart';

class InventoryTab extends StatelessWidget {
  const InventoryTab({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    if (state.inventory.isEmpty) {
      return const Center(child: Text('背包为空'));
    }
    return ListView(
      children: state.inventory.map((entry) {
        final item = state.definitions?.items[entry.itemId];
        return Text('${item?.name ?? entry.itemId} x${entry.count}');
      }).toList(),
    );
  }
}
