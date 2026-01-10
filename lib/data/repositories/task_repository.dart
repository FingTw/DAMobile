import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/task_model.dart';
import 'package:untitled3/models/project_task_model.dart';

/// Repository for task-related database operations (both personal and project tasks)
/// Extracted from DatabaseService to follow Repository Pattern
class TaskRepository {
  final String? uid;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  TaskRepository({this.uid});

  // Database references
  DatabaseReference get _tasksRef => _database.ref('tasks');
  DatabaseReference? get _personalTasksRef => uid != null
      ? _database.ref('users').child(uid!).child('personal_tasks')
      : null;

  // =================== PERSONAL TASKS ===================

  /// Stream of personal tasks for current user
  Stream<List<Task>> get personalTasks {
    if (uid == null || _personalTasksRef == null) {
      return Stream.value([]);
    }
    return _personalTasksRef!.onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(
        event.snapshot.value as Map,
      );
      return data.entries.map((entry) {
        final value = Map<String, dynamic>.from(entry.value as Map);
        return Task.fromMap(value, entry.key);
      }).toList();
    });
  }

  /// Add a new personal task
  Future<void> addPersonalTask(
    String title,
    int priority,
    DateTime dueDate,
    String? assigneeId,
  ) async {
    if (uid == null || _personalTasksRef == null) {
      throw Exception('User ID is required to add personal task');
    }
    final ref = _personalTasksRef!.push();
    await ref.set({
      'title': title,
      'priority': priority,
      'status': TaskStatus.inProgress
          .toString()
          .split('.')
          .last, // Default is inProgress
      'createdAt': ServerValue.timestamp,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'assigneeId': assigneeId ?? uid,
      'evidenceLink': '',
      'isReminded': false,
    });
  }

  /// Update personal task status
  Future<void> updatePersonalTaskStatus(
    String taskId,
    TaskStatus status,
  ) async {
    if (uid == null || _personalTasksRef == null) {
      throw Exception('User ID is required to update personal task');
    }
    await _personalTasksRef!.child(taskId).update({
      'status': status.toString().split('.').last,
    });
  }

  /// Update personal task evidence
  Future<void> updatePersonalTaskEvidence(
    String taskId,
    String evidenceLink,
  ) async {
    if (uid == null || _personalTasksRef == null) {
      throw Exception('User ID is required to update task evidence');
    }
    await _personalTasksRef!.child(taskId).update({
      'evidenceLink': evidenceLink,
    });
  }

  /// Delete a personal task
  Future<void> deletePersonalTask(String taskId) async {
    if (uid == null || _personalTasksRef == null) {
      throw Exception('User ID is required to delete personal task');
    }
    await _personalTasksRef!.child(taskId).remove();
  }

  // =================== PROJECT TASKS ===================

  /// Add a new project task
  Future<void> addProjectTask(
    String projectId,
    String sprintId,
    String storyId,
    String title,
    DateTime startDate,
    DateTime dueDate,
    String assigneeId,
  ) async {
    final ref = _tasksRef.push();
    await ref.set({
      'projectId': projectId,
      'sprintId': sprintId,
      'storyId': storyId,
      'title': title,
      'assigneeId': assigneeId,
      'evidenceLink': '',
      'evidenceNotes': '',
      'status': ProjectTaskStatus.todo.toString().split('.').last,
      'createdAt': ServerValue.timestamp,
      'startDate': startDate.millisecondsSinceEpoch,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'isReminded': false,
    });
  }

  /// Update project task assignee
  Future<void> updateProjectTaskAssignee(
    String taskId,
    String assigneeId,
  ) async {
    await _tasksRef.child(taskId).update({'assigneeId': assigneeId});
  }

  /// Update project task status
  Future<void> updateProjectTaskStatus(
    String taskId,
    ProjectTaskStatus status,
  ) async {
    await _tasksRef.child(taskId).update({
      'status': status.toString().split('.').last,
    });
  }

  /// Update project task evidence
  Future<void> updateProjectTaskEvidence(
    String taskId,
    String evidenceLink,
    String evidenceNotes,
  ) async {
    await _tasksRef.child(taskId).update({
      'evidenceLink': evidenceLink,
      'evidenceNotes': evidenceNotes,
    });
  }

  /// Get all tasks for a specific user story
  Stream<List<ProjectTask>> getProjectTasksByStory(String storyId) {
    return _tasksRef.orderByChild('storyId').equalTo(storyId).onValue.map((
      event,
    ) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries
          .map(
            (e) => ProjectTask.fromMap(
              Map<String, dynamic>.from(e.value as Map),
              e.key,
            ),
          )
          .toList();
    });
  }

  /// Get all tasks for a specific sprint
  Stream<List<ProjectTask>> getProjectTasks(String sprintId) {
    return _tasksRef.orderByChild('sprintId').equalTo(sprintId).onValue.map((
      event,
    ) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries
          .map(
            (e) => ProjectTask.fromMap(
              Map<String, dynamic>.from(e.value as Map),
              e.key,
            ),
          )
          .toList();
    });
  }

  /// Update task Definition of Done checklist
  Future<void> updateTaskDoDChecklist(
    String taskId,
    Map<String, bool> checklist,
  ) async {
    await _tasksRef.child(taskId).update({'dodChecklist': checklist});
  }
}
