part of 'map_panel.dart';

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
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showLegend =
              constraints.maxWidth >= 260 && constraints.maxHeight >= 120;
          return Stack(
            fit: StackFit.expand,
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey(
                  '${previousRoom?.id ?? currentRoomId}->$currentRoomId',
                ),
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
              if (showLegend)
                const Positioned(right: 4, top: 4, child: _MapLegend()),
            ],
          );
        },
      ),
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

    canvas.clipRect(Offset.zero & size);
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
    _drawGrid(
      canvas,
      Size(mapWidth, mapHeight),
      center,
      anchor,
      gridStep,
      gridPaint,
    );

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

  void _drawGrid(
    Canvas canvas,
    Size size,
    Offset center,
    Offset anchor,
    double gridStep,
    Paint paint,
  ) {
    final minGridX = (anchor.dx - center.dx / gridStep).floor() - 1;
    final maxGridX =
        (anchor.dx + (size.width - center.dx) / gridStep).ceil() + 1;
    for (var gridX = minGridX; gridX <= maxGridX; gridX += 1) {
      final x = center.dx + (gridX - anchor.dx) * gridStep;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    final minGridY = (anchor.dy - center.dy / gridStep).floor() - 1;
    final maxGridY =
        (anchor.dy + (size.height - center.dy) / gridStep).ceil() + 1;
    for (var gridY = minGridY; gridY <= maxGridY; gridY += 1) {
      final y = center.dy + (gridY - anchor.dy) * gridStep;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  Offset _directionOffset(String direction) {
    return switch (direction) {
      'north' => const Offset(0, -1),
      'south' => const Offset(0, 1),
      'east' => const Offset(1, 0),
      'west' => const Offset(-1, 0),
      'northeast' => const Offset(1, -1),
      'northwest' => const Offset(-1, -1),
      'southeast' => const Offset(1, 1),
      'southwest' => const Offset(-1, 1),
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
