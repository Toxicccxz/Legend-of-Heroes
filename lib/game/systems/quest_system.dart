import '../core/game_action.dart';
import '../core/game_state.dart';
import '../models/quest_progress.dart';

class QuestSystem {
  const QuestSystem();

  GameState startQuest(GameState state, String questId) {
    final quest = state.definitions?.quests[questId];
    if (quest == null) {
      return state;
    }
    final nextProgress = Map<String, QuestProgress>.from(state.questProgress);
    nextProgress[questId] = QuestProgress(
      questId: questId,
      currentStage: 0,
      status: QuestStatus.active,
      progress: quest.initialProgress,
    );
    return state.copyWith(questProgress: nextProgress);
  }

  GameState updateQuestProgress(
    GameState state,
    String questId,
    String key,
    int value,
  ) {
    final current = state.questProgress[questId];
    if (current == null) {
      return state;
    }
    final nextValues = Map<String, int>.from(current.progress);
    nextValues[key] = value;
    final nextProgress = Map<String, QuestProgress>.from(state.questProgress);
    nextProgress[questId] = current.copyWith(progress: nextValues);
    return state.copyWith(questProgress: nextProgress);
  }

  GameState completeQuest(GameState state, String questId) {
    final current = state.questProgress[questId];
    if (current == null) {
      return state;
    }
    final nextProgress = Map<String, QuestProgress>.from(state.questProgress);
    nextProgress[questId] = current.copyWith(status: QuestStatus.completed);
    return state.copyWith(questProgress: nextProgress);
  }

  QuestProgress? getTrackedQuest(GameState state) {
    final questId = state.trackedQuestId;
    if (questId == null) {
      return null;
    }
    return state.questProgress[questId];
  }

  GameState checkProgressAfterAction(GameState state, GameAction action) {
    if (action is TalkToNpcAction && action.npcId == 'guard') {
      final current = state.questProgress['side_guard_herb'];
      if (current == null || current.status == QuestStatus.completed) {
        return state;
      }
      final collected = current.progress['collected'] ?? 0;
      if (collected >= 3) {
        return completeQuest(state, 'side_guard_herb');
      }
    }
    return state;
  }
}
