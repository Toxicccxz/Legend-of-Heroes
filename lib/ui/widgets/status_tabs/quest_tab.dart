import 'package:flutter/material.dart';

import '../../../game/core/game_state.dart';

class QuestTab extends StatelessWidget {
  const QuestTab({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final quests = state.definitions?.quests.values.toList() ?? const [];
    return ListView.separated(
      itemCount: quests.length,
      separatorBuilder: (context, index) => const Divider(height: 14),
      itemBuilder: (context, index) {
        final quest = quests[index];
        final progress = state.questProgress[quest.id];
        final current =
            progress?.progress['collected'] ??
            progress?.progress['investigated'] ??
            progress?.progress['arrived'];
        final required = progress?.progress['required'];
        final suffix =
            current != null && required != null ? ' $current/$required' : '';
        return Text(
          '${quest.title}$suffix',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        );
      },
    );
  }
}
