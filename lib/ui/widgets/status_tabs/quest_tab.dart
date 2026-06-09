import 'package:flutter/material.dart';

import '../../../game/core/game_state.dart';
import '../../../game/models/quest_progress.dart';

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
        final current = progress?.progress['collected'] ??
            progress?.progress['investigated'] ??
            progress?.progress['arrived'];
        final required = progress?.progress['required'];
        final suffix = current != null && required != null
            ? ' $current/$required'
            : '';
        final tracked = state.trackedQuestId == quest.id;
        return Row(
          children: [
            Text(_iconFor(quest.category)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${quest.category}：${quest.title}$suffix',
                style: TextStyle(
                  fontWeight: tracked ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            Text(_statusText(progress?.status)),
          ],
        );
      },
    );
  }

  String _iconFor(String category) {
    return switch (category) {
      '主线' => '○',
      '支线' => '□',
      '门派引导' => '◇',
      _ => '•',
    };
  }

  String _statusText(QuestStatus? status) {
    return switch (status) {
      QuestStatus.completed => '完成',
      QuestStatus.active => '›',
      QuestStatus.inactive || null => '',
    };
  }
}
