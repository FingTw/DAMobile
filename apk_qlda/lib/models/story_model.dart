import 'package:firebase_database/firebase_database.dart';

class StoryModel {
  String id;
  String projectId;
  String title;
  String description;
  int storyPoints;
  int priority;

  StoryModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.storyPoints,
    required this.priority,
  });

  factory StoryModel.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return StoryModel(
      id: snapshot.key!,
      projectId: data['project_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      storyPoints: data['story_points'] ?? 0,
      priority: data['priority'] ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'title': title,
      'description': description,
      'story_points': storyPoints,
      'priority': priority,
    };
  }
}