
enum UserStoryStatus { backlog, inSprint, done }

class UserStory {
  final String id;
  final String title;
  final String description;
  final int points; // Story points for estimation
  final UserStoryStatus status;

  UserStory({
    required this.id,
    required this.title,
    this.description = '',
    this.points = 0,
    this.status = UserStoryStatus.backlog,
  });

  factory UserStory.fromMap(Map<String, dynamic> data, String documentId) {
    return UserStory(
      id: documentId,
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
      'title': title,
      'description': description,
      'points': points,
      'status': status.toString().split('.').last,
    };
  }
}
