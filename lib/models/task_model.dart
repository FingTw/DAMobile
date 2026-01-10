
enum TaskStatus { todo, inProgress, done }

class Task {
  final String id;
  final String title;
  final TaskStatus status;
  final int priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? assigneeId; // For personal tasks, this is the owner
  final String? evidenceLink; // For done tasks, allow image upload

  Task({
    required this.id,
    required this.title,
    this.status = TaskStatus.todo,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    this.assigneeId,
    this.evidenceLink,
  });

  factory Task.fromMap(Map<String, dynamic> data, String documentId) {
    return Task(
      id: documentId,
      title: data['title'] ?? '',
      status: TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => TaskStatus.todo,
      ),
      priority: data['priority'] ?? 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      dueDate: data['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['dueDate'])
          : null,
      assigneeId: data['assigneeId'],
      evidenceLink: data['evidenceLink'],
    );
  }
}
