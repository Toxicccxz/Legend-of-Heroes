class DialogueDefinition {
  const DialogueDefinition({
    required this.id,
    required this.lines,
    required this.events,
  });

  final String id;
  final List<String> lines;
  final List<String> events;

  factory DialogueDefinition.fromJson(Map<String, dynamic> json) {
    return DialogueDefinition(
      id: json['id'] as String,
      lines: List<String>.from(json['lines'] as List<dynamic>? ?? const []),
      events: List<String>.from(json['events'] as List<dynamic>? ?? const []),
    );
  }
}
