import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/core/game_action.dart';
import '../../../game/core/game_controller.dart';
import '../../../game/core/game_state.dart';
import '../../../game/models/skill_definition.dart';

class SkillTab extends StatelessWidget {
  const SkillTab({super.key, required this.state, required this.ref});

  final GameState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final skills = state.definitions?.skills.values.toList() ?? const [];
    final knownSkills =
        skills.where((skill) {
          return (state.player.skillLevels[skill.id] ?? 0) > 0;
        }).toList();
    final mapped = state.player.mappedSkillIds;

    return ListView(
      children: [
        const Text('已学技能', style: TextStyle(fontWeight: FontWeight.w800)),
        if (knownSkills.isEmpty) const Text('尚未学会技能。'),
        for (final skill in knownSkills)
          _KnownSkillRow(
            skill: skill,
            level: state.player.skillLevels[skill.id] ?? 0,
            mappedSlots:
                mapped.entries
                    .where((entry) => entry.value == skill.id)
                    .map((entry) => entry.key)
                    .toList(),
            onMap:
                skill.mappedSlots.isEmpty
                    ? null
                    : (slot) => ref
                        .read(gameControllerProvider.notifier)
                        .dispatch(MapSkillAction(slot, skill.id)),
          ),
        const Divider(),
        const Text('技能图鉴', style: TextStyle(fontWeight: FontWeight.w800)),
        for (final skill in skills) _SkillCatalogRow(skill: skill),
      ],
    );
  }
}

class _SkillCatalogRow extends StatelessWidget {
  const _SkillCatalogRow({required this.skill});

  final SkillDefinition skill;

  @override
  Widget build(BuildContext context) {
    final performs =
        skill.performIds.isEmpty ? '无绝招' : '绝招：${skill.performIds.join('、')}';
    final family = skill.familyId == null ? '通用' : skill.familyId!;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${skill.name} · ${_kindLabel(skill.kind)} · ${skill.category} · ${skill.slot.name} · 威${skill.power}/难${skill.difficulty} · $family · $performs',
      ),
    );
  }

  String _kindLabel(SkillKind kind) {
    return switch (kind) {
      SkillKind.basic => '基础',
      SkillKind.special => '武功',
      SkillKind.ultimate => '绝学',
    };
  }
}

class _KnownSkillRow extends StatelessWidget {
  const _KnownSkillRow({
    required this.skill,
    required this.level,
    required this.mappedSlots,
    required this.onMap,
  });

  final SkillDefinition skill;
  final int level;
  final List<String> mappedSlots;
  final void Function(String slot)? onMap;

  @override
  Widget build(BuildContext context) {
    final mappedText =
        mappedSlots.isEmpty ? '' : ' 已映射：${mappedSlots.join('、')}';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${skill.name} Lv.$level$mappedText'),
          if (skill.mappedSlots.isNotEmpty)
            Wrap(
              spacing: 4,
              children: [
                for (final slot in skill.mappedSlots)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 26),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onMap == null ? null : () => onMap!(slot),
                    child: Text(
                      '映射$slot',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
