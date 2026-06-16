class NpcDefinition {
  const NpcDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.dialogueId,
    this.aliases = const [],
    this.title = '',
    this.role = NpcRole.commoner,
    this.sectId,
    this.teacherLevel,
    this.inventory = const [],
    this.commandVerbs = const [],
    this.interactions = const [],
    this.combat,
  });

  final String id;
  final String name;
  final String description;
  final String dialogueId;
  final List<String> aliases;
  final String title;
  final NpcRole role;
  final String? sectId;
  final int? teacherLevel;
  final List<NpcInventoryEntry> inventory;
  final List<String> commandVerbs;
  final List<NpcInteractionOption> interactions;
  final NpcCombatDefinition? combat;

  factory NpcDefinition.fromJson(Map<String, dynamic> json) {
    return NpcDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      dialogueId: json['dialogueId'] as String,
      aliases: List<String>.from(json['aliases'] as List<dynamic>? ?? const []),
      title: json['title'] as String? ?? '',
      role: NpcRole.values.byName(json['role'] as String? ?? 'commoner'),
      sectId: json['sectId'] as String?,
      teacherLevel: json['teacherLevel'] as int?,
      inventory:
          (json['inventory'] as List<dynamic>? ?? const [])
              .map(
                (item) => NpcInventoryEntry.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      commandVerbs: List<String>.from(
        json['commandVerbs'] as List<dynamic>? ?? const [],
      ),
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

enum NpcRole { commoner, merchant, guard, quest, teacher, enemy, master }

class NpcInventoryEntry {
  const NpcInventoryEntry({
    required this.itemId,
    this.count = 1,
    this.dropChance = 0,
  });

  final String itemId;
  final int count;
  final int dropChance;

  factory NpcInventoryEntry.fromJson(Map<String, dynamic> json) {
    return NpcInventoryEntry(
      itemId: json['itemId'] as String,
      count: json['count'] as int? ?? 1,
      dropChance: json['dropChance'] as int? ?? 0,
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
