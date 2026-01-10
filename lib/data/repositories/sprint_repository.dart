import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/sprint_model.dart';

/// Repository for sprint-related database operations
/// Extracted from DatabaseService to follow Repository Pattern
class SprintRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference get _sprintsRef => _database.ref('sprints');

  /// Add a new sprint to a project
  Future<void> addSprint(
    String projectId,
    String name,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final ref = _sprintsRef.push();
    await ref.set({
      'projectId': projectId,
      'name': name,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'status': SprintStatus.upcoming.toString().split('.').last,
      'priority': 0, // Priority for sorting
    });
  }

  /// Add a new sprint with goal
  Future<void> addSprintWithGoal(
    String projectId,
    String name,
    DateTime startDate,
    DateTime endDate,
    String goal,
    String goalDescription,
  ) async {
    final ref = _sprintsRef.push();
    await ref.set({
      'projectId': projectId,
      'name': name,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'status': SprintStatus.upcoming.toString().split('.').last,
      'priority': 0,
      'goal': goal,
      'goalDescription': goalDescription,
    });
  }

  /// Update sprint status
  Future<void> updateSprintStatus(String sprintId, SprintStatus status) async {
    await _sprintsRef.child(sprintId).update({
      'status': status.toString().split('.').last,
    });
  }

  /// Update sprint priority
  Future<void> updateSprintPriority(String sprintId, int priority) async {
    await _sprintsRef.child(sprintId).update({'priority': priority});
  }

  /// Update sprint goal
  Future<void> updateSprintGoal(
    String sprintId,
    String goal,
    String goalDescription,
  ) async {
    await _sprintsRef.child(sprintId).update({
      'goal': goal,
      'goalDescription': goalDescription,
    });
  }

  /// Get all sprints for a project
  Stream<List<Sprint>> getSprints(String projectId) {
    return _sprintsRef.orderByChild('projectId').equalTo(projectId).onValue.map(
      (event) {
        if (!event.snapshot.exists || event.snapshot.value == null) return [];
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final sprints = data.entries.map((entry) {
          return Sprint.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key,
          );
        }).toList();
        // Sort by priority (lower number = higher priority), then by start date
        sprints.sort((a, b) {
          if (a.priority != b.priority) return a.priority.compareTo(b.priority);
          return a.startDate.compareTo(b.startDate);
        });
        return sprints;
      },
    );
  }

  /// Auto-update sprint status based on dates
  Future<void> checkAndUpdateSprintStatuses(String projectId) async {
    final sprints = await getSprints(projectId).first;
    final now = DateTime.now();

    for (final sprint in sprints) {
      SprintStatus? newStatus;
      if (sprint.startDate.isBefore(now) && sprint.endDate.isAfter(now)) {
        if (sprint.status != SprintStatus.inProgress) {
          newStatus = SprintStatus.inProgress;
        }
      } else if (sprint.endDate.isBefore(now)) {
        if (sprint.status != SprintStatus.completed) {
          newStatus = SprintStatus.completed;
        }
      }

      if (newStatus != null) {
        await updateSprintStatus(sprint.id, newStatus);
      }
    }
  }
}
