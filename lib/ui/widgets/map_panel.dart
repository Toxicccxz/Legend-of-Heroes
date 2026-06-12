import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/core/game_state.dart';
import '../../game/models/npc_definition.dart';
import '../../game/models/room_definition.dart';
import '../../game/systems/map_system.dart';
import 'panel_frame.dart';

class MapPanel extends ConsumerWidget {
  const MapPanel({super.key});

  static const _mapSystem = MapSystem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final room = state.definitions?.rooms[state.currentRoomId];
    final zone = _mapSystem.getCurrentZone(state);
    final visibleRooms = _mapSystem.getVisibleRooms(
      state,
      radius: zone?.visibleRadius ?? 3,
    );

    return PanelFrame(
      title: '',
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: _RoomMapPainter(
                      rooms: visibleRooms,
                      currentRoom: room,
                      currentRoomId: state.currentRoomId,
                    ),
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
                const SizedBox(width: 8),
                SizedBox(
                  width: 132,
                  child: _MapInteractionList(state: state, ref: ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _RoomInfo(room: room, zoneName: zone?.name),
        ],
      ),
    );
  }
}

class _MapInteractionList extends StatelessWidget {
  const _MapInteractionList({required this.state, required this.ref});

  final GameState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final room = state.definitions?.rooms[state.currentRoomId];
    final npcs =
        room?.npcs
            .map((id) => state.definitions?.npcs[id])
            .whereType<NpcDefinition>()
            .toList() ??
        const <NpcDefinition>[];
    final hasInvestigate = room?.investigateEvents.isNotEmpty ?? false;
    final hasRest = room?.restEvents.isNotEmpty ?? false;
    final hasInteractions = npcs.isNotEmpty || hasInvestigate || hasRest;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('可互动', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Expanded(
            child:
                hasInteractions
                    ? ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final npc in npcs)
                          _InteractionRow(
                            icon: Icons.person_outline,
                            label: npc.name,
                            actionLabel: '交谈',
                            onPressed:
                                () => ref
                                    .read(gameControllerProvider.notifier)
                                    .dispatch(TalkToNpcAction(npc.id)),
                          ),
                        if (hasInvestigate)
                          _InteractionRow(
                            icon: Icons.search,
                            label: '可疑线索',
                            actionLabel: '调查',
                            onPressed:
                                () => ref
                                    .read(gameControllerProvider.notifier)
                                    .dispatch(const InvestigateAction()),
                          ),
                        if (hasRest)
                          _InteractionRow(
                            icon: Icons.bed,
                            label: '休息点',
                            actionLabel: '休息',
                            onPressed:
                                () => ref
                                    .read(gameControllerProvider.notifier)
                                    .dispatch(const RestAction()),
                          ),
                      ],
                    )
                    : const Center(child: Text('无')),
          ),
        ],
      ),
    );
  }
}

class _InteractionRow extends StatelessWidget {
  const _InteractionRow({
    required this.icon,
    required this.label,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: onPressed,
            child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _MapInteractionList extends StatelessWidget {
  const _MapInteractionList({required this.state, required this.ref});

  final GameState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final room = state.definitions?.rooms[state.currentRoomId];
    final npcs =
        room?.npcs
            .map((id) => state.definitions?.npcs[id])
            .whereType<NpcDefinition>()
            .toList() ??
        const <NpcDefinition>[];
    final hasInvestigate = room?.investigateEvents.isNotEmpty ?? false;
    final hasRest = room?.restEvents.isNotEmpty ?? false;
    final hasInteractions = npcs.isNotEmpty || hasInvestigate || hasRest;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('可互动', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Expanded(
            child:
                hasInteractions
                    ? ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final npc in npcs)
                          _InteractionRow(
                            icon: Icons.person_outline,
                            label: npc.name,
                            actionLabel: '交谈',
                            onPressed:
                                () => ref
                                    .read(gameControllerProvider.notifier)
                                    .dispatch(TalkToNpcAction(npc.id)),
                          ),
                        if (hasInvestigate)
                          _InteractionRow(
                            icon: Icons.search,
                            label: '可疑线索',
                            actionLabel: '调查',
                            onPressed:
                                () => ref
                                    .read(gameControllerProvider.notifier)
                                    .dispatch(const InvestigateAction()),
                          ),
                        if (hasRest)
                          _InteractionRow(
                            icon: Icons.bed,
                            label: '休息点',
                            actionLabel: '休息',
                            onPressed:
                                () => ref
                                    .read(gameControllerProvider.notifier)
                                    .dispatch(const RestAction()),
                          ),
                      ],
                    )
                    : const Center(child: Text('无')),
          ),
        ],
      ),
    );
  }
}

class _InteractionRow extends StatelessWidget {
  const _InteractionRow({
    required this.icon,
    required this.label,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: onPressed,
            child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _RoomInfo extends StatelessWidget {
  const _RoomInfo({required this.room, required this.zoneName});

  final RoomDefinition? room;
  final String? zoneName;

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
            '区域： ${zoneName ?? '未知区域'} · ${room?.name ?? '未知房间'}',
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
          width: 14,
          height: 14,
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
  const _RoomMapPainter({
    required this.rooms,
    required this.currentRoom,
    required this.currentRoomId,
  });

  static const _legendWidth = 112.0;
  static const _maxGridStep = 22.0;
  static const _nodeSize = 12.0;
  static const _viewportDiameter = 7;

  final List<RoomDefinition> rooms;
  final RoomDefinition? currentRoom;
  final String currentRoomId;

  @override
  void paint(Canvas canvas, Size size) {
    final current = currentRoom;
    if (rooms.isEmpty || current == null) {
      return;
    }

    final mapWidth = math.max(80.0, size.width - _legendWidth);
    final mapHeight = math.max(80.0, size.height);
    final gridStep = math.min(
      _maxGridStep,
      math.min(mapWidth, mapHeight) / (_viewportDiameter + 1),
    );
    final center = Offset(mapWidth / 2, mapHeight / 2);

    final gridPaint =
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    for (var x = center.dx % gridStep; x < mapWidth; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, mapHeight), gridPaint);
    }
    for (var y = center.dy % gridStep; y < mapHeight; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(mapWidth, y), gridPaint);
    }

    final positions = <String, Offset>{
      for (final room in rooms)
        room.id: _positionFor(room, current, center, gridStep),
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
      final nodeCenter = positions[room.id];
      if (nodeCenter == null) {
        continue;
      }
      final isCurrent = room.id == currentRoomId;
      final rect = Rect.fromCenter(
        center: nodeCenter,
        width: _nodeSize,
        height: _nodeSize,
      );
      final paint =
          Paint()
            ..color = isCurrent ? Colors.black : Colors.white
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

  Offset _positionFor(
    RoomDefinition room,
    RoomDefinition current,
    Offset center,
    double gridStep,
  ) {
    final relativeX = room.mapX - current.mapX;
    final relativeY = room.mapY - current.mapY;
    return Offset(
      center.dx + relativeX * gridStep,
      center.dy + relativeY * gridStep,
    );
  }

  @override
  bool shouldRepaint(covariant _RoomMapPainter oldDelegate) {
    return oldDelegate.currentRoomId != currentRoomId ||
        oldDelegate.currentRoom != currentRoom ||
        oldDelegate.rooms != rooms;
  }
}
