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
      title: '',
      child: Column(
        children: [
          Expanded(child: _MessageLog(state: state)),
          const SizedBox(height: 6),
          const SizedBox(height: 86, child: _ExitButtons()),
        ],
      ),
    );
  }
}

class _MessageLog extends StatelessWidget {
  const _MessageLog({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final logs = state.logs;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListView(
        children:
            logs.map((log) {
              return Text('[${_formatTime(log.timestamp)}] ${log.message}');
            }).toList(),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
