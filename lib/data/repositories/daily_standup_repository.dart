import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/daily_standup_model.dart';

/// Repository for daily standup-related database operations
/// Extracted from DatabaseService to follow Repository Pattern
class DailyStandupRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference get _standupRef => _database.ref('daily_standups');

  /// Add a new daily standup
  Future<void> addDailyStandup(
    String sprintId,
    String projectId,
    String userId,
    String userName,
    String yesterday,
    String today,
    List<String> blockers,
  ) async {
    final ref = _standupRef.push();
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);

    await ref.set({
      'sprintId': sprintId,
      'projectId': projectId,
      'userId': userId,
      'userName': userName,
      'date': dateOnly.millisecondsSinceEpoch,
      'yesterday': yesterday,
      'today': today,
      'blockers': blockers,
      'createdAt': ServerValue.timestamp,
    });
  }

  /// Get all daily standups for a sprint on a specific date
  Stream<List<DailyStandup>> getDailyStandups(String sprintId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _standupRef.orderByChild('sprintId').equalTo(sprintId).onValue.map((
      event,
    ) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries
          .map(
            (e) =>
                DailyStandup.fromMap(Map<String, dynamic>.from(e.value), e.key),
          )
          .where((standup) {
            final standupDate = DateTime(
              standup.date.year,
              standup.date.month,
              standup.date.day,
            );
            return standupDate.isAtSameMomentAs(dateOnly);
          })
          .toList();
    });
  }

  /// Get today's standup for a specific user
  Stream<DailyStandup?> getTodayStandup(String sprintId, String userId) {
    final now = DateTime.now();
    return getDailyStandups(sprintId, now).map((standups) {
      try {
        return standups.firstWhere((s) => s.userId == userId);
      } catch (e) {
        return null;
      }
    });
  }

  /// Get all blockers from the last 7 days for a sprint
  Stream<List<String>> getSprintBlockers(String sprintId) {
    return _standupRef.orderByChild('sprintId').equalTo(sprintId).onValue.map((
      event,
    ) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final allBlockers = <String>[];

      for (var entry in data.entries) {
        final standup = DailyStandup.fromMap(
          Map<String, dynamic>.from(entry.value),
          entry.key,
        );
        if (DateTime.now().difference(standup.date).inDays <= 7) {
          allBlockers.addAll(standup.blockers);
        }
      }

      return allBlockers.where((b) => b.isNotEmpty).toList();
    });
  }
}
