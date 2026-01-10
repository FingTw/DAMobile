import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/retrospective_model.dart';

/// Repository for retrospective-related database operations
/// Extracted from DatabaseService to follow Repository Pattern
class RetrospectiveRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference get _retroItemsRef => _database.ref('retro_items');
  DatabaseReference get _actionItemsRef => _database.ref('action_items');

  // =================== RETRO ITEMS ===================

  /// Add a new retrospective item
  Future<void> addRetroItem(
    String sprintId,
    String description,
    String authorId,
    String authorName,
    RetroCategory category,
  ) async {
    final ref = _retroItemsRef.push();
    await ref.set({
      'sprintId': sprintId,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'category': category.toString().split('.').last,
      'votes': 0,
      'votedBy': [],
      'createdAt': ServerValue.timestamp,
    });
  }

  /// Get retrospective items for a sprint by category
  Stream<List<RetroItem>> getRetroItems(
    String sprintId,
    RetroCategory category,
  ) {
    return _retroItemsRef
        .orderByChild('sprintId')
        .equalTo(sprintId)
        .onValue
        .map((event) {
          if (!event.snapshot.exists || event.snapshot.value == null) return [];
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          return data.entries
              .map(
                (e) => RetroItem.fromMap(
                  Map<String, dynamic>.from(e.value),
                  e.key,
                ),
              )
              .where((item) => item.category == category)
              .toList();
        });
  }

  /// Vote or unvote a retrospective item
  Future<void> voteRetroItem(String itemId, String userId) async {
    final snapshot = await _retroItemsRef.child(itemId).get();
    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      List<String> votedBy = List<String>.from(data['votedBy'] ?? []);

      if (votedBy.contains(userId)) {
        votedBy.remove(userId);
      } else {
        votedBy.add(userId);
      }

      await _retroItemsRef.child(itemId).update({
        'votes': votedBy.length,
        'votedBy': votedBy,
      });
    }
  }

  // =================== ACTION ITEMS ===================

  /// Add a new action item
  Future<void> addActionItem(
    String sprintId,
    String description,
    String assigneeId,
    String assigneeName,
  ) async {
    final ref = _actionItemsRef.push();
    await ref.set({
      'sprintId': sprintId,
      'description': description,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'completed': false,
      'createdAt': ServerValue.timestamp,
    });
  }

  /// Get all action items for a sprint
  Stream<List<ActionItem>> getActionItems(String sprintId) {
    return _actionItemsRef
        .orderByChild('sprintId')
        .equalTo(sprintId)
        .onValue
        .map((event) {
          if (!event.snapshot.exists || event.snapshot.value == null) return [];
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          return data.entries
              .map(
                (e) => ActionItem.fromMap(
                  Map<String, dynamic>.from(e.value),
                  e.key,
                ),
              )
              .toList();
        });
  }

  /// Toggle action item completion status
  Future<void> toggleActionItem(String itemId, bool completed) async {
    await _actionItemsRef.child(itemId).update({
      'completed': completed,
      'completedAt': completed ? ServerValue.timestamp : null,
    });
  }
}
