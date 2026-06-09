class NpcDefinition {
  const NpcDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.dialogueId,
  });

  final String id;
  final String name;
  final String description;
  final String dialogueId;

  factory NpcDefinition.fromJson(Map<String, dynamic> json) {
    return NpcDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      dialogueId: json['dialogueId'] as String,
    );
  }
}
