import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/core/game_state.dart';
import 'panel_frame.dart';
import 'status_tabs/equipment_tab.dart';
import 'status_tabs/inventory_tab.dart';
import 'status_tabs/quest_tab.dart';
import 'status_tabs/sect_tab.dart';
import 'status_tabs/skill_tab.dart';

class CharacterStatusPanel extends ConsumerWidget {
  const CharacterStatusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);

    return SizedBox(
      height: 245,
      child: PanelFrame(
        title: '人物状态',
        child: Row(
          children: [
            SizedBox(width: 122, child: _PlayerStats(state: state)),
            const VerticalDivider(
              width: 20,
              thickness: 1.4,
              color: Colors.black,
            ),
            Expanded(child: _StatusTabArea(state: state, ref: ref)),
          ],
        ),
      ),
    );
  }
}

class _PlayerStats extends StatelessWidget {
  const _PlayerStats({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final player = state.player;
    return FittedBox(
      alignment: Alignment.topLeft,
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 122,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatText(label: '姓名', value: player.name),
            _StatText(label: '等级', value: '${player.level}'),
            _BarStat(label: 'HP', value: player.hp, max: player.maxHp),
            _BarStat(label: 'MP', value: player.mp, max: player.maxMp),
            _BarStat(
              label: '体力',
              value: player.stamina,
              max: player.maxStamina,
            ),
            _StatText(label: '金币', value: '${player.gold} ○'),
          ],
        ),
      ),
    );
  }
}

class _StatusTabArea extends StatelessWidget {
  const _StatusTabArea({required this.state, required this.ref});

  final GameState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children:
              StatusTab.values.map((tab) {
                final selected = state.selectedStatusTab == tab;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        foregroundColor: Colors.black,
                        backgroundColor:
                            selected ? Colors.grey.shade200 : Colors.white,
                        side: BorderSide(
                          color: Colors.black,
                          width: selected ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed:
                          () => ref
                              .read(gameControllerProvider.notifier)
                              .dispatch(SelectStatusTabAction(tab)),
                      child: Text(tab.label),
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _buildSelectedTab(state),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedTab(GameState state) {
    return switch (state.selectedStatusTab) {
      StatusTab.inventory => InventoryTab(state: state),
      StatusTab.quest => QuestTab(state: state),
      StatusTab.skill => SkillTab(state: state),
      StatusTab.equipment => EquipmentTab(state: state),
      StatusTab.sect => SectTab(state: state),
    };
  }
}

class _StatText extends StatelessWidget {
  const _StatText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label： $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _BarStat extends StatelessWidget {
  const _BarStat({required this.label, required this.value, required this.max});

  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : value / max;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label    $value / $max',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            color: Colors.grey.shade700,
            backgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

extension StatusTabLabel on StatusTab {
  String get label {
    return switch (this) {
      StatusTab.inventory => '背包',
      StatusTab.quest => '任务',
      StatusTab.skill => '技能',
      StatusTab.equipment => '装备',
      StatusTab.sect => '门派',
    };
  }
}
