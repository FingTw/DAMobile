import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/project_task_model.dart';

/// Repository for fetching project tasks across all projects
class ProjectTaskRepository {
  final String uid;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  ProjectTaskRepository({required this.uid});

  DatabaseReference get _projectsRef => _database.ref('projects');

  /// Get all project tasks where the current user is assigned
  Stream<List<ProjectTask>> getUserProjectTasks() {
    return _projectsRef.onValue.asyncMap((event) async {
      final List<ProjectTask> allTasks = [];
      
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return allTasks;
      }

      try {
        final allProjects = Map<String, dynamic>.from(
          event.snapshot.value as Map,
        );

        // For each project where user is a member
        for (final entry in allProjects.entries) {
          final projectId = entry.key;
          final projectData = entry.value;

          if (projectData is Map) {
            final projectMap = Map<String, dynamic>.from(projectData);
            final members = projectMap['members'] ?? {};
            
            // Check if user is a member of this project
            if (members.containsKey(uid)) {
              // Fetch user stories for this project
              final storiesSnapshot = await _database
                  .ref('projects/$projectId/userStories')
                  .get();

              if (storiesSnapshot.exists && storiesSnapshot.value != null) {
                final stories = Map<String, dynamic>.from(
                  storiesSnapshot.value as Map,
                );

                // For each user story, fetch its tasks
                for (final storyEntry in stories.entries) {
                  final storyId = storyEntry.key;
                  
                  final tasksSnapshot = await _database
                      .ref('projects/$projectId/userStories/$storyId/tasks')
                      .get();

                  if (tasksSnapshot.exists && tasksSnapshot.value != null) {
                    final tasks = Map<String, dynamic>.from(
                      tasksSnapshot.value as Map,
                    );

                    // Add tasks where user is assigned
                    for (final taskEntry in tasks.entries) {
                      final taskId = taskEntry.key;
                      final taskData = Map<String, dynamic>.from(taskEntry.value);
                      
                      if (taskData['assigneeId'] == uid) {
                        allTasks.add(ProjectTask.fromMap(taskData, taskId));
                      }
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching project tasks: $e");
      }

      return allTasks;
    });
  }

  /// Get project tasks statistics for a specific project
  Future<Map<String, int>> getProjectTaskStats(String projectId) async {
    int totalTasks = 0;
    int completedTasks = 0;
    int overdueTasks = 0;

    try {
      final storiesSnapshot = await _database
          .ref('projects/$projectId/userStories')
          .get();

      if (storiesSnapshot.exists && storiesSnapshot.value != null) {
        final stories = Map<String, dynamic>.from(
          storiesSnapshot.value as Map,
        );

        for (final storyEntry in stories.entries) {
          final storyId = storyEntry.key;
          
          final tasksSnapshot = await _database
              .ref('projects/$projectId/userStories/$storyId/tasks')
              .get();

          if (tasksSnapshot.exists && tasksSnapshot.value != null) {
            final tasks = Map<String, dynamic>.from(
              tasksSnapshot.value as Map,
            );

            for (final taskEntry in tasks.entries) {
              final taskData = Map<String, dynamic>.from(taskEntry.value);
              totalTasks++;

              final status = taskData['status'] ?? 'todo';
              if (status == 'done' || status == 'verified') {
                completedTasks++;
              }

              final dueDate = taskData['dueDate'];
              if (dueDate != null) {
                final due = DateTime.fromMillisecondsSinceEpoch(dueDate);
                if (due.isBefore(DateTime.now()) && 
                    status != 'done' && 
                    status != 'verified') {
                  overdueTasks++;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching project task stats: $e");
    }

    return {
      'total': totalTasks,
      'completed': completedTasks,
      'overdue': overdueTasks,
    };
  }
}
