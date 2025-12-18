import 'package:firebase_database/firebase_database.dart';

class ProjectModel {
  String id;
  String name;
  String description;
  DateTime startDate;
  DateTime? endDate;
  String managerId; // Thêm lại trường này
  List<String> memberIds; // Thêm lại trường này

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.managerId,
    required this.memberIds,
  });

  factory ProjectModel.fromSnapshot(DataSnapshot snapshot) {
    // Ép kiểu dữ liệu an toàn
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    // Xử lý danh sách thành viên (Realtime DB có thể trả về List hoặc Map)
    List<String> members = [];
    if (data['member_ids'] != null) {
      if (data['member_ids'] is List) {
        members = List<String>.from(data['member_ids']);
      } else if (data['member_ids'] is Map) {
        members = List<String>.from((data['member_ids'] as Map).values);
      }
    }

    return ProjectModel(
      id: snapshot.key!,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(data['start_date']),
      endDate: data['end_date'] != null ? DateTime.fromMillisecondsSinceEpoch(data['end_date']) : null,
      managerId: data['manager_id'] ?? 'TEST_MANAGER',
      memberIds: members,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'manager_id': managerId,
      'member_ids': memberIds,
    };
  }
}