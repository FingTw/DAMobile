class DefinitionOfDone {
  final String id;
  final String projectId;
  final List<DoDItem> items;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DefinitionOfDone({
    required this.id,
    required this.projectId,
    required this.items,
    required this.createdAt,
    this.updatedAt,
  });

  factory DefinitionOfDone.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return DefinitionOfDone(
      id: documentId,
      projectId: data['projectId'] ?? '',
      items:
          (data['items'] as List?)
              ?.map((item) => DoDItem.fromMap(item))
              .toList() ??
          [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }
}

class DoDItem {
  final String description;
  final bool isMandatory;
  final int order;

  DoDItem({
    required this.description,
    this.isMandatory = true,
    required this.order,
  });

  factory DoDItem.fromMap(Map<String, dynamic> data) {
    return DoDItem(
      description: data['description'] ?? '',
      isMandatory: data['isMandatory'] ?? true,
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'isMandatory': isMandatory,
      'order': order,
    };
  }
}
