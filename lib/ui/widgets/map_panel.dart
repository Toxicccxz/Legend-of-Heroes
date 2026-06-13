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

class MapPanel extends ConsumerStatefulWidget {
  const MapPanel({super.key});

  static const _mapSystem = MapSystem();

  @override
  ConsumerState<MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends ConsumerState<MapPanel> {
  String? _lastRoomId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);
    final room = state.definitions?.rooms[state.currentRoomId];
    final zone = MapPanel._mapSystem.getCurrentZone(state);
    final visibleRooms = MapPanel._mapSystem.getVisibleRooms(
      state,
      radius: zone?.visibleRadius ?? 3,
    );
    final previousRoom = _previousRoomFor(state, room);
    final previousVisibleRooms = _previousVisibleRooms(
      state,
      previousRoom,
      radius: zone?.visibleRadius ?? 3,
    );
    final mapRooms = _mapRooms(
      visibleRooms,
      previousVisibleRooms,
      room,
      previousRoom,
    );
    _rememberRoomAfterBuild(state.currentRoomId);

    return PanelFrame(
      title: '',
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 300;
                final interactionWidth = math.min(
                  compact ? 112.0 : 136.0,
                  constraints.maxWidth * (compact ? 0.42 : 0.36),
                );
                return Row(
                  children: [
                    Expanded(
                      child: _MapCanvas(
                        rooms: mapRooms,
                        currentRooms: visibleRooms,
                        previousRooms: previousVisibleRooms,
                        currentRoom: room,
                        previousRoom: previousRoom,
                        currentRoomId: state.currentRoomId,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: interactionWidth,
                      child: _MapInteractionList(state: state, ref: ref),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          _RoomInfo(room: room, zoneName: zone?.name),
        ],
      ),
    );
  }

  RoomDefinition? _previousRoomFor(
    GameState state,
    RoomDefinition? currentRoom,
  ) {
    final previousRoomId = _lastRoomId;
    if (previousRoomId == null || previousRoomId == state.currentRoomId) {
      return null;
    }
    final previousRoom = state.definitions?.rooms[previousRoomId];
    if (currentRoom == null || previousRoom?.zoneId != currentRoom.zoneId) {
      return null;
    }
    return previousRoom;
  }

  List<RoomDefinition> _mapRooms(
    List<RoomDefinition> visibleRooms,
    List<RoomDefinition> previousVisibleRooms,
    RoomDefinition? currentRoom,
    RoomDefinition? previousRoom,
  ) {
    final roomsById = <String, RoomDefinition>{
      for (final room in visibleRooms) room.id: room,
      for (final room in previousVisibleRooms) room.id: room,
    };
    if (previousRoom != null) {
      roomsById[previousRoom.id] = previousRoom;
    }
    if (currentRoom != null) {
      roomsById[currentRoom.id] = currentRoom;
    }
    return roomsById.values.toList();
  }

  List<RoomDefinition> _previousVisibleRooms(
    GameState state,
    RoomDefinition? previousRoom, {
    required int radius,
  }) {
    if (previousRoom == null) {
      return const [];
    }
    return MapPanel._mapSystem.getVisibleRooms(
      state.copyWith(currentRoomId: previousRoom.id),
      radius: radius,
    );
  }

  void _rememberRoomAfterBuild(String currentRoomId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _lastRoomId != currentRoomId) {
        _lastRoomId = currentRoomId;
      }
    });
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({
    required this.rooms,
    required this.currentRooms,
    required this.previousRooms,
    required this.currentRoom,
    required this.previousRoom,
    required this.currentRoomId,
  });

  final List<RoomDefinition> rooms;
  final List<RoomDefinition> currentRooms;
  final List<RoomDefinition> previousRooms;
  final RoomDefinition? currentRoom;
  final RoomDefinition? previousRoom;
  final String currentRoomId;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey('${previousRoom?.id ?? currentRoomId}->$currentRoomId'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) {
            return CustomPaint(
              painter: _RoomMapPainter(
                rooms: rooms,
                currentRooms: currentRooms,
                previousRooms: previousRooms,
                currentRoom: currentRoom,
                previousRoom: previousRoom,
                currentRoomId: currentRoomId,
                moveProgress: progress,
              ),
            );
          },
        ),
        const Positioned(right: 4, top: 4, child: _MapLegend()),
      ],
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendItem(label: '其他房间', current: false),
            SizedBox(height: 6),
            _LegendItem(label: '当前位置', current: true),
          ],
        ),
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
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _RoomMapPainter extends CustomPainter {
  const _RoomMapPainter({
    required this.rooms,
    required this.currentRooms,
    required this.previousRooms,
    required this.currentRoom,
    required this.previousRoom,
    required this.currentRoomId,
    required this.moveProgress,
  });

  static const _maxGridStep = 22.0;
  static const _nodeSize = 12.0;
  static const _viewportDiameter = 7;

  final List<RoomDefinition> rooms;
  final List<RoomDefinition> currentRooms;
  final List<RoomDefinition> previousRooms;
  final RoomDefinition? currentRoom;
  final RoomDefinition? previousRoom;
  final String currentRoomId;
  final double moveProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final current = currentRoom;
    if (rooms.isEmpty || current == null) {
      return;
    }

    final mapWidth = math.max(80.0, size.width);
    final mapHeight = math.max(80.0, size.height);
    final gridStep = math.min(
      _maxGridStep,
      math.min(mapWidth, mapHeight) / (_viewportDiameter + 1),
    );
    final center = Offset(mapWidth / 2, mapHeight / 2);
    final currentAnchor = _viewportAnchor(
      current,
      currentRooms.isEmpty ? rooms : currentRooms,
    );
    final previous = previousRoom;
    final previousAnchor =
        previous == null
            ? null
            : _viewportAnchor(
              previous,
              previousRooms.isEmpty ? rooms : previousRooms,
            );
    final anchor =
        previousAnchor == null
            ? currentAnchor
            : Offset.lerp(previousAnchor, currentAnchor, moveProgress) ??
                currentAnchor;

    final gridPaint =
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    for (
      var x = _gridStart(center.dx - anchor.dx * gridStep, gridStep);
      x < mapWidth;
      x += gridStep
    ) {
      canvas.drawLine(Offset(x, 0), Offset(x, mapHeight), gridPaint);
    }
    for (
      var y = _gridStart(center.dy - anchor.dy * gridStep, gridStep);
      y < mapHeight;
      y += gridStep
    ) {
      canvas.drawLine(Offset(0, y), Offset(mapWidth, y), gridPaint);
    }

    final positions = <String, Offset>{
      for (final room in rooms)
        room.id: _positionFor(room, anchor, center, gridStep),
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
      for (final exit in room.exits.entries) {
        final to = positions[exit.value];
        if (to != null) {
          canvas.drawLine(from, to, linePaint);
        } else {
          final direction = _directionOffset(exit.key);
          if (direction != Offset.zero) {
            canvas.drawLine(
              from,
              from + direction * (gridStep * 0.45),
              linePaint,
            );
          }
        }
      }
    }

    for (final room in rooms) {
      final nodeCenter = positions[room.id];
      if (nodeCenter == null) {
        continue;
      }
      _drawRoomNode(canvas, nodeCenter, current: false);
    }

    final currentPosition = positions[currentRoomId];
    if (currentPosition == null) {
      return;
    }
    final previousPosition =
        previousRoom == null ? null : positions[previousRoom?.id];
    final markerPosition =
        previousPosition == null
            ? currentPosition
            : Offset.lerp(previousPosition, currentPosition, moveProgress) ??
                currentPosition;
    _drawRoomNode(canvas, markerPosition, current: true);
  }

  Offset _viewportAnchor(RoomDefinition current, List<RoomDefinition> rooms) {
    final minX = rooms.map((room) => room.mapX).reduce(math.min).toDouble();
    final maxX = rooms.map((room) => room.mapX).reduce(math.max).toDouble();
    final minY = rooms.map((room) => room.mapY).reduce(math.min).toDouble();
    final maxY = rooms.map((room) => room.mapY).reduce(math.max).toDouble();
    const centralRadius = 1.2;
    final zoneCenterX = (minX + maxX) / 2;
    final zoneCenterY = (minY + maxY) / 2;
    return Offset(
      zoneCenterX.clamp(
        current.mapX - centralRadius,
        current.mapX + centralRadius,
      ),
      zoneCenterY.clamp(
        current.mapY - centralRadius,
        current.mapY + centralRadius,
      ),
    );
  }

  Offset _positionFor(
    RoomDefinition room,
    Offset anchor,
    Offset center,
    double gridStep,
  ) {
    final relativeX = room.mapX - anchor.dx;
    final relativeY = room.mapY - anchor.dy;
    return Offset(
      center.dx + relativeX * gridStep,
      center.dy + relativeY * gridStep,
    );
  }

  double _gridStart(double origin, double gridStep) {
    var start = origin % gridStep;
    if (start > 0) {
      start -= gridStep;
    }
    return start;
  }

  Offset _directionOffset(String direction) {
    return switch (direction) {
      'north' => const Offset(0, -1),
      'south' => const Offset(0, 1),
      'east' => const Offset(1, 0),
      'west' => const Offset(-1, 0),
      _ => Offset.zero,
    };
  }

  void _drawRoomNode(Canvas canvas, Offset center, {required bool current}) {
    final rect = Rect.fromCenter(
      center: center,
      width: _nodeSize,
      height: _nodeSize,
    );
    final paint =
        Paint()
          ..color = current ? Colors.black : Colors.white
          ..style = PaintingStyle.fill;
    final border =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = current ? 1.8 : 1.5;
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, border);
  }

  @override
  bool shouldRepaint(covariant _RoomMapPainter oldDelegate) {
    return oldDelegate.currentRoomId != currentRoomId ||
        oldDelegate.currentRooms != currentRooms ||
        oldDelegate.previousRooms != previousRooms ||
        oldDelegate.currentRoom != currentRoom ||
        oldDelegate.previousRoom != previousRoom ||
        oldDelegate.moveProgress != moveProgress ||
        oldDelegate.rooms != rooms;
  }
}
