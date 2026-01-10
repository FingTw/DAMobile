import 'package:flutter_test/flutter_test.dart';
import 'package:untitled3/models/task_model.dart';
import 'package:untitled3/models/project_task_model.dart';
import 'package:untitled3/models/sprint_model.dart';
import 'package:untitled3/models/user_story_model.dart';

void main() {
  group('Task Model Tests', () {
    test('Task should be created with correct values', () {
      final task = Task(
        id: 'test-id',
        title: 'Test Task',
        priority: 1,
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(Duration(days: 1)),
      );

      expect(task.id, 'test-id');
      expect(task.title, 'Test Task');
      expect(task.priority, 1);
      expect(task.status, TaskStatus.todo);
      expect(task.dueDate, isNotNull);
    });

    test('Task.fromMap should parse correctly', () {
      final now = DateTime.now();
      final data = {
        'title': 'Test Task',
        'status': 'todo',
        'priority': 2,
        'createdAt': now.millisecondsSinceEpoch,
        'dueDate': now.add(Duration(days: 1)).millisecondsSinceEpoch,
        'assigneeId': 'user-123',
        'evidenceLink': 'https://example.com/image.jpg',
      };

      final task = Task.fromMap(data, 'test-id');

      expect(task.id, 'test-id');
      expect(task.title, 'Test Task');
      expect(task.status, TaskStatus.todo);
      expect(task.priority, 2);
      expect(task.assigneeId, 'user-123');
      expect(task.evidenceLink, 'https://example.com/image.jpg');
    });
  });

  group('ProjectTask Model Tests', () {
    test('ProjectTask should be created with correct values', () {
      final task = ProjectTask(
        id: 'task-1',
        title: 'Project Task',
        storyId: 'story-1',
        assigneeId: 'user-1',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(Duration(days: 2)),
      );

      expect(task.id, 'task-1');
      expect(task.title, 'Project Task');
      expect(task.storyId, 'story-1');
      expect(task.assigneeId, 'user-1');
      expect(task.status, ProjectTaskStatus.todo);
    });

    test('ProjectTask.fromMap should parse correctly', () {
      final now = DateTime.now();
      final data = {
        'title': 'Project Task',
        'storyId': 'story-1',
        'assigneeId': 'user-1',
        'status': 'inProgress',
        'evidenceLink': 'https://example.com/evidence.jpg',
        'evidenceNotes': 'Test notes',
        'createdAt': now.millisecondsSinceEpoch,
        'dueDate': now.add(Duration(days: 2)).millisecondsSinceEpoch,
      };

      final task = ProjectTask.fromMap(data, 'task-1');

      expect(task.id, 'task-1');
      expect(task.title, 'Project Task');
      expect(task.status, ProjectTaskStatus.inProgress);
      expect(task.evidenceLink, 'https://example.com/evidence.jpg');
      expect(task.evidenceNotes, 'Test notes');
    });
  });

  group('Sprint Model Tests', () {
    test('Sprint should be created with correct values', () {
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: 14));
      final sprint = Sprint(
        id: 'sprint-1',
        projectId: 'project-1',
        name: 'Sprint 1',
        startDate: startDate,
        endDate: endDate,
        priority: 1,
      );

      expect(sprint.id, 'sprint-1');
      expect(sprint.name, 'Sprint 1');
      expect(sprint.projectId, 'project-1');
      expect(sprint.priority, 1);
      expect(sprint.status, SprintStatus.upcoming);
    });

    test('Sprint.isActive should return correct value', () {
      final now = DateTime.now();
      final pastSprint = Sprint(
        id: 'sprint-1',
        name: 'Past Sprint',
        startDate: now.subtract(Duration(days: 20)),
        endDate: now.subtract(Duration(days: 10)),
        status: SprintStatus.completed,
      );

      final activeSprint = Sprint(
        id: 'sprint-2',
        name: 'Active Sprint',
        startDate: now.subtract(Duration(days: 5)),
        endDate: now.add(Duration(days: 9)),
        status: SprintStatus.inProgress,
      );

      expect(pastSprint.isActive, false);
      expect(activeSprint.isActive, true);
    });
  });

  group('UserStory Model Tests', () {
    test('UserStory should be created with correct values', () {
      final story = UserStory(
        id: 'story-1',
        projectId: 'project-1',
        title: 'User Story 1',
        description: 'Test description',
        points: 5,
      );

      expect(story.id, 'story-1');
      expect(story.title, 'User Story 1');
      expect(story.points, 5);
      expect(story.status, UserStoryStatus.backlog);
    });

    test('UserStory.fromMap should parse correctly', () {
      final data = {
        'projectId': 'project-1',
        'sprintId': 'sprint-1',
        'title': 'User Story',
        'description': 'Description',
        'points': 8,
        'status': 'inSprint',
      };

      final story = UserStory.fromMap(data, 'story-1');

      expect(story.id, 'story-1');
      expect(story.projectId, 'project-1');
      expect(story.sprintId, 'sprint-1');
      expect(story.points, 8);
      expect(story.status, UserStoryStatus.inSprint);
    });
  });
}
