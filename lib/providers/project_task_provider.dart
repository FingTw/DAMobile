import 'package:flutter/foundation.dart';
import 'package:untitled3/data/repositories/project_task_repository.dart';
import 'package:untitled3/models/project_task_model.dart';

/// Provider for managing project tasks with real-time updates
class ProjectTaskProvider with ChangeNotifier {
  final ProjectTaskRepository _repository;
  List<ProjectTask> _tasks = [];
  bool _isLoading = true;
  String? _error;

  ProjectTaskProvider(this._repository) {
    _init();
  }

  List<ProjectTask> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _init() {
    _repository.getUserProjectTasks().listen(
      (tasks) {
        _tasks = tasks;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Get total task count
  int get totalTasks => _tasks.length;

  /// Get completed task count
  int get completedTasks => _tasks
      .where((task) =>
          task.status == ProjectTaskStatus.done ||
          task.status == ProjectTaskStatus.verified)
      .length;

  /// Get completion percentage
  double get completionPercentage {
    if (_tasks.isEmpty) return 0.0;
    return completedTasks / totalTasks;
  }

  /// Get overdue task count
  int get overdueTasks => _tasks.where((task) => task.isOverdue).length;

  /// Get in-progress task count
  int get inProgressTasks =>
      _tasks.where((task) => task.status == ProjectTaskStatus.inProgress).length;

  /// Get todo task count
  int get todoTasks =>
      _tasks.where((task) => task.status == ProjectTaskStatus.todo).length;

  /// Get tasks sorted by due date
  List<ProjectTask> get tasksByDueDate {
    final tasksWithDueDate = _tasks.where((task) => task.dueDate != null).toList();
    tasksWithDueDate.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return tasksWithDueDate;
  }

  /// Get upcoming tasks (next 7 days)
  List<ProjectTask> get upcomingTasks {
    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(now) && task.dueDate!.isBefore(weekLater);
    }).toList();
  }
}
