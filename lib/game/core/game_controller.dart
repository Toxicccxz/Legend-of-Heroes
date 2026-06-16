import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sample_game_data_loader.dart';
import '../models/event_definition.dart';
import '../models/item_definition.dart';
import '../models/npc_definition.dart';
import '../models/room_definition.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';
import '../repositories/save_repository.dart';
import '../systems/combat_system.dart';
import '../systems/dialogue_system.dart';
import '../systems/equipment_system.dart';
import '../systems/event_system.dart';
import '../systems/inventory_system.dart';
import '../systems/map_system.dart';
import '../systems/mud_command_system.dart';
import '../systems/quest_system.dart';
import '../systems/sect_system.dart';
import '../systems/shop_system.dart';
import '../systems/skill_system.dart';
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
  final CombatSystem _combatSystem = const CombatSystem();
  final InventorySystem _inventorySystem = const InventorySystem();
  final EquipmentSystem _equipmentSystem = const EquipmentSystem();
  final DialogueSystem _dialogueSystem = const DialogueSystem();
  final MudCommandSystem _mudCommandSystem = const MudCommandSystem();
  final EventSystem _eventSystem = const EventSystem();
  final SectSystem _sectSystem = const SectSystem();
  final SkillSystem _skillSystem = const SkillSystem();
  final ShopSystem _shopSystem = const ShopSystem();

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
      case ExecuteCommandAction():
        _executeCommand(action.input);
      case ExecuteRoomCommandAction():
        _executeRoomCommand(action.verb, targetId: action.targetId);
      case MoveAction():
        _move(action.direction);
      case TalkToNpcAction():
        _talkToNpc(action.npcId);
      case InteractWithNpcAction():
        _interactWithNpc(action.npcId, action.interactionType);
      case AskNpcInquiryAction():
        _askNpcInquiry(action.npcId, action.inquiryId);
      case GiveItemToNpcAction():
        _giveItemToNpc(action.npcId, action.itemId);
      case BuyShopItemAction():
        _buyShopItem(action.npcId, action.itemId);
      case UseItemAction():
        _useItem(action.itemId);
      case EquipItemAction():
        _equipItem(action.itemId);
      case UnequipItemAction():
        _unequipItem(action.slot);
      case MapSkillAction():
        _mapSkill(action.slot, action.skillId);
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

  void _executeCommand(String input) {
    final command = _mudCommandSystem.parse(input);
    switch (command.verb) {
      case '':
        return;
      case 'look':
        _look(command.target);
      case 'go':
        _move(command.target ?? '');
      case 'north' || 'south' || 'east' || 'west':
        _move(command.verb);
      case 'ask':
        if (command.extra == null || command.extra!.isEmpty) {
          _talkToResolvedNpc(command.target);
        } else {
          _askResolvedNpcInquiry(command.target, command.extra!);
        }
      case 'trade':
        _performResolvedNpcOption(command.target, 'trade');
      case 'give':
        _giveResolvedItemToNpc(command.target, command.extra);
      case 'quest':
        _performResolvedNpcOption(command.target, 'quest');
      case 'apprentice':
        _apprenticeToResolvedNpc(command.target);
      case 'learn':
        _learnFromResolvedNpc(command.target);
      case 'enable':
        _enableSkill(command.target, command.extra);
      case 'spar':
        _sparResolvedNpc(command.target);
      case 'kill':
        _fightResolvedNpc(command.target);
      case 'perform':
        _performSkill(command.target);
      case 'investigate':
        _investigate();
      case 'rest':
        _rest();
      case 'inventory':
        _showInventory();
      case 'score':
        _showScore();
      default:
        if (!_executeRoomCommand(command.verb, targetId: command.target)) {
          _addLog(GameLogType.system, '未知指令：${command.raw}。');
        }
    }
  }

  bool _executeRoomCommand(String verb, {String? targetId}) {
    final room = state.definitions?.rooms[state.currentRoomId];
    if (room == null) {
      return false;
    }
    for (final command in room.commands) {
      if (_matchesRoomCommand(command, verb, targetId)) {
        _performRoomCommand(command);
        return true;
      }
    }
    return false;
  }

  bool _matchesRoomCommand(
    RoomCommandDefinition command,
    String verb,
    String? targetId,
  ) {
    if (command.verb != verb) {
      return false;
    }
    return targetId == null || targetId.isEmpty || command.targetId == targetId;
  }

  void _performRoomCommand(RoomCommandDefinition command) {
    if (!_meetsRequiredFlags(command.requiresFlags)) {
      _addLog(GameLogType.system, '现在还不能这么做。');
      return;
    }
    if (command.description.isNotEmpty) {
      _addLog(GameLogType.system, command.description);
    }
    if (command.eventIds.isEmpty) {
      return;
    }
    _applyEvents(_eventSystem.processActionEvents(state, command.eventIds));
  }

  bool _meetsRequiredFlags(Map<String, dynamic> requiredFlags) {
    for (final entry in requiredFlags.entries) {
      if (state.flags[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  void _look(String? target) {
    final definitions = state.definitions;
    if (definitions == null) {
      return;
    }
    final room = definitions.rooms[state.currentRoomId];
    if (room == null) {
      return;
    }
    if (target == null || target.isEmpty || target == 'room') {
      final zone = definitions.zones[room.zoneId];
      final exits = room.exits.keys.join('、');
      final npcNames = room.npcs
          .map((id) => definitions.npcs[id]?.name)
          .whereType<String>()
          .join('、');
      final itemNames = room.items
          .map((id) => definitions.items[id]?.name)
          .whereType<String>()
          .join('、');
      _addLog(GameLogType.system, '${room.name}：${room.description}');
      if (zone != null) {
        _addLog(GameLogType.system, '区域：${zone.name}。');
      }
      if (exits.isNotEmpty) {
        _addLog(GameLogType.system, '出口：$exits。');
      }
      if (npcNames.isNotEmpty) {
        _addLog(GameLogType.system, '人物：$npcNames。');
      }
      if (itemNames.isNotEmpty) {
        _addLog(GameLogType.system, '物品：$itemNames。');
      }
      return;
    }

    final npc = _resolveNpcInCurrentRoom(target);
    if (npc != null) {
      final title = npc.title.isEmpty ? '' : '${npc.title} ';
      _addLog(GameLogType.system, '$title${npc.name}：${npc.description}');
      final sectId = npc.sectId ?? npc.combat?.sectId;
      if (sectId != null) {
        final sectName = definitions.sects[sectId]?.name ?? sectId;
        _addLog(GameLogType.system, '所属：$sectName。');
      }
      return;
    }

    final item = _resolveRoomItem(target);
    if (item != null) {
      _addLog(GameLogType.system, '${item.name}：${item.description}');
      return;
    }

    _addLog(GameLogType.system, '你没有看到“$target”。');
  }

  void _talkToResolvedNpc(String? target) {
    final npc = _resolveNpcInCurrentRoom(target);
    if (npc == null) {
      _addLog(GameLogType.system, '你想问谁？');
      return;
    }
    _talkToNpc(npc.id);
  }

  void _askResolvedNpcInquiry(String? target, String inquiryTarget) {
    final npc = _resolveNpcInCurrentRoom(target);
    if (npc == null) {
      _addLog(GameLogType.system, '你想问谁？');
      return;
    }
    final inquiry = _resolveNpcInquiry(npc, inquiryTarget);
    if (inquiry == null) {
      _addLog(GameLogType.dialogue, '${npc.name}摇了摇头，似乎不想谈这个。');
      return;
    }
    _askNpcInquiry(npc.id, inquiry.id);
  }

  void _performResolvedNpcOption(String? target, String interactionType) {
    final npc = _resolveNpcInCurrentRoom(target);
    if (npc == null) {
      _addLog(GameLogType.system, '你想找谁？');
      return;
    }
    _performNpcOption(npc.id, interactionType);
  }

  void _giveResolvedItemToNpc(String? itemTarget, String? npcTarget) {
    if (itemTarget == null || itemTarget.isEmpty) {
      _addLog(GameLogType.system, '你想交出什么？');
      return;
    }
    final npc = _resolveNpcInCurrentRoom(_cleanGiveNpcTarget(npcTarget));
    if (npc == null) {
      _addLog(GameLogType.system, '你想交给谁？');
      return;
    }
    final item = _resolveInventoryItem(itemTarget);
    if (item == null) {
      _addLog(GameLogType.system, '你身上没有这样东西。');
      return;
    }
    _giveItemToNpc(npc.id, item.id);
  }

  String? _cleanGiveNpcTarget(String? target) {
    if (target == null || target.isEmpty) {
      return target;
    }
    final parts = target.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts.first.toLowerCase() == 'to') {
      return parts.skip(1).join(' ');
    }
    return target;
  }

  void _apprenticeToResolvedNpc(String? target) {
    final npc = _resolveNpcInCurrentRoom(target);
    if (npc == null) {
      _addLog(GameLogType.system, '你想拜谁为师？');
      return;
    }
    _joinSectFromNpc(npc.id, _sectIdForNpcOption(npc, 'joinSect'));
  }

  void _learnFromResolvedNpc(String? target) {
    final npc = _resolveNpcInCurrentRoom(target);
    if (npc == null) {
      _addLog(GameLogType.system, '你想向谁请教？');
      return;
    }
    _askNpcForTeaching(npc.id, _sectIdForNpcOption(npc, 'learn'));
  }

  void _enableSkill(String? slot, String? skillTarget) {
    if (slot == null || skillTarget == null) {
      _addLog(GameLogType.system, '请选择要映射的槽位和武功。');
      return;
    }
    final skill = _resolveKnownSkill(skillTarget);
    _mapSkill(slot, skill?.id ?? skillTarget);
  }

  void _sparResolvedNpc(String? target) {
    final npc = _resolveNpcInCurrentRoom(target);
    if (npc == null) {
      _addLog(GameLogType.system, '你想和谁切磋？');
      return;
    }
    _fightNpc(npc.id, spar: true);
  }

  void _fightResolvedNpc(String? target) {
    final npc = _resolveNpcInCurrentRoom(target);
    if (npc == null) {
      _addLog(GameLogType.system, '你要攻击谁？');
      return;
    }
    _fightNpc(npc.id, spar: false);
  }

  void _performSkill(String? target) {
    if (target == null || target.isEmpty) {
      _addLog(GameLogType.system, '你要施展哪一招？');
      return;
    }
    final skill = _resolveKnownSkill(target);
    if (skill == null || !_skillSystem.knowsSkill(state, skill.id)) {
      _addLog(GameLogType.system, '你还不会这门功夫。');
      return;
    }
    if (skill.performIds.isEmpty) {
      _addLog(GameLogType.combat, '你凝神运转${skill.name}，但还没有领悟可施展的绝招。');
      return;
    }
    _addLog(GameLogType.combat, '你施展${skill.name}：${skill.performIds.first}。');
  }

  void _showInventory() {
    if (state.inventory.isEmpty) {
      _addLog(GameLogType.system, '你身上没有携带物品。');
      return;
    }
    final names = state.inventory
        .map((entry) {
          final item = state.definitions?.items[entry.itemId];
          return '${item?.name ?? entry.itemId} x${entry.count}';
        })
        .join('、');
    _addLog(GameLogType.system, '你携带着：$names。');
  }

  void _showScore() {
    final player = state.player;
    final sectName =
        player.sectId == null
            ? '无门无派'
            : state.definitions?.sects[player.sectId]?.name ?? player.sectId!;
    _addLog(
      GameLogType.system,
      '${player.name}：$sectName，等级${player.level}，气血${player.hp}/${player.maxHp}，内力${player.mp}/${player.maxMp}，体力${player.stamina}/${player.maxStamina}。',
    );
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

  void _askNpcInquiry(String npcId, String inquiryId) {
    final npc = state.definitions?.npcs[npcId];
    if (npc == null) {
      return;
    }
    final inquiry = _resolveNpcInquiry(npc, inquiryId);
    if (inquiry == null) {
      _addLog(GameLogType.dialogue, '${npc.name}摇了摇头，似乎不想谈这个。');
      return;
    }
    _addLog(GameLogType.dialogue, '你向${npc.name}询问${inquiry.label}。');
    if (inquiry.response.isNotEmpty) {
      _addLog(GameLogType.dialogue, '${npc.name}：${inquiry.response}');
    }
    if (inquiry.eventIds.isNotEmpty) {
      _applyEvents(_eventSystem.processActionEvents(state, inquiry.eventIds));
    }
  }

  void _giveItemToNpc(String npcId, String itemId) {
    final npc = state.definitions?.npcs[npcId];
    final item = state.definitions?.items[itemId];
    if (npc == null || item == null) {
      return;
    }
    final acceptedItem = _acceptedItemFor(npc, itemId);
    if (acceptedItem == null) {
      _addLog(GameLogType.dialogue, '${npc.name}摆了摆手，并不需要${item.name}。');
      return;
    }
    if (!_meetsRequiredFlags(acceptedItem.requiresFlags)) {
      _addLog(GameLogType.system, '现在还不能交出${item.name}。');
      return;
    }
    if (_inventorySystem.getItemCount(state, itemId) < acceptedItem.count) {
      _addLog(GameLogType.system, '你身上的${item.name}数量不够。');
      return;
    }

    state = _inventorySystem.removeItem(state, itemId, acceptedItem.count);
    final countText = acceptedItem.count > 1 ? ' x${acceptedItem.count}' : '';
    _addLog(GameLogType.dialogue, '你将${item.name}$countText交给${npc.name}。');
    if (acceptedItem.eventIds.isNotEmpty) {
      _applyEvents(
        _eventSystem.processActionEvents(state, acceptedItem.eventIds),
      );
    }
  }

  void _interactWithNpc(String npcId, String interactionType) {
    switch (interactionType) {
      case 'talk':
        _talkToNpc(npcId);
      case 'spar':
        _fightNpc(npcId, spar: true);
      case 'cancel':
        return;
      default:
        _performNpcOption(npcId, interactionType);
    }
  }

  void _performNpcOption(String npcId, String interactionType) {
    final npc = state.definitions?.npcs[npcId];
    if (npc == null) {
      return;
    }
    final matchingOptions = npc.interactions.where(
      (item) => item.type == interactionType,
    );
    if (matchingOptions.isEmpty) {
      return;
    }
    final option = matchingOptions.first;
    final requiredSectId = option.requiresSectId;
    if (requiredSectId != null && state.player.sectId != requiredSectId) {
      _addLog(GameLogType.system, '${npc.name}摇头：你尚非本门弟子。');
      return;
    }
    if (option.eventIds.isNotEmpty) {
      _applyEvents(_eventSystem.processActionEvents(state, option.eventIds));
    }
    switch (option.type) {
      case 'trade':
        if (npc.shopId == null) {
          _addLog(GameLogType.system, '${npc.name}打开随身货箱，里面暂时没有可买的东西。');
        } else {
          _addLog(GameLogType.system, '${npc.name}打开随身货箱。');
        }
      case 'quest':
        _addLog(GameLogType.quest, '你向${npc.name}询问可托付之事。');
      case 'joinSect':
        _joinSectFromNpc(npc.id, option.sectId);
      case 'learn':
        _askNpcForTeaching(npc.id, option.sectId);
      case 'battle':
        _fightNpc(npc.id, spar: false);
      default:
        _addLog(GameLogType.system, '你选择了${option.label}。');
    }
  }

  void _buyShopItem(String npcId, String itemId) {
    final npc = state.definitions?.npcs[npcId];
    final shopId = npc?.shopId;
    final shop = shopId == null ? null : state.definitions?.shops[shopId];
    if (npc == null || shop == null) {
      _addLog(GameLogType.system, '这里没有可交易的货品。');
      return;
    }

    final result = _shopSystem.buyItem(state, shop: shop, itemId: itemId);
    state = result.state;
    _addLog(
      result.success ? GameLogType.system : GameLogType.dialogue,
      result.message,
    );
  }

  void _fightNpc(String npcId, {required bool spar}) {
    final result = _combatSystem.fightNpc(state, npcId, spar: spar);
    state = result.state;
    for (final log in result.logs) {
      _addLog(GameLogType.combat, log);
    }
  }

  void _joinSectFromNpc(String npcId, String? sectId) {
    if (sectId == null) {
      return;
    }
    final result = _sectSystem.joinMaster(
      state,
      sectId: sectId,
      masterNpcId: npcId,
    );
    if (!result.success) {
      _addLog(GameLogType.system, result.message);
      return;
    }
    state = result.state;
    final sectName = result.sect?.name ?? sectId;
    final masterName = state.definitions?.npcs[npcId]?.name ?? npcId;
    _addLog(GameLogType.system, '$masterName点头收你入门，你拜入了$sectName。');
  }

  void _askNpcForTeaching(String npcId, String? sectId) {
    final npcName = state.definitions?.npcs[npcId]?.name ?? npcId;
    if (sectId != null && state.player.sectId != sectId) {
      _addLog(GameLogType.system, '$npcName摇头：不可跨门派请教。');
      return;
    }
    if (state.player.masterNpcId != npcId) {
      _addLog(GameLogType.system, '$npcName说：我并非你的授业师父，不可偷师学艺。');
      return;
    }
    final result = _sectSystem.learnFromCurrentMaster(state);
    if (!result.success) {
      _addLog(GameLogType.system, result.message);
      return;
    }
    state = result.state;
    final skillNames = result.learnedSkillIds
        .map((id) => state.definitions?.skills[id]?.name ?? id)
        .join('、');
    _addLog(GameLogType.system, '$npcName传授了你：$skillNames。');
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
    if (item == null ||
        item.type != ItemType.equipment ||
        _inventorySystem.getItemCount(state, itemId) <= 0) {
      return;
    }
    state = _equipmentSystem.equipItem(state, itemId);
    _addLog(GameLogType.system, '已装备${item.name}。');
  }

  void _unequipItem(String slot) {
    final itemId = state.equippedItems[slot];
    state = _equipmentSystem.unequipItem(state, slot);
    final item = itemId == null ? null : state.definitions?.items[itemId];
    if (item != null) {
      _addLog(GameLogType.system, '已卸下${item.name}。');
    }
  }

  void _mapSkill(String slot, String skillId) {
    final result = _skillSystem.mapSkill(state, slot: slot, skillId: skillId);
    if (!result.success) {
      _addLog(GameLogType.system, result.message);
      return;
    }
    state = result.state;
    final skillName = state.definitions?.skills[skillId]?.name ?? skillId;
    _addLog(GameLogType.system, '已将$skillName映射到$slot。');
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
      _applyMovementEffects(event.effects);
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

  void _applyMovementEffects(Map<String, dynamic> effects) {
    final roomId =
        effects['moveToRoomId'] as String? ?? effects['roomId'] as String?;
    if (roomId == null || roomId == state.currentRoomId) {
      return;
    }
    final room = state.definitions?.rooms[roomId];
    if (room == null) {
      return;
    }
    final visited = Set<String>.from(state.visitedRoomIds)..add(roomId);
    state = state.copyWith(currentRoomId: roomId, visitedRoomIds: visited);
    _addLog(GameLogType.system, '你来到${room.name}。');
    _applyEnterRoomEvents();
  }

  NpcDefinition? _resolveNpcInCurrentRoom(String? target) {
    final definitions = state.definitions;
    final room = definitions?.rooms[state.currentRoomId];
    if (definitions == null || room == null) {
      return null;
    }
    final npcs =
        room.npcs.map((id) => definitions.npcs[id]).whereType<NpcDefinition>();
    if (target == null || target.isEmpty) {
      return npcs.length == 1 ? npcs.first : null;
    }
    for (final npc in npcs) {
      if (_matchesNpc(npc, target)) {
        return npc;
      }
    }
    return null;
  }

  ItemDefinition? _resolveRoomItem(String target) {
    final definitions = state.definitions;
    final room = definitions?.rooms[state.currentRoomId];
    if (definitions == null || room == null) {
      return null;
    }
    for (final itemId in room.items) {
      final item = definitions.items[itemId];
      if (item != null && _matchesItem(item, target)) {
        return item;
      }
    }
    return null;
  }

  SkillDefinition? _resolveKnownSkill(String target) {
    final skills =
        state.definitions?.skills.values ?? const <SkillDefinition>[];
    for (final skill in skills) {
      if ((skill.id == target || skill.name == target) &&
          _skillSystem.knowsSkill(state, skill.id)) {
        return skill;
      }
    }
    return null;
  }

  ItemDefinition? _resolveInventoryItem(String target) {
    final definitions = state.definitions;
    if (definitions == null) {
      return null;
    }
    for (final entry in state.inventory) {
      final item = definitions.items[entry.itemId];
      if (item != null && _matchesItem(item, target)) {
        return item;
      }
    }
    return null;
  }

  NpcAcceptedItemDefinition? _acceptedItemFor(
    NpcDefinition npc,
    String itemId,
  ) {
    for (final acceptedItem in npc.acceptedItems) {
      if (acceptedItem.itemId == itemId) {
        return acceptedItem;
      }
    }
    return null;
  }

  NpcInquiryDefinition? _resolveNpcInquiry(NpcDefinition npc, String target) {
    for (final inquiry in npc.inquiries) {
      if (inquiry.id == target ||
          inquiry.label == target ||
          inquiry.aliases.contains(target)) {
        return inquiry;
      }
    }
    return null;
  }

  String? _sectIdForNpcOption(NpcDefinition npc, String type) {
    for (final option in npc.interactions) {
      if (option.type == type) {
        return option.sectId ?? npc.sectId ?? npc.combat?.sectId;
      }
    }
    return npc.sectId ?? npc.combat?.sectId;
  }

  bool _matchesNpc(NpcDefinition npc, String target) {
    return npc.id == target ||
        npc.name == target ||
        npc.aliases.contains(target);
  }

  bool _matchesItem(ItemDefinition item, String target) {
    return item.id == target ||
        item.name == target ||
        item.aliases.contains(target);
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
