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
      _requireAllIds(
        errors,
        source: 'Item ${item.id}',
        field: 'useEvents',
        ids: item.useEvents,
        targetIds: events.keys,
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
    key: 'npcId',
    targetIds: definitions.npcs.keys,
  );
  _requireOptionalEffectId(
    errors,
    event: event,
    key: 'roomId',
    targetIds: definitions.rooms.keys,
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
