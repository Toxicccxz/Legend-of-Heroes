class ZoneDefinition {
  const ZoneDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.visibleRadius,
    this.path = '',
    this.parentZoneId,
    this.levelRange = const [1, 99],
    this.respawnSeconds = 300,
  });

  final String id;
  final String name;
  final String description;
  final int visibleRadius;
  final String path;
  final String? parentZoneId;
  final List<int> levelRange;
  final int respawnSeconds;

  factory ZoneDefinition.fromJson(Map<String, dynamic> json) {
    return ZoneDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      visibleRadius: json['visibleRadius'] as int? ?? 3,
      path: json['path'] as String? ?? '',
      parentZoneId: json['parentZoneId'] as String?,
      levelRange: List<int>.from(
        json['levelRange'] as List<dynamic>? ?? const [1, 99],
      ),
      respawnSeconds: json['respawnSeconds'] as int? ?? 300,
    );
  }
}
