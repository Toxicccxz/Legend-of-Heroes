class NpcDefinition {
  const NpcDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.dialogueId,
    this.interactions = const [],
  });

  final String id;
  final String name;
  final String description;
  final String dialogueId;
  final List<NpcInteractionOption> interactions;

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
