import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_state.dart';
import 'package:legend_of_heroes/game/models/quest_progress.dart';
import 'package:legend_of_heroes/game/systems/quest_system.dart';

void main() {
  test('completeQuestIfProgressMet completes generic progress quests', () {
    const questSystem = QuestSystem();
    final state = GameState.loading().copyWith(
      questProgress: const {
        'main_investigate_village': QuestProgress(
          questId: 'main_investigate_village',
          currentStage: 0,
          status: QuestStatus.active,
          progress: {'investigated': 1, 'required': 1},
        ),
      },
    );

    final nextState = questSystem.completeQuestIfProgressMet(
      state,
      'main_investigate_village',
    );

    expect(
      nextState.questProgress['main_investigate_village']?.status,
      QuestStatus.completed,
    );
  });

  test('completeQuestIfProgressMet keeps incomplete quests active', () {
    const questSystem = QuestSystem();
    final state = GameState.loading().copyWith(
      questProgress: const {
        'side_guard_herb': QuestProgress(
          questId: 'side_guard_herb',
          currentStage: 0,
          status: QuestStatus.active,
          progress: {'collected': 1, 'required': 3},
        ),
      },
    );

    final nextState = questSystem.completeQuestIfProgressMet(
      state,
      'side_guard_herb',
    );

    expect(
      nextState.questProgress['side_guard_herb']?.status,
      QuestStatus.active,
    );
  });
}
