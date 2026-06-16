class RoomDefinition {
  const RoomDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.zoneId = 'default',
    this.aliases = const [],
    this.sceneType = 'outdoor',
    this.levelRange = const [1, 99],
    required this.tags,
    required this.exits,
    required this.npcs,
    this.items = const [],
    this.commands = const [],
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
  final List<String> aliases;
  final String sceneType;
  final List<int> levelRange;
  final List<String> tags;
  final Map<String, String> exits;
  final List<String> npcs;
  final List<String> items;
  final List<RoomCommandDefinition> commands;
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
      aliases: List<String>.from(json['aliases'] as List<dynamic>? ?? const []),
      sceneType: json['sceneType'] as String? ?? 'outdoor',
      levelRange: List<int>.from(
        json['levelRange'] as List<dynamic>? ?? const [1, 99],
      ),
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? const []),
      exits: Map<String, String>.from(json['exits'] as Map? ?? const {}),
      npcs: List<String>.from(json['npcs'] as List<dynamic>? ?? const []),
      items: List<String>.from(json['items'] as List<dynamic>? ?? const []),
      commands:
          (json['commands'] as List<dynamic>? ?? const [])
              .map(
                (item) => RoomCommandDefinition.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
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

class RoomCommandDefinition {
  const RoomCommandDefinition({
    required this.verb,
    required this.label,
    this.description = '',
    this.targetId,
    this.eventIds = const [],
    this.requiresFlags = const {},
  });

  final String verb;
  final String label;
  final String description;
  final String? targetId;
  final List<String> eventIds;
  final Map<String, dynamic> requiresFlags;

  factory RoomCommandDefinition.fromJson(Map<String, dynamic> json) {
    return RoomCommandDefinition(
      verb: json['verb'] as String? ?? 'look',
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetId: json['targetId'] as String?,
      eventIds: List<String>.from(
        json['eventIds'] as List<dynamic>? ?? const [],
      ),
      requiresFlags: Map<String, dynamic>.from(
        json['requiresFlags'] as Map? ?? const {},
      ),
    );
  }
}
