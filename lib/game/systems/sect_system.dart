import '../core/game_state.dart';
import '../models/sect_definition.dart';

class SectSystem {
  const SectSystem();

  SectDefinition? getCurrentSect(GameState state) {
    final sectId = state.player.sectId;
    if (sectId == null) {
      return null;
    }
    return state.definitions?.sects[sectId];
  }

  GameState joinSect(GameState state, String sectId) {
    final sect = state.definitions?.sects[sectId];
    if (sect == null) {
      return state;
    }
    return state.copyWith(
      player: state.player.copyWith(
        sectId: sectId,
        sectRank: sect.ranks.isEmpty ? null : sect.ranks.first,
      ),
    );
  }

  GameState updateReputation(GameState state, int amount) {
    return state;
  }

  String getSectRank(GameState state) {
    return state.player.sectRank ?? '未入门';
  }
}
