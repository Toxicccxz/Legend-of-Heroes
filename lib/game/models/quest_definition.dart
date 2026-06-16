class QuestDefinition {
  const QuestDefinition({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.objectives,
    required this.initialProgress,
    this.giverNpcId,
    this.acceptCommand,
    this.requiredQuestIds = const [],
    this.stages = const [],
    this.rewards = const QuestRewardDefinition(),
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final List<String> objectives;
  final Map<String, int> initialProgress;
  final String? giverNpcId;
  final String? acceptCommand;
  final List<String> requiredQuestIds;
  final List<QuestStageDefinition> stages;
  final QuestRewardDefinition rewards;

  factory QuestDefinition.fromJson(Map<String, dynamic> json) {
    return QuestDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String? ?? '支线',
      description: json['description'] as String? ?? '',
      objectives: List<String>.from(
        json['objectives'] as List<dynamic>? ?? const [],
      ),
      initialProgress: Map<String, int>.from(
        json['initialProgress'] as Map? ?? const {},
      ),
      giverNpcId: json['giverNpcId'] as String?,
      acceptCommand: json['acceptCommand'] as String?,
      requiredQuestIds: List<String>.from(
        json['requiredQuestIds'] as List<dynamic>? ?? const [],
      ),
      stages:
          (json['stages'] as List<dynamic>? ?? const [])
              .map(
                (item) => QuestStageDefinition.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      rewards: QuestRewardDefinition.fromJson(
        Map<String, dynamic>.from(json['rewards'] as Map? ?? const {}),
      ),
    );
  }
}

class QuestStageDefinition {
  const QuestStageDefinition({
    required this.id,
    required this.description,
    this.roomId,
    this.npcId,
    this.eventIds = const [],
  });

  final String id;
  final String description;
  final String? roomId;
  final String? npcId;
  final List<String> eventIds;

  factory QuestStageDefinition.fromJson(Map<String, dynamic> json) {
    return QuestStageDefinition(
      id: json['id'] as String,
      description: json['description'] as String? ?? '',
      roomId: json['roomId'] as String?,
      npcId: json['npcId'] as String?,
      eventIds: List<String>.from(
        json['eventIds'] as List<dynamic>? ?? const [],
      ),
    );
  }
}

class QuestRewardDefinition {
  const QuestRewardDefinition({
    this.exp = 0,
    this.gold = 0,
    this.itemIds = const [],
    this.skillIds = const [],
  });

  final int exp;
  final int gold;
  final List<String> itemIds;
  final List<String> skillIds;

  factory QuestRewardDefinition.fromJson(Map<String, dynamic> json) {
    return QuestRewardDefinition(
      exp: json['exp'] as int? ?? 0,
      gold: json['gold'] as int? ?? 0,
      itemIds: List<String>.from(json['itemIds'] as List<dynamic>? ?? const []),
      skillIds: List<String>.from(
        json['skillIds'] as List<dynamic>? ?? const [],
      ),
    );
  }
}
