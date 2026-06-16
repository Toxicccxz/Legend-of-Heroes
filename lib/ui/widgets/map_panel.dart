import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/core/game_state.dart';
import '../../game/models/item_definition.dart';
import '../../game/models/npc_definition.dart';
import '../../game/models/room_definition.dart';
import '../../game/models/shop_definition.dart';
import '../../game/systems/map_system.dart';
import 'panel_frame.dart';

part 'map_canvas.dart';
part 'map_interaction_list.dart';

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
      title: '地图',
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 300;
                final interactionWidth = math.min(
                  compact ? 130.0 : 156.0,
                  constraints.maxWidth * (compact ? 0.46 : 0.42),
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

class _RoomInfo extends StatelessWidget {
  const _RoomInfo({required this.room, required this.zoneName});

  final RoomDefinition? room;
  final String? zoneName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Container(
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
              '区域：${zoneName ?? '未知区域'} · ${room?.name ?? '未知房间'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                '描述：${room?.description ?? ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
