import 'package:hive/hive.dart';

import '../core/game_action.dart';
import '../core/game_state.dart';
import '../models/item_definition.dart';
import '../models/player_state.dart';
import '../models/quest_progress.dart';

abstract class SaveRepository {
  Future<GameState?> load();

  Future<void> save(GameState state);
}

class HiveSaveRepository implements SaveRepository {
  HiveSaveRepository({this.boxName = 'legend_of_heroes_save'});

  static const _saveKey = 'current';

  final String boxName;

  Future<Box<dynamic>> _openBox() {
    if (Hive.isBoxOpen(boxName)) {
      return Future.value(Hive.box<dynamic>(boxName));
    }
    return Hive.openBox<dynamic>(boxName);
  }

  @override
  Future<GameState?> load() async {
    final box = await _openBox();
    final raw = box.get(_saveKey);
    if (raw is! Map) {
      return null;
    }
    return _stateFromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> save(GameState state) async {
    final box = await _openBox();
    await box.put(_saveKey, _stateToJson(state));
  }
}

class InMemorySaveRepository implements SaveRepository {
  GameState? _state;

  @override
  Future<GameState?> load() async => _state;

  @override
  Future<void> save(GameState state) async {
    _state = state;
  }
}

Map<String, dynamic> _stateToJson(GameState state) {
  return {
    'player': _playerToJson(state.player),
    'currentRoomId': state.currentRoomId,
    'questProgress': {
      for (final entry in state.questProgress.entries)
        entry.key: _questProgressToJson(entry.value),
    },
    'inventory': state.inventory.map(_inventoryEntryToJson).toList(),
    'equippedItems': state.equippedItems,
    'visitedRoomIds': state.visitedRoomIds.toList(),
    'flags': state.flags,
    'logs': state.logs.map(_logEntryToJson).toList(),
    'trackedQuestId': state.trackedQuestId,
    'selectedStatusTab': state.selectedStatusTab.name,
    'selectedMessageFilter': state.selectedMessageFilter.name,
  };
}

GameState _stateFromJson(Map<String, dynamic> json) {
  return GameState(
    definitions: null,
    player: _playerFromJson(_asMap(json['player'])),
    currentRoomId: json['currentRoomId'] as String? ?? 'village_entrance',
    questProgress: _questProgressMapFromJson(_asMap(json['questProgress'])),
    inventory: _inventoryFromJson(json['inventory']),
    equippedItems: Map<String, String>.from(_asMap(json['equippedItems'])),
    visitedRoomIds: Set<String>.from(
      json['visitedRoomIds'] as List? ?? const [],
    ),
    flags: _asMap(json['flags']),
    logs: _logsFromJson(json['logs']),
    trackedQuestId: json['trackedQuestId'] as String?,
    selectedStatusTab: _enumByName(
      StatusTab.values,
      json['selectedStatusTab'] as String?,
      StatusTab.quest,
    ),
    selectedMessageFilter: _enumByName(
      MessageFilter.values,
      json['selectedMessageFilter'] as String?,
      MessageFilter.all,
    ),
  );
}

Map<String, dynamic> _playerToJson(PlayerState player) {
  return {
    'name': player.name,
    'level': player.level,
    'hp': player.hp,
    'maxHp': player.maxHp,
    'mp': player.mp,
    'maxMp': player.maxMp,
    'stamina': player.stamina,
    'maxStamina': player.maxStamina,
    'gold': player.gold,
    'exp': player.exp,
    'sectId': player.sectId,
    'sectRank': player.sectRank,
    'masterNpcId': player.masterNpcId,
    'learnedSectSkillIds': player.learnedSectSkillIds,
  };
}

PlayerState _playerFromJson(Map<String, dynamic> json) {
  return PlayerState(
    name: json['name'] as String? ?? '冒险者',
    level: json['level'] as int? ?? 1,
    hp: json['hp'] as int? ?? 100,
    maxHp: json['maxHp'] as int? ?? 100,
    mp: json['mp'] as int? ?? 50,
    maxMp: json['maxMp'] as int? ?? 50,
    stamina: json['stamina'] as int? ?? 100,
    maxStamina: json['maxStamina'] as int? ?? 100,
    gold: json['gold'] as int? ?? 0,
    exp: json['exp'] as int? ?? 0,
    sectId: json['sectId'] as String?,
    sectRank: json['sectRank'] as String?,
    masterNpcId: json['masterNpcId'] as String?,
    learnedSectSkillIds: List<String>.from(
      json['learnedSectSkillIds'] as List? ?? const [],
    ),
  );
}

Map<String, dynamic> _questProgressToJson(QuestProgress progress) {
  return {
    'questId': progress.questId,
    'currentStage': progress.currentStage,
    'status': progress.status.name,
    'progress': progress.progress,
  };
}

Map<String, QuestProgress> _questProgressMapFromJson(
  Map<String, dynamic> json,
) {
  return {
    for (final entry in json.entries)
      if (entry.value is Map)
        entry.key: _questProgressFromJson(
          Map<String, dynamic>.from(entry.value as Map),
        ),
  };
}

QuestProgress _questProgressFromJson(Map<String, dynamic> json) {
  return QuestProgress(
    questId: json['questId'] as String? ?? '',
    currentStage: json['currentStage'] as int? ?? 0,
    status: _enumByName(
      QuestStatus.values,
      json['status'] as String?,
      QuestStatus.active,
    ),
    progress: Map<String, int>.from(_asMap(json['progress'])),
  );
}

Map<String, dynamic> _inventoryEntryToJson(InventoryEntry entry) {
  return {'itemId': entry.itemId, 'count': entry.count};
}

List<InventoryEntry> _inventoryFromJson(Object? value) {
  final entries = value as List? ?? const [];
  return [
    for (final entry in entries)
      if (entry is Map)
        InventoryEntry(
          itemId: entry['itemId'] as String? ?? '',
          count: entry['count'] as int? ?? 0,
        ),
  ];
}

Map<String, dynamic> _logEntryToJson(GameLogEntry entry) {
  return {
    'timestamp': entry.timestamp.toIso8601String(),
    'type': entry.type.name,
    'message': entry.message,
  };
}

List<GameLogEntry> _logsFromJson(Object? value) {
  final entries = value as List? ?? const [];
  return [
    for (final entry in entries)
      if (entry is Map)
        GameLogEntry(
          timestamp:
              DateTime.tryParse(entry['timestamp'] as String? ?? '') ??
              DateTime.now(),
          type: _enumByName(
            GameLogType.values,
            entry['type'] as String?,
            GameLogType.system,
          ),
          message: entry['message'] as String? ?? '',
        ),
  ];
}

Map<String, dynamic> _asMap(Object? value) {
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}
