import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/user_story_model.dart';

/// Repository for user story-related database operations
/// Extracted from DatabaseService to follow Repository Pattern
class UserStoryRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference get _storiesRef => _database.ref('stories');

  /// Add a new user story to the backlog
  Future<void> addUserStory(
    String projectId,
    String title,
    String description,
    int points,
  ) async {
    final ref = _storiesRef.push();
    await ref.set({
      'projectId': projectId,
      'sprintId': '',
      'title': title,
      'description': description,
      'points': points,
      'status': UserStoryStatus.backlog.toString().split('.').last,
    });
  }

  /// Add a story to a sprint
  Future<void> addStoryToSprint(
    String projectId,
    String sprintId,
    String storyId,
  ) async {
    await _storiesRef.child(storyId).update({
      'projectId': projectId,
      'sprintId': sprintId,
      'status': UserStoryStatus.inSprint.toString().split('.').last,
    });
  }

  /// Get all stories for a specific sprint
  Stream<List<UserStory>> getStoriesForSprint(
    String projectId,
    String sprintId,
  ) {
    return _storiesRef.orderByChild('sprintId').equalTo(sprintId).onValue.map((
      event,
    ) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries
          .map(
            (e) => UserStory.fromMap(
              Map<String, dynamic>.from(e.value as Map),
              e.key,
            ),
          )
          .where(
            (story) => story.projectId.isEmpty || story.projectId == projectId,
          )
          .toList();
    });
  }

  /// Get product backlog for a project
  Stream<List<UserStory>> getBacklog(String projectId) {
    return _storiesRef.orderByChild('projectId').equalTo(projectId).onValue.map(
      (event) {
        if (!event.snapshot.exists || event.snapshot.value == null) return [];
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return data.entries
            .map(
              (e) => UserStory.fromMap(
                Map<String, dynamic>.from(e.value as Map),
                e.key,
              ),
            )
            .where(
              (story) =>
                  story.status == UserStoryStatus.backlog ||
                  story.status == UserStoryStatus.inSprint,
            )
            .toList();
      },
    );
  }

  /// Update user story details
  Future<void> updateUserStory(
    String projectId,
    String storyId, {
    String? title,
    String? description,
    int? points,
    UserStoryStatus? status,
  }) async {
    final Map<String, dynamic> updates = {};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (points != null) updates['points'] = points;
    if (status != null) updates['status'] = status.toString().split('.').last;

    if (updates.isNotEmpty) {
      await _storiesRef.child(storyId).update(updates);
    }
  }
}
