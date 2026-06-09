import '../core/game_state.dart';

class CombatSystem {
  const CombatSystem();

  GameLogEntry simulateSimpleAttack() {
    return GameLogEntry(
      timestamp: DateTime.now(),
      type: GameLogType.combat,
      message: '野狼发动攻击，造成 8 点伤害。',
    );
  }
}
