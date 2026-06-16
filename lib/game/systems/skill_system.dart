import '../core/game_state.dart';

class SkillSystem {
  const SkillSystem();

  bool knowsSkill(GameState state, String skillId) {
    return (state.player.skillLevels[skillId] ?? 0) > 0;
  }

  int getSkillLevel(GameState state, String skillId) {
    return state.player.skillLevels[skillId] ?? 0;
  }

  GameState learnSkill(GameState state, String skillId, {int level = 1}) {
    final skill = state.definitions?.skills[skillId];
    if (skill == null) {
      return state;
    }
    final nextLevels = Map<String, int>.from(state.player.skillLevels);
    final currentLevel = nextLevels[skillId] ?? 0;
    nextLevels[skillId] = currentLevel > level ? currentLevel : level;
    final baseSkillId = skill.baseSkillId;
    if (baseSkillId != null && state.definitions?.skills[baseSkillId] != null) {
      nextLevels[baseSkillId] = nextLevels[baseSkillId] ?? 1;
    }
    return state.copyWith(
      player: state.player.copyWith(skillLevels: nextLevels),
    );
  }

  SkillMapResult mapSkill(
    GameState state, {
    required String slot,
    required String skillId,
  }) {
    final skill = state.definitions?.skills[skillId];
    if (skill == null) {
      return SkillMapResult.failure(state, '技能不存在。');
    }
    if (!knowsSkill(state, skillId)) {
      return SkillMapResult.failure(state, '尚未学会${skill.name}。');
    }
    if (!skill.mappedSlots.contains(slot)) {
      return SkillMapResult.failure(state, '${skill.name}不能映射到$slot。');
    }
    final baseSkillId = skill.baseSkillId;
    if (baseSkillId != null && !knowsSkill(state, baseSkillId)) {
      final baseName =
          state.definitions?.skills[baseSkillId]?.name ?? baseSkillId;
      return SkillMapResult.failure(state, '须先掌握基础技能：$baseName。');
    }
    final nextMapped = Map<String, String>.from(state.player.mappedSkillIds);
    nextMapped[slot] = skillId;
    return SkillMapResult.success(
      state.copyWith(player: state.player.copyWith(mappedSkillIds: nextMapped)),
    );
  }
}

class SkillMapResult {
  const SkillMapResult._({
    required this.state,
    required this.success,
    required this.message,
  });

  final GameState state;
  final bool success;
  final String message;

  factory SkillMapResult.success(GameState state) {
    return SkillMapResult._(state: state, success: true, message: '');
  }

  factory SkillMapResult.failure(GameState state, String message) {
    return SkillMapResult._(state: state, success: false, message: message);
  }
}
