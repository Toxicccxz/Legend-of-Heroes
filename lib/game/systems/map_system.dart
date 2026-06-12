import '../core/game_state.dart';
import '../models/room_definition.dart';
import '../models/zone_definition.dart';

class MapSystem {
  const MapSystem();

  RoomDefinition? getCurrentRoom(GameState state) {
    return state.definitions?.rooms[state.currentRoomId];
  }

  Map<String, String> getAvailableExits(GameState state) {
    return getCurrentRoom(state)?.exits ?? const {};
  }

  ZoneDefinition? getCurrentZone(GameState state) {
    final currentRoom = getCurrentRoom(state);
    if (currentRoom == null) {
      return null;
    }
    return state.definitions?.zones[currentRoom.zoneId];
  }

  List<RoomDefinition> getNearbyRooms(GameState state) {
    final definitions = state.definitions;
    final currentRoom = getCurrentRoom(state);
    if (definitions == null || currentRoom == null) {
      return const [];
    }
    return {
      currentRoom.id,
      ...currentRoom.exits.values,
    }.map((id) => definitions.rooms[id]).whereType<RoomDefinition>().toList();
  }

  List<RoomDefinition> getRoomsInCurrentZone(GameState state) {
    final definitions = state.definitions;
    final currentRoom = getCurrentRoom(state);
    if (definitions == null || currentRoom == null) {
      return const [];
    }

    final rooms =
        definitions.rooms.values
            .where((room) => room.zoneId == currentRoom.zoneId)
            .toList();
    rooms.sort((a, b) {
      final yCompare = a.mapY.compareTo(b.mapY);
      return yCompare != 0 ? yCompare : a.mapX.compareTo(b.mapX);
    });
    return rooms;
  }

  List<RoomDefinition> getVisibleRooms(GameState state, {int radius = 3}) {
    final currentRoom = getCurrentRoom(state);
    if (currentRoom == null) {
      return const [];
    }

    return getRoomsInCurrentZone(state)
        .where(
          (room) =>
              (room.mapX - currentRoom.mapX).abs() <= radius &&
              (room.mapY - currentRoom.mapY).abs() <= radius,
        )
        .toList();
  }

  String? move(GameState state, String direction) {
    return getAvailableExits(state)[direction];
  }
}
