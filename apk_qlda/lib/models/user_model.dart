import 'package:firebase_database/firebase_database.dart';

class UserModel {
  String id;
  String email;
  String name;
  String role; // 'Manager' hoặc 'Member'
  String? avatarUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  factory UserModel.fromSnapshot(DataSnapshot snapshot) {
    // Ép kiểu dữ liệu từ Realtime DB
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    return UserModel(
      id: snapshot.key!,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Unknown',
      role: data['role'] ?? 'Member',
      avatarUrl: data['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'avatar_url': avatarUrl,
    };
  }
}