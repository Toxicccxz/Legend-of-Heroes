enum QuestStatus { inactive, active, completed }

class QuestProgress {
  const QuestProgress({
    required this.questId,
    required this.currentStage,
    required this.status,
    required this.progress,
  });

  final String questId;
  final int currentStage;
  final QuestStatus status;
  final Map<String, int> progress;

  QuestProgress copyWith({
    String? questId,
    int? currentStage,
    QuestStatus? status,
    Map<String, int>? progress,
  }) {
    return QuestProgress(
      questId: questId ?? this.questId,
      currentStage: currentStage ?? this.currentStage,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}
