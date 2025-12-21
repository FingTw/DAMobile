class Project {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String joinCode;
  final bool isLocked;
  final int maxMembers; // MỚI: Giới hạn số lượng
  final Map<String, String> members;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.joinCode,
    required this.isLocked,
    required this.maxMembers,
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
      maxMembers: data['maxMembers'] ?? 10, // Mặc định 10 người nếu không có
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
      'maxMembers': maxMembers,
      'members': members,
    };
  }
}