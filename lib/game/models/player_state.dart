class PlayerState {
  const PlayerState({
    required this.name,
    required this.level,
    required this.hp,
    required this.maxHp,
    required this.mp,
    required this.maxMp,
    required this.stamina,
    required this.maxStamina,
    required this.gold,
    required this.exp,
    this.sectId,
    this.sectRank,
  });

  final String name;
  final int level;
  final int hp;
  final int maxHp;
  final int mp;
  final int maxMp;
  final int stamina;
  final int maxStamina;
  final int gold;
  final int exp;
  final String? sectId;
  final String? sectRank;

  PlayerState copyWith({
    String? name,
    int? level,
    int? hp,
    int? maxHp,
    int? mp,
    int? maxMp,
    int? stamina,
    int? maxStamina,
    int? gold,
    int? exp,
    String? sectId,
    String? sectRank,
  }) {
    return PlayerState(
      name: name ?? this.name,
      level: level ?? this.level,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      mp: mp ?? this.mp,
      maxMp: maxMp ?? this.maxMp,
      stamina: stamina ?? this.stamina,
      maxStamina: maxStamina ?? this.maxStamina,
      gold: gold ?? this.gold,
      exp: exp ?? this.exp,
      sectId: sectId ?? this.sectId,
      sectRank: sectRank ?? this.sectRank,
    );
  }
}
