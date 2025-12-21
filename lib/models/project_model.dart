class Project {
  final String id;
  final String name;
  final String description;
  final String ownerId; // UID người tạo

  // --- CÁC TRƯỜNG MỚI ---
  final String joinCode;        // Mã tham gia (VD: A2B9X)
  final bool isLocked;          // Trạng thái khóa
  final Map<String, String> members; // Lưu dạng: {"uid": "Role"}

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.joinCode,
    required this.isLocked,
    required this.members,
  });

  factory Project.fromMap(Map<String, dynamic> data, String documentId) {
    Map<String, String> membersMap = {};
    if (data['members'] != null) {
      if (data['members'] is Map) {
        (data['members'] as Map).forEach((key, value) {
          membersMap[key.toString()] = value.toString();
        });
      } else if (data['members'] is List) {
        // Fallback cho dữ liệu cũ (nếu có)
        for (var id in (data['members'] as List)) {
          membersMap[id.toString()] = 'Dev';
        }
      }
    }

    return Project(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      joinCode: data['joinCode'] ?? '',
      isLocked: data['isLocked'] ?? false,
      members: membersMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'joinCode': joinCode,
      'isLocked': isLocked,
      'members': members,
    };
  }
}