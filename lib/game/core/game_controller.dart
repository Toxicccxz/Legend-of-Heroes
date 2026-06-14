import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sample_game_data_loader.dart';
import '../models/event_definition.dart';
import '../models/item_definition.dart';
import '../repositories/game_definition_repository.dart';
import '../repositories/save_repository.dart';
import '../systems/dialogue_system.dart';
import '../systems/equipment_system.dart';
import '../systems/event_system.dart';
import '../systems/inventory_system.dart';
import '../systems/map_system.dart';
import '../systems/quest_system.dart';
import '../systems/sect_system.dart';
import 'game_action.dart';
import 'game_state.dart';

final gameDefinitionsProvider = FutureProvider<GameDefinitions>((ref) {
  final repository = AssetGameDefinitionRepository();
  return SampleGameDataLoader(repository).load();
});

final saveRepositoryProvider = Provider<SaveRepository>((ref) {
  return HiveSaveRepository();
});

final savedGameProvider = FutureProvider<GameState?>((ref) {
  return ref.watch(saveRepositoryProvider).load();
});

final gameControllerProvider = StateNotifierProvider<GameController, GameState>(
  (ref) {
    final definitions = ref.watch(gameDefinitionsProvider);
    return definitions.when(
      data:
          (data) => GameController(
            definitions: data,
            saveRepository: ref.watch(saveRepositoryProvider),
          ),
      loading: GameController.loading,
      error: (error, stackTrace) => GameController.error(error.toString()),
    );
  },
);

class GameController extends StateNotifier<GameState> {
  GameController({
    required GameDefinitions definitions,
    required SaveRepository saveRepository,
  }) : _definitions = definitions,
       _saveRepository = saveRepository,
       super(GameState.initial(definitions)) {
    _applyEnterRoomEvents();
  }

  GameController.loading()
    : _definitions = null,
      _saveRepository = InMemorySaveRepository(),
      super(GameState.loading());

  GameController.error(String message)
    : _definitions = null,
      _saveRepository = InMemorySaveRepository(),
      super(
        GameState.loading().copyWith(isLoading: false, errorMessage: message),
      );

  final GameDefinitions? _definitions;
  final SaveRepository _saveRepository;
  final MapSystem _mapSystem = const MapSystem();
  final QuestSystem _questSystem = const QuestSystem();
  final InventorySystem _inventorySystem = const InventorySystem();
  final EquipmentSystem _equipmentSystem = const EquipmentSystem();
  final DialogueSystem _dialogueSystem = const DialogueSystem();
  final EventSystem _eventSystem = const EventSystem();
  final SectSystem _sectSystem = const SectSystem();

  Future<void> startNewGame() async {
    final definitions = _definitions;
    if (definitions == null) {
      return;
    }
    state = GameState.initial(definitions);
    _applyEnterRoomEvents();
    await _saveRepository.save(state);
  }

  Future<bool> loadSavedGame() async {
    final definitions = _definitions;
    if (definitions == null) {
      return false;
    }
    final savedState = await _saveRepository.load();
    if (savedState == null) {
      return false;
    }
    state = savedState.copyWith(
      definitions: definitions,
      isLoading: false,
      errorMessage: null,
    );
    return true;
  }

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
      _applyEvents(_eventSystem.processActionEvents(state, dialogue.events));
    }
  }

  void _useItem(String itemId) {
    final item = state.definitions?.items[itemId];
    if (item == null) {
      return;
    }
    if (item.type != ItemType.consumable) {
      _addLog(GameLogType.system, '${item.name}无法直接使用。');
      return;
    }
    if (_inventorySystem.getItemCount(state, itemId) <= 0) {
      _addLog(GameLogType.system, '背包中没有${item.name}。');
      return;
    }
    state = _inventorySystem.useItem(state, itemId);
    if (item.useEvents.isEmpty) {
      _addLog(GameLogType.system, '你使用了${item.name}。');
      return;
    }
    _applyEvents(_eventSystem.processActionEvents(state, item.useEvents));
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
    final events = _eventSystem.processRestEvents(state);
    if (events.isEmpty) {
      _addLog(GameLogType.system, '你短暂休息，但没有恢复效果。');
      return;
    }
    _applyEvents(events);
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
        state = _questSystem.completeQuestIfProgressMet(state, questId);
      }
      final completeQuestId = event.effects['completeQuestId'] as String?;
      if (completeQuestId != null) {
        state = _questSystem.completeQuest(state, completeQuestId);
      }
      _applyInventoryEffects(event.effects);
      _applySectEffects(event.effects);
      _applyCombatEffects(event.effects);
      _applyPlayerRestoreEffects(event.effects);
    }
  }

  void _applyInventoryEffects(Map<String, dynamic> effects) {
    final giveItemId = effects['giveItemId'] as String?;
    final giveItemCount = effects['giveItemCount'] as int? ?? 1;
    if (giveItemId != null && giveItemCount > 0) {
      state = _inventorySystem.addItem(state, giveItemId, giveItemCount);
    }

    final removeItemId = effects['removeItemId'] as String?;
    final removeItemCount = effects['removeItemCount'] as int? ?? 1;
    if (removeItemId != null && removeItemCount > 0) {
      state = _inventorySystem.removeItem(state, removeItemId, removeItemCount);
    }
  }

  void _applySectEffects(Map<String, dynamic> effects) {
    final joinSectId = effects['joinSectId'] as String?;
    if (joinSectId == null) {
      return;
    }
    state = _sectSystem.joinSect(state, joinSectId);
  }

  void _applyCombatEffects(Map<String, dynamic> effects) {
    final combatLogMessage = effects['combatLogMessage'] as String?;
    if (combatLogMessage == null || combatLogMessage.isEmpty) {
      return;
    }
    _addLog(GameLogType.combat, combatLogMessage);
  }

  void _applyPlayerRestoreEffects(Map<String, dynamic> effects) {
    final restoreHp = effects['restoreHp'] as int? ?? 0;
    final restoreMp = effects['restoreMp'] as int? ?? 0;
    final restoreStamina = effects['restoreStamina'] as int? ?? 0;
    if (restoreHp == 0 && restoreMp == 0 && restoreStamina == 0) {
      return;
    }

    state = state.copyWith(
      player: state.player.copyWith(
        hp: (state.player.hp + restoreHp).clamp(0, state.player.maxHp),
        mp: (state.player.mp + restoreMp).clamp(0, state.player.maxMp),
        stamina: (state.player.stamina + restoreStamina).clamp(
          0,
          state.player.maxStamina,
        ),
      ),
    );
  }

  void _addLog(GameLogType type, String message) {
    state = state.copyWith(
      logs: [
        ...state.logs,
        GameLogEntry(timestamp: DateTime.now(), type: type, message: message),
      ],
      selectedMessageFilter:
          type == GameLogType.combat ? MessageFilter.combat : null,
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
