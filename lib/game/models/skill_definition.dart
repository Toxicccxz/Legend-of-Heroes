enum SkillKind { basic, special, ultimate }

enum SkillSlot { force, dodge, parry, sword, blade, staff, hand, strike }

class SkillDefinition {
  const SkillDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.kind = SkillKind.special,
    this.slot = SkillSlot.hand,
    this.familyId,
    this.baseSkillId,
    this.mappedSlots = const [],
    this.requiredSkillIds = const [],
    this.sectId,
    this.power = 10,
    this.difficulty = 10,
    this.performIds = const [],
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final SkillKind kind;
  final SkillSlot slot;
  final String? familyId;
  final String? baseSkillId;
  final List<String> mappedSlots;
  final List<String> requiredSkillIds;
  final String? sectId;
  final int power;
  final int difficulty;
  final List<String> performIds;

  factory SkillDefinition.fromJson(Map<String, dynamic> json) {
    return SkillDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '通用',
      kind: SkillKind.values.byName(json['kind'] as String? ?? 'special'),
      slot: SkillSlot.values.byName(json['slot'] as String? ?? 'hand'),
      familyId: json['familyId'] as String?,
      baseSkillId: json['baseSkillId'] as String?,
      mappedSlots: List<String>.from(
        json['mappedSlots'] as List<dynamic>? ?? const [],
      ),
      requiredSkillIds: List<String>.from(
        json['requiredSkillIds'] as List<dynamic>? ?? const [],
      ),
      sectId: json['sectId'] as String?,
      power: json['power'] as int? ?? 10,
      difficulty: json['difficulty'] as int? ?? 10,
      performIds: List<String>.from(
        json['performIds'] as List<dynamic>? ?? const [],
      ),
    );
  }
}
