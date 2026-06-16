import '../core/game_state.dart';
import '../models/npc_definition.dart';
import '../models/sect_definition.dart';
import '../models/skill_definition.dart';

class SectSystem {
  const SectSystem();

  SectDefinition? getCurrentSect(GameState state) {
    final sectId = state.player.sectId;
    if (sectId == null) {
      return null;
    }
    return state.definitions?.sects[sectId];
  }

  NpcDefinition? getCurrentMaster(GameState state) {
    final masterNpcId = state.player.masterNpcId;
    if (masterNpcId == null) {
      return null;
    }
    return state.definitions?.npcs[masterNpcId];
  }

  SectMasterDefinition? getMasterForNpc(
    GameState state,
    String sectId,
    String npcId,
  ) {
    final sect = state.definitions?.sects[sectId];
    if (sect == null) {
      return null;
    }
    for (final master in sect.masters) {
      if (master.npcId == npcId) {
        return master;
      }
    }
    return null;
  }

  List<SkillDefinition> getLearnedSectSkills(GameState state) {
    final skills = state.definitions?.skills;
    if (skills == null) {
      return const [];
    }
    return state.player.learnedSectSkillIds
        .map((id) => skills[id])
        .whereType<SkillDefinition>()
        .toList();
  }

  SectJoinResult joinMaster(
    GameState state, {
    required String sectId,
    required String masterNpcId,
  }) {
    final definitions = state.definitions;
    final sect = definitions?.sects[sectId];
    if (definitions == null || sect == null) {
      return SectJoinResult.failure(state, '门派不存在。');
    }
    final master = getMasterForNpc(state, sectId, masterNpcId);
    if (master == null) {
      return SectJoinResult.failure(state, '不可向非本门师父拜师。');
    }
    final currentSectId = state.player.sectId;
    if (currentSectId != null && currentSectId != sectId) {
      final currentSect =
          definitions.sects[currentSectId]?.name ?? currentSectId;
      return SectJoinResult.failure(state, '你已属$currentSect，不可跨门派拜师。');
    }
    if (master.level > 0 && currentSectId != sectId) {
      return SectJoinResult.failure(state, '须先正式入门，才可拜进阶师父。');
    }
    final missingSkills = _missingPreviousSkills(state, sect, master.level);
    if (missingSkills.isNotEmpty) {
      return SectJoinResult.failure(
        state,
        '须先完成前一阶段学习：${_skillNames(state, missingSkills)}。',
      );
    }
    final nextState = state.copyWith(
      player: state.player.copyWith(
        sectId: sectId,
        sectRank: master.rank.isEmpty ? sect.name : master.rank,
        masterNpcId: masterNpcId,
      ),
    );
    return SectJoinResult.success(nextState, sect: sect, master: master);
  }

  SectLearnResult learnFromCurrentMaster(GameState state) {
    final sectId = state.player.sectId;
    final masterNpcId = state.player.masterNpcId;
    if (sectId == null || masterNpcId == null) {
      return SectLearnResult.failure(state, '先拜师，再请教。');
    }
    final master = getMasterForNpc(state, sectId, masterNpcId);
    if (master == null) {
      return SectLearnResult.failure(state, '当前师承不属于本门。');
    }
    final missingSkills = _missingPreviousSkills(
      state,
      getCurrentSect(state),
      master.level,
    );
    if (missingSkills.isNotEmpty) {
      return SectLearnResult.failure(
        state,
        '不可偷师学艺，须先学完：${_skillNames(state, missingSkills)}。',
      );
    }
    final learned = state.player.learnedSectSkillIds.toSet();
    final newSkillIds =
        master.skillIds.where((id) => !learned.contains(id)).toList();
    if (newSkillIds.isEmpty) {
      return SectLearnResult.failure(state, '本阶段功法已经学完。');
    }
    final nextState = state.copyWith(
      player: state.player.copyWith(
        learnedSectSkillIds: [
          ...state.player.learnedSectSkillIds,
          ...newSkillIds,
        ],
      ),
    );
    return SectLearnResult.success(nextState, newSkillIds);
  }

  GameState joinSect(GameState state, String sectId) {
    final sect = state.definitions?.sects[sectId];
    if (sect == null || sect.masters.isEmpty) {
      return state;
    }
    return joinMaster(
      state,
      sectId: sectId,
      masterNpcId: sect.masters.first.npcId,
    ).state;
  }

  GameState updateReputation(GameState state, int amount) {
    return state;
  }

  String getSectRank(GameState state) {
    return state.player.sectRank ?? '未入门';
  }

  List<String> _missingPreviousSkills(
    GameState state,
    SectDefinition? sect,
    int masterLevel,
  ) {
    if (sect == null || masterLevel <= 0) {
      return const [];
    }
    final learned = state.player.learnedSectSkillIds.toSet();
    final required = <String>[];
    for (final master in sect.masters) {
      if (master.level < masterLevel) {
        required.addAll(master.skillIds);
      }
    }
    return required.where((id) => !learned.contains(id)).toList();
  }

  String _skillNames(GameState state, List<String> skillIds) {
    return skillIds
        .map((id) => state.definitions?.skills[id]?.name ?? id)
        .join('、');
  }
}

class SectJoinResult {
  const SectJoinResult._({
    required this.state,
    required this.success,
    required this.message,
    this.sect,
    this.master,
  });

  final GameState state;
  final bool success;
  final String message;
  final SectDefinition? sect;
  final SectMasterDefinition? master;

  factory SectJoinResult.success(
    GameState state, {
    required SectDefinition sect,
    required SectMasterDefinition master,
  }) {
    return SectJoinResult._(
      state: state,
      success: true,
      message: '',
      sect: sect,
      master: master,
    );
  }

  factory SectJoinResult.failure(GameState state, String message) {
    return SectJoinResult._(state: state, success: false, message: message);
  }
}

class SectLearnResult {
  const SectLearnResult._({
    required this.state,
    required this.success,
    required this.message,
    this.learnedSkillIds = const [],
  });

  final GameState state;
  final bool success;
  final String message;
  final List<String> learnedSkillIds;

  factory SectLearnResult.success(GameState state, List<String> skillIds) {
    return SectLearnResult._(
      state: state,
      success: true,
      message: '',
      learnedSkillIds: skillIds,
    );
  }

  factory SectLearnResult.failure(GameState state, String message) {
    return SectLearnResult._(state: state, success: false, message: message);
  }
}
