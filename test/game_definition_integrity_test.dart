import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/models/dialogue_definition.dart';
import 'package:legend_of_heroes/game/models/event_definition.dart';
import 'package:legend_of_heroes/game/models/item_definition.dart';
import 'package:legend_of_heroes/game/models/npc_definition.dart';
import 'package:legend_of_heroes/game/models/quest_definition.dart';
import 'package:legend_of_heroes/game/models/room_definition.dart';
import 'package:legend_of_heroes/game/models/sect_definition.dart';
import 'package:legend_of_heroes/game/models/skill_definition.dart';
import 'package:legend_of_heroes/game/models/zone_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('asset game definitions pass integrity validation', () async {
    final definitions = await AssetGameDefinitionRepository().load();

    expect(definitions.rooms, isNotEmpty);
  });

  test('sect skills expose MUD combat metadata', () async {
    final definitions = await AssetGameDefinitionRepository().load();
    final sectSkillIds = definitions.sects.values.expand((sect) => sect.skills);

    for (final skillId in sectSkillIds) {
      final skill = definitions.skills[skillId];
      expect(skill, isNotNull, reason: '$skillId should exist.');
      expect(
        skill!.familyId,
        isNotNull,
        reason: '$skillId should have family.',
      );
      expect(
        skill.power,
        greaterThan(0),
        reason: '$skillId should have power.',
      );
      expect(
        skill.difficulty,
        greaterThan(0),
        reason: '$skillId should have difficulty.',
      );
      expect(
        skill.performIds,
        isNotEmpty,
        reason: '$skillId should define at least one perform.',
      );
    }
  });

  test('validateIntegrity reports missing content references', () {
    final definitions = GameDefinitions(
      rooms: {
        'room': _room(
          zoneId: 'missing_zone',
          exits: const {'north': 'missing_room'},
          npcs: const ['missing_npc'],
          onEnterEvents: const ['missing_enter_event'],
          investigateEvents: const ['missing_investigate_event'],
          restEvents: const ['missing_rest_event'],
        ),
      },
      zones: const {},
      npcs: const {
        'npc': NpcDefinition(
          id: 'npc',
          name: 'Npc',
          description: '',
          dialogueId: 'missing_dialogue',
        ),
      },
      items: const {
        'item': ItemDefinition(
          id: 'item',
          name: 'Item',
          description: '',
          type: ItemType.consumable,
          effects: {},
          useEvents: ['missing_use_event'],
        ),
      },
      quests: const {},
      dialogues: const {
        'dialogue': DialogueDefinition(
          id: 'dialogue',
          lines: [],
          events: ['missing_dialogue_event'],
        ),
      },
      events: const {
        'event': EventDefinition(
          id: 'event',
          type: 'investigate',
          message: '',
          logType: 'system',
          effects: {'questId': 'missing_quest'},
        ),
      },
      sects: const {},
      skills: const {},
    );

    expect(
      definitions.validateIntegrity,
      throwsA(
        isA<StateError>()
            .having(
              (error) => error.message,
              'message',
              contains('Room room references missing zoneId "missing_zone".'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('Event event references missing effects.questId'),
            ),
      ),
    );
  });

  test('validateIntegrity rejects oversized equipment effects', () {
    const definitions = GameDefinitions(
      rooms: {},
      npcs: {},
      items: {
        'artifact': ItemDefinition(
          id: 'artifact',
          name: 'Artifact',
          description: '',
          type: ItemType.equipment,
          effects: {'attack': 99},
          slot: 'weapon',
        ),
      },
      quests: {},
      dialogues: {},
      events: {},
      sects: {},
      skills: {},
    );

    expect(
      definitions.validateIntegrity,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('above cap'),
        ),
      ),
    );
  });

  test('validateIntegrity accepts MUD-style content references', () {
    const definitions = GameDefinitions(
      rooms: {
        'training_yard': RoomDefinition(
          id: 'training_yard',
          name: 'Training Yard',
          description: '',
          zoneId: 'zone',
          aliases: ['yard'],
          tags: [],
          exits: {},
          npcs: ['master'],
          items: ['manual'],
          commands: [
            RoomCommandDefinition(
              verb: 'read',
              label: '读碑',
              eventIds: ['event'],
            ),
          ],
          onEnterEvents: [],
          investigateEvents: [],
          mapX: 0,
          mapY: 0,
        ),
      },
      zones: {
        'zone': ZoneDefinition(
          id: 'zone',
          name: 'Zone',
          description: '',
          visibleRadius: 3,
        ),
      },
      npcs: {
        'master': NpcDefinition(
          id: 'master',
          name: 'Master',
          description: '',
          dialogueId: 'dialogue',
          sectId: 'sect',
          inventory: [NpcInventoryEntry(itemId: 'manual')],
        ),
      },
      items: {
        'manual': ItemDefinition(
          id: 'manual',
          name: 'Manual',
          description: '',
          type: ItemType.book,
          effects: {},
          skillId: 'skill',
        ),
      },
      quests: {
        'quest': QuestDefinition(
          id: 'quest',
          title: 'Quest',
          category: 'mud',
          description: '',
          objectives: [],
          initialProgress: {},
          giverNpcId: 'master',
          stages: [
            QuestStageDefinition(
              id: 'stage',
              description: '',
              roomId: 'training_yard',
              npcId: 'master',
              eventIds: ['event'],
            ),
          ],
          rewards: QuestRewardDefinition(
            itemIds: ['manual'],
            skillIds: ['skill'],
          ),
        ),
      },
      dialogues: {
        'dialogue': DialogueDefinition(id: 'dialogue', lines: [], events: []),
      },
      events: {
        'event': EventDefinition(
          id: 'event',
          type: 'action',
          message: '',
          logType: 'system',
          effects: {},
        ),
      },
      sects: {
        'sect': SectDefinition(
          id: 'sect',
          name: 'Sect',
          description: '',
          ranks: ['outer', 'inner', 'elder'],
          skills: ['skill', 'skill_two', 'skill_three'],
          headquartersRoomId: 'training_yard',
          masters: [
            SectMasterDefinition(
              npcId: 'master',
              level: 0,
              title: '',
              rank: 'outer',
              skillIds: ['skill'],
            ),
            SectMasterDefinition(
              npcId: 'master',
              level: 1,
              title: '',
              rank: 'inner',
              skillIds: ['skill_two'],
            ),
            SectMasterDefinition(
              npcId: 'master',
              level: 2,
              title: '',
              rank: 'elder',
              skillIds: ['skill_three'],
            ),
          ],
        ),
      },
      skills: {
        'skill': SkillDefinition(
          id: 'skill',
          name: 'Skill',
          description: '',
          category: 'skill',
          sectId: 'sect',
          familyId: 'sect',
        ),
        'skill_two': SkillDefinition(
          id: 'skill_two',
          name: 'Skill Two',
          description: '',
          category: 'skill',
        ),
        'skill_three': SkillDefinition(
          id: 'skill_three',
          name: 'Skill Three',
          description: '',
          category: 'skill',
        ),
      },
    );

    expect(definitions.validateIntegrity, returnsNormally);
  });
}

RoomDefinition _room({
  required String zoneId,
  required Map<String, String> exits,
  required List<String> npcs,
  required List<String> onEnterEvents,
  required List<String> investigateEvents,
  required List<String> restEvents,
}) {
  return RoomDefinition(
    id: 'room',
    name: 'Room',
    description: '',
    zoneId: zoneId,
    tags: const [],
    exits: exits,
    npcs: npcs,
    onEnterEvents: onEnterEvents,
    investigateEvents: investigateEvents,
    restEvents: restEvents,
    mapX: 0,
    mapY: 0,
  );
}
