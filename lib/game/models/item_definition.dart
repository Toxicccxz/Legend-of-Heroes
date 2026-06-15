enum ItemType { consumable, quest, equipment }

class EquipmentSlotIds {
  const EquipmentSlotIds._();

  static const head = 'head';
  static const upperBody = 'upperBody';
  static const wrist = 'wrist';
  static const lowerBody = 'lowerBody';
  static const feet = 'feet';
  static const necklace = 'necklace';
  static const weapon = 'weapon';

  static const all = [
    head,
    upperBody,
    wrist,
    lowerBody,
    feet,
    necklace,
    weapon,
  ];

  static const labels = {
    head: '帽子',
    upperBody: '上衣',
    wrist: '护腕',
    lowerBody: '下衣',
    feet: '鞋子',
    necklace: '项链',
    weapon: '武器',
  };

  static String labelFor(String slot) {
    return labels[slot] ?? slot;
  }
}

class ItemEffectKeys {
  const ItemEffectKeys._();

  static const maxHp = 'maxHp';
  static const maxMp = 'maxMp';
  static const maxStamina = 'maxStamina';
  static const attack = 'attack';
  static const defense = 'defense';

  static const equipmentKeys = [maxHp, maxMp, maxStamina, attack, defense];

  static const all = equipmentKeys;

  static const equipmentCaps = {
    maxHp: 30,
    maxMp: 20,
    maxStamina: 20,
    attack: 5,
    defense: 5,
  };

  static const labels = {
    maxHp: '最大HP',
    maxMp: '最大MP',
    maxStamina: '最大体力',
    attack: '攻击',
    defense: '防御',
  };

  static String labelFor(String key) {
    return labels[key] ?? key;
  }
}

class ItemDefinition {
  const ItemDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.effects,
    this.useEvents = const [],
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
