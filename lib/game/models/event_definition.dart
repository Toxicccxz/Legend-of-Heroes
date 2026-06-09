class EventDefinition {
  const EventDefinition({
    required this.id,
    required this.type,
    required this.message,
    required this.logType,
    required this.effects,
    this.onceFlag,
  });

  final String id;
  final String type;
  final String message;
  final String logType;
  final Map<String, dynamic> effects;
  final String? onceFlag;

  factory EventDefinition.fromJson(Map<String, dynamic> json) {
    return EventDefinition(
      id: json['id'] as String,
      type: json['type'] as String,
      message: json['message'] as String? ?? '',
      logType: json['logType'] as String? ?? 'system',
      effects: Map<String, dynamic>.from(json['effects'] as Map? ?? const {}),
      onceFlag: json['onceFlag'] as String?,
    );
  }
}
