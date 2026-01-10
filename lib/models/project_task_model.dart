
enum ProjectTaskStatus { todo, inProgress, done, verified }

class ProjectTask {
  final String id;
  final String title;
  final String storyId;
  final ProjectTaskStatus status;
  final String assigneeId; 
  final String evidenceLink; 
  final String evidenceNotes; // New field for notes
  final DateTime createdAt;
  final DateTime? startDate; // Thời gian bắt đầu task
  final DateTime? dueDate;

  ProjectTask({
    required this.id,
    required this.title,
    required this.storyId,
    this.status = ProjectTaskStatus.todo,
    this.assigneeId = '',
    this.evidenceLink = '',
    this.evidenceNotes = '',
    required this.createdAt,
    this.startDate,
    this.dueDate,
  });

  factory ProjectTask.fromMap(Map<String, dynamic> data, String documentId) {
    return ProjectTask(
      id: documentId,
      title: data['title'] ?? '',
      storyId: data['storyId'] ?? '',
      assigneeId: data['assigneeId'] ?? '',
      evidenceLink: data['evidenceLink'] ?? '',
      evidenceNotes: data['evidenceNotes'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      startDate: data['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['startDate'])
          : null,
      status: ProjectTaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ProjectTaskStatus.todo,
      ),
      dueDate: data['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['dueDate'])
          : null,
    );
  }

  Duration? get timeRemaining {
    if (dueDate == null) return null;
    final now = DateTime.now();
    if (dueDate!.isBefore(now)) return null;
    return dueDate!.difference(now);
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now()) && status != ProjectTaskStatus.done;
  }
}
