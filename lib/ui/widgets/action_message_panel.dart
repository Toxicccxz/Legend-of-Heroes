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
      child: Column(
        children: [
          _MessageFilterBar(state: state, ref: ref),
          const SizedBox(height: 6),
          Expanded(child: _MessageLog(state: state)),
          const SizedBox(height: 6),
          const SizedBox(height: 84, child: _ExitButtons()),
        ],
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

class _ExitButtons extends StatelessWidget {
  const _ExitButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 48,
          child: Text('出口', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        Expanded(
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 1.65,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
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
    final exits =
        state.definitions?.rooms[state.currentRoomId]?.exits ?? const {};
    final enabled = exits.containsKey(direction);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: enabled ? Colors.white : Colors.grey.shade100,
        side: BorderSide(color: enabled ? Colors.black : Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed:
          enabled
              ? () => ref
                  .read(gameControllerProvider.notifier)
                  .dispatch(MoveAction(direction))
              : null,
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
  }
}
