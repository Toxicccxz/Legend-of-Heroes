import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/core/game_state.dart';
import 'panel_frame.dart';

class ActionMessagePanel extends ConsumerWidget {
  const ActionMessagePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);

    return PanelFrame(
      title: '江湖消息',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actionPadHeight = math.min(
            214.0,
            math.max(132.0, constraints.maxHeight * 0.48),
          );
          return Column(
            children: [
              _MessageFilterBar(state: state, ref: ref),
              const SizedBox(height: 6),
              Expanded(child: _MessageLog(state: state)),
              const SizedBox(height: 6),
              SizedBox(height: actionPadHeight, child: const _MudActionPad()),
            ],
          );
        },
      ),
    );
  }
}

class _MessageLog extends StatefulWidget {
  const _MessageLog({required this.state});

  final GameState state;

  @override
  State<_MessageLog> createState() => _MessageLogState();
}

class _MessageLogState extends State<_MessageLog> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToBottomAfterLayout();
  }

  @override
  void didUpdateWidget(covariant _MessageLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.logs.length != widget.state.logs.length ||
        oldWidget.state.selectedMessageFilter !=
            widget.state.selectedMessageFilter) {
      _scrollToBottomAfterLayout();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs(widget.state);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(),
        borderRadius: BorderRadius.circular(6),
      ),
      child:
          logs.isEmpty
              ? const Center(
                child: Text('暂无消息', style: TextStyle(color: Colors.white70)),
              )
              : ListView(
                controller: _scrollController,
                children:
                    logs.map((log) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '[${_formatTime(log.timestamp)}] ${log.message}',
                          style: TextStyle(
                            color: _colorForLog(log.type),
                            fontFamily: 'monospace',
                            height: 1.25,
                          ),
                        ),
                      );
                    }).toList(),
              ),
    );
  }

  List<GameLogEntry> _filteredLogs(GameState state) {
    return switch (state.selectedMessageFilter) {
      MessageFilter.all => state.logs,
      MessageFilter.dialogue =>
        state.logs.where((log) => log.type == GameLogType.dialogue).toList(),
      MessageFilter.combat =>
        state.logs.where((log) => log.type == GameLogType.combat).toList(),
      MessageFilter.system =>
        state.logs.where((log) => log.type == GameLogType.system).toList(),
      MessageFilter.quest =>
        state.logs.where((log) => log.type == GameLogType.quest).toList(),
    };
  }

  Color _colorForLog(GameLogType type) {
    return switch (type) {
      GameLogType.dialogue => const Color(0xFFBDE0FE),
      GameLogType.combat => const Color(0xFFFFC857),
      GameLogType.system => const Color(0xFFE6E6E6),
      GameLogType.quest => const Color(0xFFC8F7C5),
    };
  }

  void _scrollToBottomAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _MessageFilterBar extends StatelessWidget {
  const _MessageFilterBar({required this.state, required this.ref});

  final GameState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Row(
      children:
          MessageFilter.values.map((filter) {
            final selected = state.selectedMessageFilter == filter;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
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
                          .dispatch(SelectMessageFilterAction(filter)),
                  child: Text(
                    filter.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            );
          }).toList(),
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
      MessageFilter.quest => '任务',
    };
  }
}

class _MudActionPad extends ConsumerWidget {
  const _MudActionPad();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final exits =
        state.definitions?.rooms[state.currentRoomId]?.exits.keys.toSet() ??
        const <String>{};

    return Column(
      children: [
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _QuickCommandButton(
                command: 'look room',
                label: '查看',
                icon: Icons.visibility_outlined,
              ),
              _QuickCommandButton(
                command: 'score',
                label: '状态',
                icon: Icons.badge_outlined,
              ),
              _QuickCommandButton(
                command: 'inventory',
                label: '背包',
                icon: Icons.inventory_2_outlined,
              ),
              _QuickCommandButton(
                command: 'investigate',
                label: '调查',
                icon: Icons.search,
              ),
              _QuickCommandButton(
                command: 'rest',
                label: '休息',
                icon: Icons.bed,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Row(
            children: [
              const SizedBox(
                width: 48,
                child: Text(
                  '出口',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(child: _ExitDirectionPad(enabledDirections: exits)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExitDirectionPad extends StatelessWidget {
  const _ExitDirectionPad({required this.enabledDirections});

  final Set<String> enabledDirections;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _directionButton('northwest')),
              const SizedBox(width: 6),
              Expanded(child: _directionButton('north')),
              const SizedBox(width: 6),
              Expanded(child: _directionButton('northeast')),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _directionButton('west')),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _directionButton('up')),
                    const SizedBox(height: 6),
                    Expanded(child: _directionButton('down')),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: _directionButton('east')),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _directionButton('southwest')),
              const SizedBox(width: 6),
              Expanded(child: _directionButton('south')),
              const SizedBox(width: 6),
              Expanded(child: _directionButton('southeast')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _directionButton(String direction) {
    return _DirectionButton(
      direction: direction,
      enabled: enabledDirections.contains(direction),
      icon: _directionIcon(direction),
      label: _directionLabel(direction),
    );
  }

  IconData _directionIcon(String direction) {
    return switch (direction) {
      'north' => Icons.arrow_upward,
      'south' => Icons.arrow_downward,
      'east' => Icons.arrow_forward,
      'west' => Icons.arrow_back,
      'northeast' => Icons.north_east,
      'northwest' => Icons.north_west,
      'southeast' => Icons.south_east,
      'southwest' => Icons.south_west,
      'up' => Icons.keyboard_double_arrow_up,
      'down' => Icons.keyboard_double_arrow_down,
      _ => Icons.circle_outlined,
    };
  }

  String _directionLabel(String direction) {
    return switch (direction) {
      'north' => '北',
      'south' => '南',
      'east' => '东',
      'west' => '西',
      'northeast' => '东北',
      'northwest' => '西北',
      'southeast' => '东南',
      'southwest' => '西南',
      'up' => '上',
      'down' => '下',
      _ => direction,
    };
  }
}

class _QuickCommandButton extends ConsumerWidget {
  const _QuickCommandButton({
    required this.command,
    required this.label,
    required this.icon,
  });

  final String command;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 30),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Colors.black),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed:
            () => ref
                .read(gameControllerProvider.notifier)
                .dispatch(ExecuteCommandAction(command)),
        icon: Icon(icon, size: 15),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _DirectionButton extends ConsumerWidget {
  const _DirectionButton({
    required this.direction,
    required this.enabled,
    required this.icon,
    required this.label,
  });

  final String direction;
  final bool enabled;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? Colors.black : Colors.grey.shade500,
        backgroundColor: enabled ? Colors.white : Colors.grey.shade100,
        disabledForegroundColor: Colors.grey.shade500,
        padding: const EdgeInsets.all(4),
        side: BorderSide(color: enabled ? Colors.black : Colors.grey.shade400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed:
          enabled
              ? () => ref
                  .read(gameControllerProvider.notifier)
                  .dispatch(ExecuteCommandAction(direction))
              : null,
      child: Tooltip(
        message: label,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
