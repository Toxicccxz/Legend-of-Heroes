import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sample_game_data_loader.dart';
import '../models/event_definition.dart';
import '../repositories/game_definition_repository.dart';
import '../repositories/save_repository.dart';
import '../systems/dialogue_system.dart';
import '../systems/equipment_system.dart';
import '../systems/event_system.dart';
import '../systems/inventory_system.dart';
import '../systems/map_system.dart';
import '../systems/quest_system.dart';
import 'game_action.dart';
import 'game_state.dart';

final gameDefinitionsProvider = FutureProvider<GameDefinitions>((ref) {
  const repository = AssetGameDefinitionRepository();
  return const SampleGameDataLoader(repository).load();
});

final saveRepositoryProvider = Provider<SaveRepository>((ref) {
  return InMemorySaveRepository();
});

final gameControllerProvider =
    StateNotifierProvider<GameController, GameState>((ref) {
      final definitions = ref.watch(gameDefinitionsProvider);
      return definitions.when(
        data: (data) => GameController(
          definitions: data,
          saveRepository: ref.watch(saveRepositoryProvider),
        ),
        loading: GameController.loading,
        error: (error, stackTrace) => GameController.error(error.toString()),
      );
    });

class GameController extends StateNotifier<GameState> {
  GameController({
    required GameDefinitions definitions,
    required SaveRepository saveRepository,
  }) : _saveRepository = saveRepository,
       super(GameState.initial(definitions)) {
    _applyEnterRoomEvents();
  }

  GameController.loading()
    : _saveRepository = InMemorySaveRepository(),
      super(GameState.loading());

  GameController.error(String message)
    : _saveRepository = InMemorySaveRepository(),
      super(GameState.loading().copyWith(isLoading: false, errorMessage: message));

  final SaveRepository _saveRepository;
  final MapSystem _mapSystem = const MapSystem();
  final QuestSystem _questSystem = const QuestSystem();
  final InventorySystem _inventorySystem = const InventorySystem();
  final EquipmentSystem _equipmentSystem = const EquipmentSystem();
  final DialogueSystem _dialogueSystem = const DialogueSystem();
  final EventSystem _eventSystem = const EventSystem();

  void dispatch(GameAction action) {
    if (state.definitions == null) {
      return;
    }

    switch (action) {
      case MoveAction():
        _move(action.direction);
      case TalkToNpcAction():
        _talkToNpc(action.npcId);
      case UseItemAction():
        _useItem(action.itemId);
      case EquipItemAction():
        _equipItem(action.itemId);
      case AcceptQuestAction():
        state = _questSystem.startQuest(state, action.questId);
        _addLog(GameLogType.quest, '已接取任务。');
      case TrackQuestAction():
        state = state.copyWith(trackedQuestId: action.questId);
      case InvestigateAction():
        _investigate();
      case RestAction():
        _rest();
      case SelectStatusTabAction():
        state = state.copyWith(selectedStatusTab: action.tab);
      case SelectMessageFilterAction():
        state = state.copyWith(selectedMessageFilter: action.filter);
    }

    _saveRepository.save(state);
  }

  void _move(String direction) {
    final nextRoomId = _mapSystem.move(state, direction);
    if (nextRoomId == null) {
      _addLog(GameLogType.system, '这个方向没有道路。');
      return;
    }
    final visited = Set<String>.from(state.visitedRoomIds)..add(nextRoomId);
    state = state.copyWith(currentRoomId: nextRoomId, visitedRoomIds: visited);
    final roomName = state.definitions?.rooms[nextRoomId]?.name ?? nextRoomId;
    _addLog(GameLogType.system, '你来到了$roomName。');
    _applyEnterRoomEvents();
  }

  void _talkToNpc(String npcId) {
    final npcName = state.definitions?.npcs[npcId]?.name ?? npcId;
    _addLog(GameLogType.dialogue, '你对$npcName发起了交谈。');
    for (final line in _dialogueSystem.talkToNpc(state, npcId)) {
      _addLog(GameLogType.dialogue, '$npcName：$line');
    }
    final dialogue = _dialogueSystem.getDialogueForNpc(state, npcId);
    if (dialogue != null) {
      _applyEvents(
        _eventSystem.processActionEvents(state, dialogue.events),
      );
    }
    state = _questSystem.checkProgressAfterAction(
      state,
      TalkToNpcAction(npcId),
    );
  }

  void _useItem(String itemId) {
    final item = state.definitions?.items[itemId];
    state = _inventorySystem.useItem(state, itemId);
    if (item != null) {
      _addLog(GameLogType.system, '你使用了${item.name}。');
    }
  }

  void _equipItem(String itemId) {
    final item = state.definitions?.items[itemId];
    state = _equipmentSystem.equipItem(state, itemId);
    if (item != null) {
      _addLog(GameLogType.system, '你装备了${item.name}。');
    }
  }

  void _investigate() {
    final events = _eventSystem.processInvestigateEvents(state);
    if (events.isEmpty) {
      _addLog(GameLogType.system, '你仔细查看四周，没有发现新的线索。');
      return;
    }
    _applyEvents(events);
  }

  void _rest() {
    final player = state.player.copyWith(
      hp: (state.player.hp + 10).clamp(0, state.player.maxHp) as int,
      mp: (state.player.mp + 8).clamp(0, state.player.maxMp) as int,
      stamina:
          (state.player.stamina + 20).clamp(0, state.player.maxStamina) as int,
    );
    state = state.copyWith(player: player);
    _addLog(GameLogType.system, '你短暂休息，恢复了一些 HP、MP 和体力。');
  }

  void _applyEnterRoomEvents() {
    _applyEvents(_eventSystem.processEnterRoomEvents(state));
  }

  void _applyEvents(List<EventDefinition> events) {
    for (final event in events) {
      if (event.message.isNotEmpty) {
        _addLog(_parseLogType(event.logType), event.message);
      }
      final onceFlag = event.onceFlag;
      if (onceFlag != null) {
        state = _eventSystem.setFlag(state, onceFlag, true);
      }
      final questId = event.effects['questId'] as String?;
      final progressKey = event.effects['progressKey'] as String?;
      final progressValue = event.effects['progressValue'] as int?;
      if (questId != null && progressKey != null && progressValue != null) {
        state = _questSystem.updateQuestProgress(
          state,
          questId,
          progressKey,
          progressValue,
        );
      }
      final completeQuestId = event.effects['completeQuestId'] as String?;
      if (completeQuestId != null) {
        state = _questSystem.completeQuest(state, completeQuestId);
      }
    }
  }

  void _addLog(GameLogType type, String message) {
    state = state.copyWith(
      logs: [
        ...state.logs,
        GameLogEntry(
          timestamp: DateTime.now(),
          type: type,
          message: message,
        ),
      ],
    );
  }

  GameLogType _parseLogType(String value) {
    return switch (value) {
      'dialogue' => GameLogType.dialogue,
      'combat' => GameLogType.combat,
      'quest' => GameLogType.quest,
      _ => GameLogType.system,
    };
  }
}
