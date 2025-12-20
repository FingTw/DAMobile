
enum TaskStatus { todo, inProgress, done }

class Task {
  final String id;
  final String title;
  final TaskStatus status;
  final int priority;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.status = TaskStatus.todo,
    required this.priority,
    required this.createdAt,
  });
}
