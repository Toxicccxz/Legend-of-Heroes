import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_state.dart';

void main() {
  test('copyWith can clear nullable fields', () {
    final state = GameState.loading().copyWith(
      trackedQuestId: 'side_guard_herb',
      errorMessage: '加载失败',
    );

    final nextState = state.copyWith(
      trackedQuestId: null,
      errorMessage: null,
    );

    expect(nextState.trackedQuestId, isNull);
    expect(nextState.errorMessage, isNull);
  });

  test('copyWith preserves nullable fields when omitted', () {
    final state = GameState.loading().copyWith(
      trackedQuestId: 'side_guard_herb',
      errorMessage: '加载失败',
    );

    final nextState = state.copyWith(currentRoomId: 'old_well');

    expect(nextState.currentRoomId, 'old_well');
    expect(nextState.trackedQuestId, 'side_guard_herb');
    expect(nextState.errorMessage, '加载失败');
  });
}
