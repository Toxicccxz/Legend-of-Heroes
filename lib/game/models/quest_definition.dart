class QuestDefinition {
  const QuestDefinition({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.objectives,
    required this.initialProgress,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final List<String> objectives;
  final Map<String, int> initialProgress;

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
    );
  }
}
