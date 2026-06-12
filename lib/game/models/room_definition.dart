class RoomDefinition {
  const RoomDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.zoneId = 'default',
    required this.tags,
    required this.exits,
    required this.npcs,
    required this.onEnterEvents,
    required this.investigateEvents,
    this.restEvents = const [],
    required this.mapX,
    required this.mapY,
  });

  final String id;
  final String name;
  final String description;
  final String zoneId;
  final List<String> tags;
  final Map<String, String> exits;
  final List<String> npcs;
  final List<String> onEnterEvents;
  final List<String> investigateEvents;
  final List<String> restEvents;
  final int mapX;
  final int mapY;

  factory RoomDefinition.fromJson(Map<String, dynamic> json) {
    return RoomDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      zoneId: json['zoneId'] as String? ?? 'default',
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? const []),
      exits: Map<String, String>.from(json['exits'] as Map? ?? const {}),
      npcs: List<String>.from(json['npcs'] as List<dynamic>? ?? const []),
      onEnterEvents: List<String>.from(
        json['onEnterEvents'] as List<dynamic>? ?? const [],
      ),
      investigateEvents: List<String>.from(
        json['investigateEvents'] as List<dynamic>? ?? const [],
      ),
      restEvents: List<String>.from(
        json['restEvents'] as List<dynamic>? ?? const [],
      ),
      mapX: json['mapX'] as int? ?? 0,
      mapY: json['mapY'] as int? ?? 0,
    );
  }
}
