import '../core/game_state.dart';

abstract class SaveRepository {
  Future<GameState?> load();

  Future<void> save(GameState state);
}

class InMemorySaveRepository implements SaveRepository {
  GameState? _state;

  @override
  Future<GameState?> load() async => _state;

  @override
  Future<void> save(GameState state) async {
    // TODO: Replace with a Hive-backed implementation once save slots are designed.
    _state = state;
  }
}
