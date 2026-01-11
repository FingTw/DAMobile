class DailyStandup {
  final String id;
  final String userId;
  final String userName;
  final String sprintId;
  final String projectId;
  final DateTime date;
  final String yesterday;
  final String today;
  final List<String> blockers;
  final DateTime createdAt;

  DailyStandup({
    required this.id,
    required this.userId,
    required this.userName,
    required this.sprintId,
    required this.projectId,
    required this.date,
    required this.yesterday,
    required this.today,
    this.blockers = const [],
    required this.createdAt,
  });

  factory DailyStandup.fromMap(Map<String, dynamic> data, String documentId) {
    return DailyStandup(
      id: documentId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      sprintId: data['sprintId'] ?? '',
      projectId: data['projectId'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? 0),
      yesterday: data['yesterday'] ?? '',
      today: data['today'] ?? '',
      blockers: List<String>.from(data['blockers'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'sprintId': sprintId,
      'projectId': projectId,
      'date': date.millisecondsSinceEpoch,
      'yesterday': yesterday,
      'today': today,
      'blockers': blockers,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Helper to check if this is today's standup
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
