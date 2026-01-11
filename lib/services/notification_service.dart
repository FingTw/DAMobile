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

    var id = OneSignal.User.pushSubscription.id;
    debugPrint("OneSignal Player ID: \$id");

    OneSignal.User.pushSubscription.addObserver((state) {
      debugPrint("OneSignal Player ID update: \${state.current.id}");
      if (state.current.id != null) {
        syncOneSignalId();
      }
    });

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.preventDefault();
      ToastService.show(
        title: event.notification.title ?? "Thông báo",
        message: event.notification.body ?? "",
        type: NotificationType.info,
      );
    });

    OneSignal.Notifications.addClickListener((event) {
      debugPrint('NOTIFICATION CLICKED: \${event.notification.additionalData}');
      _handleNotificationClick(event.notification.additionalData);
    });
  }

  /// Associates the user's email with their OneSignal profile.
  /// Call this after a user successfully logs in.
  static Future<void> setEmail(String email) async {
    if (email.isEmpty) {
      debugPrint("Email is empty, skipping OneSignal email association.");
      return;
    }
    try {
      await OneSignal.User.addEmail(email: email);
      debugPrint("Successfully associated email with OneSignal: \$email");
    } catch (e) {
      debugPrint("Error associating email with OneSignal: \$e");
    }
  }

  /// Disassociates the user from the OneSignal device record.
  /// Call this when a user logs out.
  static Future<void> logout() async {
    try {
      await OneSignal.logout();
      debugPrint("Successfully logged out from OneSignal.");
    } catch (e) {
      debugPrint("Error logging out from OneSignal: \$e");
    }
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
            debugPrint("Project with ID \$projectId not found.");
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
        DatabaseReference userRef = FirebaseDatabase.instance.ref('users/\${user.uid}');

        await userRef.update({
          'oneSignalId': playerId,
          'lastSync': ServerValue.timestamp, // Dùng timestamp của Realtime DB
        });

        debugPrint("Đã đồng bộ OneSignal ID thành công: \$playerId");
      } catch (e) {
        debugPrint("Lỗi đồng bộ OneSignal ID: \$e");
      }
    } else {
      debugPrint("Chưa lấy được OneSignal ID (null)");
    }
  }
}
