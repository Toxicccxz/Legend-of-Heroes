import '../core/game_state.dart';
import '../models/room_definition.dart';

class MapSystem {
  const MapSystem();

  RoomDefinition? getCurrentRoom(GameState state) {
    return state.definitions?.rooms[state.currentRoomId];
  }

  Map<String, String> getAvailableExits(GameState state) {
    return getCurrentRoom(state)?.exits ?? const {};
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

  String? move(GameState state, String direction) {
    return getAvailableExits(state)[direction];
  }
}
