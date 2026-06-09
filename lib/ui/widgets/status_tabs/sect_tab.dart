import 'package:flutter/material.dart';

import '../../../game/core/game_state.dart';

class SectTab extends StatelessWidget {
  const SectTab({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final sects = state.definitions?.sects.values.toList() ?? const [];
    return ListView(
      children: [
        Text('当前门派：${state.player.sectId ?? '未入门'}'),
        Text('当前阶位：${state.player.sectRank ?? '无'}'),
        const Divider(),
        ...sects.map((sect) => Text('${sect.name}：${sect.description}')),
      ],
    );
  }
}
