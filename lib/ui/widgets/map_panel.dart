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
import 'character_status_panel.dart';
import 'panel_frame.dart';

part 'map_canvas.dart';
part 'map_interaction_list.dart';

class MapPanel extends ConsumerStatefulWidget {
  const MapPanel({super.key, this.showCharacterSummary = false});

  final bool showCharacterSummary;

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
      title: _panelTitle(room, zone?.name),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mapCanvas = _MapCanvas(
                  rooms: mapRooms,
                  currentRooms: visibleRooms,
                  previousRooms: previousVisibleRooms,
                  currentRoom: room,
                  previousRoom: previousRoom,
                  currentRoomId: state.currentRoomId,
                );
                final primaryContent =
                    widget.showCharacterSummary
                        ? Row(
                          children: [
                            Expanded(child: mapCanvas),
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 118,
                              child: CharacterSummary(),
                            ),
                          ],
                        )
                        : mapCanvas;

                return primaryContent;
              },
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: widget.showCharacterSummary ? 92 : 112,
            child: _MapInteractionList(state: state, ref: ref),
          ),
        ],
      ),
    );
  }

  String _panelTitle(RoomDefinition? room, String? zoneName) {
    return '区域：${zoneName ?? '未知区域'}。${room?.name ?? '未知房间'}';
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
