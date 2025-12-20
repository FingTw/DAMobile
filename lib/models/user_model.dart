
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String avatarUrl;
  final String workplace;
  final String zodiacSign;
  final int? age;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.workplace = '',
    this.zodiacSign = '',
    this.age,
  });

  // Factory constructor to create a UserModel from a database map
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      workplace: data['workplace'] ?? '',
      zodiacSign: data['zodiacSign'] ?? '',
      age: data['age'] as int?,
    );
  }

  // Method to convert UserModel to a map for writing to the database
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'workplace': workplace,
      'zodiacSign': zodiacSign,
      'age': age,
    };
  }
}
