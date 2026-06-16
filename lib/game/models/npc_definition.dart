class NpcDefinition {
  const NpcDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.dialogueId,
    this.interactions = const [],
    this.combat,
  });

  final String id;
  final String name;
  final String description;
  final String dialogueId;
  final List<NpcInteractionOption> interactions;
  final NpcCombatDefinition? combat;

  factory NpcDefinition.fromJson(Map<String, dynamic> json) {
    return NpcDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      dialogueId: json['dialogueId'] as String,
      interactions:
          (json['interactions'] as List<dynamic>? ?? const [])
              .map(
                (item) => NpcInteractionOption.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      combat:
          json['combat'] is Map
              ? NpcCombatDefinition.fromJson(
                Map<String, dynamic>.from(json['combat'] as Map),
              )
              : null,
    );
  }
}

class NpcCombatDefinition {
  const NpcCombatDefinition({
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.dodge,
    this.expReward = 0,
    this.sectId,
    this.attackSkillSlot = 'sword',
    this.skillLevels = const {},
    this.mappedSkillIds = const {},
  });

  final int maxHp;
  final int attack;
  final int defense;
  final int dodge;
  final int expReward;
  final String? sectId;
  final String attackSkillSlot;
  final Map<String, int> skillLevels;
  final Map<String, String> mappedSkillIds;

  factory NpcCombatDefinition.fromJson(Map<String, dynamic> json) {
    return NpcCombatDefinition(
      maxHp: json['maxHp'] as int? ?? 30,
      attack: json['attack'] as int? ?? 6,
      defense: json['defense'] as int? ?? 2,
      dodge: json['dodge'] as int? ?? 2,
      expReward: json['expReward'] as int? ?? 0,
      sectId: json['sectId'] as String?,
      attackSkillSlot: json['attackSkillSlot'] as String? ?? 'sword',
      skillLevels: Map<String, int>.from(
        json['skillLevels'] as Map? ?? const {},
      ),
      mappedSkillIds: Map<String, String>.from(
        json['mappedSkillIds'] as Map? ?? const {},
      ),
    );
  }
}

class NpcInteractionOption {
  const NpcInteractionOption({
    required this.type,
    required this.label,
    this.eventIds = const [],
    this.sectId,
    this.itemIds = const [],
    this.requiresSectId,
  });

  final String type;
  final String label;
  final List<String> eventIds;
  final String? sectId;
  final List<String> itemIds;
  final String? requiresSectId;

  factory NpcInteractionOption.fromJson(Map<String, dynamic> json) {
    return NpcInteractionOption(
      type: json['type'] as String? ?? 'talk',
      label: json['label'] as String? ?? '',
      eventIds: List<String>.from(
        json['eventIds'] as List<dynamic>? ?? const [],
      ),
      sectId: json['sectId'] as String?,
      itemIds: List<String>.from(json['itemIds'] as List<dynamic>? ?? const []),
      requiresSectId: json['requiresSectId'] as String?,
    );
  }
}
