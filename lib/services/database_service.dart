import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/models/task_model.dart';
import 'package:untitled3/models/project_model.dart';
import 'package:untitled3/models/user_story_model.dart';
import 'package:untitled3/models/sprint_model.dart';
import 'package:untitled3/models/project_task_model.dart';

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
      'name': name, 'email': email, 'avatarUrl': '', 'workplace': '', 'zodiacSign': '', 'age': null,
    });
  }

  Future<void> updateUserData({required String name, String? workplace, String? zodiacSign, int? age}) async {
    await userRef.update({
      'name': name, 'workplace': workplace ?? '', 'zodiacSign': zodiacSign ?? '', 'age': age,
    });
  }

  Future<void> updateUserAvatar(String avatarUrl) async {
    await userRef.update({'avatarUrl': avatarUrl});
  }

  Stream<UserModel?> get userData {
    return userRef.onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null && event.snapshot.value is Map) {
        return UserModel.fromMap(Map<String, dynamic>.from(event.snapshot.value as Map), uid!);
      }
      return null;
    });
  }

  Future<List<UserModel>> getProjectMembers(List<String> memberIds) async {
    List<UserModel> members = [];
    for (String id in memberIds) {
      final snapshot = await _usersRef.child(id).get();
      if (snapshot.exists && snapshot.value != null && snapshot.value is Map) {
        members.add(UserModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map), id));
      }
    }
    return members;
  }

  // =================== PROJECT METHODS ===================

  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> createProject(String name, String description) async {
    final newProjectRef = _projectsRef.push();
    String code = _generateJoinCode();

    await newProjectRef.set({
      'name': name,
      'description': description,
      'ownerId': uid,
      'joinCode': code,
      'isLocked': false,
      'members': {
        uid!: 'PO' // Người tạo là PO
      },
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<String> joinProjectByCode(String inputCode) async {
    final snapshot = await _projectsRef.orderByChild('joinCode').equalTo(inputCode).get();

    if (!snapshot.exists) return "Project code not found!";

    Map<dynamic, dynamic> values = snapshot.value as Map;
    String projectId = values.keys.first;
    Map<String, dynamic> projectData = Map<String, dynamic>.from(values[projectId]);

    bool isLocked = projectData['isLocked'] ?? false;
    if (isLocked) return "This project is locked by PO.";

    Map<dynamic, dynamic> members = projectData['members'] ?? {};
    if (members.containsKey(uid)) return "You are already in this project!";

    // Thêm vào với vai trò Dev
    await _projectsRef.child(projectId).child('members').update({
      uid!: 'Dev'
    });

    return "Success";
  }

  Stream<List<Project>> getProjects() {
    return _projectsRef.onValue.map((event) {
      final List<Project> projects = [];
      if (!event.snapshot.exists || event.snapshot.value == null) return projects;

      try {
        final allProjects = Map<String, dynamic>.from(event.snapshot.value as Map);
        allProjects.forEach((projectId, projectData) {
          if (projectData is Map) {
            final projectMap = Map<String, dynamic>.from(projectData);
            Map<dynamic, dynamic> members = projectMap['members'] ?? {};
            // Chỉ lấy project mà mình có trong danh sách thành viên
            if (members.containsKey(uid)) {
              projects.add(Project.fromMap(projectMap, projectId));
            }
          }
        });
      } catch (e) {
        print("Error parsing projects: $e");
      }
      return projects;
    });
  }

  // =================== USER STORY (BACKLOG) ===================

  Future<void> addUserStory(String projectId, String title, String description, int points) async {
    await _storiesRef.push().set({
      'projectId': projectId,
      'title': title,
      'description': description,
      'points': points,
      'status': 'backlog',
      'createdAt': ServerValue.timestamp,
    });
  }

  Stream<List<UserStory>> getBacklog(String projectId) {
    return _storiesRef.orderByChild('projectId').equalTo(projectId).onValue.map((event) {
      final List<UserStory> stories = [];
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final allStories = Map<String, dynamic>.from(event.snapshot.value as Map);
        allStories.forEach((storyId, storyData) {
          if (storyData is Map) {
            final data = Map<String, dynamic>.from(storyData);
            if (data['status'] == 'backlog') {
              stories.add(UserStory.fromMap(data, storyId));
            }
          }
        });
      }
      return stories;
    });
  }

  // =================== SPRINT METHODS ===================

  Future<void> addSprint(String projectId, String name, DateTime startDate, DateTime endDate) async {
    await _sprintsRef.push().set({
      'projectId': projectId,
      'name': name,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'status': 'upcoming',
    });
  }

  Stream<List<Sprint>> getSprints(String projectId) {
    return _sprintsRef.orderByChild('projectId').equalTo(projectId).onValue.map((event) {
      final List<Sprint> sprints = [];
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final allSprints = Map<String, dynamic>.from(event.snapshot.value as Map);
        allSprints.forEach((sprintId, sprintData) {
          if (sprintData is Map) {
            sprints.add(Sprint.fromMap(Map<String, dynamic>.from(sprintData), sprintId));
          }
        });
      }
      return sprints;
    });
  }

  Future<void> addStoryToSprint(String projectId, String sprintId, String storyId) async {
    await _storiesRef.child(storyId).update({
      'status': 'inSprint',
      'sprintId': sprintId,
    });
  }

  Stream<List<UserStory>> getStoriesForSprint(String projectId, String sprintId) {
    return _storiesRef.orderByChild('sprintId').equalTo(sprintId).onValue.map((event) {
      final List<UserStory> stories = [];
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final allStories = Map<String, dynamic>.from(event.snapshot.value as Map);
        allStories.forEach((storyId, storyData) {
          if (storyData is Map) {
            stories.add(UserStory.fromMap(Map<String, dynamic>.from(storyData), storyId));
          }
        });
      }
      return stories;
    });
  }

  // =================== PROJECT TASK METHODS ===================

  Future<void> addProjectTask(String projectId, String sprintId, String storyId, String title) async {
    await _tasksRef.push().set({
      'projectId': projectId,
      'sprintId': sprintId,
      'storyId': storyId,
      'title': title,
      'status': 'todo',
      'assigneeId': '',
      'evidenceLink': '',
      'evidenceNotes': '',
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<void> updateProjectTaskStatus(String projectId, String sprintId, String taskId, ProjectTaskStatus newStatus) async {
    await _tasksRef.child(taskId).update({'status': newStatus.toString().split('.').last});
  }

  Future<void> submitTaskForReview(String projectId, String sprintId, String taskId, {String? evidenceLink, String? evidenceNotes}) async {
    await _tasksRef.child(taskId).update({
      'status': 'done',
      'evidenceLink': evidenceLink ?? '',
      'evidenceNotes': evidenceNotes ?? '',
    });
  }

  Future<void> updateTaskDetails(String projectId, String sprintId, String taskId, {required String assigneeId, required String evidenceLink, required String evidenceNotes}) async {
    await _tasksRef.child(taskId).update({
      'assigneeId': assigneeId,
      'evidenceLink': evidenceLink,
      'evidenceNotes': evidenceNotes,
    });
  }

  Stream<List<ProjectTask>> getTasksForSprint(String projectId, String sprintId) {
    return _tasksRef.orderByChild('sprintId').equalTo(sprintId).onValue.map((event) {
      final List<ProjectTask> tasks = [];
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final allTasks = Map<String, dynamic>.from(event.snapshot.value as Map);
        allTasks.forEach((key, value) {
          if (value is Map) {
            tasks.add(ProjectTask.fromMap(Map<String, dynamic>.from(value), key));
          }
        });
      }
      return tasks;
    });
  }

  // =================== PERSONAL TASK METHODS ===================

  Future<void> addPersonalTask(String title, int priority) async {
    await personalTasksRef.push().set({
      'title': title, 'priority': priority, 'status': 'inProgress', 'createdAt': ServerValue.timestamp,
    });
  }

  Future<void> updatePersonalTaskStatus(String taskId, TaskStatus status) async {
    await personalTasksRef.child(taskId).update({'status': status.toString().split('.').last});
  }

  Future<void> deletePersonalTask(String taskId) async {
    await personalTasksRef.child(taskId).remove();
  }

  Stream<List<Task>> get personalTasks {
    return personalTasksRef.onValue.map((event) {
      final List<Task> tasks = [];
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          if (value is Map) {
            final taskMap = Map<String, dynamic>.from(value);
            tasks.add(Task(
              id: key,
              title: taskMap['title'] ?? '',
              priority: taskMap['priority'] ?? 2,
              createdAt: DateTime.fromMillisecondsSinceEpoch(taskMap['createdAt'] ?? 0),
              status: TaskStatus.values.firstWhere(
                    (e) => e.toString().split('.').last == (taskMap['status'] ?? 'inProgress'),
                orElse: () => TaskStatus.inProgress,
              ),
            ));
          }
        });
      }
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    });
  }
}