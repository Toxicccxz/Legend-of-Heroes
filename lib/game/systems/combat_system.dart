import '../core/game_state.dart';
import '../models/npc_definition.dart';

class CombatSystem {
  const CombatSystem();

  CombatResult fightNpc(GameState state, String npcId, {required bool spar}) {
    final npc = state.definitions?.npcs[npcId];
    if (npc == null) {
      return CombatResult(state: state, logs: const []);
    }
    final npcCombat =
        npc.combat ??
        const NpcCombatDefinition(maxHp: 30, attack: 6, defense: 2, dodge: 2);
    final playerAttackSlot = _bestPlayerAttackSlot(state);
    final npcAttackSlot = npcCombat.attackSkillSlot;
    final playerBaseSkillId = _baseSkillId(state, playerAttackSlot);
    final npcBaseSkillId = _npcBaseSkillId(state, npcCombat, npcAttackSlot);
    final playerAttack =
        _mappedLevel(state, playerAttackSlot) * 6 +
        _skillLevel(state, playerBaseSkillId) * 2 +
        _skillLevel(state, 'force') +
        state.player.level * 3;
    final playerDefense =
        _mappedLevel(state, 'parry') * 4 +
        _mappedLevel(state, 'dodge') * 3 +
        _equipmentEffect(state, 'defense') * 3;
    final npcAttack =
        _npcMappedLevel(npcCombat, npcAttackSlot) * 6 +
        _npcSkillLevel(npcCombat, npcBaseSkillId) * 2 +
        _npcSkillLevel(npcCombat, 'force') +
        npcCombat.attack * 3;
    final npcDefense =
        _npcMappedLevel(npcCombat, 'parry') * 4 +
        _npcMappedLevel(npcCombat, 'dodge') * 3 +
        npcCombat.defense * 3;
    final hit =
        playerAttack + 20 >=
        npcCombat.dodge * 5 + _npcMappedLevel(npcCombat, 'dodge');
    final damage =
        hit
            ? _atLeastOne((playerAttack / 3).round() - (npcDefense / 5).round())
            : 0;
    final npcDefeated = damage >= npcCombat.maxHp;
    final incomingDamage =
        npcDefeated
            ? 0
            : _atLeastOne(
              (npcAttack / 3).round() - (playerDefense / 5).round(),
            );
    final nextHp =
        spar
            ? (state.player.hp - incomingDamage).clamp(1, state.player.maxHp)
            : (state.player.hp - incomingDamage).clamp(0, state.player.maxHp);
    var nextState = state.copyWith(player: state.player.copyWith(hp: nextHp));
    final logs = <String>[];
    final attackName = _mappedSkillName(state, playerAttackSlot) ?? '普通拳脚';
    final npcAttackName =
        _npcMappedSkillName(state, npcCombat, npcAttackSlot) ?? '普通拳脚';
    logs.add(spar ? '你与${npc.name}点到即止。' : '你向${npc.name}发起战斗。');
    if (hit) {
      logs.add('你施展$attackName，造成 $damage 点伤害。');
    } else {
      logs.add('${npc.name}身形一闪，避开了你的攻势。');
    }
    if (npcDefeated) {
      logs.add('${npc.name}败下阵来。');
      if (!spar && npcCombat.expReward > 0) {
        nextState = nextState.copyWith(
          player: nextState.player.copyWith(
            exp: nextState.player.exp + npcCombat.expReward,
          ),
        );
        logs.add('你获得 ${npcCombat.expReward} 点经验。');
      }
    } else {
      logs.add('${npc.name}施展$npcAttackName还击，造成 $incomingDamage 点伤害。');
      if (nextHp <= 0) {
        logs.add('你气力不支，败下阵来。');
      }
    }
    return CombatResult(state: nextState, logs: logs);
  }

  int _mappedLevel(GameState state, String slot) {
    final skillId = state.player.mappedSkillIds[slot];
    if (skillId == null) {
      return 0;
    }
    return _skillLevel(state, skillId);
  }

  String _bestPlayerAttackSlot(GameState state) {
    const attackSlots = ['sword', 'blade', 'hand', 'staff', 'unarmed'];
    var bestSlot = 'sword';
    var bestLevel = -1;
    for (final slot in attackSlots) {
      final level = _mappedLevel(state, slot);
      if (level > bestLevel) {
        bestSlot = slot;
        bestLevel = level;
      }
    }
    return bestSlot;
  }

  String _baseSkillId(GameState state, String slot) {
    final skillId = state.player.mappedSkillIds[slot];
    if (skillId == null) {
      return slot;
    }
    return state.definitions?.skills[skillId]?.baseSkillId ?? slot;
  }

  int _skillLevel(GameState state, String skillId) {
    return state.player.skillLevels[skillId] ?? 0;
  }

  int _equipmentEffect(GameState state, String effectKey) {
    var total = 0;
    for (final itemId in state.equippedItems.values) {
      total += state.definitions?.items[itemId]?.effects[effectKey] ?? 0;
    }
    return total;
  }

  String? _mappedSkillName(GameState state, String slot) {
    final skillId = state.player.mappedSkillIds[slot];
    if (skillId == null) {
      return null;
    }
    return state.definitions?.skills[skillId]?.name ?? skillId;
  }

  int _npcMappedLevel(NpcCombatDefinition combat, String slot) {
    final skillId = combat.mappedSkillIds[slot];
    if (skillId == null) {
      return 0;
    }
    return _npcSkillLevel(combat, skillId);
  }

  String _npcBaseSkillId(
    GameState state,
    NpcCombatDefinition combat,
    String slot,
  ) {
    final skillId = combat.mappedSkillIds[slot];
    if (skillId == null) {
      return slot;
    }
    return state.definitions?.skills[skillId]?.baseSkillId ?? slot;
  }

  int _npcSkillLevel(NpcCombatDefinition combat, String skillId) {
    return combat.skillLevels[skillId] ?? 0;
  }

  String? _npcMappedSkillName(
    GameState state,
    NpcCombatDefinition combat,
    String slot,
  ) {
    final skillId = combat.mappedSkillIds[slot];
    if (skillId == null) {
      return null;
    }
    return state.definitions?.skills[skillId]?.name ?? skillId;
  }

  int _atLeastOne(int value) {
    return value < 1 ? 1 : value;
  }
}

class CombatResult {
  const CombatResult({required this.state, required this.logs});

  final GameState state;
  final List<String> logs;
}
