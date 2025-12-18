import 'package:firebase_database/firebase_database.dart';

class SprintModel {
  String id;
  String projectId;
  String name;
  DateTime startDate;
  DateTime endDate;
  bool isCompleted;

  SprintModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
  });

  factory SprintModel.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return SprintModel(
      id: snapshot.key!,
      projectId: data['project_id'] ?? '',
      name: data['name'] ?? '',
      // Chuyển đổi số (milliseconds) thành Ngày tháng
      startDate: DateTime.fromMillisecondsSinceEpoch(data['start_date']),
      endDate: DateTime.fromMillisecondsSinceEpoch(data['end_date']),
      isCompleted: data['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'name': name,
      // Chuyển Ngày tháng thành số để lưu
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate.millisecondsSinceEpoch,
      'is_completed': isCompleted,
    };
  }
}