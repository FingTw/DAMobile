import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/user_model.dart';

/// Repository for user-related database operations
/// Extracted from DatabaseService to follow Repository Pattern
class UserRepository {
  final String? uid;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  UserRepository({this.uid});

  // Database references
  DatabaseReference get _usersRef => _database.ref('users');
  DatabaseReference? get userRef => uid != null ? _usersRef.child(uid!) : null;

  /// Create a new user in the database
  Future<void> createNewUser(String name, String email) async {
    if (uid == null || userRef == null) {
      throw Exception('User ID is required to create a new user');
    }
    await userRef!.set({
      'name': name,
      'email': email,
      'avatarUrl': '',
      'workplace': '',
      'zodiacSign': '',
      'age': null,
    });
  }

  /// Update user profile data
  Future<void> updateUserData({
    required String name,
    String? workplace,
    String? zodiacSign,
    int? age,
  }) async {
    if (uid == null || userRef == null) {
      throw Exception('User ID is required to update user data');
    }
    await userRef!.update({
      'name': name,
      'workplace': workplace ?? '',
      'zodiacSign': zodiacSign ?? '',
      'age': age,
    });
  }

  /// Update user avatar URL
  Future<void> updateUserAvatar(String avatarUrl) async {
    if (uid == null || userRef == null) {
      throw Exception('User ID is required to update avatar');
    }
    await userRef!.update({'avatarUrl': avatarUrl});
  }

  /// Stream of current user data
  Stream<UserModel?> get userData {
    if (uid == null || userRef == null) {
      return Stream.value(null);
    }
    return userRef!.onValue.map((event) {
      if (event.snapshot.exists &&
          event.snapshot.value != null &&
          event.snapshot.value is Map) {
        return UserModel.fromMap(
          Map<String, dynamic>.from(event.snapshot.value as Map),
          uid!,
        );
      }
      return null;
    });
  }

  /// Get multiple users by their IDs (for project members)
  Future<List<UserModel>> getProjectMembers(List<String> memberIds) async {
    List<UserModel> members = [];
    for (String id in memberIds) {
      final snapshot = await _usersRef.child(id).get();
      if (snapshot.exists && snapshot.value != null && snapshot.value is Map) {
        members.add(
          UserModel.fromMap(
            Map<String, dynamic>.from(snapshot.value as Map),
            id,
          ),
        );
      }
    }
    return members;
  }
}
