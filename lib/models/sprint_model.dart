
enum SprintStatus { upcoming, inProgress, completed }

class Sprint {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final SprintStatus status;

  Sprint({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.status = SprintStatus.upcoming,
  });

  factory Sprint.fromMap(Map<String, dynamic> data, String documentId) {
    return Sprint(
      id: documentId,
      name: data['name'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(data['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(data['endDate'] ?? 0),
      status: SprintStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => SprintStatus.upcoming,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'status': status.toString().split('.').last,
    };
  }
}
