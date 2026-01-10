import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/definition_of_done_model.dart';

/// Repository for Definition of Done-related database operations
/// Extracted from DatabaseService to follow Repository Pattern
class DefinitionOfDoneRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference get _dodRef => _database.ref('definition_of_done');

  /// Create a Definition of Done for a project
  Future<void> createDefinitionOfDone(
    String projectId,
    List<String> items,
  ) async {
    final ref = _dodRef.push();
    await ref.set({
      'projectId': projectId,
      'items': items
          .asMap()
          .entries
          .map(
            (entry) => {
              'description': entry.value,
              'isMandatory': true,
              'order': entry.key,
            },
          )
          .toList(),
      'createdAt': ServerValue.timestamp,
    });
  }

  /// Get Definition of Done for a project
  Stream<DefinitionOfDone?> getDefinitionOfDone(String projectId) {
    return _dodRef.orderByChild('projectId').equalTo(projectId).onValue.map((
      event,
    ) {
      if (!event.snapshot.exists || event.snapshot.value == null) return null;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (data.isEmpty) return null;
      final entry = data.entries.first;
      return DefinitionOfDone.fromMap(
        Map<String, dynamic>.from(entry.value),
        entry.key,
      );
    });
  }
}
