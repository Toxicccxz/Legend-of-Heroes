enum ItemType { consumable, quest, equipment }

class ItemDefinition {
  const ItemDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.effects,
    required this.useEvents,
    this.slot,
  });

  final String id;
  final String name;
  final String description;
  final ItemType type;
  final Map<String, int> effects;
  final List<String> useEvents;
  final String? slot;

  factory ItemDefinition.fromJson(Map<String, dynamic> json) {
    return ItemDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      type: ItemType.values.byName(json['type'] as String? ?? 'quest'),
      effects: Map<String, int>.from(json['effects'] as Map? ?? const {}),
      useEvents: List<String>.from(
        json['useEvents'] as List<dynamic>? ?? const [],
      ),
      slot: json['slot'] as String?,
    );
  }
}

class InventoryEntry {
  const InventoryEntry({required this.itemId, required this.count});

  final String itemId;
  final int count;

  InventoryEntry copyWith({String? itemId, int? count}) {
    return InventoryEntry(
      itemId: itemId ?? this.itemId,
      count: count ?? this.count,
    );
  }
}
