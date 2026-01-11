enum RetroCategory { wentWell, needsImprovement, actionItem }

class Retrospective {
  final String id;
  final String sprintId;
  final String projectId;
  final DateTime date;
  final List<RetroItem> items;
  final List<ActionItem> actionItems;

  Retrospective({
    required this.id,
    required this.sprintId,
    required this.projectId,
    required this.date,
    required this.items,
    required this.actionItems,
  });

  factory Retrospective.fromMap(Map<String, dynamic> data, String documentId) {
    return Retrospective(
      id: documentId,
      sprintId: data['sprintId'] ?? '',
      projectId: data['projectId'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? 0),
      items:
          (data['items'] as List?)
              ?.asMap()
              .entries
              .map(
                (entry) => RetroItem.fromMap(
                  Map<String, dynamic>.from(entry.value),
                  'item_${entry.key}',
                ),
              )
              .toList() ??
          [],
      actionItems:
          (data['actionItems'] as List?)
              ?.asMap()
              .entries
              .map(
                (entry) => ActionItem.fromMap(
                  Map<String, dynamic>.from(entry.value),
                  'action_${entry.key}',
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sprintId': sprintId,
      'projectId': projectId,
      'date': date.millisecondsSinceEpoch,
      'items': items.map((item) => item.toMap()).toList(),
      'actionItems': actionItems.map((item) => item.toMap()).toList(),
    };
  }
}

class RetroItem {
  final String id;
  final String description;
  final String authorId;
  final String authorName;
  final RetroCategory category;
  final int votes;
  final List<String> votedBy;
  final DateTime createdAt;

  RetroItem({
    required this.id,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.category,
    this.votes = 0,
    this.votedBy = const [],
    required this.createdAt,
  });

  factory RetroItem.fromMap(Map<String, dynamic> data, String documentId) {
    return RetroItem(
      id: documentId,
      description: data['description'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      category: RetroCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'],
        orElse: () => RetroCategory.needsImprovement,
      ),
      votes: data['votes'] ?? 0,
      votedBy: List<String>.from(data['votedBy'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'category': category.toString().split('.').last,
      'votes': votes,
      'votedBy': votedBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

class ActionItem {
  final String id;
  final String description;
  final String assigneeId;
  final String assigneeName;
  final bool completed;
  final DateTime? completedAt;
  final DateTime createdAt;

  ActionItem({
    required this.id,
    required this.description,
    required this.assigneeId,
    required this.assigneeName,
    this.completed = false,
    this.completedAt,
    required this.createdAt,
  });

  factory ActionItem.fromMap(Map<String, dynamic> data, String documentId) {
    return ActionItem(
      id: documentId,
      description: data['description'] ?? '',
      assigneeId: data['assigneeId'] ?? '',
      assigneeName: data['assigneeName'] ?? '',
      completed: data['completed'] ?? false,
      completedAt: data['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['completedAt'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'completed': completed,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
