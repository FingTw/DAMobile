
class Project {
  final String id;
  final String name;
  final String description;
  final List<String> members; // List of user UIDs
  final String ownerId; // UID of the person who created the project

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.ownerId,
  });

  // Factory constructor to create a Project from a database map
  factory Project.fromMap(Map<String, dynamic> data, String documentId) {
    return Project(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      ownerId: data['ownerId'] ?? '',
    );
  }

  // Method to convert Project to a map for writing to the database
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'members': members,
      'ownerId': ownerId,
    };
  }
}
