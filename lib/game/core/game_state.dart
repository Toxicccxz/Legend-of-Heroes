import '../models/item_definition.dart';
import '../models/player_state.dart';
import '../models/quest_progress.dart';
import '../repositories/game_definition_repository.dart';
import 'game_action.dart';

enum GameLogType { dialogue, combat, system, quest }

class GameLogEntry {
  const GameLogEntry({
    required this.timestamp,
    required this.type,
    required this.message,
  });

  final DateTime timestamp;
  final GameLogType type;
  final String message;
}

const _unset = Object();

class GameState {
  const GameState({
    required this.definitions,
    required this.player,
    required this.currentRoomId,
    required this.questProgress,
    required this.inventory,
    required this.equippedItems,
    required this.visitedRoomIds,
    required this.flags,
    required this.logs,
    required this.selectedStatusTab,
    required this.selectedMessageFilter,
    this.trackedQuestId,
    this.isLoading = false,
    this.errorMessage,
  });

  final GameDefinitions? definitions;
  final PlayerState player;
  final String currentRoomId;
  final Map<String, QuestProgress> questProgress;
  final List<InventoryEntry> inventory;
  final Map<String, String> equippedItems;
  final Set<String> visitedRoomIds;
  final Map<String, dynamic> flags;
  final List<GameLogEntry> logs;
  final String? trackedQuestId;
  final StatusTab selectedStatusTab;
  final MessageFilter selectedMessageFilter;
  final bool isLoading;
  final String? errorMessage;

  GameState copyWith({
    GameDefinitions? definitions,
    PlayerState? player,
    String? currentRoomId,
    Map<String, QuestProgress>? questProgress,
    List<InventoryEntry>? inventory,
    Map<String, String>? equippedItems,
    Set<String>? visitedRoomIds,
    Map<String, dynamic>? flags,
    List<GameLogEntry>? logs,
    Object? trackedQuestId = _unset,
    StatusTab? selectedStatusTab,
    MessageFilter? selectedMessageFilter,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return GameState(
      definitions: definitions ?? this.definitions,
      player: player ?? this.player,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      questProgress: questProgress ?? this.questProgress,
      inventory: inventory ?? this.inventory,
      equippedItems: equippedItems ?? this.equippedItems,
      visitedRoomIds: visitedRoomIds ?? this.visitedRoomIds,
      flags: flags ?? this.flags,
      logs: logs ?? this.logs,
      trackedQuestId:
          identical(trackedQuestId, _unset)
              ? this.trackedQuestId
              : trackedQuestId as String?,
      selectedStatusTab: selectedStatusTab ?? this.selectedStatusTab,
      selectedMessageFilter:
          selectedMessageFilter ?? this.selectedMessageFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          identical(errorMessage, _unset)
              ? this.errorMessage
              : errorMessage as String?,
    );
  }

  static GameState loading() {
    return GameState(
      definitions: null,
      player: _defaultPlayer,
      currentRoomId: 'village_entrance',
      questProgress: const {},
      inventory: const [],
      equippedItems: const {},
      visitedRoomIds: const {},
      flags: const {},
      logs: const [],
      selectedStatusTab: StatusTab.quest,
      selectedMessageFilter: MessageFilter.all,
      isLoading: true,
    );
  }

  static GameState initial(GameDefinitions definitions) {
    final questProgress = {
      for (final quest in definitions.quests.values)
        quest.id: QuestProgress(
          questId: quest.id,
          currentStage: 0,
          status: QuestStatus.active,
          progress: quest.initialProgress,
        ),
    };

    return GameState(
      definitions: definitions,
      player: _defaultPlayer,
      currentRoomId: 'village_entrance',
      questProgress: questProgress,
      inventory: const [
        InventoryEntry(itemId: 'small_potion', count: 1),
        InventoryEntry(itemId: 'healing_herb', count: 1),
        InventoryEntry(itemId: 'bread', count: 2),
        InventoryEntry(itemId: 'novice_cloth', count: 1),
        InventoryEntry(itemId: 'wooden_token', count: 1),
      ],
      equippedItems: const {},
      visitedRoomIds: const {'village_entrance'},
      flags: const {},
      logs: [
        GameLogEntry(
          timestamp: DateTime(2026, 6, 9, 10, 21),
          type: GameLogType.dialogue,
          message: '流浪商人：最近村里不太平……',
        ),
        GameLogEntry(
          timestamp: DateTime(2026, 6, 9, 10, 21),
          type: GameLogType.dialogue,
          message: '你对守卫发起了交谈。',
        ),
        GameLogEntry(
          timestamp: DateTime(2026, 6, 9, 10, 22),
          type: GameLogType.combat,
          message: '野狼发动攻击，造成 8 点伤害。',
        ),
        GameLogEntry(
          timestamp: DateTime(2026, 6, 9, 10, 22),
          type: GameLogType.system,
          message: '你使用了小红药水，恢复 20 HP。',
        ),
      ],
      trackedQuestId: 'side_guard_herb',
      selectedStatusTab: StatusTab.quest,
      selectedMessageFilter: MessageFilter.all,
    );
  }

  static const _defaultPlayer = PlayerState(
    name: '冒险者',
    level: 12,
    hp: 120,
    maxHp: 120,
    mp: 60,
    maxMp: 60,
    stamina: 80,
    maxStamina: 100,
    gold: 256,
    exp: 0,
  );
}
