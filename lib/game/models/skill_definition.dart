enum SkillKind { basic, special, ultimate }

class SkillDefinition {
  const SkillDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.kind = SkillKind.special,
    this.baseSkillId,
    this.mappedSlots = const [],
    this.requiredSkillIds = const [],
    this.sectId,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final SkillKind kind;
  final String? baseSkillId;
  final List<String> mappedSlots;
  final List<String> requiredSkillIds;
  final String? sectId;

  factory SkillDefinition.fromJson(Map<String, dynamic> json) {
    return SkillDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '通用',
      kind: SkillKind.values.byName(json['kind'] as String? ?? 'special'),
      baseSkillId: json['baseSkillId'] as String?,
      mappedSlots: List<String>.from(
        json['mappedSlots'] as List<dynamic>? ?? const [],
      ),
      requiredSkillIds: List<String>.from(
        json['requiredSkillIds'] as List<dynamic>? ?? const [],
      ),
      sectId: json['sectId'] as String?,
    );
  }
}
