import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/dialogue_definition.dart';
import '../models/event_definition.dart';
import '../models/item_definition.dart';
import '../models/npc_definition.dart';
import '../models/quest_definition.dart';
import '../models/room_definition.dart';
import '../models/sect_definition.dart';
import '../models/skill_definition.dart';
import '../models/zone_definition.dart';

class GameDefinitions {
  const GameDefinitions({
    required this.rooms,
    this.zones = const {},
    required this.npcs,
    required this.items,
    required this.quests,
    required this.dialogues,
    required this.events,
    required this.sects,
    required this.skills,
  });

  final Map<String, RoomDefinition> rooms;
  final Map<String, ZoneDefinition> zones;
  final Map<String, NpcDefinition> npcs;
  final Map<String, ItemDefinition> items;
  final Map<String, QuestDefinition> quests;
  final Map<String, DialogueDefinition> dialogues;
  final Map<String, EventDefinition> events;
  final Map<String, SectDefinition> sects;
  final Map<String, SkillDefinition> skills;

  void validateIntegrity() {
    final errors = <String>[];

    for (final room in rooms.values) {
      _requireId(
        errors,
        source: 'Room ${room.id}',
        field: 'zoneId',
        id: room.zoneId,
        targetIds: zones.keys,
      );
      _requireAllIds(
        errors,
        source: 'Room ${room.id}',
        field: 'exits',
        ids: room.exits.values,
        targetIds: rooms.keys,
      );
      _requireAllIds(
        errors,
        source: 'Room ${room.id}',
        field: 'npcs',
        ids: room.npcs,
        targetIds: npcs.keys,
      );
      _requireAllIds(
        errors,
        source: 'Room ${room.id}',
        field: 'items',
        ids: room.items,
        targetIds: items.keys,
      );
      for (final command in room.commands) {
        _requireAllIds(
          errors,
          source: 'Room ${room.id} command ${command.verb}',
          field: 'eventIds',
          ids: command.eventIds,
          targetIds: events.keys,
        );
      }
      _requireAllIds(
        errors,
        source: 'Room ${room.id}',
        field: 'onEnterEvents',
        ids: room.onEnterEvents,
        targetIds: events.keys,
      );
      _requireAllIds(
        errors,
        source: 'Room ${room.id}',
        field: 'investigateEvents',
        ids: room.investigateEvents,
        targetIds: events.keys,
      );
      _requireAllIds(
        errors,
        source: 'Room ${room.id}',
        field: 'restEvents',
        ids: room.restEvents,
        targetIds: events.keys,
      );
    }

    for (final npc in npcs.values) {
      _requireId(
        errors,
        source: 'Npc ${npc.id}',
        field: 'dialogueId',
        id: npc.dialogueId,
        targetIds: dialogues.keys,
      );
      _validateNpcInteractionReferences(errors, npc, this);
      _validateNpcCombatReferences(errors, npc, this);
    }

    for (final dialogue in dialogues.values) {
      _requireAllIds(
        errors,
        source: 'Dialogue ${dialogue.id}',
        field: 'events',
        ids: dialogue.events,
        targetIds: events.keys,
      );
    }

    for (final item in items.values) {
      _validateItemDefinition(errors, item, this);
      _requireAllIds(
        errors,
        source: 'Item ${item.id}',
        field: 'useEvents',
        ids: item.useEvents,
        targetIds: events.keys,
      );
    }

    for (final sect in sects.values) {
      _validateSectDefinition(errors, sect, this);
    }

    for (final skill in skills.values) {
      _validateSkillDefinition(errors, skill, this);
    }

    for (final quest in quests.values) {
      _validateQuestDefinition(errors, quest, this);
    }

    for (final zone in zones.values) {
      _requireOptionalId(
        errors,
        source: 'Zone ${zone.id}',
        field: 'parentZoneId',
        id: zone.parentZoneId,
        targetIds: zones.keys,
      );
    }

    for (final event in events.values) {
      _validateEventEffectReferences(errors, event, this);
    }

    if (errors.isNotEmpty) {
      throw StateError('Invalid game definitions:\n${errors.join('\n')}');
    }
  }
}

void _validateNpcCombatReferences(
  List<String> errors,
  NpcDefinition npc,
  GameDefinitions definitions,
) {
  final combat = npc.combat;
  if (combat == null) {
    return;
  }
  _requireOptionalId(
    errors,
    source: 'Npc ${npc.id}',
    field: 'sectId',
    id: npc.sectId,
    targetIds: definitions.sects.keys,
  );
  for (final entry in npc.inventory) {
    _requireId(
      errors,
      source: 'Npc ${npc.id} inventory',
      field: 'itemId',
      id: entry.itemId,
      targetIds: definitions.items.keys,
    );
  }
  _requireOptionalId(
    errors,
    source: 'Npc ${npc.id} combat',
    field: 'sectId',
    id: combat.sectId,
    targetIds: definitions.sects.keys,
  );
  _requireAllIds(
    errors,
    source: 'Npc ${npc.id} combat',
    field: 'skillLevels',
    ids: combat.skillLevels.keys,
    targetIds: definitions.skills.keys,
  );
  _requireAllIds(
    errors,
    source: 'Npc ${npc.id} combat',
    field: 'mappedSkillIds',
    ids: combat.mappedSkillIds.values,
    targetIds: definitions.skills.keys,
  );
  for (final entry in combat.mappedSkillIds.entries) {
    final skill = definitions.skills[entry.value];
    if (skill != null && !skill.mappedSlots.contains(entry.key)) {
      errors.add(
        'Npc ${npc.id} combat maps ${entry.value} to invalid slot "${entry.key}".',
      );
    }
  }
  if (!combat.mappedSkillIds.containsKey(combat.attackSkillSlot)) {
    errors.add(
      'Npc ${npc.id} combat attackSkillSlot "${combat.attackSkillSlot}" is not mapped.',
    );
  }
}

void _validateSkillDefinition(
  List<String> errors,
  SkillDefinition skill,
  GameDefinitions definitions,
) {
  _requireOptionalId(
    errors,
    source: 'Skill ${skill.id}',
    field: 'baseSkillId',
    id: skill.baseSkillId,
    targetIds: definitions.skills.keys,
  );
  _requireAllIds(
    errors,
    source: 'Skill ${skill.id}',
    field: 'requiredSkillIds',
    ids: skill.requiredSkillIds,
    targetIds: definitions.skills.keys,
  );
  _requireOptionalId(
    errors,
    source: 'Skill ${skill.id}',
    field: 'familyId',
    id: skill.familyId,
    targetIds: definitions.sects.keys,
  );
  _requireOptionalId(
    errors,
    source: 'Skill ${skill.id}',
    field: 'sectId',
    id: skill.sectId,
    targetIds: definitions.sects.keys,
  );
}

void _validateSectDefinition(
  List<String> errors,
  SectDefinition sect,
  GameDefinitions definitions,
) {
  _requireAllIds(
    errors,
    source: 'Sect ${sect.id}',
    field: 'skills',
    ids: sect.skills,
    targetIds: definitions.skills.keys,
  );
  _requireOptionalId(
    errors,
    source: 'Sect ${sect.id}',
    field: 'headquartersRoomId',
    id: sect.headquartersRoomId,
    targetIds: definitions.rooms.keys,
  );
  _requireAllIds(
    errors,
    source: 'Sect ${sect.id}',
    field: 'forbiddenSectIds',
    ids: sect.forbiddenSectIds,
    targetIds: definitions.sects.keys,
  );
  if (sect.masters.length != 3) {
    errors.add('Sect ${sect.id} must define exactly three masters.');
  }
  final levels = sect.masters.map((master) => master.level).toSet();
  for (final level in const [0, 1, 2]) {
    if (!levels.contains(level)) {
      errors.add('Sect ${sect.id} is missing master level $level.');
    }
  }
  for (final master in sect.masters) {
    final source = 'Sect ${sect.id} master ${master.npcId}';
    _requireId(
      errors,
      source: source,
      field: 'npcId',
      id: master.npcId,
      targetIds: definitions.npcs.keys,
    );
    _requireAllIds(
      errors,
      source: source,
      field: 'skillIds',
      ids: master.skillIds,
      targetIds: definitions.skills.keys,
    );
    if (master.rank.isNotEmpty && !sect.ranks.contains(master.rank)) {
      errors.add('$source rank "${master.rank}" is not listed in ranks.');
    }
  }
}

void _validateNpcInteractionReferences(
  List<String> errors,
  NpcDefinition npc,
  GameDefinitions definitions,
) {
  for (final option in npc.interactions) {
    final source = 'Npc ${npc.id} interaction ${option.type}';
    _requireAllIds(
      errors,
      source: source,
      field: 'eventIds',
      ids: option.eventIds,
      targetIds: definitions.events.keys,
    );
    _requireAllIds(
      errors,
      source: source,
      field: 'itemIds',
      ids: option.itemIds,
      targetIds: definitions.items.keys,
    );
    _requireOptionalId(
      errors,
      source: source,
      field: 'sectId',
      id: option.sectId,
      targetIds: definitions.sects.keys,
    );
    _requireOptionalId(
      errors,
      source: source,
      field: 'requiresSectId',
      id: option.requiresSectId,
      targetIds: definitions.sects.keys,
    );
  }
}

void _validateItemDefinition(
  List<String> errors,
  ItemDefinition item,
  GameDefinitions definitions,
) {
  final slot = item.slot;
  if (item.type == ItemType.equipment || item.type == ItemType.weapon) {
    if (slot == null) {
      errors.add('Item ${item.id} is equipment but has no slot.');
    } else if (!EquipmentSlotIds.all.contains(slot)) {
      errors.add('Item ${item.id} uses unknown equipment slot "$slot".');
    }
  }
  _requireOptionalId(
    errors,
    source: 'Item ${item.id}',
    field: 'skillId',
    id: item.skillId,
    targetIds: definitions.skills.keys,
  );

  for (final effectKey in item.effects.keys) {
    if (!ItemEffectKeys.all.contains(effectKey)) {
      errors.add('Item ${item.id} uses unknown effect "$effectKey".');
      continue;
    }
    final value = item.effects[effectKey] ?? 0;
    final cap = ItemEffectKeys.equipmentCaps[effectKey];
    if (value < 0) {
      errors.add('Item ${item.id} effect "$effectKey" cannot be negative.');
    }
    if (cap != null && value > cap) {
      errors.add(
        'Item ${item.id} effect "$effectKey" is $value, above cap $cap.',
      );
    }
  }
}

void _validateQuestDefinition(
  List<String> errors,
  QuestDefinition quest,
  GameDefinitions definitions,
) {
  _requireOptionalId(
    errors,
    source: 'Quest ${quest.id}',
    field: 'giverNpcId',
    id: quest.giverNpcId,
    targetIds: definitions.npcs.keys,
  );
  _requireAllIds(
    errors,
    source: 'Quest ${quest.id}',
    field: 'requiredQuestIds',
    ids: quest.requiredQuestIds,
    targetIds: definitions.quests.keys,
  );
  _requireAllIds(
    errors,
    source: 'Quest ${quest.id}',
    field: 'rewards.itemIds',
    ids: quest.rewards.itemIds,
    targetIds: definitions.items.keys,
  );
  _requireAllIds(
    errors,
    source: 'Quest ${quest.id}',
    field: 'rewards.skillIds',
    ids: quest.rewards.skillIds,
    targetIds: definitions.skills.keys,
  );
  for (final stage in quest.stages) {
    final source = 'Quest ${quest.id} stage ${stage.id}';
    _requireOptionalId(
      errors,
      source: source,
      field: 'roomId',
      id: stage.roomId,
      targetIds: definitions.rooms.keys,
    );
    _requireOptionalId(
      errors,
      source: source,
      field: 'npcId',
      id: stage.npcId,
      targetIds: definitions.npcs.keys,
    );
    _requireAllIds(
      errors,
      source: source,
      field: 'eventIds',
      ids: stage.eventIds,
      targetIds: definitions.events.keys,
    );
  }
}

abstract class GameDefinitionRepository {
  Future<GameDefinitions> load();
}

class AssetGameDefinitionRepository implements GameDefinitionRepository {
  AssetGameDefinitionRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<GameDefinitions> load() async {
    final definitions = GameDefinitions(
      rooms: await _loadMap('assets/data/rooms.json', RoomDefinition.fromJson),
      zones: await _loadMap('assets/data/zones.json', ZoneDefinition.fromJson),
      npcs: await _loadMap('assets/data/npcs.json', NpcDefinition.fromJson),
      items: await _loadMap('assets/data/items.json', ItemDefinition.fromJson),
      quests: await _loadMap(
        'assets/data/quests.json',
        QuestDefinition.fromJson,
      ),
      dialogues: await _loadMap(
        'assets/data/dialogues.json',
        DialogueDefinition.fromJson,
      ),
      events: await _loadMap(
        'assets/data/events.json',
        EventDefinition.fromJson,
      ),
      sects: await _loadMap('assets/data/sects.json', SectDefinition.fromJson),
      skills: await _loadMap(
        'assets/data/skills.json',
        SkillDefinition.fromJson,
      ),
    );
    definitions.validateIntegrity();
    return definitions;
  }

  Future<Map<String, T>> _loadMap<T>(
    String assetPath,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final jsonText = await _bundle.loadString(assetPath);
    final jsonList = jsonDecode(jsonText) as List<dynamic>;
    final entries = <MapEntry<String, T>>[];
    final ids = <String>{};
    for (final item in jsonList) {
      final json = item as Map<String, dynamic>;
      final id = json['id'] as String;
      if (!ids.add(id)) {
        throw StateError('Duplicate id "$id" in $assetPath.');
      }
      final object = fromJson(json);
      entries.add(MapEntry(id, object));
    }
    return Map<String, T>.fromEntries(entries);
  }
}

void _requireAllIds(
  List<String> errors, {
  required String source,
  required String field,
  required Iterable<String> ids,
  required Iterable<String> targetIds,
}) {
  for (final id in ids) {
    _requireId(
      errors,
      source: source,
      field: field,
      id: id,
      targetIds: targetIds,
    );
  }
}

void _requireId(
  List<String> errors, {
  required String source,
  required String field,
  required String id,
  required Iterable<String> targetIds,
}) {
  if (!targetIds.contains(id)) {
    errors.add('$source references missing $field "$id".');
  }
}

void _requireOptionalId(
  List<String> errors, {
  required String source,
  required String field,
  required String? id,
  required Iterable<String> targetIds,
}) {
  if (id == null) {
    return;
  }
  _requireId(
    errors,
    source: source,
    field: field,
    id: id,
    targetIds: targetIds,
  );
}

void _validateEventEffectReferences(
  List<String> errors,
  EventDefinition event,
  GameDefinitions definitions,
) {
  _requireOptionalEffectId(
    errors,
    event: event,
    key: 'questId',
    targetIds: definitions.quests.keys,
  );
  _requireOptionalEffectId(
    errors,
    event: event,
    key: 'completeQuestId',
    targetIds: definitions.quests.keys,
  );
  _requireOptionalEffectId(
    errors,
    event: event,
    key: 'itemId',
    targetIds: definitions.items.keys,
  );
  _requireOptionalEffectId(
    errors,
    event: event,
    key: 'giveItemId',
    targetIds: definitions.items.keys,
  );
  _requireOptionalEffectId(
    errors,
    event: event,
    key: 'removeItemId',
    targetIds: definitions.items.keys,
  );
  _requireOptionalEffectId(
    errors,
    event: event,
    key: 'npcId',
    targetIds: definitions.npcs.keys,
  );
  _requireOptionalEffectId(
    errors,
    event: event,
    key: 'roomId',
    targetIds: definitions.rooms.keys,
  );
  _requireOptionalEffectId(
    errors,
    event: event,
    key: 'joinSectId',
    targetIds: definitions.sects.keys,
  );
}

void _requireOptionalEffectId(
  List<String> errors, {
  required EventDefinition event,
  required String key,
  required Iterable<String> targetIds,
}) {
  final value = event.effects[key];
  if (value is! String) {
    return;
  }
  _requireId(
    errors,
    source: 'Event ${event.id}',
    field: 'effects.$key',
    id: value,
    targetIds: targetIds,
  );
}
