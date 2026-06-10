import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/core/game_controller.dart';
import '../../game/core/game_state.dart';
import '../../game/models/room_definition.dart';
import 'panel_frame.dart';

class MapPanel extends ConsumerWidget {
  const MapPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final room = state.definitions?.rooms[state.currentRoomId];

    return PanelFrame(
      title: '',
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _RoomMapPainter(state),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 112,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _LegendItem(label: '其他房间', current: false),
                      SizedBox(height: 8),
                      _LegendItem(label: '当前位置', current: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _RoomInfo(room: room),
        ],
      ),
    );
  }
}

class _RoomInfo extends StatelessWidget {
  const _RoomInfo({required this.room});

  final RoomDefinition? room;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '区域： ${room?.name ?? '未知区域'}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('描述： ${room?.description ?? ''}'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.current});

  final String label;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            border: Border.all(width: 1.4),
            color: current ? Colors.black : Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class _RoomMapPainter extends CustomPainter {
  const _RoomMapPainter(this.state);

  final GameState state;

  @override
  void paint(Canvas canvas, Size size) {
    final rooms = state.definitions?.rooms.values.toList() ?? const [];
    if (rooms.isEmpty) {
      return;
    }

    final gridPaint =
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += size.width / 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += size.height / 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final positions = <String, Offset>{
      for (final room in rooms) room.id: _positionFor(room, size),
    };
    final linePaint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2;
    for (final room in rooms) {
      final from = positions[room.id];
      if (from == null) {
        continue;
      }
      for (final toId in room.exits.values) {
        final to = positions[toId];
        if (to != null) {
          canvas.drawLine(from, to, linePaint);
        }
      }
    }

    for (final room in rooms) {
      final center = positions[room.id];
      if (center == null) {
        continue;
      }
      final current = room.id == state.currentRoomId;
      final rect = Rect.fromCenter(center: center, width: 22, height: 22);
      final paint =
          Paint()
            ..color = current ? Colors.black : Colors.white
            ..style = PaintingStyle.fill;
      final border =
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, border);
    }
  }

  Offset _positionFor(RoomDefinition room, Size size) {
    final left = 46 + room.mapX * ((size.width - 160) / 4);
    final top = 22 + room.mapY * ((size.height - 44) / 3);
    return Offset(left, top);
  }

  @override
  bool shouldRepaint(covariant _RoomMapPainter oldDelegate) {
    return oldDelegate.state.currentRoomId != state.currentRoomId ||
        oldDelegate.state.definitions != state.definitions;
  }
}
