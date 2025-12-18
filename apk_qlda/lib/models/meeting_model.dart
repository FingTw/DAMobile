import 'package:firebase_database/firebase_database.dart';

class MeetingModel {
  String id;
  String sprintId;
  String type; // 'Daily' hoặc 'Review'
  String content;
  List<String> imageUrls;
  DateTime date;

  MeetingModel({
    required this.id,
    required this.sprintId,
    required this.type,
    required this.content,
    required this.imageUrls,
    required this.date,
  });

  factory MeetingModel.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    // Xử lý danh sách ảnh (nếu có)
    List<String> images = [];
    if (data['image_urls'] != null) {
      // Realtime DB có thể trả về List hoặc Map tùy vào key
      if (data['image_urls'] is List) {
        images = List<String>.from(data['image_urls']);
      } else if (data['image_urls'] is Map) {
        images = List<String>.from((data['image_urls'] as Map).values);
      }
    }

    return MeetingModel(
      id: snapshot.key!,
      sprintId: data['sprint_id'] ?? '',
      type: data['type'] ?? 'Daily',
      content: data['content'] ?? '',
      imageUrls: images,
      date: DateTime.fromMillisecondsSinceEpoch(data['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sprint_id': sprintId,
      'type': type,
      'content': content,
      'image_urls': imageUrls,
      'date': date.millisecondsSinceEpoch,
    };
  }
}