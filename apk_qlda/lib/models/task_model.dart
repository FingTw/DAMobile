import 'package:firebase_database/firebase_database.dart';

class TaskModel {
  String id;
  String projectId;
  String sprintId;
  String title;
  String content;
  int status; // 1: Todo, 2: Doing, 3: Wait, 4: Done
  String? proofImage;
  String? proofGitLink;
  DateTime createdAt;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.sprintId,
    required this.title,
    required this.content,
    required this.status,
    this.proofImage,
    this.proofGitLink,
    required this.createdAt,
  });

  factory TaskModel.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return TaskModel(
      id: snapshot.key!,
      projectId: data['project_id'] ?? '',
      sprintId: data['sprint_id'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      status: data['status'] ?? 1,
      proofImage: data['proof_image'],
      proofGitLink: data['proof_git_link'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'sprint_id': sprintId,
      'title': title,
      'content': content,
      'status': status,
      'proof_image': proofImage,
      'proof_git_link': proofGitLink,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}