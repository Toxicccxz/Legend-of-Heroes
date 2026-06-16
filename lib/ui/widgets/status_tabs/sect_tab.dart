import 'package:flutter/material.dart';

import '../../../game/core/game_state.dart';
import '../../../game/systems/sect_system.dart';

class SectTab extends StatelessWidget {
  const SectTab({super.key, required this.state});

  final GameState state;
  static const _sectSystem = SectSystem();

  @override
  Widget build(BuildContext context) {
    final sects = state.definitions?.sects.values.toList() ?? const [];
    final currentSect = _sectSystem.getCurrentSect(state);
    final currentMaster = _sectSystem.getCurrentMaster(state);
    final learnedSkills = _sectSystem.getLearnedSectSkills(state);

    return ListView(
      children: [
        Text('当前门派：${currentSect?.name ?? '未入门'}'),
        Text('当前身份：${state.player.sectRank ?? '无'}'),
        Text('当前师父：${currentMaster?.name ?? '无'}'),
        Text(
          '已学功法：${learnedSkills.isEmpty ? '无' : learnedSkills.map((skill) => skill.name).join('、')}',
        ),
        const Divider(),
        for (final sect in sects) ...[
          Text(sect.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(sect.description),
          if (sect.features.isNotEmpty) Text('特点：${sect.features}'),
          Text('拜师规则：${sect.rules.join('；')}'),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
