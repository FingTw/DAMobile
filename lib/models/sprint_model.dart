
enum SprintStatus { upcoming, inProgress, completed }

class Sprint {
  final String id;
  final String projectId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final SprintStatus status;
  final int priority;

  Sprint({
    required this.id,
    this.projectId = '',
    required this.name,
    required this.startDate,
    required this.endDate,
    this.status = SprintStatus.upcoming,
    this.priority = 0,
  });

  factory Sprint.fromMap(Map<String, dynamic> data, String documentId) {
    return Sprint(
      id: documentId,
      projectId: data['projectId'] ?? '',
      name: data['name'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(data['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(data['endDate'] ?? 0),
      status: SprintStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => SprintStatus.upcoming,
      ),
      priority: data['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'name': name,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'status': status.toString().split('.').last,
      'priority': priority,
    };
  }

  bool get isActive {
    final now = DateTime.now();
    return status == SprintStatus.inProgress ||
        (status == SprintStatus.upcoming && startDate.isBefore(now) && endDate.isAfter(now));
  }
}
