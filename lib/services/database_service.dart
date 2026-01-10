import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/project_model.dart';
import 'package:untitled3/models/project_task_model.dart';
import 'package:untitled3/models/sprint_model.dart';
import 'package:untitled3/models/task_model.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/models/user_story_model.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // --- REFERENCES (CẤU TRÚC PHẲNG) ---
  DatabaseReference get _usersRef => _database.ref('users');
  DatabaseReference get _projectsRef => _database.ref('projects');
  DatabaseReference get _sprintsRef => _database.ref('sprints');
  DatabaseReference get _tasksRef => _database.ref('tasks');
  DatabaseReference get _storiesRef => _database.ref('stories');

  DatabaseReference get userRef => _usersRef.child(uid!);
  DatabaseReference get personalTasksRef => userRef.child('personal_tasks');

  // =================== USER METHODS ===================

  Future<void> createNewUser(String name, String email) async {
    await userRef.set({
      'name': name,
      'email': email,
      'avatarUrl': '',
      'workplace': '',
      'zodiacSign': '',
      'age': null,
    });
  }

  Future<void> updateUserData({
    required String name,
    String? workplace,
    String? zodiacSign,
    int? age,
  }) async {
    await userRef.update({
      'name': name,
      'workplace': workplace ?? '',
      'zodiacSign': zodiacSign ?? '',
      'age': age,
    });
  }

  Future<void> updateUserAvatar(String avatarUrl) async {
    await userRef.update({'avatarUrl': avatarUrl});
  }

  Stream<UserModel?> get userData {
    return userRef.onValue.map((event) {
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

  // =================== PROJECT METHODS ===================

  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> createProject(
    String name,
    String description,
    int maxMembers,
    DateTime? deadline,
  ) async {
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

  Future<String> joinProjectByCode(String inputCode) async {
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

  Stream<List<Project>> getProjects() {
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

  Future<void> removeMember(String projectId, String memberId) async {
    await _projectsRef
        .child(projectId)
        .child('members')
        .child(memberId)
        .remove();
  }

  Future<void> updateMemberRole(
    String projectId,
    String memberId,
    String newRole,
  ) async {
    await _projectsRef.child(projectId).child('members').update({
      memberId: newRole,
    });
  }

  Future<void> toggleProjectLock(String projectId, bool isLocked) async {
    await _projectsRef.child(projectId).update({'isLocked': isLocked});
  }

  Future<void> deleteProject(String projectId) async {
    await _projectsRef.child(projectId).remove();
  }

  // =================== PERSONAL TASKS ===================

  Stream<List<Task>> get personalTasks {
    return personalTasksRef.onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final Map<dynamic, dynamic> data =
          Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      return data.entries.map((entry) {
        final value = Map<String, dynamic>.from(entry.value as Map);
        return Task(
          id: entry.key,
          title: value['title'] ?? '',
          status: TaskStatus.values.firstWhere(
            (e) => e.toString().split('.').last == value['status'],
            orElse: () => TaskStatus.todo,
          ),
          priority: value['priority'] ?? 1,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            value['createdAt'] ?? 0,

          ),

        );
      }).toList();
    });
  }

  Future<void> addPersonalTask(String title, int priority, DateTime? dueDate) async { // Thêm tham số dueDate
    final ref = personalTasksRef.push();
    await ref.set({
      'title': title,
      'priority': priority,
      'status': TaskStatus.todo.toString().split('.').last,
      'createdAt': ServerValue.timestamp,
      'dueDate': dueDate?.millisecondsSinceEpoch, // Lưu ngày hết hạn
      'isReminded': false, // Cờ đánh dấu đã nhắc
    });
  }

  Future<void> updatePersonalTaskStatus(
    String taskId,
    TaskStatus status,
  ) async {
    await personalTasksRef
        .child(taskId)
        .update({'status': status.toString().split('.').last});
  }

  Future<void> deletePersonalTask(String taskId) async {
    await personalTasksRef.child(taskId).remove();
  }

  // =================== SPRINTS & STORIES ===================

  Future<void> addSprint(
    String projectId,
    String name,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final ref = _sprintsRef.push();
    await ref.set({
      'projectId': projectId,
      'name': name,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'status': SprintStatus.upcoming.toString().split('.').last,
    });
  }

  Stream<List<Sprint>> getSprints(String projectId) {
    return _sprintsRef
        .orderByChild('projectId')
        .equalTo(projectId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries.map((entry) {
        return Sprint.fromMap(
          Map<String, dynamic>.from(entry.value as Map),
          entry.key,
        );
      }).toList();
    });
  }

  Future<void> addUserStory(
    String projectId,
    String title,
    String description,
    int points,
  ) async {
    final ref = _storiesRef.push();
    await ref.set({
      'projectId': projectId,
      'sprintId': '',
      'title': title,
      'description': description,
      'points': points,
      'status': UserStoryStatus.backlog.toString().split('.').last,
    });
  }

  Future<void> addStoryToSprint(
    String projectId,
    String sprintId,
    String storyId,
  ) async {
    await _storiesRef.child(storyId).update({
      'projectId': projectId,
      'sprintId': sprintId,
      'status': UserStoryStatus.inSprint.toString().split('.').last,
    });
  }

  Stream<List<UserStory>> getStoriesForSprint(
    String projectId,
    String sprintId,
  ) {
    return _storiesRef
        .orderByChild('sprintId')
        .equalTo(sprintId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries
          .map(
            (e) => UserStory.fromMap(
              Map<String, dynamic>.from(e.value as Map),
              e.key,
            ),
          )
          .where((story) =>
              story.projectId.isEmpty || story.projectId == projectId)
          .toList();
    });
  }

  Stream<List<UserStory>> getBacklog(String projectId) {
    return _storiesRef
        .orderByChild('projectId')
        .equalTo(projectId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries
          .map(
            (e) => UserStory.fromMap(
              Map<String, dynamic>.from(e.value as Map),
              e.key,
            ),
          )
          .where((story) =>
              story.status == UserStoryStatus.backlog ||
              story.status == UserStoryStatus.inSprint)
          .toList();
    });
  }

  Future<void> updateUserStory(
    String projectId,
    String storyId, {
    String? title,
    String? description,
    int? points,
    UserStoryStatus? status,
  }) async {
    final Map<String, dynamic> updates = {};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (points != null) updates['points'] = points;
    if (status != null) updates['status'] = status.toString().split('.').last;

    if (updates.isNotEmpty) {
      await _storiesRef.child(storyId).update(updates);
    }
  }

  // =================== PROJECT TASKS (DỰNG TỐI THIỂU) ===================

  Future<void> addProjectTask(
    String projectId,
    String sprintId,
    String storyId,
    String title, DateTime? dueDate,
  ) async {
    final ref = _tasksRef.push();
    await ref.set({
      'projectId': projectId,
      'sprintId': sprintId,
      'storyId': storyId,
      'title': title,
      'assigneeId': '',
      'evidenceLink': '',
      'evidenceNotes': '',
      'status': ProjectTaskStatus.todo.toString().split('.').last,
      'createdAt': ServerValue.timestamp,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'isReminded': false,
    });
  }

  Stream<List<ProjectTask>> getProjectTasks(String sprintId) {
    return _tasksRef
        .orderByChild('sprintId')
        .equalTo(sprintId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries
          .map(
            (e) => ProjectTask.fromMap(
              Map<String, dynamic>.from(e.value as Map),
              e.key,
            ),
          )
          .toList();
    });
  }
}
