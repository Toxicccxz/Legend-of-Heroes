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
    return GameDefinitions(
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
  }

  Future<Map<String, T>> _loadMap<T>(
    String assetPath,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final jsonText = await _bundle.loadString(assetPath);
    final jsonList = jsonDecode(jsonText) as List<dynamic>;
    final entries = jsonList.map((item) {
      final object = fromJson(item as Map<String, dynamic>);
      final id = item['id'] as String;
      return MapEntry(id, object);
    });
    return Map<String, T>.fromEntries(entries);
  }
}
