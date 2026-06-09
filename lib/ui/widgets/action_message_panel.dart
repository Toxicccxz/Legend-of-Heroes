import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/core/game_state.dart';
import '../../game/models/npc_definition.dart';
import 'panel_frame.dart';

class ActionMessagePanel extends ConsumerWidget {
  const ActionMessagePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);

    return PanelFrame(
      title: '行动与消息',
      child: Column(
        children: [
          _TrackedQuestBar(state: state),
          const SizedBox(height: 6),
          _MessageTabs(state: state, ref: ref),
          Expanded(child: _MessageLog(state: state)),
          const SizedBox(height: 8),
          SizedBox(
            height: 126,
            child: Row(
              children: [
                Expanded(flex: 5, child: _NearbyNpcList(state: state, ref: ref)),
                const VerticalDivider(width: 18, thickness: 1.4, color: Colors.black),
                SizedBox(width: 86, child: _SmallActions(ref: ref)),
                const VerticalDivider(width: 18, thickness: 1.4, color: Colors.black),
                const Expanded(flex: 4, child: _ExitButtons()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackedQuestBar extends StatelessWidget {
  const _TrackedQuestBar({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final questId = state.trackedQuestId;
    final quest = questId == null ? null : state.definitions?.quests[questId];
    final progress = questId == null ? null : state.questProgress[questId];
    final current = progress?.progress['collected'] ??
        progress?.progress['investigated'] ??
        progress?.progress['arrived'];
    final required = progress?.progress['required'];
    final suffix = current != null && required != null ? '（$current/$required）' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.track_changes, size: 24, color: Colors.black),
          const SizedBox(width: 8),
          const Text('当前目标', style: TextStyle(fontWeight: FontWeight.w800)),
          const VerticalDivider(width: 24, color: Colors.black),
          Expanded(child: Text('${quest?.title ?? '暂无追踪任务'} $suffix')),
          OutlinedButton(
            onPressed: questId == null ? null : () {},
            child: const Text('追踪中'),
          ),
        ],
      ),
    );
  }
}

class _MessageTabs extends StatelessWidget {
  const _MessageTabs({required this.state, required this.ref});

  final GameState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MessageFilter.values.map((filter) {
        final selected = state.selectedMessageFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: selected ? Colors.grey.shade200 : Colors.white,
              side: BorderSide(width: selected ? 2 : 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            onPressed: () => ref
                .read(gameControllerProvider.notifier)
                .dispatch(SelectMessageFilterAction(filter)),
            child: Text(filter.label),
          ),
        );
      }).toList(),
    );
  }
}

class _MessageLog extends StatelessWidget {
  const _MessageLog({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final logs = state.logs.where((log) => _matchesFilter(log)).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListView(
        children: logs.map((log) {
          return Text('[${_formatTime(log.timestamp)}] ${log.message}');
        }).toList(),
      ),
    );
  }

  bool _matchesFilter(GameLogEntry log) {
    return switch (state.selectedMessageFilter) {
      MessageFilter.all => true,
      MessageFilter.dialogue => log.type == GameLogType.dialogue,
      MessageFilter.combat => log.type == GameLogType.combat,
      MessageFilter.system =>
        log.type == GameLogType.system || log.type == GameLogType.quest,
    };
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _NearbyNpcList extends StatelessWidget {
  const _NearbyNpcList({required this.state, required this.ref});

  final GameState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final room = state.definitions?.rooms[state.currentRoomId];
    final npcs = room?.npcs
            .map((id) => state.definitions?.npcs[id])
            .whereType<NpcDefinition>()
            .toList() ??
        const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('附近 NPC', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Expanded(
          child: npcs.isEmpty
              ? const Center(child: Text('附近没有 NPC'))
              : ListView.separated(
                  itemCount: npcs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final npc = npcs[index];
                    return Row(
                      children: [
                        const Icon(Icons.person_outline, size: 22),
                        Expanded(child: Text(npc.name)),
                        OutlinedButton(
                          onPressed: () => ref
                              .read(gameControllerProvider.notifier)
                              .dispatch(TalkToNpcAction(npc.id)),
                          child: const Text('交谈'),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SmallActions extends StatelessWidget {
  const _SmallActions({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _ActionButton(
          icon: Icons.search,
          label: '调查',
          onPressed: () => ref
              .read(gameControllerProvider.notifier)
              .dispatch(const InvestigateAction()),
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.hotel,
          label: '休息',
          onPressed: () => ref
              .read(gameControllerProvider.notifier)
              .dispatch(const RestAction()),
        ),
      ],
    );
  }
}

class _ExitButtons extends StatelessWidget {
  const _ExitButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('出口', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Expanded(
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: const [
              _DirectionButton(direction: 'north', label: '北'),
              _DirectionButton(direction: 'south', label: '南'),
              _DirectionButton(direction: 'east', label: '东'),
              _DirectionButton(direction: 'west', label: '西'),
            ],
          ),
        ),
      ],
    );
  }
}

class _DirectionButton extends ConsumerWidget {
  const _DirectionButton({required this.direction, required this.label});

  final String direction;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final exits = state.definitions?.rooms[state.currentRoomId]?.exits ?? const {};
    final enabled = exits.containsKey(direction);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: enabled ? Colors.white : Colors.grey.shade100,
        side: BorderSide(color: enabled ? Colors.black : Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: enabled
          ? () => ref
              .read(gameControllerProvider.notifier)
              .dispatch(MoveAction(direction))
          : null,
      child: Text(
        label,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            Text(label),
          ],
        ),
      ),
    );
  }
}

extension MessageFilterLabel on MessageFilter {
  String get label {
    return switch (this) {
      MessageFilter.all => '全部',
      MessageFilter.dialogue => '对话',
      MessageFilter.combat => '战斗',
      MessageFilter.system => '系统',
    };
  }
}
