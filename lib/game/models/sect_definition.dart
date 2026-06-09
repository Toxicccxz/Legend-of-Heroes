class SectDefinition {
  const SectDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.ranks,
    required this.skills,
  });

  final String id;
  final String name;
  final String description;
  final List<String> ranks;
  final List<String> skills;

  factory SectDefinition.fromJson(Map<String, dynamic> json) {
    return SectDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      ranks: List<String>.from(json['ranks'] as List<dynamic>? ?? const []),
      skills: List<String>.from(json['skills'] as List<dynamic>? ?? const []),
    );
  }
}
