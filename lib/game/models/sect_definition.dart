class SectDefinition {
  const SectDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.ranks,
    required this.skills,
    this.features = '',
    this.rules = const [],
    this.masters = const [],
  });

  final String id;
  final String name;
  final String description;
  final List<String> ranks;
  final List<String> skills;
  final String features;
  final List<String> rules;
  final List<SectMasterDefinition> masters;

  factory SectDefinition.fromJson(Map<String, dynamic> json) {
    return SectDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      ranks: List<String>.from(json['ranks'] as List<dynamic>? ?? const []),
      skills: List<String>.from(json['skills'] as List<dynamic>? ?? const []),
      features: json['features'] as String? ?? '',
      rules: List<String>.from(json['rules'] as List<dynamic>? ?? const []),
      masters:
          (json['masters'] as List<dynamic>? ?? const [])
              .map(
                (item) => SectMasterDefinition.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
    );
  }
}

class SectMasterDefinition {
  const SectMasterDefinition({
    required this.npcId,
    required this.level,
    required this.title,
    required this.rank,
    required this.skillIds,
  });

  final String npcId;
  final int level;
  final String title;
  final String rank;
  final List<String> skillIds;

  factory SectMasterDefinition.fromJson(Map<String, dynamic> json) {
    return SectMasterDefinition(
      npcId: json['npcId'] as String,
      level: json['level'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      rank: json['rank'] as String? ?? '',
      skillIds: List<String>.from(
        json['skillIds'] as List<dynamic>? ?? const [],
      ),
    );
  }
}
