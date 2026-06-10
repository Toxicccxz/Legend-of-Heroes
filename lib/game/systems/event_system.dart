import '../core/game_state.dart';
import '../models/event_definition.dart';

class EventSystem {
  const EventSystem();

  List<EventDefinition> processEnterRoomEvents(GameState state) {
    final room = state.definitions?.rooms[state.currentRoomId];
    return _activeEvents(state, room?.onEnterEvents ?? const []);
  }

  List<EventDefinition> processInvestigateEvents(GameState state) {
    final room = state.definitions?.rooms[state.currentRoomId];
    return _activeEvents(state, room?.investigateEvents ?? const []);
  }

  List<EventDefinition> processActionEvents(GameState state, List<String> ids) {
    return _activeEvents(state, ids);
  }

  List<EventDefinition> processRestEvents(GameState state) {
    final room = state.definitions?.rooms[state.currentRoomId];
    return _activeEvents(state, room?.restEvents ?? const []);
  }

  GameState setFlag(GameState state, String key, dynamic value) {
    final nextFlags = Map<String, dynamic>.from(state.flags);
    nextFlags[key] = value;
    return state.copyWith(flags: nextFlags);
  }

  bool checkFlag(GameState state, String key) {
    return state.flags[key] == true;
  }

  List<EventDefinition> _activeEvents(GameState state, List<String> ids) {
    final definitions = state.definitions;
    if (definitions == null) {
      return const [];
    }
    return ids
        .map((id) => definitions.events[id])
        .whereType<EventDefinition>()
        .where((event) {
          final onceFlag = event.onceFlag;
          return onceFlag == null || state.flags[onceFlag] != true;
        })
        .toList();
  }
}
