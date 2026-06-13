class ZoneDefinition {
  const ZoneDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.visibleRadius,
  });

  final String id;
  final String name;
  final String description;
  final int visibleRadius;

  factory ZoneDefinition.fromJson(Map<String, dynamic> json) {
    return ZoneDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      visibleRadius: json['visibleRadius'] as int? ?? 3,
    );
  }
}
