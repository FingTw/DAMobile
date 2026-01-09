enum UserStoryStatus { backlog, inSprint, todo, inProgress, review, done }

class UserStory {
  final String id;
  final String projectId;
  final String sprintId;
  final String title;
  final String description;
  final int points; // Story points for estimation
  final UserStoryStatus status;

  UserStory({
    required this.id,
    this.projectId = '',
    this.sprintId = '',
    required this.title,
    this.description = '',
    this.points = 0,
    this.status = UserStoryStatus.backlog,
  });

  factory UserStory.fromMap(Map<String, dynamic> data, String documentId) {
    return UserStory(
      id: documentId,
      projectId: data['projectId'] ?? '',
      sprintId: data['sprintId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      points: data['points'] ?? 0,
      status: UserStoryStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => UserStoryStatus.backlog,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'sprintId': sprintId,
      'title': title,
      'description': description,
      'points': points,
      'status': status.toString().split('.').last,
    };
  }
}
