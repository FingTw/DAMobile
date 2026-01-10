import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/project_model.dart';

/// Repository for project-related database operations
/// Extracted from DatabaseService to follow Repository Pattern
class ProjectRepository {
  final String? uid;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  ProjectRepository({this.uid});

  // Database references
  DatabaseReference get _projectsRef => _database.ref('projects');

  /// Generate a random 6-character join code for projects
  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  /// Create a new project
  Future<void> createProject(
    String name,
    String description,
    int maxMembers,
    DateTime? deadline,
  ) async {
    if (uid == null) {
      throw Exception('User ID is required to create a project');
    }
    final newProjectRef = _projectsRef.push();
    String code = _generateJoinCode();

    await newProjectRef.set({
      'name': name,
      'description': description,
      'ownerId': uid,
      'joinCode': code,
      'isLocked': false,
      'maxMembers': maxMembers,
      'members': {
        uid!: 'PO', // Creator is the PO
      },
      'createdAt': ServerValue.timestamp,
      'deadline': deadline?.millisecondsSinceEpoch,
    });
  }

  /// Join a project using a join code
  /// Returns "Success" on success, or an error message on failure
  Future<String> joinProjectByCode(String inputCode) async {
    if (uid == null) {
      return "User ID is required to join a project";
    }
    final snapshot = await _projectsRef
        .orderByChild('joinCode')
        .equalTo(inputCode)
        .get();

    if (!snapshot.exists) return "Project code not found!";

    Map<dynamic, dynamic> values = snapshot.value as Map;
    String projectId = values.keys.first;
    Map<String, dynamic> projectData = Map<String, dynamic>.from(
      values[projectId],
    );

    bool isLocked = projectData['isLocked'] ?? false;
    if (isLocked) return "This project is locked by PO.";

    Map<dynamic, dynamic> members = projectData['members'] ?? {};
    if (members.containsKey(uid)) return "You are already in this project!";

    int maxMembers = projectData['maxMembers'] ?? 10;
    if (members.length >= maxMembers) {
      return "Project is FULL (Max: $maxMembers members).";
    }

    await _projectsRef.child(projectId).child('members').update({uid!: 'Dev'});

    return "Success";
  }

  /// Get all projects that the current user is a member of
  Stream<List<Project>> getProjects() {
    if (uid == null) {
      return Stream.value([]);
    }
    return _projectsRef.onValue.map((event) {
      final List<Project> projects = [];
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return projects;
      }

      try {
        final allProjects = Map<String, dynamic>.from(
          event.snapshot.value as Map,
        );
        allProjects.forEach((projectId, projectData) {
          if (projectData is Map) {
            final projectMap = Map<String, dynamic>.from(projectData);
            Map<dynamic, dynamic> members = projectMap['members'] ?? {};
            if (members.containsKey(uid)) {
              projects.add(Project.fromMap(projectMap, projectId));
            }
          }
        });
      } catch (e) {
        debugPrint("Error parsing projects: $e");
      }
      return projects;
    });
  }

  /// Get a specific project by ID
  Future<Project?> getProjectById(String projectId) async {
    final snapshot = await _projectsRef.child(projectId).get();
    if (snapshot.exists && snapshot.value != null && snapshot.value is Map) {
      return Project.fromMap(
        Map<String, dynamic>.from(snapshot.value as Map),
        projectId,
      );
    }
    return null;
  }

  /// Remove a member from a project
  Future<void> removeMember(String projectId, String memberId) async {
    await _projectsRef
        .child(projectId)
        .child('members')
        .child(memberId)
        .remove();
  }

  /// Update a member's role in a project
  Future<void> updateMemberRole(
    String projectId,
    String memberId,
    String newRole,
  ) async {
    await _projectsRef.child(projectId).child('members').update({
      memberId: newRole,
    });
  }

  /// Toggle project lock status (locked projects cannot be joined)
  Future<void> toggleProjectLock(String projectId, bool isLocked) async {
    await _projectsRef.child(projectId).update({'isLocked': isLocked});
  }

  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    await _projectsRef.child(projectId).remove();
  }
}
