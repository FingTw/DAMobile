import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:untitled3/main.dart';
import 'package:untitled3/models/project_model.dart';
import 'package:untitled3/screens/project_details_screen.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/services/toast_service.dart';
import 'package:untitled3/widgets/custom_notification_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationService {
  static const String oneSignalAppId = "6ac28531-232a-43aa-a960-d1114cab6c8a";

  static Future<void> initOneSignal() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    OneSignal.Notifications.addClickListener((event) {
      _handleNotificationClick(event.notification.additionalData);
    });
  }


  static Future<void> _handleNotificationClick(Map<String, dynamic>? data) async {
    if (data == null) return;

    final String? notificationType = data['notification_type'] as String?;
    final String? projectId = data['project_id'] as String?;

    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint("Navigator context is not available");
      return;
    }

    // Switch based on the type of notification
    // This can be expanded for different notification types
    switch (notificationType) {
      case 'project_invite':
      case 'task_assigned':
      case 'deadline_reminder':
      case 'new_member_joined':
      case 'task_completed':
      case 'task_late':
        if (projectId != null) {
          Project? project = await DatabaseService().getProjectById(projectId);
          if (project != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectDetailsScreen(project: project),
              ),
            );
          } else {
            debugPrint("Project with ID $projectId not found.");
          }
        }
        break;
      default:
        debugPrint("Unknown notification type or no action defined.");
        break;
    }
  }
  // Hàm này gọi ở HomeScreen hoặc sau khi Login
  static Future<void> syncOneSignalId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Lấy OneSignal Player ID
    var playerId = OneSignal.User.pushSubscription.id;

    if (playerId != null) {
      // ▼▼▼ SỬA ĐOẠN NÀY: Dùng Realtime Database ▼▼▼
      try {
        DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${user.uid}');

        await userRef.update({
          'oneSignalId': playerId,
          'lastSync': ServerValue.timestamp, // Dùng timestamp của Realtime DB
        });

        debugPrint("Đã đồng bộ OneSignal ID thành công: $playerId");
      } catch (e) {
        debugPrint("Lỗi đồng bộ OneSignal ID: $e");
      }
    } else {
      debugPrint("Chưa lấy được OneSignal ID (null)");
    }
  }
}
