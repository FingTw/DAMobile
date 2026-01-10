import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled3/models/task_model.dart';
import 'package:untitled3/models/project_task_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/services/toast_service.dart';
import 'package:untitled3/widgets/custom_notification_widget.dart';

class DailyNotificationService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final String _lastNotificationKey = 'lastDailyNotification';

  /// Kiểm tra và hiển thị thông báo hàng ngày khi đăng nhập
  static Future<void> checkAndShowDailyNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Kiểm tra xem đã hiển thị thông báo hôm nay chưa
      final userRef = _database.ref('users/${user.uid}');
      final snapshot = await userRef.child(_lastNotificationKey).get();
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      if (snapshot.exists) {
        final lastNotification = DateTime.fromMillisecondsSinceEpoch(snapshot.value as int);
        final lastNotificationDay = DateTime(lastNotification.year, lastNotification.month, lastNotification.day);
        
        // Đã hiển thị thông báo hôm nay rồi
        if (lastNotificationDay == today) {
          return;
        }
      }

      // Lấy thông tin task
      final dbService = DatabaseService(uid: user.uid);
      final personalTasks = await dbService.personalTasks.first;
      
      // Lấy tất cả project tasks của user
      final allProjectTasks = await _getUserProjectTasks(user.uid);

      // Đếm số task sắp đến hạn
      final nowMs = now.millisecondsSinceEpoch;
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowMs = tomorrow.millisecondsSinceEpoch;

      int personalTasksDue = 0;
      int projectTasksDue = 0;
      int overduePersonalTasks = 0;
      int overdueProjectTasks = 0;

      // Kiểm tra personal tasks
      for (var task in personalTasks) {
        if (task.dueDate != null && task.status != TaskStatus.done) {
          final dueMs = task.dueDate!.millisecondsSinceEpoch;
          if (dueMs < nowMs) {
            overduePersonalTasks++;
          } else if (dueMs <= tomorrowMs) {
            personalTasksDue++;
          }
        }
      }

      // Kiểm tra project tasks
      for (var task in allProjectTasks) {
        if (task.assigneeId == user.uid && 
            task.dueDate != null && 
            task.status != ProjectTaskStatus.done) {
          final dueMs = task.dueDate!.millisecondsSinceEpoch;
          if (dueMs < nowMs) {
            overdueProjectTasks++;
          } else if (dueMs <= tomorrowMs) {
            projectTasksDue++;
          }
        }
      }

      // Hiển thị thông báo tổng hợp
      if (overduePersonalTasks > 0 || overdueProjectTasks > 0) {
        final totalOverdue = overduePersonalTasks + overdueProjectTasks;
        ToastService.show(
          title: "⚠️ Cảnh báo",
          message: "Bạn có $totalOverdue task quá hạn cần xử lý ngay!",
          type: NotificationType.error,
          duration: const Duration(seconds: 5),
        );
      } else if (personalTasksDue > 0 || projectTasksDue > 0) {
        final totalDue = personalTasksDue + projectTasksDue;
        ToastService.show(
          title: "📅 Nhắc nhở",
          message: "Bạn có $totalDue task sắp đến hạn trong 24h tới",
          type: NotificationType.warning,
          duration: const Duration(seconds: 4),
        );
      }

      // Lưu thời gian hiển thị thông báo cuối cùng
      await userRef.update({
        _lastNotificationKey: nowMs,
      });
    } catch (e) {
      // Silent fail - không làm gián đoạn flow đăng nhập
      print('Error showing daily notifications: $e');
    }
  }

  /// Lấy tất cả project tasks của user
  static Future<List<ProjectTask>> _getUserProjectTasks(String userId) async {
    try {
      final tasksRef = _database.ref('tasks');
      final snapshot = await tasksRef.get();
      
      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final tasks = <ProjectTask>[];

      for (var entry in data.entries) {
        final taskData = Map<String, dynamic>.from(entry.value as Map);
        if (taskData['assigneeId'] == userId) {
          tasks.add(ProjectTask.fromMap(taskData, entry.key));
        }
      }

      return tasks;
    } catch (e) {
      return [];
    }
  }
}
